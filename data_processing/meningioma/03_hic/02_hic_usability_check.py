#!/usr/bin/env python3
"""HiC usability check (headless) — same logic as qc_plots.ipynb's usability cell.

Drops methylation-QC-passed cells whose Hi-C would crash hicluster's
generatematrix/imputecell (any autosome lacking a usable cis contact). Exact
gate: >=1 cis contact with dist > 2500 bp AND ends in different MAX_RES bins.

Run AFTER Stage 1 (code/hic1_matrices.sh) has produced the per-cell
06.hiccluster_snakemake/{cell}.hic_matrix.txt.gz files.

Writes:
  QC/meningioma_passed_hicusable.txt          (all 3 batches  -> config_hic_all3)
  QC/meningioma_passed_hicusable_batch23.txt  (batch2+3       -> config_hic_batch23)
"""
import gzip, re, sys
from collections import Counter
from pathlib import Path
import multiprocessing as mp
import yaml

WORK = Path('/gpfs/projects/b1198/epifluidlab/yoshii/meningioma_scnomehic/snakemake')
CFG = yaml.safe_load(open(WORK / 'config.yaml'))
HIC_DIR = WORK / '06.hiccluster_snakemake'
OUT_QC = WORK / 'QC'

MIN_BYTES, MIN_CIS_DIST_BP, MIN_PER_CHR = 200, 2500, 1
MAX_RES = max(CFG.get('hicluster_resolutions') or [250000])


import re as _re
def assign_batch(p):  # returns group = sample_plate
    if p.startswith('NU04113_scNOMe_HiC_p2_'): return 'sample2_plate2'
    if p.startswith('NU04113_'):               return 'sample2_plate1'
    if p.startswith('MY_'):
        m = _re.match(r'MY_(\d+)_', p); n = int(m.group(1)) if m else 999
        return 'sample1_plate1' if n <= 24 else 'sample1_plate2'
    return 'unknown'


def autosomes():
    sizes = Path(str(CFG['reference']) + '.chrom.sizes')
    if sizes.exists():
        out = {m.group(1) for ln in open(sizes)
               for m in [re.match(r'^(chr[0-9]+)\b', ln)] if m}
        if out:
            return out
    return {f'chr{i}' for i in range(1, 23)}
AUTOSOMES = autosomes()


def hic_usable(prefix):
    p = HIC_DIR / f'{prefix}.hic_matrix.txt.gz'
    if not p.exists() or p.stat().st_size < MIN_BYTES:
        return prefix, False, {}
    counts = {c: 0 for c in AUTOSOMES}
    try:
        with gzip.open(p, 'rt') as f:
            for ln in f:
                a = ln.split('\t')
                if len(a) < 7:
                    continue
                c1, p1, c2, p2 = a[1], a[2], a[5], a[6]
                if c1 != c2 or c1 not in AUTOSOMES:
                    continue
                p1 = int(p1); p2 = int(p2)
                if abs(p1 - p2) > MIN_CIS_DIST_BP and (p1 // MAX_RES) != (p2 // MAX_RES):
                    counts[c1] += 1
    except Exception:
        return prefix, False, counts
    return prefix, all(counts[c] >= MIN_PER_CHR for c in AUTOSOMES), counts


def main():
    passed = [l.strip() for l in open(OUT_QC / 'meningioma_passed.txt') if l.strip()]
    have = sum((HIC_DIR / f'{p}.hic_matrix.txt.gz').exists() for p in passed)
    print(f'methylation-passed: {len(passed)} | with hic_matrix: {have}')
    if have < len(passed):
        print(f'WARNING: {len(passed)-have} cells lack a hic_matrix (run hic1_matrices.sh) '
              f'-> they will be dropped as non-usable.', file=sys.stderr)
    print(f'gate: >=1 cis contact [dist>{MIN_CIS_DIST_BP}bp AND different {MAX_RES//1000}kb bins] '
          f'per autosome ({len(AUTOSOMES)} autosomes)')

    with mp.Pool(min(16, mp.cpu_count())) as pool:
        results = pool.map(hic_usable, passed, chunksize=8)

    usable = sorted(p for p, ok, _ in results if ok)
    dropped = [(p, c) for p, ok, c in results if not ok]
    print(f'HiC-usable: {len(usable)}/{len(passed)} (dropped {len(dropped)})')
    for p, counts in dropped[:25]:
        if not counts:
            print(f'  drop {p} (no/empty hic_matrix)')
        else:
            bad = [c for c in sorted(AUTOSOMES, key=lambda x: int(x[3:]))
                   if counts.get(c, 0) < MIN_PER_CHR]
            print(f'  drop {p} (failing chrs: {bad[:6]})')

    (OUT_QC / 'meningioma_passed_hicusable.txt').write_text('\n'.join(usable) + '\n')
    b23 = [p for p in usable if assign_batch(p) in ('sample2_plate1', 'sample2_plate2')]
    (OUT_QC / 'meningioma_passed_hicusable_batch23.txt').write_text('\n'.join(b23) + '\n')
    print('by batch:', dict(Counter(assign_batch(p) for p in usable)))
    print(f'wrote meningioma_passed_hicusable.txt ({len(usable)})')
    print(f'wrote meningioma_passed_hicusable_batch23.txt ({len(b23)})')


if __name__ == '__main__':
    main()
