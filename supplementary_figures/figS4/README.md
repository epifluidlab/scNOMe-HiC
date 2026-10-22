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
  `.6plus2.bed.gz` files, column 7 (methy/cov), read via the sample tables that
  `02_qc/build_sample_tables.py` writes.

  **BisSNP-1.0.1** (`.cyt.filtered.sort.*`). Regenerated 2026-10-21: the panels had
  been built from the superseded BisSNP-0.90 (`.calmd.cytosine.filtered.sort.*`)
  tables dated 2026-05-17. 1.0.1 calls ~2.3x more sites per cell, but the
  distribution is caller-robust — both are ~98% bimodal at 0 and 1 because most
  sites are covered by one read. On a sampled cell the intermediate fraction roughly
  doubles (GCH 1.3% -> 2.5%, HCG 1.2% -> 2.2%) and the GCH mean moves 0.626 -> 0.637.

## Notes

- The distributions pool **per-cell** site ratios, not one ratio per site at pooled
  depth. The published figure is single-cell level; a pseudobulk variant exists in
  the working tree and is deliberately not used.
- `MAX_SITES_PER_CELL = 50_000` caps each cell's contribution, drawn from
  `np.random.default_rng(0)` so a top-to-bottom run reproduces the figure. Set it to
  `None` to pool every site.
- Human contigs are `chr*`, mouse contigs `mm10_chr*`, so every read is assignable.
  Points off the axes are collisions — two nuclei in one well.
