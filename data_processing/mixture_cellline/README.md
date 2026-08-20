# GM12878 / IMR90 mixture — single-cell NOMe-HiC processing

A defined mixture of two cell lines, used as a **ground-truth benchmark**: the cell
types are known, so clustering can be scored against them and pseudobulk profiles
can be compared to matching bulk data.

**639 cells → 441 pass QC** (281 GM12878 + 160 IMR90 labelled).

This folder covers processing up to data generation. Figure panels are built in
`../../main_figures/fig2/`.

## The pipeline is a separate repository

Same shared workflow as the other datasets — see
<https://github.com/epifluidlab/sc_NOMeHiC_pipeline> (commit `a0456b9`) and the
note in `../README.md`.

**This dataset starts from `trimmed`, not `raw`.** `00_config/config.yaml` sets
`trimmed_data: /scratch/jmj7858/scnomehic/cellline_fastq`, so demultiplexing and
trimming happened before this chain. That scratch directory has since been purged,
and the raw→trimmed step is not recorded here.

## Config differences from the other datasets

| | this dataset | GM12878 |
|---|---|---|
| `start_from` | `trimmed` | `raw` |
| `cisnum_max_threshold` | **3,000,000** | not set |
| `transrate_threshold` | not set | 0.7 |

The `cisnum` upper bound drops suspected doublets: a joint-UMAP QC overlay found a
20-cell outlier cluster at 5–10× normal cis-contact depth, and `cisnum ≥ 3M` is a
clean depth signature for them. All other thresholds match the other datasets.

## Run order

### 01_pipeline

- **`01_run_pipeline.sh`** — Snakemake driver against the shared pipeline: align →
  bamprocess → QC → bistools (Bis-SNP) → per-bin methylation, for all 639 cells.
- **`02_hicluster_launch.sh`** — runs the `hicluster_selected` target, producing the
  250 kb Hi-C embedding (`hicluster_250kb_embed_dir/...svd20.hdf5`) that the UMAP
  notebook consumes. Unlike GM12878, this dataset does use the hiccluster branch —
  it is the one that needs clustering.

### 02_qc — QC gate **and** cell × bin matrices

- **`qc_plots.ipynb`** — the canonical QC. Applies the config thresholds (including
  the doublet cap) and writes `QC/cellline_passed.txt` (**441 cells**). Its later
  cells also build the cells × bins methylation matrices under
  `QC/methylation_matrices/`, at 50 kb / 100 kb / 250 kb plus gene body and TSS.
- **`rebuild_methylation_matrices.py`** — standalone equivalent of that
  matrix-building step, for rebuilding without opening the notebook. Reads the
  per-cell `08.methylation_snakemake/*_methylation.txt.gz`, pivots on bin id, and
  writes one matrix per (context, bin size).
  `USE_QC_PASSED_ONLY = True` so it builds over the 441 QC-passing cells, matching
  the notebook. (The UMAP notebook intersects against the QC list itself, so either
  setting yields the same embedding — but this keeps the two in step.)

`methylation_matrix_{HCG,GCH}_250kb.tsv.gz` are the direct UMAP inputs.

### 03_pseudobulk — pool cells per cell type

> **Ordering note.** Both scripts need cell-type labels
> (`annotation/cell_type_table.tsv`), which are produced by **§9 of the UMAP
> notebook** in `../../main_figures/fig2/fig2_umap.ipynb`. So the real order is
> pipeline → QC → UMAP notebook → these scripts → the heatmap notebooks.

- **`01_build_sc_pseudobulk_gch_250kb.{py,sh}`** — read-weighted GpC pseudobulk,
  Σmeth/Σtotal over 250 kb bins, per cell type → `sc_pseudobulk_GCH_250kb.tsv.gz`.
- **`02_build_sc_pseudobulk_metilene_dmr.{py,sh}`** — the same pooling over the
  metilene DMRs called in `../bulk_others/03_differential/`, joined with the bulk
  WGBS means → `sc_pseudobulk_metilene_dmr_top2000.tsv.gz`.

Each `.sh` is a SLURM wrapper that `cd`s to the analysis workdir and calls its `.py`.

## Outputs

| Product | Path |
|---|---|
| QC-passing cells (441 of 639) | `QC/cellline_passed.txt` |
| Cells × bins matrices | `QC/methylation_matrices/methylation_matrix_{GCH,HCG}_{50kb,100kb,250kb}.tsv.gz` |
| Hi-C 250 kb embedding | `06.hiccluster_snakemake/hicluster_250kb_embed_dir/...svd20.hdf5` |
| sc pseudobulk accessibility | `analysis/gch_acc_250kb/sc_pseudobulk_GCH_250kb.tsv.gz` |
| sc pseudobulk over DMRs | `analysis/dmr_metilene_hcg/sc_pseudobulk_metilene_dmr_top2000.tsv.gz` |

## Notes on paths

Scripts keep the absolute paths they ran with. Original working directory:
`/gpfs/projects/b1198/epifluidlab/yoshii/sc_nomehic_cellline/snakemake`.
