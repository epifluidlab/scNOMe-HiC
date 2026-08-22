# Meningioma — single-cell NOMe-HiC processing and copy number

Human meningioma, **hg38**. Two patients across three sequencing batches, run
through the pipeline together under one workdir.

| Batch | Source | Cells |
|---|---|---|
| data_batch_1 | `MY_*` | 176 |
| data_batch_2 | `NU04113_*` (not p2) | 92 |
| data_batch_3 | `NU04113_scNOMe_HiC_p2_*` | 80 |
| **total** | | **348** |

Prefixes are unique across batches, so the three trimmed-fastq sets can be
symlinked into one scan directory without collisions.

Cell counts narrow at two points, and the distinction matters downstream:

| set | cells | written by |
|---|---|---|
| sequenced | 348 | — |
| methylation QC passed | **294** | `02_qc/qc_plots.ipynb` |
| **Hi-C usable** (the analysis set) | **292** | `03_hic/02_hic_usability_check.py` |

## The pipeline is a separate repository

Alignment and methylation come from `github.com/epifluidlab/sc_NOMeHiC_pipeline`,
shared with the cell-line and cortex datasets and pinned in the root `README.md`.
Only the configs and drivers live here.

## Run order

### 00_config

`config.yaml` is self-contained: `start_from: trimmed`, `trimmed_data:
merged_trimmed`, hg38 reference paths, the QC thresholds, and the methylation
bins/regions. `config_hic_all3.yaml` is layered on top for the hicluster step.

The QC thresholds are the set **common to the cell-line and cortex projects**,
replacing an older per-batch meningioma config:

```
fragnum > 100000      noncpg < 5        GCH > 1000000
HCG > 150000          cis1kbnum > 2000
```

### 01_pipeline

| Step | What it does |
|---|---|
| `00_setup_merged_trimmed.sh` | Symlinks each batch's `*.R1_val_1.fq.gz` / `*.R2_val_2.fq.gz` into `merged_trimmed/` — 696 links for 348 cells. Run once; it is what lets the pipeline auto-discover all three batches as one set. |
| `01_run_pipeline.sh` | Snakemake driver: `mapping → bamprocess → qc → bisqc → bistools → methylation` for all 348 cells. |

The hicluster stage is deliberately **not** in the default run — it is gated on
`selected_cells_file`, which does not exist until QC has run.

### 02_qc

| Step | What it does |
|---|---|
| `qc_plots.ipynb` | Per-cell metric tables, threshold histograms, per-batch overlays; writes `QC/meningioma_passed.txt` (294) and the cell × bin methylation matrices. Outputs preserved — 39 figures. |
| `remove_controls.py` | Drops the 7 control / titration wells (blank, 10c, 100c, 1000c) from the passing list. They are never real single cells. |
| `build_methylation_matrices_250kb.py` | GCH / HCG cell × bin matrices at 250 kb — the input to the clustering. |

### 03_hic

| Step | What it does |
|---|---|
| `01_hic_matrices.sh` | Per-cell contact matrices (`scbam2hic` + `hicprocess`) for the QC-passed cells. Cell-set independent, so it is done once. |
| `02_hic_usability_check.py` | Drops cells whose Hi-C would crash hicluster — the gate is ≥ 1 cis contact with distance > 2500 bp whose ends fall in different bins, required on **every** autosome. **294 → 292.** Writes `QC/meningioma_passed_hicusable.txt`. |
| `03_hicluster.sh` | `hicluster_selected` over the usable cells at 250 kb → `06.hiccluster_snakemake/hicluster_250kb_embed_dir_all3/`. |

Step 2 is the reason the analysis set is 292 rather than 294, and it must run
after step 1 — the check reads the per-cell matrices that step 1 produces.

### 04_cna — copy number

| Step | What it does |
|---|---|
| `01_build_cna_1M.sh` → `count_fragment.py` | Per-cell fragment counts in **1 Mb** bins across the autosomes, from the alignment BEDs, for the QC-passed cells → `CNA.1M.txt`. This count table is the copy-number proxy. |

Fragment count per bin stands in for copy number: a cell with a gained region
yields proportionally more fragments there. The table is per-cell and raw —
normalisation, clustering into sub-clones, and the heatmap are done downstream,
where the CNA groups used by the clustering figures are assigned.

## Outputs

| Product | Path |
|---|---|
| Per-cell alignment / methylation | `04.alignment_snakemake/`, `07.bistools_snakemake/`, `08.methylation_snakemake/` |
| QC-passing cells | `QC/meningioma_passed.txt` (294) |
| Hi-C usable cells | `QC/meningioma_passed_hicusable.txt` (292) |
| Cells × bins matrices | `QC/methylation_matrices/methylation_matrix_{GCH,HCG}_250kb.tsv.gz` |
| Hi-C embedding | `06.hiccluster_snakemake/hicluster_250kb_embed_dir_all3/` |
| Copy-number counts | `subset_clustering/250kb/CNA.1M.txt` |

## Notes on paths

Scripts keep the absolute paths they ran with. Original working directory:
`/gpfs/projects/b1198/epifluidlab/yoshii/meningioma_scnomehic/snakemake`.
