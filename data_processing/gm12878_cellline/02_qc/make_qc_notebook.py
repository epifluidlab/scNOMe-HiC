#!/usr/bin/env python
"""Generate gm_sc_new/qc_plots.ipynb.

Faithful replica of ../snakemake/qc_plots.ipynb adapted to this GM dataset:
  - WORKDIR -> gm_sc_new
  - trinuc files are gzipped  (.calmd.trinuc_methy.{chrM,chr21}.txt.gz)
  - GCH/HCG 6plus2 bed middle  (.calmd.cytosine.filtered.sort.)
  - per-cell aggregate tables are built from scratch (none pre-saved here)
  - batch = single group ('scNH_GM_4plex'); no barcode/plex split
"""
import json
from pathlib import Path

OUT = Path(__file__).resolve().parent / "qc_plots.ipynb"


def md(text):
    return {"cell_type": "markdown", "metadata": {}, "source": text.splitlines(keepends=True)}


def code(text):
    return {"cell_type": "code", "execution_count": None, "metadata": {},
            "outputs": [], "source": text.splitlines(keepends=True)}


cells = []

# ── Cell 0 ──────────────────────────────────────────────────────────────
cells.append(md(
"""# NOMe-HiC GM12878 QC plots (gm_sc_new)

QC summary and histograms for the cells processed under this workdir
(`gm_sc_new/`), using the same logic as [`../snakemake/qc_plots.ipynb`]
(`../snakemake/qc_plots.ipynb`) (`summarize_cellline_qc_from_data`).

**Dataset:** 188 cells = 47 samples (`scNH_GM_4plex_*_S*`) x 4 barcodes
(ATCACG / CGATGT / GCCAAT / TGACCA). Single 4plex GM12878 run, so all cells
are treated as one "batch" (`scNH_GM_4plex`).

**Inputs (per cell):**
- `04.alignment_snakemake/{prefix}.summary.txt.gz` — Hi-C alignment stats
- `07.bistools_snakemake/qc/{prefix}/{prefix}.calmd.trinuc_methy.{chrM,chr21}.txt.gz` — methylation QC
- `07.bistools_snakemake/methylation/{prefix}/{prefix}.calmd.cytosine.filtered.sort.{GCH,HCG}.6plus2.bed.gz` — GCH/HCG site counts
- `07.bistools_snakemake/WCG/{prefix}/{prefix}.calmd.cytosine.filtered.sort.WCG.6plus2.bed.gz` — WCG loci counts

**Outputs:** `QC/` tables, `figures/cellline_summary.pdf` (+ `_p99`),
`QC/cellline_passed.txt`, per-batch overlay/violin PDFs under `figures/`, and
`QC/methylation_matrices/methylation_matrix_{GCH,HCG}_{bin}.tsv.gz`.

**NOTE vs snakemake:** trinuc files and the 6plus2 BEDs are gzipped here and use
the `.calmd.cytosine.filtered.sort.` middle (snakemake used `.cyt.filtered.sort.`);
the per-cell aggregate tables are built from scratch (none were pre-saved here).
"""))

# ── Cell 1: imports + config ────────────────────────────────────────────
cells.append(code(
"""import gzip
import os
from pathlib import Path

import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
import yaml
from matplotlib.backends.backend_pdf import PdfPages
from tqdm.auto import tqdm

WORKDIR = Path('/gpfs/projects/b1198/epifluidlab/yoshii/sc_nomehic_cellline/gm_sc_new')
os.chdir(WORKDIR)

ALIGN_DIR = WORKDIR / '04.alignment_snakemake'
QC_DIR = WORKDIR / '07.bistools_snakemake' / 'qc'
METH_DIR = WORKDIR / '07.bistools_snakemake' / 'methylation'
WCG_DIR = WORKDIR / '07.bistools_snakemake' / 'WCG'
OUT_QC = WORKDIR / 'QC'
OUT_FIG = WORKDIR / 'figures'
OUT_QC.mkdir(exist_ok=True)
OUT_FIG.mkdir(exist_ok=True)

with open('configs/config.yaml') as f:
    CFG = yaml.safe_load(f)

THRESHOLDS = {
    'fragnum_threshold': CFG['fragnum_threshold'],
    'noncpg_threshold': CFG['noncpg_threshold'],
    'GCH_threshold': CFG['GCH_threshold'],
    'HCG_threshold': CFG['HCG_threshold'],
    'transrate_threshold': CFG['transrate_threshold'],
    'cis1kbnum_threshold': CFG['cis1kbnum_threshold'],
    # not set in this project's config -> sensible defaults
    'reads_mapq30_threshold': CFG.get('reads_mapq30_threshold', 100000),
    # Upper bound on cisnum to drop suspected doublets (inf = disabled)
    'cisnum_max_threshold': CFG.get('cisnum_max_threshold', float('inf')),
}
print('Workdir:', WORKDIR)
print('QC thresholds:', THRESHOLDS)
"""))

