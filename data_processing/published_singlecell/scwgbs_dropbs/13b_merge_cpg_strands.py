#!/usr/bin/env python3
"""
13b_merge_cpg_strands.py — collapse the per-cytosine scWGBS pseudobulk to one
entry per CpG (both strands summed), matching the NOMe-HiC 6plus2 convention.

NOMe-HiC 6plus2 reports each CpG once, at the + strand C position, with both
strands' reads merged. My per-site file (13) is per-cytosine: + strand C at
position p, - strand C at p+1. Using the reference base:
  ref[p]=='C'  -> + strand cytosine -> CpG key = p
  ref[p]=='G'  -> - strand cytosine -> CpG key = p-1   (its + strand partner)
Sum mc/cov by CpG key. Output: chrom<TAB>cpg_pos<TAB>mc<TAB>cov (1-based cpg_pos
== NOMe-HiC 'end').
"""
import argparse
import gzip
import os
from collections import defaultdict

import pysam


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--persite", required=True)
    ap.add_argument("--genome-fa", required=True)
    ap.add_argument("--out", required=True)
    args = ap.parse_args()

    fa = pysam.FastaFile(args.genome_fa)
    agg = defaultdict(lambda: [0.0, 0])
    n_c = n_g = n_other = 0
    with gzip.open(args.persite, "rt") as fh:
        for line in fh:
            chrom, pos, mc, cov = line.rstrip("\n").split("\t")
            pos = int(pos)
            try:
                b = fa.fetch(chrom, pos - 1, pos).upper()
            except (KeyError, ValueError):
                continue
            if b == "C":
                key = (chrom, pos)        # + strand C
                n_c += 1
            elif b == "G":
                key = (chrom, pos - 1)    # - strand C -> + partner
                n_g += 1
            else:
                n_other += 1
                continue
            a = agg[key]
            a[0] += float(mc)
            a[1] += int(cov)

    os.makedirs(os.path.dirname(args.out), exist_ok=True)
    plain = args.out[:-3] if args.out.endswith(".gz") else args.out
    with open(plain, "w") as out:
        for (chrom, pos) in sorted(agg, key=lambda k: (k[0], k[1])):
            mc, cov = agg[(chrom, pos)]
            out.write(f"{chrom}\t{pos}\t{mc}\t{cov}\n")
    pysam.tabix_compress(plain, args.out, force=True)
    os.remove(plain)
    print(f"[13b] +strand(C)={n_c:,}  -strand(G)={n_g:,}  other={n_other:,}")
    print(f"[13b] merged CpGs: {len(agg):,} -> {args.out}")


if __name__ == "__main__":
    main()
