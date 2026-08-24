#!/usr/bin/env python3
"""
10_remove_gcg.py — remove GCG-context cytosines from an allc file (NOMe matching).

In NOMe-seq / NOMe-HiC, GpC positions carry the accessibility mark. A cytosine
in GCG context is simultaneously a CpG (endogenous methylation) and a GpC
(accessibility), so it is ambiguous and dropped; only HCG (H = A/C/T) is used
for CpG methylation. This script filters a WGBS allc to make it comparable.

A site is GCG iff it is CpG (mc_class starts "CG") AND the reference base
immediately 5' of the cytosine (on the cytosine's own strand) is G:
  + strand C at pos p : 5' base = ref[p-1]           -> GCG if == 'G'
  - strand C at pos p : 5' base = complement(ref[p+1]) -> GCG if ref[p+1] == 'C'
Non-CpG cytosines (CHG/CHH, incl. GpC accessibility sites GCH) are never GCG and
are kept unchanged.
"""
import argparse
import gzip
import os

import pysam


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--allc", required=True)
    ap.add_argument("--genome-fa", required=True)
    ap.add_argument("--out", required=True, help="output .tsv.gz")
    args = ap.parse_args()

    fa = pysam.FastaFile(args.genome_fa)
    os.makedirs(os.path.dirname(args.out), exist_ok=True)
    plain = args.out[:-3] if args.out.endswith(".gz") else args.out

    kept = removed = total = 0
    opn = gzip.open if args.allc.endswith(".gz") else open
    with opn(args.allc, "rt") as fin, open(plain, "w") as out:
        for line in fin:
            f = line.rstrip("\n").split("\t")
            if len(f) < 7:
                continue
            total += 1
            chrom, pos, strand, mc_class = f[0], int(f[1]), f[2], f[3]
            is_gcg = False
            if mc_class[:2] == "CG":                       # CpG context only
                try:
                    if strand == "+":
                        b = fa.fetch(chrom, pos - 2, pos - 1).upper()   # ref[p-1]
                        is_gcg = (b == "G")
                    else:
                        b = fa.fetch(chrom, pos, pos + 1).upper()       # ref[p+1]
                        is_gcg = (b == "C")
                except (KeyError, ValueError):
                    is_gcg = False
            if is_gcg:
                removed += 1
            else:
                out.write(line if line.endswith("\n") else line + "\n")
                kept += 1

    pysam.tabix_compress(plain, args.out, force=True)
    os.remove(plain)
    pysam.tabix_index(args.out, seq_col=0, start_col=1, end_col=1,
                      force=True, keep_original=True)
    print(f"[10] {args.allc}: total={total} kept={kept} removed_GCG={removed}")


if __name__ == "__main__":
    main()