# ── Cell 2: main summarize function (verbatim from snakemake notebook) ───
cells.append(code(
r"""def summarize_cellline_qc_from_data(
    prefixes,
    gch_hcg_df,
    chrm_df,
    chr21_df,
    summary_files,
    dataset_label='mixed cellline',
    output_file=None,
    summary_pdf=None,
    utilized_cell_output=None,
    fragnum_threshold=800000,
    noncpg_threshold=3,
    GCH_threshold=1_000_000,
    HCG_threshold=150_000,
    transrate_threshold=0.7,
    cis1kbnum_threshold=2000,
    reads_mapq30_threshold=10000,
    cisnum_max_threshold=float('inf'),   # upper bound to drop suspected doublets
    show_inline=False,
    summary_pdf_p99=None,
    clip_percentile_p99=99,
    clip_only_if_outlier=True,
):
    """ + '"""' + r"""
    Summarize QC metrics from in-memory data for NOMe-HiC cellline analysis.
    Returns (df_all, df_passed).
    """ + '"""' + r"""

    def plot_hist(
        df,
        column,
        title,
        xlabel,
        pdf=None,
        threshold=None,
        clip_percentile=None,
        clip_only_if_outlier=False,
    ):
        plt.figure(figsize=(8, 5))
        subset = df[column].dropna()
        if subset.empty:
            plt.close()
            return

        plot_vals = subset
        title_use = title
        bins = 50

        if clip_percentile is not None:
            x_hi = np.percentile(subset, clip_percentile)
            n_above = int((subset > x_hi).sum())
            apply_clip = n_above > 0 if clip_only_if_outlier else True
            if apply_clip:
                plot_vals = subset[subset <= x_hi]
                x_lo = plot_vals.min()
                bins = np.linspace(x_lo, x_hi, 51)
                if n_above > 0:
                    title_use = (
                        f"{title} (x <= p{clip_percentile:.0f}={x_hi:.4g}; "
                        f"{n_above} above)"
                    )

        plt.hist(
            plot_vals,
            bins=bins,
            alpha=0.7,
            color='steelblue',
            edgecolor='black',
        )
        if threshold is not None:
            plt.axvline(
                threshold,
                color='red',
                linestyle='--',
                linewidth=1.5,
                label='threshold',
            )
        plt.title(title_use)
        plt.xlabel(xlabel)
        plt.ylabel('Frequency')
        if threshold is not None:
            plt.legend()
        if pdf:
            pdf.savefig()
        if show_inline:
            plt.show()
        plt.close()
    chrm_df.columns = ['noncpg_chrM','endo_chrM','exo_chrM']
    # --- Parse summaries ---
    all_entries = []
    for prefix, summ_path in tqdm(zip(prefixes, summary_files), total=len(prefixes), desc="Parsing QC summaries"):
        entry = {"prefix": prefix, "dataset": dataset_label}
        try:
            align_df = pd.read_csv(summ_path, sep='\t', header=None)
            entry.update({
                'uniquemap': float(align_df[align_df[0]=='UniqMapped:'][2].values[0].strip('%')),
                'mapq30rate': float(align_df[align_df[0]=='UniqMappedMapQ30:'][2].values[0].strip('%')),
                'mapq30num': int(align_df[align_df[0]=='UniqMappedMapQ30:'][1].values[0]),
                'fragnum': int(align_df[align_df[0]=='TotalFragments:'][1].values[0]),
                'cisnum':int(align_df[align_df[0]=='UniqMappedMapQ30NoPcrCis:'][1].values[0]),
                'cis1kbnum': int(align_df[align_df[0]=='UniqMappedMapQ30NoPcrCisMore1kb:'][1].values[0]),
                'transnum': int(align_df[align_df[0]=='UniqMappedMapQ30NoPcrTrans:'][1].values[0]),
                'cis1kbrate': float(align_df[align_df[0]=='UniqMappedMapQ30NoPcrCisMore1kb:'][2].values[0].strip('%')),
                'transrate': float(align_df[align_df[0]=='UniqMappedMapQ30NoPcrTrans:'][2].values[0].strip('%')),
            })
        except Exception:
            entry.update({k: np.nan for k in [
                'uniquemap','mapq30rate','mapq30num','fragnum','cisnum','cis1kbnum','transnum','cis1kbrate','transrate'
            ]})

        # Add methylation and GCH/HCG data
        if prefix in chrm_df.index:
            entry.update(chrm_df.loc[prefix].to_dict())
        else:
            entry.update({'noncpg_chrM': np.nan, 'endo_chrM': np.nan, 'exo_chrM': np.nan})

        if prefix in chr21_df.index:
            entry.update(chr21_df.loc[prefix].to_dict())
        else:
            entry.update({'noncpg': np.nan, 'endo': np.nan, 'exo': np.nan})

        if prefix in gch_hcg_df.index:
            entry.update(gch_hcg_df.loc[prefix].to_dict())
        else:
            entry.update({'GCH': np.nan, 'HCG': np.nan, 'WCG': np.nan})

        all_entries.append(entry)

    df = pd.DataFrame(all_entries)

    # --- Save summary table ---
    if output_file:
        df.to_csv(output_file, sep='\t', index=False)
        print(f"Saved summary table: {output_file}")

    # --- Plot histograms ---
    plot_columns = [
        ('fragnum', 'Raw fragment number', '# of fragments'),
        ('uniquemap', 'Unique mapping rate', 'Mapping rate (%)'),
        ('mapq30rate', 'Fragments MAPQ>30 rate', 'MAPQ>30 (%)'),
        ('mapq30num', 'Reads passing MAPQ>30', '# of reads'),
        ('cisnum', 'Cis interactions for Hi-C', '# of cis interactions'),
        ('transnum', 'Trans interactions for Hi-C', '# of trans interactions'),
        ('cis1kbnum', 'Cis interactions >1kb Hi-C', '# of cis interactions'),
        ('transrate', 'Trans interaction rate Hi-C', 'Trans rate (%)'),
        ('cis1kbrate', 'Cis >1kb interaction rate Hi-C', 'Cis >1kb rate (%)'),
        ('noncpg_chrM', 'Non-CpG methylation rate', '% methylation'),
        ('endo_chrM', 'Endogenous methylation rate', '% methylation'),
        ('exo_chrM', 'Exogenous methylation rate', '% methylation'),
        ('noncpg', 'Non-CpG methylation rate', '% methylation'),
        ('endo', 'Endogenous methylation rate', '% methylation'),
        ('exo', 'Exogenous methylation rate', '% methylation'),
        ('GCH', 'Number of GCH sites', 'Number of sites'),
        ('HCG', 'Number of HCG sites', 'Number of sites'),
        ('WCG', 'Number of WCG loci', 'Number of loci')
    ]
    thresholds = {
        'fragnum': fragnum_threshold,
        'noncpg': noncpg_threshold,
        'noncpg_chrM': noncpg_threshold,
        'GCH': GCH_threshold,
        'HCG': HCG_threshold,
        'transrate': transrate_threshold,
        'cis1kbnum': cis1kbnum_threshold,
        'mapq30num': reads_mapq30_threshold,
    }

    pdf_jobs = []
    if summary_pdf:
        pdf_jobs.append((summary_pdf, None, False, False))
    if summary_pdf_p99:
        pdf_jobs.append(
            (summary_pdf_p99, clip_percentile_p99, True, clip_only_if_outlier)
        )

    for pdf_path, clip_p, show, clip_if_out in pdf_jobs:
        with PdfPages(pdf_path) as pdf:
            for col, title, xlabel in plot_columns:
                plot_hist(
                    df,
                    col,
                    title,
                    xlabel,
                    pdf,
                    thresholds.get(col),
                    clip_percentile=clip_p,
                    clip_only_if_outlier=clip_if_out,
                )
        print(f"Saved summary PDF: {pdf_path}")

    if show_inline and not pdf_jobs:
        for col, title, xlabel in plot_columns:
            plot_hist(df, col, title, xlabel, None, thresholds.get(col))
    elif show_inline and pdf_jobs:
        for col, title, xlabel in plot_columns:
            plot_hist(
                df,
                col,
                title,
                xlabel,
                None,
                thresholds.get(col),
                clip_percentile=clip_percentile_p99 if summary_pdf_p99 else None,
                clip_only_if_outlier=clip_only_if_outlier,
            )

    # --- Filtering ---
    df_filtered = df[
        (df['fragnum'] > fragnum_threshold) &
        (df['noncpg'] < noncpg_threshold) &        # chr21 (autosome) non-CpG
        (df['noncpg_chrM'] < noncpg_threshold) &   # chrM non-CpG (bisulfite conversion)
        (df['GCH'] > GCH_threshold) &
        (df['HCG'] > HCG_threshold) &
        (df['transrate'] > transrate_threshold) &
        (df['cis1kbnum'] > cis1kbnum_threshold) &
        (df['cisnum'] < cisnum_max_threshold)   # upper bound, drops doublets
    ]

    if utilized_cell_output:
        df_filtered['prefix'].to_csv(utilized_cell_output, index=False, header=False)
        print(f"Saved passing cell list: {utilized_cell_output}")

    print(f"{len(df_filtered)}/{len(df)} cells passed QC thresholds")
    return df, df_filtered
"""))

