# Meningioma — single-cell NOMe-HiC processing, copy number and deconvolution

Human meningioma, hg38. Two patients across three sequencing batches, run together
under one workdir (prefixes are unique, so there is one config and one driver).

| Batch | Source | Cells |
|---|---|---|
| data_batch_1 | `MY_*` | 176 |
| data_batch_2 | `NU04113_*` (not p2) | 92 |
| data_batch_3 | `NU04113_scNOMe_HiC_p2_*` | 80 |
| **total** | | **348** |

| set | cells | written by |
|---|---|---|
| sequenced | 348 | — |
| methylation QC passed | 294 | `02_qc/qc_plots.ipynb` |
| **Hi-C usable** (the analysis set) | **292** | `03_hic/02_hic_usability_check.py` |

Figure panels are in `../../main_figures/fig4/`. Pipeline:
<https://github.com/epifluidlab/sc_NOMeHiC_pipeline>. Running from scratch:
[../../RUNNING.md](../../RUNNING.md). This dataset ran from `start_from: trimmed`.

## Run order

| Step | What it is |
|---|---|
| `00_config/config.yaml` | Snakemake config: hg38 paths, QC thresholds, methylation bins. `config_hic_all3.yaml` is layered on top for the hicluster step. |
| `01_pipeline/01_run_pipeline.sh` | `mapping → bamprocess → qc → bisqc → bistools → methylation`, 348 cells. |
| `02_qc/qc_plots.ipynb` | Per-cell metrics, threshold histograms, per-batch overlays. Writes `QC/meningioma_passed.txt` (294). 39 figures. |
| `02_qc/remove_controls.py` | Drops the 7 control / titration wells (blank, 10c, 100c, 1000c) from the passing list. |
| `02_qc/build_methylation_matrices_250kb.py` | GCH / HCG cell × bin matrices at 250 kb. |
| `03_hic/01_hic_matrices.sh` | Per-cell contact matrices (`scbam2hic` + `hicprocess`) for the QC-passed cells. |
| `03_hic/02_hic_usability_check.py` | Requires ≥ 1 cis contact > 2500 bp spanning two bins on **every** autosome. 294 → 292. Writes `QC/meningioma_passed_hicusable.txt`. |
| `03_hic/03_hicluster.sh` | `hicluster_selected` at 250 kb → `hicluster_250kb_embed_dir_all3/`. |
| `04_cna/01_build_cna_1M.sh` → `count_fragment.py` | Per-cell fragment counts in 1 Mb autosomal bins → `CNA.1M.txt`, the copy-number proxy. Raw and per-cell; normalisation and sub-clone calling happen in `fig4_cna.ipynb`. |
| `05_deconv/01_make_cell_lists.py` | Splits cells into tumour and non-tumour by `SPLIT` (default `cna_group`; group 1 = non-tumour). |
| `05_deconv/02_combine_bam.sh` | Merges each side's BAMs and runs `wgbstools bam2pat`. |
| `05_deconv/03_run_deconv.sh` | UXM against the Loyfer brain atlas → `deconv/output.csv`. |

QC thresholds (the set common to the cell-line and cortex projects):

```
fragnum > 100000      noncpg < 5        GCH > 1000000
HCG > 150000          cis1kbnum > 2000
```

## Outputs

| Product | Path |
|---|---|
| Per-cell alignment / methylation | `04.alignment_snakemake/`, `07.bistools_snakemake/`, `08.methylation_snakemake/` |
| QC-passing cells | `QC/meningioma_passed.txt` (294) |
| Hi-C usable cells | `QC/meningioma_passed_hicusable.txt` (292) |
| Cells × bins matrices | `QC/methylation_matrices/methylation_matrix_{GCH,HCG}_250kb.tsv.gz` |
| Hi-C embedding | `06.hiccluster_snakemake/hicluster_250kb_embed_dir_all3/` |
| Copy-number counts | `subset_clustering/250kb/CNA.1M.txt` |
| Deconvolution | `deconv/output.csv` |

## Notes

- `config.yaml` points at `trimmed_data: merged_trimmed`, a directory assembled in
  the original run by symlinking three separately-trimmed batch folders. That is
  storage bookkeeping, not method, so the script is not shipped. Starting from raw
  or demultiplexed reads (GEO data is demultiplexed) the pipeline does its own
  trimming — see `RUNNING.md`.
- The hicluster stage is not in the default run: it is gated on
  `selected_cells_file`, which does not exist until QC has run.
- `03_hic/02_hic_usability_check.py` must run after `01_hic_matrices.sh` — it reads
  the per-cell matrices that step produces.
- `05_deconv` needs the CNA groups from `fig4_cna.ipynb`. Changing `SPLIT` requires
  redoing `02_combine_bam.sh` and `03_run_deconv.sh` (~1 h).
- Scripts keep the absolute paths they ran with. Original working directory:
  `meningioma_scnomehic/snakemake`.
