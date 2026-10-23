#!/usr/bin/env python
# --- repo paths: edit paths.yaml at the repository root, not this file -------
import os as _os, sys as _sys
_r = _os.path.dirname(_os.path.abspath(__file__))
while _r != "/" and not _os.path.exists(_os.path.join(_r, "paths.py")):
    _r = _os.path.dirname(_r)
_sys.path.insert(0, _r)
from paths import DATA, REFERENCE, SOFTWARE, WORK, TMP, CONDA_SH, CONDA_ENVS

"""Build cells x bins methylation matrices for HCG and GCH at multiple bin sizes.

Same logic as the matrix-building cell in qc_plots.ipynb. Reads per-cell *_methylation.txt.gz files
from 08.methylation_snakemake/, pivots on bin_id, writes one matrix per
(context, bin_label) pair to QC/methylation_matrices/.

Usage:
    build_methylation_matrices.py [250kb 100kb ...]
    (defaults to all four: 250kb, 100kb x HCG, GCH)
"""
import sys
from pathlib import Path

import pandas as pd
from tqdm import tqdm

WORKDIR      = Path(WORK + '/mixture_cellline')
METH_BIN_DIR = WORKDIR / '08.methylation_snakemake'
OUT_QC       = WORKDIR / 'QC'
OUT_MATRIX   = OUT_QC / 'methylation_matrices'
OUT_MATRIX.mkdir(exist_ok=True)

USE_QC_PASSED_ONLY = True
CONTEXTS = ('GCH', 'HCG')


def cell_from_methylation_path(path, context, bin_label):
    suffix = f'.{context}.{bin_label}_methylation.txt.gz'
    return Path(path).name[: -len(suffix)]


def save_bin_coords(meth_dir, bin_label, out_path):
    ref = next(meth_dir.glob(f'*.GCH.{bin_label}_methylation.txt.gz'))
    coords = pd.read_csv(ref, sep='\t', usecols=['bin_id', 'chr', 'start', 'end'])
    coords.to_csv(out_path, sep='\t', index=False)
    return coords


def build_methylation_matrix(context, bin_label, meth_dir=METH_BIN_DIR, cells=None):
    pattern = f'*.{context}.{bin_label}_methylation.txt.gz'
    files = sorted(meth_dir.glob(pattern))
    if not files:
        raise FileNotFoundError(f'No files matching {pattern} in {meth_dir}')
    if cells is not None:
        cells = set(cells)
        files = [f for f in files
                 if cell_from_methylation_path(f, context, bin_label) in cells]
    rows = []
    for path in tqdm(files, desc=f'{context} {bin_label}'):
        cell = cell_from_methylation_path(path, context, bin_label)
        df = pd.read_csv(path, sep='\t', usecols=['bin_id', 'methylation_level'])
        rows.append(df.set_index('bin_id')['methylation_level'].rename(cell))
    mat = pd.concat(rows, axis=1).T
    mat.index.name = 'cell'
    return mat


def main(bin_labels):
    cells_filter = None
    if USE_QC_PASSED_ONLY:
        passed_path = OUT_QC / 'cellline_passed.txt'
        if passed_path.exists():
            cells_filter = pd.read_csv(passed_path, header=None)[0].tolist()
            print(f'Filtering to {len(cells_filter)} QC-passed cells')
        else:
            print('cellline_passed.txt not found; using all cells')

    for bin_label in bin_labels:
        bin_coords_path = OUT_MATRIX / f'bins_{bin_label}.tsv'
        save_bin_coords(METH_BIN_DIR, bin_label, bin_coords_path)
        print(f'Saved bin coords: {bin_coords_path}')

        for context in CONTEXTS:
            mat = build_methylation_matrix(context, bin_label, cells=cells_filter)
            out_file = OUT_MATRIX / f'methylation_matrix_{context}_{bin_label}.tsv.gz'
            mat.to_csv(out_file, sep='\t', compression='gzip')
            size_mb = out_file.stat().st_size / 1e6
            print(f'  {context} {bin_label}: {mat.shape[0]} cells x {mat.shape[1]} bins '
                  f'-> {out_file.name}  ({size_mb:.1f} MB)')


if __name__ == '__main__':
    bin_labels = sys.argv[1:] or ['250kb', '100kb']
    print('Bin labels:', bin_labels)
    main(bin_labels)
