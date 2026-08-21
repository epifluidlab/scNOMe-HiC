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

To run this from scratch on your own machine, see **[../../RUNNING.md](../../RUNNING.md)**.

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
  Identical to `../gm12878_cellline/01_pipeline/01_run_pipeline.sh` apart from its
  job name and config. `sbatch 01_run_pipeline.sh`, or `bash … -n` to dry-run.
- **`02_hicluster.sh`** — runs the `hicluster_selected` target, producing the
  250 kb Hi-C embedding (`hicluster_250kb_embed_dir/...svd20.hdf5`) that the UMAP
  notebook consumes. Unlike GM12878, this dataset does use the hiccluster branch —
  it is the one that needs clustering.

### 02_qc — QC gate **and** cell × bin matrices

Run in this order:

1. **`qc_plots.ipynb`** — the canonical QC. Applies the config thresholds (including
   the doublet cap) and writes `QC/cellline_passed.txt` (**441 cells**). It also
   contains a matrix-building cell, superseded by the script below.
2. **`build_methylation_matrices.sh`** → **`build_methylation_matrices.py`** —
   builds the cells × bins matrices the UMAP consumes. Reads the per-cell
   `08.methylation_snakemake/*_methylation.txt.gz`, pivots on bin id, and writes one
   matrix per (context, bin size) to `QC/methylation_matrices/`.

   ```bash
   sbatch build_methylation_matrices.sh          # 250 kb — what the UMAP needs
   ```

   **This script, not the notebook, is what produced the matrices in use.** After the
   June re-methylation rerun the matrices were regenerated with it; the notebook cell
   is the older copy of the same logic and was not re-run.

   `USE_QC_PASSED_ONLY = True` builds over the 441 QC-passing cells. The original run
   used `False` (all 639), but the UMAP notebook intersects against the QC list before
   filtering bins, so the embedding is identical either way.

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

### 04_hic_imputation — per-cell-type contact matrices for the APA panel

scHiCluster imputation of the per-cell Hi-C matrices, aggregated per cell type into
the Q/E/T `.cool` files the Figure 2 APA panel piles up. Like `03_pseudobulk`, this
needs the cell-type labels from §9 of the UMAP notebook.

**This is not a repeat of the pipeline's Hi-C step.** `01_pipeline/02_hicluster.sh`
also runs scHiCluster, but at a different scale and for a different purpose:

| | pipeline `hicluster_selected` | this step |
|---|---|---|
| resolution | 100 kb + 250 kb | **25 kb** |
| smoothing | `pad 1` | `pad 2` |
| distance limit | none | `output_dist` 10.05 Mb (loops are short-range) |
| aggregation | SVD embedding across cells | per-cell-type Q/E/T `.cool` |
| consumed by | `fig2_umap.ipynb` | `fig2_apa.ipynb` |

Clustering needs coarse genome-wide bins; APA needs fine bins over short distances.
The two share only their input — the same per-cell `hic_matrix.txt.gz` files.
`generatematrix-cell` is re-run here because the pipeline produces raw matrices only
at 100/250 kb, so there is nothing at 25 kb to reuse.

| Step | What it does |
|---|---|
| `01_prep_inputs.sh` | Builds the dot-convention symlinks and `cell_table.tsv`. The pipeline writes underscore IDs (`batch1_sc1.ACTTGA`) while hicluster expects dots (`batch1.sc1.ACTTGA`); this is where the two conventions are reconciled. |
| `02_generate_impute.sbatch` | `hicluster generatematrix-cell` + `impute-cell` per cell, per chromosome. The heavy step. |
| `03_loop_sumcell.sbatch` | Sums imputed matrices across the cells of each type. |
| `04_loop_mergechr.sh` | Merges per-chromosome output. |
| `05_make_celltype_cool.sh` → `make_celltype_cool.py` | Writes `per_celltype/{GM12878,IMR90}/*.{Q,E,T,Q2,E2,T2}.cool`. |

- *in*: `06.hiccluster_snakemake/{cell}.hic_matrix.txt.gz` (441 cells) + `cell_type_table.tsv`
- *out*: per-cell-type Q/E/T `.cool`, consumed by `../../main_figures/fig2/fig2_apa.ipynb`

Outputs land on scratch to save GPFS quota; the APA notebook keeps its own copy.

## Outputs

| Product | Path |
|---|---|
| QC-passing cells (441 of 639) | `QC/cellline_passed.txt` |
| Cells × bins matrices | `QC/methylation_matrices/methylation_matrix_{GCH,HCG}_{50kb,100kb,250kb}.tsv.gz` |
| Hi-C 250 kb embedding | `06.hiccluster_snakemake/hicluster_250kb_embed_dir/...svd20.hdf5` |
| sc pseudobulk accessibility | `analysis/gch_acc_250kb/sc_pseudobulk_GCH_250kb.tsv.gz` |
| sc pseudobulk over DMRs | `analysis/dmr_metilene_hcg/sc_pseudobulk_metilene_dmr_top2000.tsv.gz` |
| Per-cell-type contact matrices | `per_celltype/{GM12878,IMR90}/*.{Q,E,T}.cool` |

## Notes on paths

Scripts keep the absolute paths they ran with. Original working directory:
`/gpfs/projects/b1198/epifluidlab/yoshii/sc_nomehic_cellline/snakemake`.
