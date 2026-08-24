# Supplementary Figure S4 — species mixing and per-site signal distributions

Two independent assay controls, from two datasets.

## Panels

| File | Made by |
|---|---|
| `barnyard_scatter_linear.pdf` | `figS4_barnyard.ipynb` |
| `acc_distribution.pdf` | `figS4_distributions.ipynb` |
| `methy_distribution.pdf` | `figS4_distributions.ipynb` |

## Files

| File | What it is |
|---|---|
| `figS4_barnyard.ipynb` | Python (`scnomehic_python`), 6 code cells. GM12878 + F123 mixing, 96 cells on a combined hg38 + mm10 reference; one point per cell, human reads vs mouse reads. Also draws the log-log version, a human-fraction histogram, and the Human/Mouse/Mixed/LowDepth classification the thresholds were read off. |
| `figS4_distributions.ipynb` | Python (`scnomehic_python`), 8 code cells. KDE of per-site GCH and HCG ratios over the 188 GM12878 cells. The last cell overlays both modalities on one axes — not an S4 panel, kept as the direct comparison. |

The two notebooks are unrelated and run in either order.

## Inputs

- Barnyard: `../../data_processing/barnyard_mixing/` — per-cell human and mouse
  high-quality read counts (proper-pair, MAPQ ≥ 30, deduplicated primary).
- Distributions: `../../data_processing/gm12878_cellline/` — per-cell
  `.6plus2.bed` files, column 7 (methy/cov).

## Notes

- The distributions pool **per-cell** site ratios, not one ratio per site at pooled
  depth. The published figure is single-cell level; a pseudobulk variant exists in
  the working tree and is deliberately not used.
- `MAX_SITES_PER_CELL = 50_000` caps each cell's contribution, drawn from
  `np.random.default_rng(0)` so a top-to-bottom run reproduces the figure. Set it to
  `None` to pool every site.
- Human contigs are `chr*`, mouse contigs `mm10_chr*`, so every read is assignable.
  Points off the axes are collisions — two nuclei in one well.
