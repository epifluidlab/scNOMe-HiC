#!/usr/bin/env python3
"""
_split_percell.py — split trimmed paired reads into per-cell FASTQ files by the
cell barcode that umi_tools already wrote into each read header.

Replaces idemp, which segfaults at single-cell scale (thousands of barcodes).
umi_tools extract already error-corrected the barcode and filtered to the
whitelist, so the header barcode is an exact whitelist entry — a plain split by
that barcode is all that's needed.

Header format from umi_tools:  @<name>_<CB>_<UMI> ...   (UMI empty here)
Output:  <outdir>/cell_<CB>_R1.fastq.gz , cell_<CB>_R2.fastq.gz

To stay under the open-file limit, at most --cap handles are kept open; the
least-recently-used cell is closed and reopened in append mode if needed (gzip
members concatenate cleanly), so it is correct regardless of the fd limit.
"""
import argparse
import gzip
import os
from collections import OrderedDict


def opener(path):
    return gzip.open(path, "rt")


def barcode_from_header(header):
    token = header[1:].split(maxsplit=1)[0]      # up to first whitespace
    parts = token.split("_")
    return parts[-2] if len(parts) >= 2 else None  # name_CB_UMI, UMI empty


class HandlePool:
    """LRU pool of gzip write handles, capped to stay under the fd limit."""
    def __init__(self, outdir, cap):
        self.outdir = outdir
        self.cap = cap
        self.open = OrderedDict()      # cell -> (fh_r1, fh_r2)
        self.seen = set()              # cells opened before (choose 'w' vs 'a')

    def get(self, cell):
        h = self.open.get(cell)
        if h is not None:
            self.open.move_to_end(cell)
            return h
        if len(self.open) >= self.cap:
            old, (a, b) = self.open.popitem(last=False)
            a.close(); b.close()
        mode = "at" if cell in self.seen else "wt"
        r1 = gzip.open(os.path.join(self.outdir, f"{cell}_R1.fastq.gz"), mode, compresslevel=6)
        r2 = gzip.open(os.path.join(self.outdir, f"{cell}_R2.fastq.gz"), mode, compresslevel=6)
        self.seen.add(cell)
        self.open[cell] = (r1, r2)
        return r1, r2

    def close(self):
        for a, b in self.open.values():
            a.close(); b.close()
        self.open.clear()


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--r1", required=True, help="trimmed R1 (_val_1) fastq.gz")
    ap.add_argument("--r2", required=True, help="trimmed R2 (_val_2) fastq.gz")
    ap.add_argument("--whitelist", required=True)
    ap.add_argument("--outdir", required=True)
    ap.add_argument("--cap", type=int, default=12000, help="max open file handles")
    args = ap.parse_args()

    os.makedirs(args.outdir, exist_ok=True)
    wl = set()
    with open(args.whitelist) as fh:
        for line in fh:
            bc = line.split("\t")[0].strip()
            if bc:
                wl.add(bc)

    pool = HandlePool(args.outdir, max(2, args.cap // 2))
    n = kept = unknown = 0
    with opener(args.r1) as f1, opener(args.r2) as f2:
        while True:
            h1 = f1.readline()
            if not h1:
                break
            s1, p1, q1 = f1.readline(), f1.readline(), f1.readline()
            h2, s2, p2, q2 = f2.readline(), f2.readline(), f2.readline(), f2.readline()
            n += 1
            bc = barcode_from_header(h1)
            if bc is None or bc not in wl:
                unknown += 1
                continue
            r1, r2 = pool.get(f"cell_{bc}")
            r1.write(h1); r1.write(s1); r1.write(p1); r1.write(q1)
            r2.write(h2); r2.write(s2); r2.write(p2); r2.write(q2)
            kept += 1
            if n % 5_000_000 == 0:
                print(f"[split] {n:,} pairs processed, {kept:,} kept", flush=True)
    pool.close()
    print(f"[split] done: {n:,} pairs, {kept:,} kept, {unknown:,} unknown-barcode")


if __name__ == "__main__":
    main()
