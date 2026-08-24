#!/usr/bin/env python3
"""
Step 03 — map pooled hg19 contacts to hg38 via the lifted anchors and re-bin at
EACH resolution in $RESLIST, writing per-chrom juicer-style triplet dumps
(start1 start2 count) so the SCC step can treat sci-Hi-C exactly like the
scNOMe-HiC juicer dumps.

The sci-Hi-C source is 500 kb (hg19). liftOver is at the 500 kb bin-midpoint level,
so 500 kb is the finest meaningful output; 1 Mb / 2.5 Mb are clean aggregations.
250 kb is NOT possible (cannot disaggregate 500 kb bins).

Inputs : work/pooled_hg19_contacts.tsv   chrom mid1_hg19 mid2_hg19 count
         work/anchors_hg38.bed           chrom_hg38 start end name(=chrom_hg19:mid)
Rules  : an anchor is used only if it lifts to the SAME chromosome; a contact is
         kept only if BOTH anchors lift and stay cis on that chromosome.
Output : work/dump_multires/schic_gm_<label>_<chr>.txt   (bin*res start1 start2 count)
         (also mirrors 2.5 Mb into work/dump_2.5Mb/ for backward compat)
"""
import os, collections

WORK = os.environ["WORK"]
RESLIST = [int(x) for x in os.environ.get("RESLIST", "500000 1000000 2500000").split()]
CHROMS = [f"chr{i}" for i in range(1, 23)] + ["chrX"]

def label(res):
    return f"{res//1000}kb" if res < 1_000_000 else (
        f"{res//1_000_000}Mb" if res % 1_000_000 == 0 else f"{res/1_000_000:g}Mb")

# ---- load lifted anchor map: (chrom_hg19, mid_hg19) -> pos_hg38 (same chrom) --
lift = {}
n_crosschrom = 0
for line in open(os.path.join(WORK, "anchors_hg38.bed")):
    c38, s, e, name = line.split()[:4]
    c19, mid = name.split(":")
    if c38 != c19:                      # lifted to a different chromosome -> drop
        n_crosschrom += 1; continue
    lift[(c19, int(mid))] = int(s)
print(f"[lift] usable anchors={len(lift)} dropped cross-chrom={n_crosschrom}")

# ---- load pooled contacts once, resolve to hg38 positions --------------------
contacts = []          # (chrom, pos1_hg38, pos2_hg38, count)
kept = dropped = 0
for line in open(os.path.join(WORK, "pooled_hg19_contacts.tsv")):
    c, m1, m2, cnt = line.split()
    a = lift.get((c, int(m1))); b = lift.get((c, int(m2)))
    if a is None or b is None:
        dropped += 1; continue
    contacts.append((c, a, b, int(cnt))); kept += 1
print(f"[resolve] contacts kept={kept} dropped(unlifted)={dropped}")

# ---- re-bin at each resolution ----------------------------------------------
mout = os.path.join(WORK, "dump_multires"); os.makedirs(mout, exist_ok=True)
compat = os.path.join(WORK, "dump_2.5Mb"); os.makedirs(compat, exist_ok=True)
for res in RESLIST:
    lab = label(res)
    mats = {c: collections.defaultdict(int) for c in CHROMS}
    for c, a, b, cnt in contacts:
        b1, b2 = a // res, b // res
        if b1 > b2:
            b1, b2 = b2, b1
        mats[c][(b1, b2)] += cnt
    tot_pix = 0
    for c in CHROMS:
        for outdir in ([mout, compat] if res == 2_500_000 else [mout]):
            path = os.path.join(outdir, f"schic_gm_{lab}_{c}.txt")
            with open(path, "w") as fh:
                for (b1, b2), v in sorted(mats[c].items()):
                    fh.write(f"{b1*res}\t{b2*res}\t{v}\n")
        tot_pix += len(mats[c])
    print(f"[rebin] res={lab}: {tot_pix} pixels total -> {mout}/schic_gm_{lab}_<chr>.txt")

# keep the legacy 2.5 Mb filename (schic_gm_2.5Mb_<chr>.txt) that step 05 expects
