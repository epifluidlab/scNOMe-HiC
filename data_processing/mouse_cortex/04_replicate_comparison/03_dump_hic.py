#!/usr/bin/env python3
"""
Step 3: dump per-chromosome contact matrices from the two replicate .hic files.

`juicer_tools dump observed NONE` for every (replicate, resolution, chromosome),
writing 'start1 start2 count' triplets. These dumps are the input to the SCC
calculation, which lives in the Figure S6 notebook
(supplementary_figures/figS6/figS6_replicate_reproducibility.ipynb) rather than
here -- the same split main_figures/fig1 uses for its single-cell-vs-bulk SCC.

Only the dump is a batch step: it needs java + juicer_tools and runs 120
invocations (2 replicates x 3 resolutions x 20 chromosomes) against ~230 MB .hic
files. Computing SCC from the dumps takes about 15 s and belongs with the figure.

RES  = 1 Mb, 500 kb, 250 kb
CHROMS = mm10 autosomes + X (chr1..chr19, chrX)

Existing non-empty dumps are skipped, so the step is safe to re-run.

Usage:
  03_dump_hic.py --hic1 hic/rep1.mapQ30.hic --hic2 hic/rep2.mapQ30.hic \
      --juicer <juicer_tools.jar> --dump_dir results/scc/dumps \
      [--name1 rep1 --name2 rep2]
"""
import argparse
import os
import subprocess
import sys

RES_LIST = [1_000_000, 500_000, 250_000]
RES_LABEL = {1_000_000: "1Mb", 500_000: "500kb", 250_000: "250kb"}
CHROMS = [f"chr{i}" for i in range(1, 20)] + ["chrX"]


def dump(juicer, hic, chrom, res, out_path):
    """juicer_tools dump observed NONE -> 'start1 start2 count' triplets."""
    if os.path.exists(out_path) and os.path.getsize(out_path) > 0:
        return out_path, True          # already present
    cmd = ["java", "-Xmx8g", "-jar", juicer, "dump", "observed", "NONE",
           hic, chrom, chrom, "BP", str(res), out_path]
    subprocess.run(cmd, check=True,
                   stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    return out_path, False


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--hic1", required=True)
    ap.add_argument("--hic2", required=True)
    ap.add_argument("--juicer", required=True)
    ap.add_argument("--dump_dir", required=True)
    ap.add_argument("--name1", default="rep1")
    ap.add_argument("--name2", default="rep2")
    args = ap.parse_args()

    os.makedirs(args.dump_dir, exist_ok=True)

    made = skipped = 0
    for res in RES_LIST:
        lab = RES_LABEL[res]
        for chrom in CHROMS:
            for name, hic in ((args.name1, args.hic1), (args.name2, args.hic2)):
                out = os.path.join(args.dump_dir, f"{name}_{lab}_{chrom}.txt")
                _, cached = dump(args.juicer, hic, chrom, res, out)
                if cached:
                    skipped += 1
                else:
                    made += 1
                    print(f"dumped {name} {lab} {chrom}", flush=True)

    total = len(RES_LIST) * len(CHROMS) * 2
    print(f"\n{made} dumped, {skipped} already present, {total} expected "
          f"-> {args.dump_dir}", flush=True)
    missing = [f for res in RES_LIST for chrom in CHROMS
               for name in (args.name1, args.name2)
               if not os.path.exists(os.path.join(
                   args.dump_dir, f"{name}_{RES_LABEL[res]}_{chrom}.txt"))]
    if missing:
        print(f"[warn] {len(missing)} dumps missing", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
