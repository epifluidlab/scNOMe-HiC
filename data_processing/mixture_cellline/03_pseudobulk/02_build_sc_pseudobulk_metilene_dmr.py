#!/usr/bin/env python
# --- repo paths: edit paths.yaml at the repository root, not this file -------
import os as _os, sys as _sys
_r = _os.path.dirname(_os.path.abspath(__file__))
while _r != "/" and not _os.path.exists(_os.path.join(_r, "paths.py")):
    _r = _os.path.dirname(_r)
_sys.path.insert(0, _r)
from paths import DATA, REFERENCE, SOFTWARE, WORK, TMP, CONDA_SH, CONDA_ENVS

"""Read-weighted single-cell pseudobulk HCG methylation over selected metilene DMRs, per cell type.

Selection: from the metilene significant DMRs (q<QMAX, |meandiff|>=DMIN, #CpGs>=CPGMIN), take the
top N_PER_DIR per direction (IMR90-hyper = meandiff<0, GM12878-hyper = meandiff>0; metilene
meandiff = GM12878 - IMR90), ranked by q-value ascending then |meandiff| descending.

For each selected DMR and each cell type, pool reads across ALL cells of that type:
    beta = sum(methylated HCG reads) / sum(total HCG reads)
Per-cell input: 07.bistools_snakemake/methylation/<cell>/<cell>.cyt.filtered.sort.HCG.6plus2.bed.gz
  (cols: chrom, start[0-based], end, name, score, strand, meth%[col6], coverage[col7];
   methylated reads = round(meth%/100 * cov)).
Cells: cellline_passed.txt ∩ cell_type_table.tsv (281 GM12878 + 160 IMR90), with HCG bed.

Output (analysis/dmr_metilene_hcg/sc_pseudobulk_metilene_dmr_top<N>.tsv.gz), one row per DMR:
  chr start stop region_id dir qvalue meandiff_GM_minus_IMR nCpG bulk_mean_GM bulk_mean_IMR
  GM12878_meth GM12878_total GM12878_beta  IMR90_meth IMR90_total IMR90_beta
  sc_delta_IMR_minus_GM  n_cells_GM12878 n_cells_IMR90
Read counts (meth/total) are recorded so DMRs can be filtered by coverage downstream.
"""
import os, sys, gzip
from concurrent.futures import ProcessPoolExecutor

import numpy as np
import pandas as pd

FIG2   = WORK + "/analysis/fig2"
SCSNK  = WORK + "/mixture_cellline"
DMRFILE= os.path.join(FIG2, "analysis/dmr_metilene_hcg/metilene_GM12878_IMR90.dmr.txt")
PASSED = os.path.join(SCSNK, "QC/cellline_passed.txt")
LABELS = os.path.join(SCSNK, "subset_clustering/250kb/annotation/cell_type_table.tsv")
METHDIR= os.path.join(SCSNK, "07.bistools_snakemake/methylation")
OUTDIR = os.path.join(FIG2, "analysis/dmr_metilene_hcg")

N_PER_DIR = int(os.environ.get("N_PER_DIR", "2000"))
QMAX   = float(os.environ.get("QMAX", "0.05"))
DMIN   = float(os.environ.get("DMIN", "0.1"))
CPGMIN = int(os.environ.get("CPGMIN", "10"))
NCPU   = int(os.environ.get("NCPU", "8"))

def hcg_path(cell):
    return os.path.join(METHDIR, cell, f"{cell}.cyt.filtered.sort.HCG.6plus2.bed.gz")

def select_dmrs():
    cols = ["chr","start","stop","qvalue","meandiff","nCpG","p_MWU","p_2DKS","mean_GM","mean_IMR"]
    d = pd.read_csv(DMRFILE, sep="\t", header=None, names=cols)
    sig = d[(d.qvalue < QMAX) & (d.meandiff.abs() >= DMIN) & (d.nCpG >= CPGMIN)].copy()
    sig["absdiff"] = sig.meandiff.abs()
    imr = (sig[sig.meandiff < 0]                          # IMR90 > GM12878
           .sort_values(["qvalue","absdiff"], ascending=[True, False]).head(N_PER_DIR))
    gm  = (sig[sig.meandiff > 0]                          # GM12878 > IMR90
           .sort_values(["qvalue","absdiff"], ascending=[True, False]).head(N_PER_DIR))
    imr = imr.assign(dir="IMR90-hyper"); gm = gm.assign(dir="GM12878-hyper")
    sel = pd.concat([gm, imr]).reset_index(drop=True)
    sel["region_id"] = (sel.chr.astype(str)+":"+sel.start.astype(str)+"-"+sel.stop.astype(str))
    print(f"selected {len(sel)} DMRs: {(sel.dir=='GM12878-hyper').sum()} GM-hyper / "
          f"{(sel.dir=='IMR90-hyper').sum()} IMR-hyper "
          f"(from sig set q<{QMAX},|d|>={DMIN},#CpG>={CPGMIN})", flush=True)
    return sel

