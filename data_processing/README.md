# data_processing

Code that turns raw scNOMe-HiC sequencing into analysis-ready matrices, organized
by dataset. Nothing here is figure code — panels are built in `../main_figures/`
and `../supplementary_figures/` from the tables these pipelines emit.

| Folder | Dataset | Source working dir |
|---|---|---|
| `mouse_cortex/` | mouse cortex scNOMe-HiC, 1,577 cells at 250 kb — the Fig. 3 dataset, plus the rep1-vs-rep2 comparison behind Fig. S6 — **migrated** | `../../sc_nomehic/snakemake/`, `../../sc_nomehic/hic/loop_final/`, `../../sc_nomehic/snakemake/replicate_comparison/` |
| `gm12878_cellline/` | GM12878 cell line, 188 cells / 180 pass QC, hg38 — **migrated**, plus the sequencing-saturation chain behind Fig. S5 | `../../sc_nomehic_cellline/gm_sc_new/` |
| `mixture_cellline/` | GM12878 / IMR90 mixture, 639 cells / 441 pass QC — the Fig. 2 ground-truth benchmark — **migrated** | `../../sc_nomehic_cellline/snakemake/` |
| `meningioma/` | human meningioma scNOMe-HiC, 348 cells → 292 analysed, hg38, two patients over three batches — preprocessing plus the 1 Mb copy-number counts — **migrated** | `../../meningioma_scnomehic/snakemake/` |
| `bulk_scNOMeHiC/` | bulk NOMe-HiC GM12878, 3 reps from SRA — the bulk arm of the Fig. 1 comparison — **migrated** | `../../sc_nomehic_cellline/bulk_gm_from_scratch/` |
| `bulk_others/` | ENCODE bulk GM12878/IMR90 + metilene DMR calling — the Fig. 2 ground truth — **migrated** | `../../scnomehic_paper/fig2/codes/` |

Each dataset folder documents, in its own `README.md`, the order the steps run in
and what each step consumes and produces.

## The Snakemake pipeline is a separate repository

The per-cell workflow (demux → trim → align → methylation calling → binning →
contact matrices) is shared across datasets and is **not duplicated here**:

<https://github.com/epifluidlab/sc_NOMeHiC_pipeline> — commit `a0456b9`

Each dataset folder carries only the config that parameterizes it plus the bash
scripts that invoke it.