# ── Cell 3: helper builders (ADAPTED suffixes/middle for gm_sc_new) ──────
cells.append(code(
r"""# ADAPTED for gm_sc_new: trinuc files are gzipped and the 6plus2 BEDs use the
# '.calmd.cytosine.filtered.sort.' middle (snakemake used '.cyt.filtered.sort.').
TRINUC_SUFFIX_CHRM = '.calmd.trinuc_methy.chrM.txt.gz'
TRINUC_SUFFIX_CHR21 = '.calmd.trinuc_methy.chr21.txt.gz'
BED_MIDDLE = '.calmd.cytosine.filtered.sort.'


def _trinuc_percent(path, trinuc):
  """ + '"""' + """Return methylation % for trinuc (e.g. ACT) from a trinuc_methy file.""" + '"""' + r"""
  df = pd.read_csv(path, sep='\t', header=None, names=['trinuc', 'count', 'percent'])
  vals = df.loc[df['trinuc'] == f'{trinuc}:', 'percent']
  if len(vals) == 0:
    return np.nan
  return float(str(vals.iloc[0]).strip('%'))


def build_trinuc_table(prefixes, suffix):
  rows = []
  for prefix in tqdm(prefixes, desc=f'trinuc {suffix}'):
    path = QC_DIR / prefix / f'{prefix}{suffix}'
    if not path.exists():
      rows.append([prefix, np.nan, np.nan, np.nan])
      continue
    rows.append([
      prefix,
      _trinuc_percent(path, 'ACT'),
      _trinuc_percent(path, 'ACG'),
      _trinuc_percent(path, 'GCT'),
    ])
  df = pd.DataFrame(rows, columns=['sample', 'noncpg', 'endo', 'exo'])
  return df.set_index('sample')


def _count_bed_gz(path):
  if not path.exists():
    return np.nan
  with gzip.open(path, 'rt') as f:
    return sum(1 for _ in f)


def build_gch_hcg_table(prefixes):
  # Counts covered loci per cell for GCH/HCG (under methylation/) and WCG (under WCG/).
  rows = []
  for prefix in tqdm(prefixes, desc='GCH/HCG/WCG counts'):
    meth_cell = METH_DIR / prefix
    gch = meth_cell / f'{prefix}{BED_MIDDLE}GCH.6plus2.bed.gz'
    hcg = meth_cell / f'{prefix}{BED_MIDDLE}HCG.6plus2.bed.gz'
    wcg = WCG_DIR / prefix / f'{prefix}{BED_MIDDLE}WCG.6plus2.bed.gz'
    rows.append([prefix, _count_bed_gz(gch), _count_bed_gz(hcg), _count_bed_gz(wcg)])
  df = pd.DataFrame(rows, columns=['sample', 'GCH', 'HCG', 'WCG'])
  return df.set_index('sample')


def discover_prefixes(qc_dir=QC_DIR):
  """ + '"""' + """All sample folders under 07.bistools_snakemake/qc that have a summary file.
  Accepts either uncompressed .summary.txt or gzipped .summary.txt.gz.
  """ + '"""' + r"""
  prefixes = []
  for p in sorted(qc_dir.iterdir()):
    if p.is_dir() and (
        (p / f'{p.name}.summary.txt').exists() or
        (p / f'{p.name}.summary.txt.gz').exists()
    ):
      prefixes.append(p.name)
  return prefixes
"""))

