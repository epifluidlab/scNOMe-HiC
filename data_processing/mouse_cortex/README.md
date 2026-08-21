# Mouse cortex — single-cell NOMe-HiC processing

Mouse cortex scNOMe-HiC, **1,577 cells**, clustered at 250 kb. The dataset behind
Figure 3: de novo cell-type annotation, marker-gene heatmaps, and differential-loop
APA across ten cortical cell types.

This folder covers processing up to data generation. Figure panels are built in
`../../main_figures/fig3/`.

## The pipeline is a separate repository

Same shared workflow as the other datasets — see
<https://github.com/epifluidlab/sc_NOMeHiC_pipeline> and the note in `../README.md`.
To run from scratch, see **[../../RUNNING.md](../../RUNNING.md)**.

**This dataset starts from `trimmed`.** The libraries were sequenced in batches and
merged before the pipeline ran; those merge steps are deliberately out of scope,
because what a reader downloads from GEO is already merged and demultiplexed. Enter
at `demultiplexed` or `trimmed` accordingly.

## Run order

### 01_pipeline

- **`01_run_pipeline.sh`** — align → bamprocess → QC → Bis-SNP → per-bin methylation.
- **`02_hicluster.sh`** — the `hicluster_selected` target, at **100 kb and 250 kb**
  (`hicluster_resolutions` in the config). It runs only over the QC-passing cells in
  `selected_cells_file` (`QC/cortex_passed.txt`), which §7 of the QC notebook writes —
  so this runs **after** `02_qc`. Imputation and embedding are the expensive stage;
  restricting them to QC-passing cells is the point of the whitelist.

### 02_qc

- **`qc_plots.ipynb`** — QC gate and the cells × bins methylation matrices. Also
  writes `QC/cortex_passed.txt`, the whitelist `02_hicluster.sh` consumes.
- **`build_hcg_counts.R`** and **`build_gch_counts.R`** — per-cell **count** matrices
  (`mc` = methylated reads, `cov` = total reads) at three gene regions: TSS window,
  gene body, and the two combined. 21,800 genes × 1,577 cells each.

  These exist because the `methylation_matrix_*.tsv.gz` files store **fractions
  only**, which cannot support Σmc/Σcov pooling. Read-weighted pseudobulk avoids the
  low-coverage bias of averaging per-cell fractions and needs no kNN imputation — it
  is what the Figure 3 marker heatmaps are built on. `bin_id` order is identical
  across cells (md5-verified), so counts are column-stacked without re-alignment.

### 03_hic_loops — differential loops for the APA panel

Runs at **25 kb**, on all 1,577 cells, grouped by the final annotation. Per-cell
imputation is annotation-independent; only the loop and cooler steps depend on the
labels, so a relabelling repeats step 02 alone.

| Step | What it does |
|---|---|
| `01_impute_missing_25kb.sh` | SLURM array: `generatematrix-cell` → `impute-cell` → `loop-bkg-cell` for the cells lacking 25 kb output. |
| `02_call_loops.sh` → `make_celltype_cool.py` | SLURM array, one task per cell type: `loop-sumcell-chr` → `loop-mergechr` → per-type `.loop.bedpe`, plus the matching Q/T/E `.cool` files so the differential fold-changes are comparable. |
| `cell_table_all1577_25kb.tsv` | `cell_id ⇥ cell_type` for all 1,577 cells. Derived from `250kb_denovo/annotation/cell_type_table.tsv`, with the `batch<N>_` prefix stripped to match the imputation directory. Rebuild this if the labels change. |

`make_celltype_cool.py` here is **not** the same file as the one under
`../mixture_cellline/04_hic_imputation/` — the two versions differ, so each dataset
carries its own.

## Outputs

| Product | Path |
|---|---|
| QC-passing cell list | `QC/cortex_passed.txt` |
| Cells × bins matrices | `QC/methylation_matrices/methylation_matrix_{HCG,GCH}_{100kb,250kb}.tsv.gz` |
| Per-cell count matrices | `QC/methylation_matrices/{HCG,GCH}_{gene,gene_tss,gene_body}_counts.rds` |
| Hi-C embeddings | `06.hiccluster_snakemake/hicluster_{100kb,250kb}_embed_dir/` |
| Per-type loops and coolers | `<cell_type>.loop.bedpe`, `<cell_type>.{Q,T,E}.cool` |

## Notes on paths

Scripts keep the absolute paths they ran with. Original working directories:
`/gpfs/projects/b1198/epifluidlab/yoshii/sc_nomehic/snakemake` and
`/gpfs/projects/b1198/epifluidlab/yoshii/sc_nomehic/hic/loop_final`.
