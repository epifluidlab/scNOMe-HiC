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
| `barnyard_mixing/` | GM_F123 human/mouse species mixing, 96 cells on a combined hg38+mm10 reference — alignment and QC only, behind Fig. S4 — **migrated** | `../../scnomehic_paper/s3/snakemake/` |
| `bulk_scNOMeHiC/` | bulk NOMe-HiC GM12878, 3 reps from SRA — the bulk arm of the Fig. 1 comparison — **migrated** | `../../sc_nomehic_cellline/bulk_gm_from_scratch/` |
| `bulk_others/` | ENCODE bulk GM12878/IMR90 + metilene DMR calling — the Fig. 2 ground truth — **migrated** | `../../scnomehic_paper/fig2/codes/` |
| `published_singlecell/` | published GM12878 single-cell datasets reprocessed to hg38 pseudobulk — Drop-BS scWGBS, sci-MET, snATAC/DNase, sci-Hi-C — the Fig. S2 comparison — **migrated** | `../../scnomehic_paper/s2_new/` |
| `benchmark/` | six published single-cell methods reprocessed the same way — Droplet Hi-C, scNOMe-seq, scWGBS, snmC-seq2, snm3C-seq, snmCAT-seq — the Fig. 1 / S1 comparison — **migrated** | `snomehic_benchmark` @ `236719d` |

Each dataset folder documents, in its own `README.md`, the order the steps run in
and what each step consumes and produces.

## The Snakemake pipeline is a separate repository

The per-cell workflow (demux → trim → align → methylation calling → binning →
contact matrices) is shared across datasets and is **not duplicated here**:

<https://github.com/epifluidlab/sc_NOMeHiC_pipeline> — commit `a0456b9`

Each dataset folder carries only the config that parameterizes it plus the bash
scripts that invoke it.

## Configs are templates

Each dataset's `00_config/*.template.yaml` carries `${DATA_ROOT}`,
`${REFERENCE_ROOT}`, `${SOFTWARE_ROOT}` and `${WORK_ROOT}` where absolute paths
used to be. `render_config.sh` substitutes the values from `../paths.yaml` and
writes the result to `${WORK_ROOT}/<dataset>/config/`; the `01_pipeline/` drivers
call it for you. Edit `../paths.yaml`, never a template.

## Where the 250 kb Hi-C embedding comes from

The three UMAP notebooks (Figures 2, 3 and 4) each read a Hi-C embedding:

```
work/<dataset>/06.hiccluster_snakemake/hicluster_250kb_embed_dir/
    all_merged.pad1_std1_rp0.5_sqrtvc.svd20.hdf5
```

Nothing in this repository builds that file directly. It is produced by the
workflow's `rules/hiccluster.smk`, which each dataset's
`01_pipeline/02_hicluster.sh` triggers through the `hicluster_selected` target,
over the cells listed in the config's `selected_cells_file`. The chain is

| scHiCluster step | writes |
|---|---|
| `generatematrix-cell` | `06.hiccluster_snakemake/.../raw/` per-cell sparse matrices |
| `impute-cell` | per-cell `*_pad1_std1_rp0.5_sqrtvc.hdf5` |
| `embed-concatcell-chr` | `..._embed_dir/pad1_std1_rp0.5_sqrtvc_chr<N>.svd50.npy` |
| `embed-mergechr` | `..._embed_dir/all_merged.pad1_std1_rp0.5_sqrtvc.svd20.hdf5` |

`impute-cell`, `embed-concatcell-chr` and `embed-mergechr` are invoked **without**
`--pad`, `--std`, `--rp`, `--dist` or `--dim`: the `pad1_std1_rp0.5_sqrtvc`,
`svd50` and `svd20` in the filenames are scHiCluster's own defaults, not flags the
pipeline passes. Quote them as defaults, not as settings, when writing this up.

Run order per dataset: `01_run_pipeline.sh` -> `02_qc/` (writes
`selected_cells_file`) -> `02_hicluster.sh` -> the figure notebooks.

> **Version caveat.** The workflow's `envs/schicluster_test.yaml` installs
> scHiCluster from `git+https://github.com/zhoujt1994/scHiCluster.git` with no
> pin, so the version you get depends on when the environment was built. The one
> used here reports `1.3.5.dev17+gda98594`. Pin it if you need an exact
> reproduction.
