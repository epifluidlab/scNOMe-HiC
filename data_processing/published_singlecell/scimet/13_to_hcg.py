#!/usr/bin/env python3
"""
13_to_hcg.py — convert the coverage2cytosine --merge_CpG output into a
GCG-removed per-CpG file (chr, pos, mc, cov), matching the scWGBS/NOMe-HiC HCG
format so sci-MET can be added as a third track.

Input (bismark merged-CpG .cov): chr  pos  pos  %meth  countM  countU  (1-based,
one entry per CpG, both strands merged at the + strand C).
GCG removal: a CpG is GCG if the reference base immediately 5' of the C is G
(ref[pos-1]); those are dropped (NOMe ambiguity), keeping HCG.
"""
import argparse
import gzip
import os

import pysam


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--cov", required=True, help="coverage2cytosine --merge_CpG output (.cov[.gz])")
    ap.add_argument("--genome-fa", required=True)
    ap.add_argument("--out", required=True, help="output .tsv.gz (chr pos mc cov)")
    args = ap.parse_args()

    fa = pysam.FastaFile(args.genome_fa)
    opn = gzip.open if args.cov.endswith(".gz") else open
    os.makedirs(os.path.dirname(args.out), exist_ok=True)
    plain = args.out[:-3] if args.out.endswith(".gz") else args.out

    kept = removed = total = 0
    with opn(args.cov, "rt") as fin, open(plain, "w") as out:
        for line in fin:
            f = line.rstrip("\n").split("\t")
            if len(f) < 6:
                continue
            chrom, pos = f[0], int(f[1])
            mc = int(f[4]); cov = mc + int(f[5])
            if cov == 0:
                continue
            total += 1
            try:
                b = fa.fetch(chrom, pos - 2, pos - 1).upper()   # ref base 5' of the C
            except (KeyError, ValueError):
                b = ""
            if b == "G":            # GCG -> drop
                removed += 1
                continue
            out.write(f"{chrom}\t{pos}\t{mc}\t{cov}\n")
            kept += 1

    pysam.tabix_compress(plain, args.out, force=True)
    os.remove(plain)
    print(f"[13] CpGs total={total:,} kept(HCG)={kept:,} removed(GCG)={removed:,} -> {args.out}")


if __name__ == "__main__":
    main()
