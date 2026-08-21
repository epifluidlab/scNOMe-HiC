#!/usr/bin/env python3
"""
Step 3: Hi-C SCC (hicrep) between two replicate pseudobulk .hic files.

Mirrors sc_nomehic_cellline/snakemake/scc_violin_R/compute_scc_tidy.py:
  RES = [1Mb, 500kb, 250kb], H = 3, per-chromosome SCC. Dumps 'observed NONE' from
  each .hic, aligns both to a common bin count, then computes SCC two ways:
    - raw      : hicrepSCC on the raw counts
    - clip95   : hicrepSCC after a per-chromosome 95th-percentile clip
                 (np.minimum(m, np.percentile(m, 95))) -- the FINAL metric matching
                 cellline hic_comparison_gm_clean.ipynb section 3b.
  All chromosomes are kept (chr4 exclusion in the cellline was GM12878-specific).

mm10 autosomes + X:  chr1..chr19, chrX.

Usage:
  03_scc_hicrep.py --hic1 hic/rep1.mapQ30.hic --hic2 hic/rep2.mapQ30.hic \
      --juicer <juicer_tools.jar> --out_dir results/scc [--dump_dir results/scc/dumps]
"""
import argparse
import os
import re
import subprocess
import sys
import numpy as np
import pandas as pd
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import cooler
from hicrep import hicrepSCC

RES_LIST = [1_000_000, 500_000, 250_000]
RES_LABEL = {1_000_000: "1Mb", 500_000: "500kb", 250_000: "250kb"}
H_SMOOTH = 3
CHROMS = [f"chr{i}" for i in range(1, 20)] + ["chrX"]


