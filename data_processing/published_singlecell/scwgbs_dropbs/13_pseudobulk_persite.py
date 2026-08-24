#!/usr/bin/env python3
"""
13_pseudobulk_persite.py — aggregate all per-cell GCG-free allc files into a
scWGBS pseudobulk, per CpG SITE (not binned), for the per-locus comparison.

Sums methylated (mc) and total (cov) reads per (chrom, pos) over CpG-context
cytosines (mc_class starts "CG"; after GCG removal these are HCG). The 1-based
allc position matches the NOMe-HiC 6plus2 'end' column, so downstream join is on
(chrom, pos). Output: chrom<TAB>pos<TAB>mc<TAB>cov (gzip), sorted.
"""
import argparse
import glob
import gzip
import os
from collections import defaultdict


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--allc-glob", required=True, help="glob for per-cell noGCG allc .tsv.gz")
    ap.add_argument("--out", required=True)
    args = ap.parse_args()

    agg = defaultdict(lambda: [0.0, 0])   # (chrom,pos) -> [mc, cov]
    files = sorted(glob.glob(args.allc_glob))
    print(f"aggregating {len(files)} allc files", flush=True)
    for i, fp in enumerate(files):
        with gzip.open(fp, "rt") as fh:
            for line in fh:
                f = line.split("\t")
                if len(f) < 7 or f[3][:2] != "CG":
                    continue
                a = agg[(f[0], int(f[1]))]
                a[0] += float(f[4])
                a[1] += int(f[5])
        if (i + 1) % 250 == 0:
            print(f"  {i+1}/{len(files)} files, {len(agg):,} sites", flush=True)

    os.makedirs(os.path.dirname(args.out), exist_ok=True)
    plain = args.out[:-3] if args.out.endswith(".gz") else args.out
    with open(plain, "w") as out:
        for (chrom, pos) in sorted(agg, key=lambda k: (k[0], k[1])):
            mc, cov = agg[(chrom, pos)]
            out.write(f"{chrom}\t{pos}\t{mc}\t{cov}\n")
    import pysam
    pysam.tabix_compress(plain, args.out, force=True)
    os.remove(plain)
    print(f"[13] wrote {len(agg):,} CpG sites -> {args.out}")


if __name__ == "__main__":
    main()
