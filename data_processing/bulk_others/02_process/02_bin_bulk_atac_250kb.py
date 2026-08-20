#!/usr/bin/env python
"""Bin bulk ATAC-seq signal bigWigs to 250 kb bins (mean signal), per cell line.

Provides the bulk reference for the sc GCH 250 kb pseudobulk accessibility comparison
(parallel to bulk WGBS for the HCG methylation pseudobulk).

bigWigs: data/bulk/{GM12878,IMR90}/atac/*.bigWig (ENCODE signal p-value, GRCh38).
Bins:    snakemake/QC/methylation_matrices/bins_250kb.tsv (bin_id, chr, start[1-based], end).
Output:  analysis/gch_acc_250kb/bulk_atac_250kb.tsv  (bin_id, chr, start, end, GM12878_atac, IMR90_atac).
"""
import os
import numpy as np
import pandas as pd
import pyBigWig

FIG2  = "/gpfs/projects/b1198/epifluidlab/yoshii/scnomehic_paper/fig2"
SCSNK = "/gpfs/projects/b1198/epifluidlab/yoshii/sc_nomehic_cellline/snakemake"
BINS  = os.path.join(SCSNK, "QC/methylation_matrices/bins_250kb.tsv")
BW = {"GM12878": os.path.join(FIG2, "data/bulk/GM12878/atac/ENCFF667MDI.bigWig"),
      "IMR90":   os.path.join(FIG2, "data/bulk/IMR90/atac/ENCFF770EAV.bigWig")}
OUTDIR = os.path.join(FIG2, "analysis/gch_acc_250kb")

def bin_bw(path, bins):
    bw = pyBigWig.open(path); chroms = set(bw.chroms().keys())
    vals = np.full(len(bins), np.nan)
    for i, (chrom, s1, e) in enumerate(zip(bins["chr"], bins["start"], bins["end"])):
        if chrom not in chroms:
            continue
        e = min(int(e), bw.chroms()[chrom]); s0 = int(s1) - 1
        if e <= s0:
            continue
        v = bw.stats(chrom, s0, e, type="mean")[0]
        if v is not None:
            vals[i] = v
    bw.close()
    return vals

def main():
    os.makedirs(OUTDIR, exist_ok=True)
    bins = pd.read_csv(BINS, sep="\t")
    out = bins[["bin_id", "chr", "start", "end"]].copy()
    for t, p in BW.items():
        print(f"binning {t}: {os.path.basename(p)}", flush=True)
        out[f"{t}_atac"] = bin_bw(p, bins)
    fout = os.path.join(OUTDIR, "bulk_atac_250kb.tsv")
    out.to_csv(fout, sep="\t", index=False)
    cov = out[["GM12878_atac", "IMR90_atac"]].notna().all(axis=1)
    print(f"DONE. {len(out)} bins; both covered: {int(cov.sum())} ({cov.mean():.1%}). wrote -> {fout}")

if __name__ == "__main__":
    main()
