#!/usr/bin/env python3
"""
Step 01 — pool the GM12878 sci-Hi-C cells into an hg19 pseudobulk contact list.

Input : GM12878-IMR90.R1.tar.gz (per-cell 500 kb matrices, hg19) + .labeled
Keep  : only cells labeled GM12878 (489 of 590).
Matrix row format (Kim 2020): globalbin1 globalbin2 count normweight chrom1 chrom2
  - global 500 kb bins over hg19 chroms chr1..chr22,chrX in numeric order,
    offset(chrom) = cumulative sum of ceil(hg19_size / 500 kb)  [VERIFIED against
    observed per-chrom bin ranges].
  - we use raw integer `count` (col 3); keep CIS only (chrom1==chrom2).
Output:
  work/pooled_hg19_contacts.tsv   chrom  mid1_hg19  mid2_hg19  count   (bin midpoints)
  work/anchors_hg19.bed           chrom  mid  mid+1  chrom:mid            (unique anchors)
"""
import os, sys, glob, math, subprocess, collections

RES = 500_000
DATA = os.environ["DATA"]; WORK = os.environ["WORK"]
LIB  = os.environ["LIB"]; KEEP = os.environ["SCHIC_CELLTYPE"]
TAR  = os.environ["SCHIC_TAR"]; LABELS = os.environ["SCHIC_LABELS"]
HG19_SIZES = os.environ["HG19_SIZES"]

CHROMS = [f"chr{i}" for i in range(1, 23)] + ["chrX"]   # data has no chrY/chrM (GM12878 female)

# ---- build hg19 global-bin offsets (numeric chrom order, ceil bins) ----------
sizes = {}
for line in open(HG19_SIZES):
    c, s = line.split()[:2]; sizes[c] = int(s)
offset = {}; off = 0
for c in CHROMS:
    offset[c] = off
    off += math.ceil(sizes[c] / RES)
print("[offsets] chr1=%d chr2=%d chr13=%d chrX=%d (next=%d)"
      % (offset["chr1"], offset["chr2"], offset["chr13"], offset["chrX"], off))

# ---- GM cell list ------------------------------------------------------------
gm = [l.split("\t")[0] for l in open(LABELS) if l.rstrip("\n").split("\t")[1] == KEEP]
print(f"[cells] {len(gm)} cells labeled {KEEP}")

# ---- extract GM cells --------------------------------------------------------
celldir = os.path.join(WORK, "cells_gm")
os.makedirs(celldir, exist_ok=True)
memberlist = os.path.join(WORK, "gm_members.txt")
tar_prefix = LIB.replace("-", "_")          # tar top dir is GM12878_IMR90.R1
with open(memberlist, "w") as fh:
    for f in gm:
        fh.write(f"{tar_prefix}/{f}\n")
subprocess.run(["tar", "xzf", TAR, "-C", celldir, "-T", memberlist], check=True)
cellfiles = glob.glob(os.path.join(celldir, tar_prefix, "*.matrix"))
print(f"[extract] {len(cellfiles)} matrix files")

# ---- pool raw CIS counts -----------------------------------------------------
pooled = collections.defaultdict(int)      # (chrom, lo_global, hi_global) -> count
kept_chroms = set(CHROMS)
n_cis = n_trans = 0
for f in cellfiles:
    for line in open(f):
        p = line.split()
        if len(p) < 6:
            continue
        c1 = p[4].replace("human_", ""); c2 = p[5].replace("human_", "")
        if c1 != c2:
            n_trans += 1; continue
        if c1 not in kept_chroms:
            continue
        g1, g2 = int(p[0]), int(p[1])
        lo, hi = (g1, g2) if g1 <= g2 else (g2, g1)
        pooled[(c1, lo, hi)] += int(p[2])
        n_cis += 1
print(f"[pool] cis rows={n_cis} trans rows dropped={n_trans} unique cis pixels={len(pooled)}")

# ---- write pooled contacts (hg19 midpoints) + unique anchors -----------------
out_c = os.path.join(WORK, "pooled_hg19_contacts.tsv")
anchors = {}                                # (chrom, mid) -> None
tot = 0
with open(out_c, "w") as oc:
    for (c, lo, hi), cnt in pooled.items():
        l1 = lo - offset[c]; l2 = hi - offset[c]
        if l1 < 0 or l2 < 0:
            continue
        m1 = l1 * RES + RES // 2
        m2 = l2 * RES + RES // 2
        oc.write(f"{c}\t{m1}\t{m2}\t{cnt}\n")
        anchors[(c, m1)] = None; anchors[(c, m2)] = None
        tot += cnt
print(f"[write] {out_c}  total pooled contacts (count sum)={tot}")

out_b = os.path.join(WORK, "anchors_hg19.bed")
with open(out_b, "w") as ob:
    for (c, m) in sorted(anchors):
        ob.write(f"{c}\t{m}\t{m+1}\t{c}:{m}\n")
print(f"[write] {out_b}  unique anchors={len(anchors)}")
