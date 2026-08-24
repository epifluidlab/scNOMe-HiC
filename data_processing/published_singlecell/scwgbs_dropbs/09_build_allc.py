#!/usr/bin/env python3
"""
09_build_allc.py — build a methylpy-format allc file for one cell from the
methylKit per-context tables + the reference genome.

allc columns (https://github.com/yupenghe/methylpy):
    chrom  pos(1-based)  strand  mc_class(trinucleotide)  mc_count  total  methylated

methylKit table columns:  chrBase  chr  base  strand(F/R)  coverage  freqC  freqT
The trinucleotide context (e.g. CGA / CAT / CGG) is looked up from the reference
so that all cytosines are annotated; this is what later lets us split CpG vs GpC
and drop the ambiguous GCG sites for the NOMe comparison.

NOTE: the 'methylated' flag here is a simple mc>0 placeholder. Full methylpy sets
it via a binomial test against the bisulfite non-conversion rate; revisit if needed.
"""
import argparse
import glob
import gzip
import os

import pysam

_COMP = str.maketrans("ACGTNacgtn", "TGCANtgcan")


def revcomp(s):
    return s.translate(_COMP)[::-1]


def context_at(fa, chrom, pos, strand):
    """Return the 3 bp cytosine context (5'->3') at 1-based `pos`."""
    try:
        if strand == "+":
            ctx = fa.fetch(chrom, pos - 1, pos + 2)
        else:  # '-' : C sits on the reverse strand
            ctx = revcomp(fa.fetch(chrom, pos - 3, pos))
    except (KeyError, ValueError):
        return None
    ctx = ctx.upper()
    return ctx if len(ctx) == 3 and ctx[0] == "C" else None


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--meth-dir", required=True, help="$D08/<cell> (methylKit tables)")
    ap.add_argument("--cell", required=True)
    ap.add_argument("--genome-fa", required=True)
    ap.add_argument("--out", required=True, help="output allc path (.tsv.gz)")
    args = ap.parse_args()

    fa = pysam.FastaFile(args.genome_fa)
    records = []
    for tbl in glob.glob(os.path.join(args.meth_dir, f"{args.cell}_*.txt")):
        with open(tbl) as fh:
            header = fh.readline()  # skip
            for line in fh:
                f = line.rstrip("\n").split("\t")
                if len(f) < 7:
                    continue
                chrom = f[1]
                pos = int(f[2])
                strand = "+" if f[3] == "F" else "-"
                cov = int(float(f[4]))
                freqC = float(f[5])
                mc = int(round(cov * freqC / 100.0))
                ctx = context_at(fa, chrom, pos, strand)
                if ctx is None:
                    continue
                records.append((chrom, pos, strand, ctx, mc, cov, 1 if mc > 0 else 0))

    records.sort(key=lambda r: (r[0], r[1]))
    os.makedirs(os.path.dirname(args.out), exist_ok=True)
    plain = args.out[:-3] if args.out.endswith(".gz") else args.out
    with open(plain, "w") as out:
        for r in records:
            out.write("\t".join(map(str, r)) + "\n")

    # bgzip + tabix so the allc is indexable like methylpy expects
    pysam.tabix_compress(plain, args.out, force=True)
    os.remove(plain)
    pysam.tabix_index(args.out, seq_col=0, start_col=1, end_col=1,
                      force=True, keep_original=True)
    print(f"[09] wrote {len(records)} cytosines -> {args.out}")


if __name__ == "__main__":
    main()
