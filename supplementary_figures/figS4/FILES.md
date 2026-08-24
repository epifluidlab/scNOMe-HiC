# FILES — figS4/

`$S3` = `/gpfs/projects/b1198/epifluidlab/yoshii/scnomehic_paper/s3`

| File | What it is | Origin |
|---|---|---|
| `README.md` | The three panels, both datasets, and the two method points behind them. | written for this repo |
| `FILES.md` | This file. | written for this repo |
| `figS4_barnyard.ipynb` | Python, 6 code cells, kernel `scnomehic_python`. Per-cell human vs mouse read counts → linear and log-log barnyard scatters, human-fraction histogram, and a provisional Human/Mouse/Mixed/LowDepth call. 4 figures, no errors. | `$S3/snakemake/species_barnyard.ipynb` |
| `figS4_distributions.ipynb` | Python, 8 code cells, kernel `scnomehic_python`. Pools per-cell per-site methylation ratios over 188 GM12878 cells and draws KDE distributions for GCH and HCG, plus a combined overlay. 3 figures, no errors. Executed for this repo — it arrived with only 1 of 8 cells run. | `$S3/s3.ipynb` |

Both notebooks are shipped whole. Only two cells lack output and neither produces
one: imports, and a defensive non-finite filter.

## Deliberately not included

- **`$S3/make_combined_figure.py`** — a script form of the distributions
  notebook's last cell, so the combined overlay can be redrawn without rerunning
  the pooling. The notebook is the method; this duplicates its final cell.
- **`$S3/snakemake/code/build_barnyard_nb.py`** — generator for the barnyard
  notebook.
- **`$S3/analysis/`, `$S3/s3_dualaxis_profiles.ipynb`, `plot_dualaxis.py`,
  `plotCGI_pseudobulk.sh`, `plotCTCF_pseudobulk.sh`, `split_cgi_figures.sh`,
  `make_readable_profiles.py`** — the CTCF/CGI dual-axis profile work that shares
  this folder. A different figure, migrated separately.
- **`$S3/acc_methy_distribution.{pdf,png}`** — the combined overlay output. Not
  an S4 panel; the notebook still draws it as the comparison the two separate
  panels are read against.

## A note on reproducibility

`figS4_distributions.ipynb` subsamples up to 50,000 sites per cell. That draw
comes from `np.random.default_rng(0)` and the generator is consumed in cell order,
so a **top-to-bottom** run reproduces the figure exactly. Running the pooling cell
twice in one session will not — the generator advances. Restart and run in order
if the figure needs to match.
