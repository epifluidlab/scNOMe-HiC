#!/usr/bin/env python3
"""
Pseudobulk GCH (accessibility) / HCG (CpG methylation) per replicate.

POOLED RATIO (not mean of per-cell ratios):
  For each genomic bin, sum methylated_reads and total_reads across all cells
  in the replicate, THEN divide:  methylation_level = sum(meth) / sum(total).

Per-cell input (from 08.methylation_snakemake/), one file per cell:
  {cell}.{context}.{label}_methylation.txt.gz
  columns: bin_id  chr  start  end  methylated_reads  total_reads  methylation_level

Output (one per rep x context):
  {rep}.{context}.{label}.pseudobulk.txt.gz
  columns: bin_id chr start end methylated_reads total_reads methylation_level n_cells_covered
  and a plain bedGraph: {rep}.{context}.{label}.pseudobulk.bedGraph
    (chr start end methylation_level ; bins with total_reads==0 are dropped)

Usage:
  01_pseudobulk_methylation.py --rep rep1 --context GCH --label 250kb \
      --cell_list cell_lists/rep1.txt --methy_dir 08.methylation_snakemake \
      --out_dir replicate_comparison/pseudobulk
"""
import argparse
import os
import sys
import numpy as np
import pandas as pd


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--rep", required=True)
    ap.add_argument("--context", required=True, choices=["GCH", "HCG"])
    ap.add_argument("--label", required=True, help="bin label, e.g. 250kb")
    ap.add_argument("--cell_list", required=True)
    ap.add_argument("--methy_dir", required=True)
    ap.add_argument("--out_dir", required=True)
    args = ap.parse_args()

    os.makedirs(args.out_dir, exist_ok=True)

    with open(args.cell_list) as fh:
        cells = [ln.strip() for ln in fh if ln.strip()]
    print(f"[{args.rep}/{args.context}] {len(cells)} cells", flush=True)

    ref = None            # bin_id,chr,start,end from the first file (fixed bin grid)
    meth_sum = None       # summed methylated_reads
    tot_sum = None        # summed total_reads
    cov_cells = None      # per-bin count of cells with total_reads > 0
    n_used = 0
    n_missing = 0

    for i, cell in enumerate(cells):
        path = os.path.join(args.methy_dir,
                            f"{cell}.{args.context}.{args.label}_methylation.txt.gz")
        if not os.path.exists(path):
            n_missing += 1
            print(f"[WARN] missing {path}", file=sys.stderr)
            continue

        df = pd.read_csv(path, sep="\t",
                         usecols=["bin_id", "chr", "start", "end",
                                  "methylated_reads", "total_reads"])
        m = df["methylated_reads"].to_numpy(dtype=np.int64)
        t = df["total_reads"].to_numpy(dtype=np.int64)

        if ref is None:
            ref = df[["bin_id", "chr", "start", "end"]].reset_index(drop=True)
            meth_sum = np.zeros(len(df), dtype=np.int64)
            tot_sum = np.zeros(len(df), dtype=np.int64)
            cov_cells = np.zeros(len(df), dtype=np.int64)
        else:
            # bin grid must be identical across cells (same reference tiling).
            if len(df) != len(ref) or not (df["bin_id"].values == ref["bin_id"].values).all():
                # fall back to bin_id alignment
                df = df.set_index("bin_id").reindex(ref["bin_id"]).reset_index()
                m = df["methylated_reads"].fillna(0).to_numpy(dtype=np.int64)
                t = df["total_reads"].fillna(0).to_numpy(dtype=np.int64)

        meth_sum += m
        tot_sum += t
        cov_cells += (t > 0).astype(np.int64)
        n_used += 1

        if (i + 1) % 100 == 0:
            print(f"  ...{i + 1}/{len(cells)} processed", flush=True)

    if ref is None:
        sys.exit(f"ERROR: no input files found for {args.rep}/{args.context}")

    with np.errstate(divide="ignore", invalid="ignore"):
        level = np.where(tot_sum > 0, meth_sum / tot_sum, np.nan)

    out = ref.copy()
    out["methylated_reads"] = meth_sum
    out["total_reads"] = tot_sum
    out["methylation_level"] = level
    out["n_cells_covered"] = cov_cells

    base = os.path.join(args.out_dir, f"{args.rep}.{args.context}.{args.label}.pseudobulk")
    out.to_csv(base + ".txt.gz", sep="\t", index=False,
               float_format="%.6f", na_rep="")

    bg = out.loc[out["total_reads"] > 0, ["chr", "start", "end", "methylation_level"]]
    # bedGraph uses 0-based start
    bg = bg.copy()
    bg["start"] = bg["start"] - 1
    bg.to_csv(base + ".bedGraph", sep="\t", index=False, header=False,
              float_format="%.6f")

    covered = int((tot_sum > 0).sum())
    print(f"[{args.rep}/{args.context}] cells used={n_used} missing={n_missing}", flush=True)
    print(f"  bins total={len(out)} covered={covered} "
          f"({100.0 * covered / len(out):.1f}%)", flush=True)
    print(f"  pooled mean level (covered bins)="
          f"{np.nanmean(level):.4f}", flush=True)
    print(f"  wrote {base}.txt.gz and {base}.bedGraph", flush=True)


if __name__ == "__main__":
    main()
