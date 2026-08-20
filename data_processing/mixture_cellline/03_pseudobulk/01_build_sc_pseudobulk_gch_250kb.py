#!/usr/bin/env python
"""Read-weighted single-cell pseudobulk GpC (GCH) accessibility over 250 kb bins, per cell type.

GCH analogue of build_sc_pseudobulk_hcg_250kb.py. For each 250 kb bin and each cell type
(GM12878 / IMR90) we pool reads across ALL cells of that type:
    pseudobulk_acc(bin) = sum(methylated GCH reads) / sum(total GCH reads)
i.e. read-weighted (NOT the mean of per-cell ratios). GCH methylation = GpC accessibility.

Per-cell input: 07.bistools_snakemake/methylation/<cell>/<cell>.cyt.filtered.sort.GCH.6plus2.bed.gz
  columns: chrom, start(0-based), end, name, score, strand, meth%(col6), coverage(col7)
Bins:  snakemake/QC/methylation_matrices/bins_250kb.tsv  (bin_id, chr, start[1-based], end).
Cells: cellline_passed.txt ∩ cell_type_table.tsv (labelled GM12878/IMR90) ∩ has GCH bed.

Output (analysis/gch_acc_250kb/):
  sc_pseudobulk_GCH_250kb.tsv.gz  per bin: chr,start,end,bin_id,
      GM12878_meth, GM12878_total, GM12878_beta,
      IMR90_meth,   IMR90_total,   IMR90_beta,
      delta_IMR90_minus_GM12878, n_cells_GM12878, n_cells_IMR90

Run via codes/build_sc_pseudobulk_gch_250kb.sh (SLURM). Env: scnomehic (pandas/numpy).
"""
import os, sys, gzip
from concurrent.futures import ProcessPoolExecutor

import numpy as np
import pandas as pd

FIG2   = "/gpfs/projects/b1198/epifluidlab/yoshii/scnomehic_paper/fig2"
SCSNK  = "/gpfs/projects/b1198/epifluidlab/yoshii/sc_nomehic_cellline/snakemake"
BINS   = os.path.join(SCSNK, "QC/methylation_matrices/bins_250kb.tsv")
PASSED = os.path.join(SCSNK, "QC/cellline_passed.txt")
LABELS = os.path.join(SCSNK, "subset_clustering/250kb/annotation/cell_type_table.tsv")
METHDIR= os.path.join(SCSNK, "07.bistools_snakemake/methylation")
OUTDIR = os.path.join(FIG2, "analysis/gch_acc_250kb")
NCPU   = int(os.environ.get("NCPU", "8"))

def gch_path(cell):
    return os.path.join(METHDIR, cell, f"{cell}.cyt.filtered.sort.GCH.6plus2.bed.gz")

def bins_by_chrom(bins):
    """bin start is 1-based -> 0-based start0; cytosine bed pos is 0-based start."""
    by = {}
    for chrom, g in bins.groupby("chr"):
        by[str(chrom)] = (g["start"].to_numpy() - 1, g["end"].to_numpy(), g["idx"].to_numpy())
    return by

def count_cell(args):
    cell, by_chrom, nbin = args
    meth = np.zeros(nbin); total = np.zeros(nbin)
    path = gch_path(cell)
    try:
        with gzip.open(path, "rt") as fh:
            skip = 1 if fh.readline().startswith("track") else 0
        df = pd.read_csv(path, sep="\t", header=None, skiprows=skip,
                         usecols=[0, 1, 6, 7], names=["chrom", "pos", "pct", "cov"],
                         dtype={"chrom": "str", "pos": "int64",
                                "pct": "float64", "cov": "float64"})
    except Exception as e:
        sys.stderr.write(f"[WARN] {cell}: read failed ({e})\n")
        return cell, meth, total
    df["m"] = np.round(df["pct"] / 100.0 * df["cov"])      # integer methylated reads
    for chrom, g in df.groupby("chrom"):
        if chrom not in by_chrom:
            continue
        starts0, ends, idx = by_chrom[chrom]
        pos = g["pos"].to_numpy(); order = np.argsort(pos)
        pos = pos[order]
        ccov = np.concatenate([[0.0], np.cumsum(g["cov"].to_numpy()[order])])
        cm   = np.concatenate([[0.0], np.cumsum(g["m"].to_numpy()[order])])
        lo = np.searchsorted(pos, starts0, side="left")
        hi = np.searchsorted(pos, ends,    side="left")    # pos < end
        for j, a, b in zip(idx, lo, hi):
            if b > a:
                total[j] += ccov[b] - ccov[a]
                meth[j]  += cm[b]  - cm[a]
    return cell, meth, total

def main():
    os.makedirs(OUTDIR, exist_ok=True)
    bins = pd.read_csv(BINS, sep="\t")
    bins["idx"] = np.arange(len(bins))
    by_chrom = bins_by_chrom(bins); nbin = len(bins)
    print(f"bins: {nbin}", flush=True)

    lab = pd.read_csv(LABELS, sep="\t")
    ct = dict(zip(lab["cell"], lab["cell_type"]))
    passed = [c.strip() for c in open(PASSED) if c.strip()]
    cells = [c for c in passed if c in ct and os.path.exists(gch_path(c))]
    types = {c: ct[c] for c in cells}
    n_gm  = sum(1 for c in cells if types[c] == "GM12878")
    n_imr = sum(1 for c in cells if types[c] == "IMR90")
    print(f"cells: {len(cells)} ({n_gm} GM12878 + {n_imr} IMR90)", flush=True)

    acc = {"GM12878": [np.zeros(nbin), np.zeros(nbin)],
           "IMR90":   [np.zeros(nbin), np.zeros(nbin)]}
    args = [(c, by_chrom, nbin) for c in cells]
    with ProcessPoolExecutor(max_workers=NCPU) as ex:
        for k, (cell, meth, total) in enumerate(ex.map(count_cell, args), 1):
            a = acc[types[cell]]; a[0] += meth; a[1] += total
            if k % 50 == 0 or k == len(cells):
                print(f"  {k}/{len(cells)} cells", flush=True)

    out = bins[["chr", "start", "end", "bin_id"]].copy()
    for t in ("GM12878", "IMR90"):
        m, tot = acc[t]
        out[f"{t}_meth"]  = m.astype(np.int64)
        out[f"{t}_total"] = tot.astype(np.int64)
        with np.errstate(invalid="ignore", divide="ignore"):
            out[f"{t}_beta"] = np.where(tot > 0, m / tot, np.nan)
    out["delta_IMR90_minus_GM12878"] = out["IMR90_beta"] - out["GM12878_beta"]
    out["n_cells_GM12878"] = n_gm
    out["n_cells_IMR90"]   = n_imr

    fout = os.path.join(OUTDIR, "sc_pseudobulk_GCH_250kb.tsv.gz")
    out.to_csv(fout, sep="\t", index=False, compression="gzip")
    cov = (out["GM12878_total"] > 0) & (out["IMR90_total"] > 0)
    print(f"DONE. {nbin} bins; both-type covered: {int(cov.sum())} "
          f"({cov.mean():.1%}). wrote -> {fout}", flush=True)

if __name__ == "__main__":
    main()
