# Figure 2 — cell-type mixture vs ground truth

A defined GM12878 / IMR90 mixture (441 cells passing QC), showing that single-cell
NOMe-HiC recovers the two cell types and that their pseudobulk profiles match
matching bulk data.

## Panels

| File | Made by |
|---|---|
| UMAPs (HCG, GCH, Hi-C, joint) | `fig2_umap.ipynb` |
| `fig2_gch250kb_pseudobulk_2row_heatmap.pdf`, `fig2_gch250kb_2row_colorbars.pdf` | `fig2_accessibility.ipynb` |
| `metilene_dmr_pseudobulk_heatmap.pdf`, `metilene_dmr_colorbar.pdf` | `fig2_methylation.ipynb` |
| `APA_2xN_insitu_diffloops.pdf` | `fig2_apa.ipynb` |
| `modality_leiden_agreement_heatmap.pdf` | `fig2_umap.ipynb` (§10b) |

## Files

| File | What it is |
|---|---|
| `fig2_umap.ipynb` | R (`scnomehic` env, kernel `ir`). SVD → Harmony → Leiden → UMAP for HCG, GCH, Hi-C and the joint embedding; §9 calls the cell types and writes the label table; §10 scores inter-modality agreement. |
| `fig2_accessibility.ipynb` | R (`scnomehic_diff`). Single-cell GpC pseudobulk vs bulk ATAC over 250 kb bins → two-row heatmap and colorbars. |
| `fig2_methylation.ipynb` | R (`scnomehic_diff`). Metilene de-novo DMRs → single-cell pseudobulk → heatmap and colorbar. |
| `fig2_apa.ipynb` | Python (`hic_cooler`). ANOVA over the per-cell-type imputed matrices → differential loops → APA pile-up. |

## Run order

`fig2_umap.ipynb` runs first: its §9 writes `annotation/cell_type_table.tsv` and
`metadata_with_cell_type.txt`, which the pseudobulk builders and the Hi-C imputation
read.

```
pipeline → 02_qc → fig2_umap.ipynb (§9 labels)
                     ├─ 03_pseudobulk    → fig2_accessibility.ipynb, fig2_methylation.ipynb
                     └─ 04_hic_imputation → fig2_apa.ipynb
```

## Inputs

From `../../data_processing/mixture_cellline/` and `../../data_processing/bulk_others/`:

| Input | Produced by |
|---|---|
| `methylation_matrix_{HCG,GCH}_250kb.tsv.gz` | `mixture_cellline/02_qc/` |
| `hicluster_250kb_embed_dir/…svd20.hdf5` | `mixture_cellline/01_pipeline/02_hicluster.sh` |
| `QC/cellline_passed.txt`, `cellline_qc_summary.txt` | `mixture_cellline/02_qc/qc_plots.ipynb` |
| `bulk_methylation_{GM12878,IMR90}.txt.gz` | `bulk_others/02_process/03_build_bulk_methylation_bins.py` |
| `sc_pseudobulk_GCH_250kb.tsv.gz`, `bulk_atac_250kb.tsv` | `mixture_cellline/03_pseudobulk/`, `bulk_others/02_process/` |
| `sc_pseudobulk_metilene_dmr_top2000.tsv.gz` | `mixture_cellline/03_pseudobulk/02_metilene_dmr` |
| `per_celltype/*.{Q,T,E}.cool` | `mixture_cellline/04_hic_imputation/` |

## Reported statistics

| Panel | Statistic |
|---|---|
| Methylation | 3,890 DMRs at coverage ≥ 20 in both types; 3,804 direction-consistent (97.8%); r(sc Δ, bulk Δ) = 0.941 |
| Accessibility | Spearman ρ = 0.767 on the differential, over the top 1,000 bins shown |

§10 reports inter-modality Leiden agreement with no bulk reference, and §10b
draws `modality_leiden_agreement_heatmap.pdf` from it:

| pair | % agree | ARI | NMI | kNN purity |
|---|---|---|---|---|
| HCG ↔ Hi-C | 95.7 | 0.833 | 0.745 | 0.933 |
| HCG ↔ GCH | 92.3 | 0.714 | 0.600 | 0.898 |
| Hi-C ↔ GCH | 89.3 | 0.616 | 0.509 | 0.854 |

## Notes

- The methylation panel keeps only DMRs where the single-cell and bulk deltas agree
  in sign. This does not change the selection: the 86 inconsistent DMRs have
  |sc Δβ| ≤ 0.257, against selection cutoffs of 0.681 and 0.724.
- The accessibility ρ is printed by the cell adjacent to the panel, which applies the
  identical bin selection.
- §10 sits after §9 because it reads `metadata_with_cell_type.txt`, which §9 writes.
