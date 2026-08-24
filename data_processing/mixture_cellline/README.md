# GM12878 / IMR90 mixture — single-cell NOMe-HiC processing

A defined two-cell-line mixture used as a ground-truth benchmark. **639 cells → 441
pass QC** (281 GM12878, 160 IMR90). Figure panels are in `../../main_figures/fig2/`.

Pipeline: <https://github.com/epifluidlab/sc_NOMeHiC_pipeline>, commit `a0456b9`.
Running from scratch: [../../RUNNING.md](../../RUNNING.md). This dataset ran from
`start_from: trimmed`.

## Run order

| Step | What it is |
|---|---|
| `00_config/config.yaml` | Snakemake config. `trimmed_data` points at a scratch path since purged; `cisnum_max_threshold: 3000000`. |
| `01_pipeline/01_run_pipeline.sh` | Align → bamprocess → QC → Bis-SNP → per-bin methylation, 639 cells. |
| `01_pipeline/02_hicluster.sh` | `hicluster_selected` → the 250 kb Hi-C embedding (`hicluster_250kb_embed_dir/…svd20.hdf5`). |
| `02_qc/qc_plots.ipynb` | QC gate. Writes `QC/cellline_passed.txt` (441 cells). |
| `02_qc/build_methylation_matrices.{sh,py}` | Cells × bins matrices from the per-cell `*_methylation.txt.gz`, one per (context, bin size). |
| `03_pseudobulk/01_build_sc_pseudobulk_gch_250kb.{sh,py}` | Read-weighted GpC pseudobulk, Σmeth/Σtotal over 250 kb bins, per cell type. |
| `03_pseudobulk/02_build_sc_pseudobulk_metilene_dmr.{sh,py}` | The same pooling over the metilene DMRs from `../bulk_others/03_differential/`, joined with the bulk WGBS means. |
| `04_hic_imputation/01_prep_inputs.sh` | Dot-convention symlinks and `cell_table.tsv` (the pipeline writes `batch1_sc1.ACTTGA`, hicluster expects `batch1.sc1.ACTTGA`). |
| `04_hic_imputation/02_generate_impute.sbatch` | `generatematrix-cell` + `impute-cell` per cell per chromosome at 25 kb. The heavy step. |
| `04_hic_imputation/03_loop_sumcell.sbatch` | Sums imputed matrices across each cell type. |
| `04_hic_imputation/04_loop_mergechr.sh` | Merges per-chromosome output. |
| `04_hic_imputation/05_make_celltype_cool.sh` → `make_celltype_cool.py` | Writes `per_celltype/{GM12878,IMR90}/*.{Q,E,T,Q2,E2,T2}.cool`. |

**`03_pseudobulk` and `04_hic_imputation` need the cell-type labels**
(`annotation/cell_type_table.tsv`), written by §9 of
`../../main_figures/fig2/fig2_umap.ipynb`. Real order:

```
pipeline → 02_qc → fig2_umap.ipynb (§9) → 03_pseudobulk / 04_hic_imputation → figure notebooks
```

## Outputs

| Product | Path |
|---|---|
| QC-passing cells (441 of 639) | `QC/cellline_passed.txt` |
| Cells × bins matrices | `QC/methylation_matrices/methylation_matrix_{GCH,HCG}_{50kb,100kb,250kb}.tsv.gz` |
| Hi-C 250 kb embedding | `06.hiccluster_snakemake/hicluster_250kb_embed_dir/…svd20.hdf5` |
| sc pseudobulk accessibility | `analysis/gch_acc_250kb/sc_pseudobulk_GCH_250kb.tsv.gz` |
| sc pseudobulk over DMRs | `analysis/dmr_metilene_hcg/sc_pseudobulk_metilene_dmr_top2000.tsv.gz` |
| Per-cell-type contact matrices | `per_celltype/{GM12878,IMR90}/*.{Q,E,T}.cool` |

## Notes

- `cisnum_max_threshold = 3000000` drops suspected doublets: a joint-UMAP QC overlay
  found a 20-cell outlier cluster at 5–10× normal cis-contact depth. All other
  thresholds match the other datasets.
- `qc_plots.ipynb` also contains a matrix-building cell. The **script**, not that
  cell, produced the matrices in use — they were regenerated with it after the June
  re-methylation rerun. `USE_QC_PASSED_ONLY = True` builds over the 441 passing
  cells; the original run used `False` (all 639), but the UMAP notebook intersects
  against the QC list before filtering bins, so the embedding is identical either way.
- `04_hic_imputation` is not a repeat of `02_hicluster.sh`. That runs scHiCluster at
  100/250 kb with `pad 1` and no distance limit, for the SVD embedding; this runs at
  **25 kb** with `pad 2` and `output_dist` 10.05 Mb, for per-cell-type Q/E/T coolers.
  They share only their per-cell `hic_matrix.txt.gz` input.
  `generatematrix-cell` is re-run because the pipeline produces raw matrices only at
  100/250 kb.
- `04_hic_imputation` outputs land on scratch to save GPFS quota; the APA notebook
  keeps its own copy.
- Scripts keep the absolute paths they ran with. Original working directory:
  `sc_nomehic_cellline/snakemake`.