# ── Cell 4: discover prefixes (single group, no batch filter) ────────────
cells.append(code(
"""# Discover cells with completed bis-QC outputs
all_prefixes = discover_prefixes()
print(f'Found {len(all_prefixes)} cells with QC outputs')

# Single 4plex GM12878 run -> no batch filter, all cells used.
cellline_prefixes = all_prefixes
print(f'Using all {len(cellline_prefixes)} cells (single group)')

pd.Series(cellline_prefixes).to_csv(OUT_QC / 'cellline_prefixes_used.txt', index=False, header=False)
"""))

# ── Cell 5: build aggregate tables (UNCOMMENTED — not pre-saved here) ────
cells.append(code(
"""# Build aggregate tables from scratch (no pre-saved tables exist in this folder).
# This reads all discovered cells; it is the main compute step.
gch_hcg_cellline = build_gch_hcg_table(cellline_prefixes)
chrm_cellline = build_trinuc_table(cellline_prefixes, TRINUC_SUFFIX_CHRM)
chr21_cellline = build_trinuc_table(cellline_prefixes, TRINUC_SUFFIX_CHR21)

gch_hcg_cellline.to_csv(OUT_QC / 'cellline.gch_hcg_count.txt', sep='\\t')
chrm_cellline.to_csv(OUT_QC / 'cellline.chrM.txt', sep='\\t')
chr21_cellline.to_csv(OUT_QC / 'cellline.chr21.txt', sep='\\t')

display(gch_hcg_cellline.head())
display(chr21_cellline.head())
"""))

# ── Cell 6: reload saved tables ──────────────────────────────────────────
cells.append(code(
"""# (Re)load the tables saved in the previous cell
gch_hcg_cellline = pd.read_csv(OUT_QC / 'cellline.gch_hcg_count.txt', sep='\\t', index_col=0)
chrm_cellline = pd.read_csv(OUT_QC / 'cellline.chrM.txt', sep='\\t', index_col=0)
chr21_cellline = pd.read_csv(OUT_QC / 'cellline.chr21.txt', sep='\\t', index_col=0)
"""))

# ── Cell 7: run summarize ────────────────────────────────────────────────
cells.append(code(
"""# Alignment summaries + QC plots
prefixes = cellline_prefixes
def _summary_path(p):
    plain = ALIGN_DIR / f'{p}.summary.txt'
    gz    = ALIGN_DIR / f'{p}.summary.txt.gz'
    return str(plain if plain.exists() else gz)   # pandas auto-infers gzip from extension
summary_files = [_summary_path(p) for p in prefixes]

df_all_cellline, df_passed = summarize_cellline_qc_from_data(
    prefixes=prefixes,
    gch_hcg_df=gch_hcg_cellline,
    chrm_df=chrm_cellline,
    chr21_df=chr21_cellline,
    summary_files=summary_files,
    dataset_label='sc NOMe-HiC GM12878 (4plex)',
    output_file=str(OUT_QC / 'cellline_qc_summary.txt'),
    summary_pdf=str(OUT_FIG / 'cellline_summary.pdf'),
    summary_pdf_p99=str(OUT_FIG / 'cellline_summary_p99.pdf'),
    clip_percentile_p99=99,
    clip_only_if_outlier=True,
    utilized_cell_output=str(OUT_QC / 'cellline_passed.txt'),
    show_inline=False,
    **THRESHOLDS,
)

df_all_cellline.head()
"""))