def dump(juicer, hic, chrom, res, out_path):
    """juicer_tools dump observed NONE -> 'start1 start2 count' triplets."""
    if os.path.exists(out_path) and os.path.getsize(out_path) > 0:
        return out_path
    cmd = ["java", "-Xmx8g", "-jar", juicer, "dump", "observed", "NONE",
           hic, chrom, chrom, "BP", str(res), out_path]
    subprocess.run(cmd, check=True,
                   stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    return out_path


def load_matrix(path, res):
    if not os.path.exists(path) or os.path.getsize(path) == 0:
        return np.zeros((0, 0), dtype=float)
    df = pd.read_csv(path, sep="\t", header=None, names=["s1", "s2", "count"])
    if df.empty:
        return np.zeros((0, 0), dtype=float)
    b1 = (df["s1"] // res).astype(int).to_numpy()
    b2 = (df["s2"] // res).astype(int).to_numpy()
    n = int(max(b1.max(), b2.max()) + 1)
    m = np.zeros((n, n), dtype=float)
    m[b1, b2] = df["count"].to_numpy(dtype=float)
    m[b2, b1] = df["count"].to_numpy(dtype=float)
    return m


def to_cool(mat, chrom, res, out_path):
    n = mat.shape[0]
    if n == 0:
        return False
    bins = pd.DataFrame({
        "chrom": [chrom] * n,
        "start": np.arange(0, n * res, res, dtype=np.int64),
        "end":   np.arange(res, (n + 1) * res, res, dtype=np.int64),
    })
    iu, ju = np.triu_indices(n)
    counts = mat[iu, ju].astype(np.float64)
    keep = counts > 0
    pixels = pd.DataFrame({
        "bin1_id": iu[keep].astype(np.int64),
        "bin2_id": ju[keep].astype(np.int64),
        "count":   counts[keep],
    })
    if os.path.exists(out_path):
        os.remove(out_path)
    cooler.create_cooler(out_path, bins=bins, pixels=pixels,
                         dtypes={"count": "float64"},
                         ordered=True, symmetric_upper=True)
    return True


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--hic1", required=True)
    ap.add_argument("--hic2", required=True)
    ap.add_argument("--juicer", required=True)
    ap.add_argument("--out_dir", required=True)
    ap.add_argument("--dump_dir", default=None)
    ap.add_argument("--name1", default="rep1")
    ap.add_argument("--name2", default="rep2")
    args = ap.parse_args()

    os.makedirs(args.out_dir, exist_ok=True)
    dump_dir = args.dump_dir or os.path.join(args.out_dir, "dumps")
    cool_dir = os.path.join(args.out_dir, "cool")
    os.makedirs(dump_dir, exist_ok=True)
    os.makedirs(cool_dir, exist_ok=True)

    def clip95(m):
        # per-chromosome clip at the 95th percentile of the dense matrix, matching
        # cellline hic_comparison_gm_clean.ipynb section 3b (the final SCC metric).
        return np.minimum(m, np.percentile(m, 95))

    def scc_from_dense(a, b, chrom, res, tag):
        ca = os.path.join(cool_dir, f"{args.name1}_{tag}_{RES_LABEL[res]}_{chrom}.cool")
        cb = os.path.join(cool_dir, f"{args.name2}_{tag}_{RES_LABEL[res]}_{chrom}.cool")
        if not to_cool(a, chrom, res, ca) or not to_cool(b, chrom, res, cb):
            return np.nan
        try:
            return float(np.asarray(
                hicrepSCC(cooler.Cooler(ca), cooler.Cooler(cb),
                          H_SMOOTH, res, False, np.array([chrom]))
            ).ravel()[0])
        except Exception as e:
            print(f"[warn] {RES_LABEL[res]} {chrom} ({tag}): hicrep failed: {e}", flush=True)
            return np.nan

    rows = []
    for res in RES_LIST:
        lab = RES_LABEL[res]
        for chrom in CHROMS:
            d1 = dump(args.juicer, args.hic1, chrom, res,
                      os.path.join(dump_dir, f"{args.name1}_{lab}_{chrom}.txt"))
            d2 = dump(args.juicer, args.hic2, chrom, res,
                      os.path.join(dump_dir, f"{args.name2}_{lab}_{chrom}.txt"))
            m1 = load_matrix(d1, res)
            m2 = load_matrix(d2, res)
            if m1.size == 0 or m2.size == 0:
                print(f"[skip] {lab} {chrom}: empty matrix", flush=True)
                continue
            n = min(m1.shape[0], m2.shape[0])
            m1, m2 = m1[:n, :n], m2[:n, :n]
            # primary metric = raw + 95th-percentile clip (cellline 3b); raw kept for reference
            scc_raw = scc_from_dense(m1, m2, chrom, res, "raw")
            scc_clip = scc_from_dense(clip95(m1), clip95(m2), chrom, res, "clip95")
            rows.append({"chrom": chrom, "resolution": lab, "bin_size": res,
                         "scc_raw": scc_raw, "scc_clip95": scc_clip})
            print(f"{lab} {chrom}: SCC raw={scc_raw:.4f} clip95={scc_clip:.4f}  (n_bins={n})", flush=True)

    df = pd.DataFrame(rows)
    df["resolution"] = pd.Categorical(df["resolution"],
                                      categories=["1Mb", "500kb", "250kb"], ordered=True)
    df = df.sort_values(["resolution", "chrom"])
    out_csv = os.path.join(args.out_dir, "scc_by_chrom_and_resolution.csv")
    df.to_csv(out_csv, index=False)

    summ = df.groupby("resolution", observed=True)[["scc_raw", "scc_clip95"]].agg(
        ["median", "mean", "std"]).round(4)
    print("\n=== SCC summary (rep1 vs rep2): raw vs 95th-percentile clip ===")
    print(summ)
    summ.to_csv(os.path.join(args.out_dir, "scc_summary.csv"))

    # violin per resolution -- primary metric = raw + 95th-percentile clip (cellline 3b)
    order = ["1Mb", "500kb", "250kb"]
    fig, ax = plt.subplots(figsize=(5.4, 4.4))
    data = [df.loc[df["resolution"] == r, "scc_clip95"].dropna().values for r in order]
    ax.violinplot(data, showmeans=False, showmedians=True)
    ax.set_xticks(range(1, len(order) + 1))
    ax.set_xticklabels(order)
    ax.set_ylabel("SCC (HiCRep, H=3, raw + 95th-pct clip)")
    ax.set_xlabel("resolution")
    ax.set_title(f"Hi-C SCC: {args.name1} vs {args.name2} (per chrom)")
    ax.set_ylim(0, 1)
    for i, d in enumerate(data, 1):
        if len(d):
            ax.scatter(np.full(len(d), i), d, s=8, color="k", alpha=0.5, zorder=3)
    fig.tight_layout()
    fig.savefig(os.path.join(args.out_dir, "scc_violin.pdf"))
    fig.savefig(os.path.join(args.out_dir, "scc_violin.png"), dpi=150)
    print(f"\nwrote {out_csv} and scc_violin.pdf/png", flush=True)


if __name__ == "__main__":
    main()
