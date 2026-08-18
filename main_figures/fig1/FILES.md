# FILES — main_figures/fig1

2 notebooks. See `README.md` for inputs, outputs, and which script produces each
input.

| File | What it is | Origin |
|---|---|---|
| `fig1_methylation_accessibility.ipynb` | R 4.4.2, 12 code cells (8 with outputs). Compares pseudobulk vs bulk NOMe-HiC for CpG methylation and GpC accessibility. Reads the per-site 6plus2 beds directly, applies the hg38 blacklist, sweeps minimum-coverage thresholds, and bins to 250 kb itself. Outputs preserved. | `sc_nomehic_cellline/single_cell_vs_bulk.ipynb` |
| `fig1_hic_comparison.ipynb` | Python 3.12.8, 11 code cells (7 with outputs). chr1 contact-matrix heatmap plus HiCRep SCC across four resolutions, raw and IC-balanced. Reads juicer text dumps and builds temporary `.cool` files for balancing. Outputs preserved. | `sc_nomehic_cellline/snakemake/hic_comparison_gm_clean.ipynb` |

Both were copied unmodified — no path rewriting, no cell edits, outputs intact.

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

## Known issue

The chr1 heatmap is rendered inline only — it has no `savefig` call, while all five
SCC panels do. If the heatmap should be exported as a PDF like the others, that
call needs adding.
