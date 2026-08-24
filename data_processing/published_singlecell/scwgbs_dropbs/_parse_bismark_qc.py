#!/usr/bin/env python3
"""
_parse_bismark_qc.py — read every cell's Bismark SE reports (R1 + R2), tabulate
raw reads and mapping efficiency, and write a QC table + a passing-cell list.
"""
import argparse
import glob
import os
import re


def parse_report(path):
    total, uniq = 0, 0
    with open(path) as fh:
        for line in fh:
            m = re.match(r"Sequences analysed in total:\s+(\d+)", line)
            if m:
                total = int(m.group(1))
            m = re.match(r"Number of alignments with a unique best hit.*:\s+(\d+)", line)
            if m:
                uniq = int(m.group(1))
    return total, uniq


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--align-dir", required=True, help="$D05 (per-cell align outputs)")
    ap.add_argument("--min-map-eff", type=float, required=True, help="percent")
    ap.add_argument("--min-reads", type=int, required=True)
    ap.add_argument("--out-table", required=True)
    ap.add_argument("--out-pass", required=True)
    args = ap.parse_args()

    rows, passing = [], []
    for cell_dir in sorted(glob.glob(os.path.join(args.align_dir, "cell_*"))):
        cell = os.path.basename(cell_dir)
        total, uniq = 0, 0
        for read in ("R1", "R2"):
            reps = glob.glob(os.path.join(cell_dir, read, "*_SE_report.txt"))
            if reps:
                t, u = parse_report(reps[0])
                total += t
                uniq += u
        eff = (100.0 * uniq / total) if total else 0.0
        keep = (total >= args.min_reads) and (eff >= args.min_map_eff)
        rows.append((cell, total, uniq, round(eff, 2), "PASS" if keep else "FAIL"))
        if keep:
            passing.append(cell)

    with open(args.out_table, "w") as t:
        t.write("cell\ttotal_reads\tunique_aligned\tmap_eff_pct\tstatus\n")
        for r in rows:
            t.write("\t".join(map(str, r)) + "\n")
    with open(args.out_pass, "w") as p:
        for c in passing:
            p.write(c + "\n")
    print(f"[qc] {len(passing)}/{len(rows)} cells pass "
          f"(min_reads={args.min_reads}, min_map_eff={args.min_map_eff}%)")


if __name__ == "__main__":
    main()
