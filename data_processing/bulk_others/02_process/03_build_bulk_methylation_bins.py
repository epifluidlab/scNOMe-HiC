#!/usr/bin/env python
"""Bin bulk WGBS methylation into the same bins as the single-cell matrices.

Produces the GM12878 and IMR90 bulk references that the Figure 2 UMAP notebook
correlates each cell cluster against to assign a cell type.

Inputs
  - ENCODE-style bulk WGBS BEDs (cov + percent-methylated columns), one per cell
    line. Prepared from the ENCODE bigBed with `bigBedToBed`, the same conversion
    01_methylation_process_imr90.sh performs.
  - bins_{label}.tsv from the single-cell matrix build
    (mixture_cellline/02_qc/build_methylation_matrices.sh), so bulk and
    single-cell land on an identical bin grid.

Outputs, next to the BED inputs' root:
  - bulk_methylation_{GM12878,IMR90}.txt.gz          for 250kb
  - bulk_methylation_{GM12878,IMR90}_{label}.txt.gz  for any other bin size

  The 250 kb files are deliberately un-suffixed: that is the name the UMAP
  notebook reads.

Usage:
    03_build_bulk_methylation_bins.py [250kb 100kb ...]     (default: 250kb)

Existing outputs are skipped, so re-running is cheap.
"""

import sys
from pathlib import Path

import numpy as np
import pandas as pd
from tqdm import tqdm


def compute_bin_methylation_from_bed_fast(bed_path, bins_df, chromosomes=None):
    """
    Fast bin-level methylation calculator using ENCODE-style BED files.

    Args:
        bed_path (str): Path to BED file with coverage and percent methylation.
        bins_df (pd.DataFrame): Must contain 'chr', 'start', 'end' columns.
        chromosomes (list[str], optional): Restrict to specific chromosomes.

    Returns:
        pd.DataFrame: bins_df with added 'methylation' column.
    """
    bed = pd.read_csv(bed_path, sep="\t", header=None)
    n_cols = bed.shape[1]

    if n_cols >= 14:
        bed.columns = [
            "chr", "start", "end", "name", "score", "strand",
            "thickStart", "thickEnd", "color", "cov", "percent",
            "ref", "sample", "quality",
        ][:n_cols]
    elif n_cols == 11:
        bed.columns = [
            "chr", "start", "end", "name", "score", "strand",
            "thickStart", "thickEnd", "color", "cov", "percent",
        ]
    else:
        raise ValueError(f"Unsupported BED format with {n_cols} columns.")

    bed["start"] = pd.to_numeric(bed["start"], errors="coerce")
    bed["end"] = pd.to_numeric(bed["end"], errors="coerce")
    bed["cov"] = pd.to_numeric(bed["cov"], errors="coerce")
    bed["percent"] = pd.to_numeric(bed["percent"], errors="coerce")
    bed = bed.dropna(subset=["start", "end", "cov", "percent"])

    bed["methy"] = (bed["cov"] * bed["percent"] / 100).astype(int)

    if chromosomes:
        bed = bed[bed["chr"].isin(chromosomes)]
        bins_df = bins_df[bins_df["chr"].isin(chromosomes)]

    bins_df = bins_df.copy()
    bins_df["start"] = pd.to_numeric(bins_df["start"], errors="coerce")
    bins_df["end"] = pd.to_numeric(bins_df["end"], errors="coerce")
    bins_df = bins_df.dropna(subset=["start", "end"])

    bed_by_chr = {chrom: df for chrom, df in bed.groupby("chr")}
    results = []

    for chrom, group in tqdm(bins_df.groupby("chr"), desc="Processing chromosomes"):
        group = group.copy()
        if chrom not in bed_by_chr:
            group["methylation"] = np.nan
            results.append(group)
            continue

        chr_bed = bed_by_chr[chrom]
        starts = group["start"].values
        ends = group["end"].values
        chr_result = []

        for start, end in zip(starts, ends):
            overlaps = chr_bed[(chr_bed["start"] >= start) & (chr_bed["end"] <= end)]
            if not overlaps.empty:
                methy_sum = overlaps["methy"].sum()
                cov_sum = overlaps["cov"].sum()
                methylation = methy_sum / cov_sum if cov_sum > 0 else np.nan
            else:
                methylation = np.nan
            chr_result.append(methylation)

        group["methylation"] = chr_result
        results.append(group)

    return pd.concat(results, ignore_index=True)


def main():
    root = Path("/gpfs/projects/b1198/epifluidlab/yoshii/sc_nomehic_cellline")
    bins_root = root / "snakemake" / "QC" / "methylation_matrices"

    # ENCODE bulk WGBS, converted from bigBed with bigBedToBed
    beds = {
        "GM12878": root / "methy" / "bulk" / "GM12878.bed.gz",
        "IMR90":   root / "methy" / "bulk" / "IMR90.bed.gz",
    }

    labels = sys.argv[1:] or ["250kb"]

    for label in labels:
        bins_path = bins_root / f"bins_{label}.tsv"
        if not bins_path.exists():
            raise SystemExit(
                f"missing {bins_path} — build it first with "
                f"mixture_cellline/02_qc/build_methylation_matrices.sh {label}"
            )
        # bins_{label}.tsv has columns: bin_id, chr, start, end
        bins = pd.read_csv(bins_path, sep="\t")[["chr", "start", "end"]]
        print(f"Loaded {len(bins):,} {label} bins from {bins_path}")

        for cell, bed_path in beds.items():
            # 250kb keeps the historical un-suffixed name the UMAP notebook reads
            suffix = "" if label == "250kb" else f"_{label}"
            out_path = root / f"bulk_methylation_{cell}{suffix}.txt.gz"
            print(f"\n=== {cell} @ {label}: {bed_path.name} -> {out_path.name} ===")
            if out_path.exists():
                print(f"  SKIP (output already exists): {out_path}")
                continue
            if not bed_path.exists():
                raise SystemExit(f"missing bulk WGBS bed: {bed_path}")
            out = compute_bin_methylation_from_bed_fast(str(bed_path), bins)
            out.to_csv(out_path, sep="\t", index=False, compression="gzip")
            print(f"  wrote {out_path} ({len(out):,} rows, "
                  f"{out['methylation'].notna().sum():,} non-NA)")


if __name__ == "__main__":
    main()