def regions_by_chrom(sel):
    by = {}
    for chrom, g in sel.groupby("chr"):
        by[str(chrom)] = (g.start.to_numpy(), g.stop.to_numpy(), g.region_id.to_numpy())
    return by

def count_cell(args):
    """Sum methylated & total HCG reads per selected DMR (region) for one cell."""
    cell, by_chrom, ridx = args
    meth = np.zeros(len(ridx)); total = np.zeros(len(ridx))
    path = hcg_path(cell)
    try:
        with gzip.open(path, "rt") as fh:
            skip = 1 if fh.readline().startswith("track") else 0
        df = pd.read_csv(path, sep="\t", header=None, skiprows=skip,
                         usecols=[0,1,6,7], names=["chrom","pos","pct","cov"],
                         dtype={"chrom":"str","pos":"int64","pct":"float64","cov":"float64"})
    except Exception as e:
        sys.stderr.write(f"[WARN] {cell}: read failed ({e})\n"); return cell, meth, total
    df["m"] = np.round(df["pct"]/100.0*df["cov"])
    for chrom, g in df.groupby("chrom"):
        if chrom not in by_chrom: continue
        starts, stops, rids = by_chrom[chrom]
        pos = g["pos"].to_numpy(); order = np.argsort(pos); pos = pos[order]
        ccov = np.concatenate([[0.0], np.cumsum(g["cov"].to_numpy()[order])])
        cm   = np.concatenate([[0.0], np.cumsum(g["m"].to_numpy()[order])])
        lo = np.searchsorted(pos, starts, side="left")
        hi = np.searchsorted(pos, stops,  side="right")   # CpGs in [start, stop] inclusive
        for rid, a, b in zip(rids, lo, hi):
            if b > a:
                j = ridx[rid]; total[j] += ccov[b]-ccov[a]; meth[j] += cm[b]-cm[a]
    return cell, meth, total

def main():
    os.makedirs(OUTDIR, exist_ok=True)
    sel = select_dmrs()
    rid_order = sel.region_id.tolist(); ridx = {r:i for i,r in enumerate(rid_order)}
    by_chrom = regions_by_chrom(sel)

    lab = pd.read_csv(LABELS, sep="\t"); ct = dict(zip(lab.cell, lab.cell_type))
    passed = [c.strip() for c in open(PASSED) if c.strip()]
    cells = [c for c in passed if c in ct and os.path.exists(hcg_path(c))]
    types = {c: ct[c] for c in cells}
    n_gm  = sum(t=="GM12878" for t in types.values()); n_imr = sum(t=="IMR90" for t in types.values())
    print(f"cells: {len(cells)} ({n_gm} GM12878 + {n_imr} IMR90)", flush=True)

    acc = {"GM12878":[np.zeros(len(rid_order)), np.zeros(len(rid_order))],
           "IMR90":  [np.zeros(len(rid_order)), np.zeros(len(rid_order))]}
    args = [(c, by_chrom, ridx) for c in cells]
    with ProcessPoolExecutor(max_workers=NCPU) as ex:
        for k,(cell,meth,total) in enumerate(ex.map(count_cell, args), 1):
            a = acc[types[cell]]; a[0]+=meth; a[1]+=total
            if k%50==0 or k==len(cells): print(f"  {k}/{len(cells)} cells", flush=True)

    out = sel[["chr","start","stop","region_id","dir","qvalue","meandiff","nCpG","mean_GM","mean_IMR"]].copy()
    out = out.rename(columns={"meandiff":"meandiff_GM_minus_IMR","mean_GM":"bulk_mean_GM","mean_IMR":"bulk_mean_IMR"})
    for t in ("GM12878","IMR90"):
        m, tot = acc[t]
        idx = [ridx[r] for r in out.region_id]
        out[f"{t}_meth"]  = np.asarray(m)[idx].astype(np.int64)
        out[f"{t}_total"] = np.asarray(tot)[idx].astype(np.int64)
        with np.errstate(invalid="ignore", divide="ignore"):
            out[f"{t}_beta"] = np.where(np.asarray(tot)[idx] > 0, np.asarray(m)[idx]/np.asarray(tot)[idx], np.nan)
    out["sc_delta_IMR_minus_GM"] = out["IMR90_beta"] - out["GM12878_beta"]
    out["n_cells_GM12878"] = n_gm; out["n_cells_IMR90"] = n_imr

    fout = os.path.join(OUTDIR, f"sc_pseudobulk_metilene_dmr_top{N_PER_DIR}.tsv.gz")
    out.to_csv(fout, sep="\t", index=False, compression="gzip")
    both = (out.GM12878_total>0) & (out.IMR90_total>0)
    print(f"DONE. {len(out)} DMRs; both-type covered: {int(both.sum())} ({both.mean():.1%}). "
          f"median total reads GM={int(out.GM12878_total.median())} IMR={int(out.IMR90_total.median())}", flush=True)
    print("wrote ->", fout, flush=True)

if __name__ == "__main__":
    main()
