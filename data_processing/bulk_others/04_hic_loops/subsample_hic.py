#!/usr/bin/env python
"""Subsample a .hic file by pulling sparse pixels via straw, applying
Binomial(count, p) per pixel, and emitting juicer pre short format text.

Used to depth-match GM12878 in-situ down to IMR90 in-situ for fair HICCUPS.

Output format (one row per subsampled contact, suitable for juicer pre):
  str1  chr1  pos1  frag1  str2  chr2  pos2  frag2
  0     <c1>  <p1>  0      0     <c2>  <p2>  1

pos = bin start + half resolution (bin midpoint).
Output is sorted by (chr1, chr2) per the chromosome enumeration order, which is
what juicer pre needs to build the .hic efficiently.
"""
from __future__ import annotations
import argparse
import gzip
import sys
import time
import numpy as np
import hicstraw


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--hic", required=True, help="Input .hic file")
    ap.add_argument("--out-gz", required=True, help="Output short-format .txt.gz")
    ap.add_argument("--p", type=float, required=True,
                    help="Bernoulli keep probability per contact")
    ap.add_argument("--resolution", type=int, default=5000,
                    help="Resolution at which to dump pixels (bp). 5000 is a good balance.")
    ap.add_argument("--seed", type=int, default=42)
    ap.add_argument("--chrom-prefix", default="chr",
                    help="Force this prefix on chrom names in output (default 'chr')")
    args = ap.parse_args()

    rng = np.random.default_rng(args.seed)
    hic = hicstraw.HiCFile(args.hic)
    chroms = [c for c in hic.getChromosomes() if c.name not in ("All", "MT")]
    chrom_names = [c.name for c in chroms]
    print(f"chromosomes ({len(chroms)}): {chrom_names[:5]} ... {chrom_names[-3:]}",
          file=sys.stderr, flush=True)
    print(f"subsample rate p = {args.p}, resolution = {args.resolution} bp",
          file=sys.stderr, flush=True)

    half = args.resolution // 2
    total_in = 0
    total_out = 0
    t0 = time.time()
    with gzip.open(args.out_gz, "wt", compresslevel=4) as fout:
        # iterate over chr1, chr2 with chr1 <= chr2 (juicer pre wants sorted)
        for i, c1 in enumerate(chroms):
            n1 = c1.name
            for j, c2 in enumerate(chroms):
                if j < i:
                    continue
                n2 = c2.name
                try:
                    recs = hicstraw.straw('observed', 'NONE', args.hic,
                                          n1, n2, 'BP', args.resolution)
                except Exception as e:
                    print(f"  skip {n1} x {n2}: {e}", file=sys.stderr)
                    continue
                if not recs:
                    continue
                bins1 = np.fromiter((r.binX for r in recs), dtype=np.int64, count=len(recs))
                bins2 = np.fromiter((r.binY for r in recs), dtype=np.int64, count=len(recs))
                counts = np.fromiter((r.counts for r in recs), dtype=np.float64, count=len(recs))
                # observed counts may come back float-typed; cast to int safely
                counts_i = np.maximum(counts.round().astype(np.int64), 0)
                total_in += int(counts_i.sum())
                new_counts = rng.binomial(counts_i, args.p).astype(np.int64)
                keep = new_counts > 0
                if not np.any(keep):
                    continue
                # expand each pixel to new_count duplicate rows
                p1 = np.repeat(bins1[keep] + half, new_counts[keep])
                p2 = np.repeat(bins2[keep] + half, new_counts[keep])
                # output chrom labels
                cn1 = (args.chrom_prefix + n1) if not n1.startswith(args.chrom_prefix) else n1
                cn2 = (args.chrom_prefix + n2) if not n2.startswith(args.chrom_prefix) else n2
                total_out += int(new_counts[keep].sum())
                # write in chunks to keep memory steady
                chunk = 1_000_000
                for k in range(0, p1.size, chunk):
                    pp1 = p1[k:k+chunk]; pp2 = p2[k:k+chunk]
                    lines = "\n".join(
                        f"0\t{cn1}\t{int(a)}\t0\t0\t{cn2}\t{int(b)}\t1"
                        for a, b in zip(pp1, pp2)
                    )
                    fout.write(lines); fout.write("\n")
            elapsed = time.time() - t0
            print(f"  done {n1}: cumulative in={total_in:,} out={total_out:,}  "
                  f"({elapsed:.0f}s elapsed, ratio={total_out/max(total_in,1):.3f})",
                  file=sys.stderr, flush=True)

    print(f"\nFINAL: input contacts={total_in:,}  output contacts={total_out:,}  "
          f"observed ratio={total_out/max(total_in,1):.4f}  target p={args.p}",
          file=sys.stderr)


if __name__ == "__main__":
    main()
