#!/usr/bin/env python3
"""Build cell x 250kb-bin methylation matrices (GCH + HCG) for subset clustering.
Mirrors qc_plots.ipynb's matrix builder, restricted to the 250kb label.
Writes QC/methylation_matrices/methylation_matrix_{GCH,HCG}_250kb.tsv.gz (+ bins).
"""
from pathlib import Path
import pandas as pd
from tqdm import tqdm

WORK = Path('/gpfs/projects/b1198/epifluidlab/yoshii/meningioma_scnomehic/snakemake')
METH = WORK / '08.methylation_snakemake'
OUT = WORK / 'QC' / 'methylation_matrices'
OUT.mkdir(parents=True, exist_ok=True)
LABEL = '250kb'

def cell_of(p, ctx):
    suf = f'.{ctx}.{LABEL}_methylation.txt.gz'
    return Path(p).name[:-len(suf)]

for ctx in ['GCH', 'HCG']:
    files = sorted(METH.glob(f'*.{ctx}.{LABEL}_methylation.txt.gz'))
    rows = []
    for f in tqdm(files, desc=f'{ctx} {LABEL}'):
        cell = cell_of(f, ctx)
        d = pd.read_csv(f, sep='\t', usecols=['bin_id', 'methylation_level'])
        rows.append(d.set_index('bin_id')['methylation_level'].rename(cell))
    mat = pd.concat(rows, axis=1).T
    mat.index.name = 'cell'
    out = OUT / f'methylation_matrix_{ctx}_{LABEL}.tsv.gz'
    mat.to_csv(out, sep='\t', compression='gzip')
    print(f'{ctx}: {mat.shape[0]} cells x {mat.shape[1]} bins -> {out.name}')
    # bins coord file once
    ref = next(METH.glob(f'*.GCH.{LABEL}_methylation.txt.gz'))
    pd.read_csv(ref, sep='\t', usecols=['bin_id', 'chr', 'start', 'end']).to_csv(
        OUT / f'bins_{LABEL}.tsv', sep='\t', index=False)
print('done')