# ── Cell 8 ───────────────────────────────────────────────────────────────
cells.append(code("df_passed\n"))

# ── Cell 9: pass rate (single group) ─────────────────────────────────────
cells.append(code(
"""# Single group: all cells share one batch label
df_all_cellline['batch'] = 'scNH_GM_4plex'
passed_set = set(df_passed['prefix'])
df_all_cellline['passed'] = df_all_cellline['prefix'].isin(passed_set)

batch_summary = (
    df_all_cellline.groupby('batch')['passed']
    .agg(['sum', 'count'])
    .assign(pass_rate=lambda x: x['sum'] / x['count'])
    .rename(columns={'sum': 'n_passed', 'count': 'n_total'})
)
batch_summary
"""))

# ── Cell 10: per-batch histograms ────────────────────────────────────────
cells.append(code(
r"""# Overlay histograms: one panel per metric (single group here)
PLOT_COLUMNS = [
    ('fragnum', 'Raw fragment number', '# of fragments'),
    ('uniquemap', 'Unique mapping rate', 'Mapping rate (%)'),
    ('mapq30rate', 'Fragments MAPQ>30 rate', 'MAPQ>30 (%)'),
    ('mapq30num', 'Reads passing MAPQ>30', '# of reads'),
    ('cisnum', 'Cis interactions for Hi-C', '# of cis interactions'),
    ('transnum', 'Trans interactions for Hi-C', '# of trans interactions'),
    ('cis1kbnum', 'Cis interactions >1kb Hi-C', '# of cis interactions'),
    ('transrate', 'Trans interaction rate Hi-C', 'Trans rate (%)'),
    ('cis1kbrate', 'Cis >1kb interaction rate Hi-C', 'Cis >1kb rate (%)'),
    ('noncpg_chrM', 'Non-CpG methylation rate (chrM)', '% methylation'),
    ('endo_chrM', 'Endogenous methylation rate (chrM)', '% methylation'),
    ('exo_chrM', 'Exogenous methylation rate (chrM)', '% methylation'),
    ('noncpg', 'Non-CpG methylation rate (chr21)', '% methylation'),
    ('endo', 'Endogenous methylation rate (chr21)', '% methylation'),
    ('exo', 'Exogenous methylation rate (chr21)', '% methylation'),
    ('GCH', 'Number of GCH sites', 'Number of sites'),
    ('HCG', 'Number of HCG sites', 'Number of sites'),
    ('WCG', 'Number of WCG loci', 'Number of loci'),
]

METRIC_THRESHOLDS = {
    'fragnum': THRESHOLDS['fragnum_threshold'],
    'noncpg': THRESHOLDS['noncpg_threshold'],
    'noncpg_chrM': THRESHOLDS['noncpg_threshold'],
    'GCH': THRESHOLDS['GCH_threshold'],
    'HCG': THRESHOLDS['HCG_threshold'],
    'transrate': THRESHOLDS['transrate_threshold'],
    'cis1kbnum': THRESHOLDS['cis1kbnum_threshold'],
    'mapq30num': THRESHOLDS['reads_mapq30_threshold'],
}


def plot_histograms_per_batch(
    df,
    plot_columns,
    thresholds,
    batch_order=None,
    out_pdf=None,
    bins=40,
    show_inline=False,
    clip_percentile=None,
    clip_only_if_outlier=False,
):
    """ + '"""' + """One figure per metric: batches overlaid by color.""" + '"""' + r"""
    if 'batch' not in df.columns:
        df = df.copy()
        df['batch'] = 'scNH_GM_4plex'
    if batch_order is None:
        batch_order = sorted(df['batch'].dropna().unique())

    batch_colors = dict(
        zip(
            batch_order,
            sns.color_palette('tab10', n_colors=max(len(batch_order), 1)),
        )
    )

    pdf = PdfPages(out_pdf) if out_pdf else None
    try:
        for col, title, xlabel in plot_columns:
            fig, ax = plt.subplots(figsize=(9, 5))
            thr = thresholds.get(col)

            all_vals = df[col].dropna()
            if all_vals.empty:
                plt.close(fig)
                continue

            title_use = title
            x_hi = None
            apply_clip = False
            if clip_percentile is not None:
                x_hi = float(np.percentile(all_vals, clip_percentile))
                n_above = int((all_vals > x_hi).sum())
                apply_clip = (n_above > 0) if clip_only_if_outlier else True
                if apply_clip:
                    x_lo = all_vals.min()
                    bin_edges = np.linspace(x_lo, x_hi, bins + 1)
                    if n_above > 0:
                        title_use = (
                            f"{title} (x <= p{clip_percentile:.0f}={x_hi:.4g}; "
                            f"{n_above} above)"
                        )
                else:
                    x_hi = None
                    bin_edges = np.histogram_bin_edges(all_vals, bins=bins)
            else:
                bin_edges = np.histogram_bin_edges(all_vals, bins=bins)

            for batch in batch_order:
                vals_full = df.loc[df['batch'] == batch, col].dropna()
                if vals_full.empty:
                    continue
                n_total = len(vals_full)
                if thr is not None and n_total > 0:
                    pct_under = 100.0 * float((vals_full < thr).sum()) / n_total
                    label = f'{batch} (n={n_total}, <thr: {pct_under:.1f}%)'
                else:
                    label = f'{batch} (n={n_total})'

                vals = vals_full
                if apply_clip and x_hi is not None:
                    vals = vals[vals <= x_hi]
                ax.hist(
                    vals,
                    bins=bin_edges,
                    alpha=0.55,
                    color=batch_colors[batch],
                    label=label,
                    edgecolor='white',
                    linewidth=0.4,
                )

            if thr is not None and (not apply_clip or thr <= x_hi):
                all_n = len(all_vals)
                pct_under_all = 100.0 * float((all_vals < thr).sum()) / all_n if all_n else 0.0
                ax.axvline(
                    thr,
                    color='red',
                    linestyle='--',
                    linewidth=1.5,
                    label=f'threshold (all <thr: {pct_under_all:.1f}%)',
                )

            ax.set_title(title_use)
            ax.set_xlabel(xlabel)
            ax.set_ylabel('Count')
            ax.legend(loc='best', fontsize=9, framealpha=0.9)
            fig.tight_layout()

            if pdf is not None:
                pdf.savefig(fig, bbox_inches='tight')
            if show_inline:
                plt.show()
            plt.close(fig)
    finally:
        if pdf is not None:
            pdf.close()

    if out_pdf is not None:
        print(f'Saved overlay histograms: {out_pdf}')


if 'batch' not in df_all_cellline.columns:
    df_all_cellline['batch'] = 'scNH_GM_4plex'

batch_order = sorted(df_all_cellline['batch'].unique())

# Cap x-axis at p98 only when outliers exist (values above p98)
plot_histograms_per_batch(
    df_all_cellline,
    PLOT_COLUMNS,
    METRIC_THRESHOLDS,
    batch_order=batch_order,
    out_pdf=OUT_FIG / 'cellline_summary_by_batch_p99_if_outlier.pdf',
    clip_percentile=98,
    clip_only_if_outlier=True,
    show_inline=True,
    bins=200,
)
"""))

