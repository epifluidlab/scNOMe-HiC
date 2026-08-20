# Figure 2 — cell-type mixture vs ground truth

A defined GM12878 / IMR90 mixture, used to show that single-cell NOMe-HiC recovers
known cell types and that their pseudobulk profiles match matching bulk data.

Inputs come from `../../data_processing/mixture_cellline/` (single cells) and
`../../data_processing/bulk_others/` (ENCODE ground truth).

| Notebook | Kernel | Published panels |
|---|---|---|
| `fig2_umap.ipynb` | R (`scnomehic`) | UMAP |
| `fig2_accessibility.ipynb` | R (`scnomehic_diff`) | `fig2_gch250kb_pseudobulk_2row_heatmap.pdf`, `fig2_gch250kb_2row_colorbars.pdf` |
| `fig2_methylation.ipynb` | R (`scnomehic_diff`) | `metilene_dmr_pseudobulk_heatmap.pdf`, `metilene_dmr_colorbar.pdf` |

> **These three notebooks are copied whole and not yet trimmed** to the published
> panels — see [Planned trimming](#planned-trimming).

The APA panel (`APA_2xN_insitu_diffloops.pdf`) has not been migrated yet.

## Run order — the UMAP notebook comes first

`fig2_umap.ipynb` is not only a figure: **§9 writes the cell-type labels**
(`annotation/cell_type_table.tsv`, `metadata_with_cell_type.txt`; 281 GM12878 +
160 IMR90) that the pseudobulk builders in `mixture_cellline/03_pseudobulk/`
require. So:

```
pipeline → QC → fig2_umap.ipynb (§9 labels) → 03_pseudobulk → the two heatmap notebooks
```

That is a figure→processing dependency, and it is deliberate: the labels are derived
by clustering, so they cannot precede it.

## Inputs

**`fig2_umap.ipynb`** — SVD → Harmony batch correction → Leiden + UMAP, per modality
and joint.

| Input | Produced by |
|---|---|
| `methylation_matrix_{HCG,GCH}_250kb.tsv.gz` | `mixture_cellline/02_qc/` |
| `hicluster_250kb_embed_dir/...svd20.hdf5` | `mixture_cellline/01_pipeline/02_hicluster_launch.sh` |
| `QC/cellline_passed.txt`, `cellline_qc_summary.txt` | `mixture_cellline/02_qc/qc_plots.ipynb` |
| `bulk_methylation_{GM12878,IMR90}.txt.gz` | bulk reference, for §8 cell-type calling |

It intersects the matrices against the QC list itself, then filters bins on the
resulting 441-cell submatrix.

**`fig2_accessibility.ipynb`** — reads `sc_pseudobulk_GCH_250kb.tsv.gz` and
`bulk_atac_250kb.tsv`, keeps bins with ≥20 GCH reads per cell type, ranks by
z-scored bulk ATAC difference, and plots the top 1,000 as a two-row heatmap.

**`fig2_methylation.ipynb`** — reads `sc_pseudobulk_metilene_dmr_top2000.tsv.gz`,
keeps DMRs with ≥20 pooled reads per cell type, and plots the 400 most different
(200 per direction).

## Reported statistics

| Panel | Statistic |
|---|---|
| Methylation | 3,890 DMRs at coverage ≥20 in both types; **3,804 direction-consistent (97.8 %)**; **r(sc Δ, bulk Δ) = 0.941** |
| Accessibility | **Spearman ρ = 0.767** on the differential, over the same top-1,000 bins the heatmap shows |

The two are not directly comparable: 0.941 is a Pearson r on deltas across 3,890
DMRs; 0.767 is a Spearman ρ on deltas across 1,000 fixed 250 kb bins.

The methylation notebook prints its statistics in the same cell that draws the
panel. The accessibility panel does not — its ρ comes from the neighbouring cell
that applies the identical bin selection, which is why that cell is kept in the
planned trim.

## Planned trimming

Verified against the code, pending review:

| Notebook | Cells | Keep |
|---|---|---|
| `fig2_methylation.ipynb` | 17 → 3 | 0 (path constants), **13** (panel + statistics), **15** (colorbar) |
| `fig2_accessibility.ipynb` | 26 → ~4 | setup, **20** (ρ = 0.767), **22** (panel), **24** (colorbars; needs `lim`/`zl` from 22) |
| `fig2_umap.ipynb` | 32 → TBD | depends on which UMAP panel is final |

Cell 13 reads only its own input and loads its own libraries; cell 22 re-reads its
two inputs and re-derives the bin selection. Neither published path touches the
methylKit or DiffBind branches, which is why those were left out of processing.
