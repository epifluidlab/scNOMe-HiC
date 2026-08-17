# data_processing

Code that turns raw scNOMe-HiC sequencing into analysis-ready matrices, organized
by dataset. Nothing here is figure code — panels are built in `../main_figures/`
and `../supplementary_figures/` from the tables these pipelines emit.

| Folder | Dataset | Source working dir |
|---|---|---|
| `mouse_cortex/` | mouse cortex scNOMe-HiC | `../../sc_nomehic/` |
| `gm12878_cellline/` | GM12878 cell line, 188 cells / 180 pass QC, hg38 — **migrated** | `../../sc_nomehic_cellline/gm_sc_new/` |
| `mixture_cellline/` | GM12878 / IMR90 mixture | `../../sc_nomehic_cellline/` |
| `meningioma/` | primary meningioma | `../../meningioma_scnomehic/` |
| `bulk_scNOMeHiC/` | bulk NOMe-HiC GM12878, 3 reps from SRA — the bulk arm of the Fig. 1 comparison — **migrated** | `../../sc_nomehic_cellline/bulk_gm_from_scratch/` |
| `bulk_others/` | published bulk datasets for comparison | <!-- FILL --> |

Each dataset folder documents, in its own `README.md`, the order the steps run in
and what each step consumes and produces.

## The Snakemake pipeline is a separate repository

The per-cell workflow (demux → trim → align → methylation calling → binning →
contact matrices) is shared across datasets and is **not duplicated here**:

<https://github.com/epifluidlab/sc_NOMeHiC_pipeline> — commit `a0456b9`

Each dataset folder carries only the config that parameterizes it plus the bash
scripts that invoke it.
