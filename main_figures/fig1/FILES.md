# FILES — main_figures/fig1

2 notebooks. See `README.md` for inputs, panels, and which script produces each
input.

| File | What it is | Origin |
|---|---|---|
| `fig1_methylation_accessibility.ipynb` | R 4.4.2, 4 code cells (3 with outputs). Pseudobulk vs bulk NOMe-HiC for CpG methylation and GpC accessibility. Reads the per-site 6plus2 beds directly, applies the hg38 blacklist, and bins to 250 kb itself. Publishes `newbulk_locus_HCG_methylation_minCT_10.pdf` and `newbulk_acc_250kb_GCH_quantileNorm.pdf`. | `sc_nomehic_cellline/single_cell_vs_bulk.ipynb` |
| `fig1_hic_comparison.ipynb` | Python 3.12.8, 6 code cells (3 with outputs). chr1 contact-matrix heatmap (bulk above the diagonal, pseudobulk below, IC-balanced at 1 Mb, 2400 dpi) plus the HiCRep SCC calculation. Reads juicer text dumps and builds temporary `.cool` files for balancing. Publishes `gm_heatmap_chr1_combined_main_dot.pdf`. | `sc_nomehic_cellline/snakemake/hic_comparison_gm_clean.ipynb` |

## Trimming

Both were copied unmodified, then reduced to the cells leading to the published
panels. Retained cells keep their source **and outputs** byte-identical.

| Notebook | Cells | Removed |
|---|---|---|
| R | 12 → 4 | minimum-coverage sweep variants (`minCT_5_10_15_20`, `minCT_10_20_50_100`, and its quantile-normalized twin); bin- and locus-blacklist variants plus the two cells building `df_binBL` / `df_locusBL` |
| Python | 11 → 6 | the all-chromosome multi-page heatmap PDF, two empty cells, and the SCC method exploration (raw vs IC, the apples-to-apples re-clip, IC across resolutions) |

**Two source changes were made.** The dropped Python cell also
defined `BIN_HEATMAP = 1_000_000`, which the chr1 heatmap requires, so that line
was moved into the heatmap cell with a comment noting where it came from. And the
SCC computation was rewritten as one cell producing only the published
`SCC_raw_clip95` column, because the publication boxplot read `keep_c` from a
dropped exploration cell — the raw arm's calls are identical, so the values are
unchanged. Verified afterwards that every function and variable is still defined
before first use. The rewritten cell carries no stored output; the panels it feeds
keep theirs.

Removed cells remain in git history and in the original working directories.

## Two panels produced but not placed in Figure 1

- **`newbulk_acc_250kb_GCH.pdf`** — the un-normalized 250 kb accessibility panel.
  Its cell builds the `m` matrix that the published quantile-normalized panel
  requires (`stopifnot(exists("m"))`), so the cell cannot be dropped.
- **`gm_scc_raw_clip95_only_1Mb.pdf`** and **`gm_scc_rawclip_by_resolution.pdf`** —
  the SCC calculation, on raw contacts with a 95th-percentile clip. Kept because
  chr1 SCC is quoted from this notebook; the three-resolution panel is destined for
  **Supplementary Figure S1**, which will get its own notebook.

## A note on the heatmap filename

The notebook writes `gm_heatmap_chr1_combined_main_dot.pdf`, via an f-string on
`CHROM_MAIN`. A file named `gm_heatmap_chr1_combined_main.pdf` also exists in the
original working directory — written one minute earlier and **byte-identical**
(48,655 bytes). The cell was run, then edited to add the max-value annotation and
re-run under the `_dot` name. Both are the same panel; the notebook is left as it
ran.

## Not included

- **`hic_comparison_clean_min_gm.ipynb`** (2026-06-03) — the earlier version of the
  Hi-C comparison, superseded by `hic_comparison_gm_clean.ipynb` (2026-06-10, rerun
  after the bulk `.hic` was rebuilt without `-pbat`).
- **`pseudobulk_vs_bulk.ipynb`** — the older IMR90-era comparison; it predates the
  from-scratch bulk and contains no `newbulk` references.
- **`hic_comparison_gm_methods_comparison.ipynb`** — a methods side-by-side, not a
  figure panel.
- **Per-site conversion and standalone SCC scripts** — `14_persite_for_notebook.sh`,
  `_concat_{bulk,pbulk}_HCG.sh`, `scc_analysis.py`. The current notebooks do not
  need them: the R notebook reads the 6plus2 beds directly, and the Python notebook
  computes SCC internally.