# ── Cell 11: violin function ─────────────────────────────────────────────
cells.append(code(
r"""def plot_violins_per_batch(
    df,
    plot_columns,
    thresholds,
    batch_order=None,
    out_pdf=None,
    show_inline=False,
    clip_percentile=None,
    clip_only_if_outlier=False,
):
    """ + '"""' + """One figure per metric: violin plot across batches.""" + '"""' + r"""

    if 'batch' not in df.columns:
        df = df.copy()
        df['batch'] = 'scNH_GM_4plex'

    if batch_order is None:
        batch_order = sorted(df['batch'].dropna().unique())

    pdf = PdfPages(out_pdf) if out_pdf else None

    try:
        for col, title, ylabel in plot_columns:
            if col not in df.columns:
                continue

            plot_df = df[['batch', col]].dropna().copy()
            plot_df = plot_df[plot_df['batch'].isin(batch_order)]

            if plot_df.empty:
                continue

            thr = thresholds.get(col)
            title_use = title

            if clip_percentile is not None:
                x_hi = float(np.percentile(plot_df[col], clip_percentile))
                n_above = int((plot_df[col] > x_hi).sum())

                apply_clip = (n_above > 0) if clip_only_if_outlier else True

                if apply_clip:
                    plot_df = plot_df[plot_df[col] <= x_hi]
                    title_use = (
                        f"{title} (<= p{clip_percentile:.0f}={x_hi:.4g}; "
                        f"{n_above} above)"
                    )

            fig, ax = plt.subplots(figsize=(10, 5))

            sns.violinplot(
                data=plot_df,
                x='batch',
                y=col,
                order=batch_order,
                inner='box',
                cut=0,
                linewidth=1,
                ax=ax,
            )

            sns.stripplot(
                data=plot_df,
                x='batch',
                y=col,
                order=batch_order,
                color='black',
                size=1.5,
                alpha=0.25,
                jitter=0.25,
                ax=ax,
            )

            if thr is not None:
                all_vals = df[col].dropna()
                pct_under_all = 100.0 * (all_vals < thr).sum() / len(all_vals)

                ax.axhline(
                    thr,
                    color='red',
                    linestyle='--',
                    linewidth=1.5,
                    label=f'threshold (all <thr: {pct_under_all:.1f}%)',
                )
                ax.legend(loc='best', fontsize=9)

            ax.set_title(title_use)
            ax.set_xlabel('Batch')
            ax.set_ylabel(ylabel)
            ax.tick_params(axis='x', rotation=45)
            fig.tight_layout()

            if pdf is not None:
                pdf.savefig(fig, bbox_inches='tight')

            if show_inline:
                plt.show()

            plt.close(fig)

    finally:
        if pdf is not None:
            pdf.close()

    if out_pdf is not None:
        print(f'Saved violin plots: {out_pdf}')
"""))

