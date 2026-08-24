# Supplementary Figure S4 — species mixing and per-site signal distributions

Two independent controls on the assay, from two different datasets.

| Panel | File | Made by |
|---|---|---|
| Barnyard scatter, human vs mouse reads | `barnyard_scatter_linear.pdf` | `figS4_barnyard.ipynb` |
| Accessibility (GCH) per-site distribution | `acc_distribution.pdf` | `figS4_distributions.ipynb` |
| CpG methylation (HCG) per-site distribution | `methy_distribution.pdf` | `figS4_distributions.ipynb` |

| Notebook | Kernel | Dataset |
|---|---|---|
| `figS4_barnyard.ipynb` | Python (`scnomehic_python`) | GM_F123 species mixing, 96 cells — `../../data_processing/barnyard_mixing/` |
| `figS4_distributions.ipynb` | Python (`scnomehic_python`) | GM12878, 188 single cells — `../../data_processing/gm12878_cellline/` |

The two notebooks are unrelated and can be run in either order.

## The barnyard panel

Human GM12878 and mouse F123 cells sequenced together and aligned to a combined
hg38 + mm10 reference. Human contigs are `chr*`, mouse contigs `mm10_chr*`, so
every read is assignable and each cell becomes a point: human reads on x, mouse
reads on y. Cells hugging the axes are clean; points in the middle are collisions
— two nuclei captured in one well.

The notebook also draws the log-log version, a human-fraction histogram, and a
provisional Human / Mouse / Mixed / LowDepth classification. The **linear** scatter
is the panel; the others are how the classification thresholds were read off.

Counts are high-quality reads — proper-pair, MAPQ ≥ 30, deduplicated primary —
which is what the upstream step writes alongside unfiltered `idxstats` totals.

## The distribution panels

Per-site methylation ratios pooled **at single-cell level**: for each of the 188
GM12878 cells, per-site methy/cov is read from column 7 of its `.6plus2.bed`, and
those per-cell ratios are pooled before the KDE. That ordering matters — pooling
per-cell ratios is not the same as computing one ratio per site at pooled depth.
A pseudobulk alternative exists in the working tree and is deliberately not used,
because the published figure is single-cell level.

`MAX_SITES_PER_CELL = 50_000` caps how many sites each cell contributes, so the
pooled array stays tractable (188 cells × up to ~6.3 M GCH sites otherwise). The
subsampling draws from `np.random.default_rng(0)`, so a top-to-bottom run
reproduces the same figure. Set it to `None` to pool every site.

The notebook's last cell draws a combined overlay of both modalities on one axes
(GCH green, HCG black). That is not an S4 panel but is kept — it is the direct
comparison the two separate panels are read against.

> An earlier version of this analysis used a **mixed GM12878 + IMR90** metadata
> table. It was switched to the single cell line on 2026-07-13; the panels here
> are GM12878 only.
