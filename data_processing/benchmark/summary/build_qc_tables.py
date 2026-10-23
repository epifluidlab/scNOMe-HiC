#!/usr/bin/env python
# --- repo paths: edit paths.yaml at the repository root, not this file -------
import os as _os, sys as _sys
_r = _os.path.dirname(_os.path.abspath(__file__))
while _r != "/" and not _os.path.exists(_os.path.join(_r, "paths.py")):
    _r = _os.path.dirname(_r)
_sys.path.insert(0, _r)
from paths import DATA, REFERENCE, SOFTWARE, WORK, TMP, CONDA_SH, CONDA_ENVS

"""
Assemble the CONSISTENT per-cell QC tables that qc.ipynb plots, from the harmonized
sources. Writes:
  summary/qc_tables/align.csv  -> dataset, cell, uniq_preDedup, uniq_postDedup,
                                   rate_preDedup, rate_postDedup   (metrics 2 & 3)
  summary/qc_tables/hic.csv    -> dataset, cell, cis_n, cis_gt1kb, trans_ratio,
                                   cis_per_million                 (metrics 4,5,6; MapQ30)
Conversion (metric 1) and loci already live in summary/conversion_percell.csv and
summary/gch_hcg_counts/all_methods.summary.txt.
"""
import glob, gzip, os
import numpy as np
import pandas as pd

B = WORK + "/benchmark"
GM = WORK + "/gm12878_cellline/04.alignment_snakemake"
OUT = f"{B}/summary/qc_tables"
os.makedirs(OUT, exist_ok=True)

# ---------- metrics 2 & 3 ----------
fc = pd.read_csv(f"{B}/summary/frag_counts_all.tsv", sep="\t")
fc[["dataset", "cell", "uniq_preDedup", "uniq_postDedup",
    "mapq30_preDedup", "mapq30_postDedup",
    "rate_preDedup", "rate_postDedup"]].to_csv(f"{OUT}/align.csv", index=False)
print(f"align.csv: {len(fc)} cells")

# ---------- metrics 4,5,6 (Hi-C contacts, MapQ30-consistent) ----------
def parse_summary(path, opener=open):
    d = {}
    with opener(path, "rt") as fh:
        for ln in fh:
            p = ln.rstrip("\n").split("\t")
            if len(p) >= 2 and p[1] not in ("", None):
                try:
                    d[p[0].rstrip(":")] = float(p[1])
                except ValueError:
                    pass
    return d

rows = []
def add(ds, cell, cis, cis1kb, trans, mapped_mapq30):
    denom = cis + trans
    tr = trans / denom if denom and denom > 0 else np.nan
    cpm = cis1kb / (mapped_mapq30 / 1e6) if mapped_mapq30 and mapped_mapq30 > 0 else np.nan
    rows.append(dict(dataset=ds, cell=str(cell), cis_n=cis, cis_gt1kb=cis1kb,
                     trans_ratio=tr, cis_per_million=cpm))

# nagano
for f in glob.glob(f"{B}/nagano/alignment/*.summary.txt"):
    d = parse_summary(f)
    add("nagano", os.path.basename(f)[:-len(".summary.txt")],
        d.get("UniqMappedMapQ30NoPcrCis", np.nan), d.get("UniqMappedMapQ30NoPcrCisMore1kb", np.nan),
        d.get("UniqMappedMapQ30NoPcrTrans", np.nan), d.get("UniqMappedMapQ30", np.nan))
# scnomehic (180 QC-passing cells). The previous list (gm_passed.txt, 187) was
# built WITHOUT the chrM non-CpG gate -- the 7 extra cells carry 5.17-6.81% chrM
# non-CpG against a <5 threshold, i.e. incomplete bisulfite conversion. 180 is the
# set Supp Table 1's "QC pass" column and every gm_sc_new figure use.
PASSED_180 = os.path.join(B, "summary", "gm12878_passed_180.txt")
passed = set(pd.read_csv(PASSED_180, header=None)[0].astype(str))
for c in passed:
    f = f"{GM}/{c}.summary.txt.gz"
    if os.path.exists(f):
        d = parse_summary(f, gzip.open)
        add("scnomehic", c, d.get("UniqMappedMapQ30NoPcrCis", np.nan), d.get("UniqMappedMapQ30NoPcrCisMore1kb", np.nan),
            d.get("UniqMappedMapQ30NoPcrTrans", np.nan), d.get("UniqMappedMapQ30", np.nan))
# droplethic -- DEDUPLICATED (pairtools dedup, job 4568716; 61.1% duplicate rate,
# confirmed by chr21 spot-check 59.3% and the paper's own 174,600->73,813 arithmetic).
# The previous source (SRR27586278_hg38.per_cell_qc.valid.tsv) was PRE-dedup because
# snakemake stopped at pairtools_sort, so the bar was ~2.8x inflated (8,535 -> 3,048).
# Restricted to barcodes with >=10,000 unique pairs, which recovers 3,646 cells,
# matching the 3,668-barcode set the pre-dedup table used (the rest are ambient
# droplets with a median of 2 pairs).
dt = pd.read_csv(f"{B}/droplethic/my_project/droplethic_percell_DEDUP.tsv", sep="\t")
dt = dt[dt["total"] >= 10000]
for _, r in dt.iterrows():
    # cis_short + cis_gt1kb = all cis; `total` = cis + trans (already MapQ30 via
    # pairtools parse --min-mapq 30, and deduplicated)
    add("droplethic", r["cell"], r["cis_short"] + r["cis_gt1kb"], r["cis_gt1kb"],
        r["trans"], r["total"])
# snmCseq3 -> GENUINE snm3C-seq (PRJNA658701, "[CEMBA snm3C-seq]", 100 cells).
# The old source was GSE213259, which GEO records as "Library strategy: snmC-seq2"
# -- a methylome-only assay with NO proximity ligation, mislabelled snm3C-seq.
# Its cis>1kb median was 8,372 against 114,980 for genuine snm3C-seq through the
# same YAP m3c pipeline. The internal key stays `snmCseq3`; the displayed label is
# "snm3C-seq (Liu et al. 2021)" -- PRJNA658701 is GEO GSE156683, published as
# Liu et al., Nature 598:120-128 (2021), doi 10.1038/s41586-020-03182-8.
sn = pd.read_csv(f"{B}/summary/snm3c_new_hic.tsv", sep="\t")
for _, r in sn.iterrows():
    add("snmCseq3", r["cell"], r["cis_n"], r["cis_gt1kb"], r["trans"], r["mapped_mapq30"])

hic = pd.DataFrame(rows)
hic.to_csv(f"{OUT}/hic.csv", index=False)
print(f"hic.csv: {len(hic)} cells")
print(hic.groupby("dataset").agg(n=("cell", "size"), med_cis1kb=("cis_gt1kb", "median"),
      med_trans=("trans_ratio", "median")).round(4).to_string())