# ── Cell 12: violin call ─────────────────────────────────────────────────
cells.append(code(
"""plot_violins_per_batch(
    df_all_cellline,
    PLOT_COLUMNS,
    METRIC_THRESHOLDS,
    batch_order=batch_order,
    out_pdf=OUT_FIG / 'cellline_summary_by_batch_violin_p98_if_outlier.pdf',
    clip_percentile=98,
    clip_only_if_outlier=True,
    show_inline=True,
)
"""))

# ── Cell 13: publication violin ──────────────────────────────────────────
cells.append(code(
"""# Publication-style violin: non-CpG methylation
sns.set_context('paper', font_scale=1.4)
sns.set_style('whitegrid')
plt.rcParams['pdf.fonttype'] = 42
plt.rcParams['ps.fonttype'] = 42

plot_df = df_all_cellline.dropna(subset=['noncpg']).copy()
batch_order = sorted(plot_df['batch'].unique())

plt.figure(figsize=(8, 6))
ax = sns.violinplot(data=plot_df, x='batch', y='noncpg', order=batch_order, inner='box', cut=0)
ax.set_xlabel('')
ax.set_ylabel('Non-CpG methylation rate (%)')
ax.set_title('Non-CpG methylation')
plt.xticks(rotation=45, ha='right')
plt.tight_layout()
plt.savefig(OUT_FIG / 'noncpg_by_batch.pdf', dpi=300)
plt.savefig(OUT_FIG / 'noncpg_by_batch.png', dpi=300)
plt.show()
"""))

# ── Cell 14: side-by-side count violins (single group, no jitter) ────────
cells.append(code(
"""# Count violins, matplotlib-styled (single group, no jitter).
#   panel 1: HCG + WCG loci   panel 2: GCH loci   panel 3: #cis + #cis>1kb
# Values are scaled to round units (x10^3 / x10^6) so there is no axis offset
# label, which keeps every panel title at the same height.
import matplotlib as mpl

PANELS = [
    ('CpG loci counts',   [('HCG', 'HCG'), ('WCG', 'WCG')],            'Number of loci'),
    ('GCH loci count',    [('GCH', 'GCH')],                            'Number of loci'),
    ('Hi-C cis contacts', [('cisnum', '#cis'), ('cis1kbnum', '#cis>1kb')], '# of contacts'),
]


def _scale(maxv):
    if maxv >= 1e6:
        return 1e6, ' (\\u00d710\\u2076)'
    if maxv >= 1e3:
        return 1e3, ' (\\u00d710\\u00b3)'
    return 1.0, ''


with mpl.rc_context({"pdf.fonttype": 42, "ps.fonttype": 42, "font.family": "sans-serif",
                     "font.sans-serif": ["Arial", "Helvetica", "DejaVu Sans"],
                     "font.size": 13, "axes.titlesize": 14, "axes.labelsize": 14,
                     "xtick.labelsize": 12, "ytick.labelsize": 12, "axes.linewidth": 1.1,
                     "savefig.dpi": 300, "savefig.bbox": "tight"}):
    fig, axes = plt.subplots(1, len(PANELS), figsize=(3.0 * len(PANELS), 4.6))
    if len(PANELS) == 1:
        axes = [axes]

    for ax, (title, cols, ylabel) in zip(axes, PANELS):
        data, labels = [], []
        for col, lab in cols:
            if col not in df_all_cellline.columns:
                continue
            v = df_all_cellline[col].dropna().values
            if len(v):
                data.append(v)
                labels.append(lab)
        if not data:
            continue
        scale, unit = _scale(max(d.max() for d in data))
        data = [d / scale for d in data]
        pos = np.arange(1, len(data) + 1)
        parts = ax.violinplot(data, positions=pos, widths=0.75,
                              showmedians=True, showextrema=False)
        for b in parts["bodies"]:
            b.set_facecolor("#aac9e3"); b.set_edgecolor("black")
            b.set_alpha(0.9); b.set_linewidth(1.0)
        parts["cmedians"].set_color("#c0392b"); parts["cmedians"].set_linewidth(2.0)

        ax.set_xticks(pos); ax.set_xticklabels(labels)
        ax.set_ylabel(ylabel + unit); ax.set_title(title, y=1.02)
        ax.spines[["top", "right"]].set_visible(False)
        ax.set_axisbelow(True); ax.yaxis.grid(True, ls=":", alpha=0.45)

    fig.tight_layout()
    fig.savefig(OUT_FIG / "cellline_count_violins.pdf")
    fig.savefig(OUT_FIG / "cellline_count_violins.png")
    plt.show()
print("[OK] ->", OUT_FIG / "cellline_count_violins.pdf")
"""))

# ── Cell 15: methylation matrices header ─────────────────────────────────
cells.append(md(
"""## Cell x bin methylation matrices

Build dense matrices from `08.methylation_snakemake/*.{GCH,HCG}.{bin}_methylation.txt.gz`:
- **rows** = cells
- **columns** = `bin_id`
- **values** = `methylation_level`

Outputs under `QC/methylation_matrices/` (gzip TSV). Set `USE_QC_PASSED_ONLY = True`
to restrict to `cellline_passed.txt`. Available bins here: 1kb, 50kb, 100kb, 250kb.
"""))

# ── Cell 16: methylation matrices code ───────────────────────────────────
cells.append(code(
r"""METH_BIN_DIR = WORKDIR / '08.methylation_snakemake'
BIN_LABEL = '250kb'
OUT_MATRIX = OUT_QC / 'methylation_matrices'
OUT_MATRIX.mkdir(exist_ok=True)

# Set True to use only QC-passed cells (from cellline_passed.txt)
USE_QC_PASSED_ONLY = False


def _cell_from_methylation_path(path, context, bin_label):
    suffix = f'.{context}.{bin_label}_methylation.txt.gz'
    return Path(path).name[: -len(suffix)]


def build_methylation_matrix(context, bin_label=BIN_LABEL, meth_dir=METH_BIN_DIR, cells=None):
    """ + '"""' + """Return cells x bins matrix of methylation_level.""" + '"""' + r"""
    pattern = f'*.{context}.{bin_label}_methylation.txt.gz'
    files = sorted(meth_dir.glob(pattern))
    if not files:
        raise FileNotFoundError(f'No files matching {pattern} in {meth_dir}')

    if cells is not None:
        cells = set(cells)
        files = [f for f in files if _cell_from_methylation_path(f, context, bin_label) in cells]

    rows = []
    for path in tqdm(files, desc=f'{context} {bin_label}'):
        cell = _cell_from_methylation_path(path, context, bin_label)
        df = pd.read_csv(path, sep='\t', usecols=['bin_id', 'methylation_level'])
        rows.append(df.set_index('bin_id')['methylation_level'].rename(cell))

    mat = pd.concat(rows, axis=1).T
    mat.index.name = 'cell'
    return mat


def save_bin_coords(meth_dir, bin_label, out_path):
    """ + '"""' + """Save bin coordinates once (same across cells).""" + '"""' + r"""
    ref = next(meth_dir.glob(f'*.GCH.{bin_label}_methylation.txt.gz'))
    coords = pd.read_csv(ref, sep='\t', usecols=['bin_id', 'chr', 'start', 'end'])
    coords.to_csv(out_path, sep='\t', index=False)
    return coords


cells_filter = None
if USE_QC_PASSED_ONLY:
    passed_path = OUT_QC / 'cellline_passed.txt'
    if passed_path.exists():
        cells_filter = pd.read_csv(passed_path, header=None)[0].tolist()
        print(f'Filtering to {len(cells_filter)} QC-passed cells')
    else:
        print('cellline_passed.txt not found; using all cells')

bin_coords_path = OUT_MATRIX / f'bins_{BIN_LABEL}.tsv'
if not bin_coords_path.exists():
    save_bin_coords(METH_BIN_DIR, BIN_LABEL, bin_coords_path)
    print(f'Saved bin coordinates: {bin_coords_path}')

for context in ('GCH', 'HCG'):
    mat = build_methylation_matrix(context, cells=cells_filter)
    out_file = OUT_MATRIX / f'methylation_matrix_{context}_{BIN_LABEL}.tsv.gz'
    mat.to_csv(out_file, sep='\t', compression='gzip')
    print(
        f'{context}: {mat.shape[0]} cells x {mat.shape[1]} bins -> {out_file} '
        f'({out_file.stat().st_size / 1e6:.1f} MB)'
    )
    display(mat.iloc[:3, :5])
"""))

def preserve_outputs(new_cells, old_path):
    """Carry over outputs/execution_count from an existing notebook so that
    regenerating does NOT wipe results already produced by running the notebook.

    A new code cell inherits the outputs of an old code cell only when their
    source matches EXACTLY (matched greedily, in order). Cells whose source
    changed get fresh empty outputs (stale outputs would be misleading).
    """
    if not old_path.exists():
        return new_cells
    try:
        old = json.loads(old_path.read_text())
    except (json.JSONDecodeError, OSError) as e:
        print(f"  (could not read existing notebook, writing fresh: {e})")
        return new_cells

    from collections import defaultdict, deque
    pool = defaultdict(deque)
    for c in old.get("cells", []):
        if c.get("cell_type") == "code":
            pool["".join(c.get("source", []))].append(
                (c.get("outputs", []), c.get("execution_count"))
            )

    carried = 0
    for c in new_cells:
        if c["cell_type"] != "code":
            continue
        key = "".join(c["source"])
        if pool[key]:
            outs, exec_count = pool[key].popleft()
            if outs or exec_count is not None:
                c["outputs"] = outs
                c["execution_count"] = exec_count
                carried += 1
    if carried:
        print(f"  preserved outputs for {carried} unchanged code cell(s)")
    return new_cells


cells = preserve_outputs(cells, OUT)

nb = {
    "cells": cells,
    "metadata": {
        "kernelspec": {"display_name": "Python 3", "language": "python", "name": "python3"},
        "language_info": {"name": "python"},
    },
    "nbformat": 4,
    "nbformat_minor": 5,
}

OUT.write_text(json.dumps(nb, indent=1))
print(f"Wrote {OUT}  ({len(cells)} cells)")
