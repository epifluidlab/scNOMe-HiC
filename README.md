# scNOMeHiC

Code accompanying the scNOMeHiC manuscript — single-cell joint profiling of
chromatin accessibility (GpC), DNA methylation (CpG) and 3D genome contacts
(Hi-C) from the same cell.

<!-- FILL: paper title, author list, journal, DOI once available -->
<!-- FILL: GEO / SRA accession for the raw sequencing data -->

## What is in this repository

This is a **code-only** repository. No sequencing data, alignment files, or
intermediate matrices are tracked here — see [Data availability](#data-availability)
for where those live. Every script keeps the paths it was run with, so treat
absolute paths in the code as a record of the original run rather than something
that will resolve on another machine.

```
env/                      Conda / R environment definitions
data_processing/          Per-dataset processing: raw reads -> analysis-ready matrices
  mouse_cortex/             mouse cortex scNOMe-HiC
  gm12878_cellline/         GM12878 cell line
  mixture_cellline/         GM12878 / IMR90 mixture (species- or genotype-mixing QC)
  meningioma/               primary meningioma samples
  bulk_scNOMeHiC/           bulk scNOMe-HiC libraries
  bulk_others/              published bulk datasets used for comparison
main_figures/             One folder per main-text figure
  fig1/ fig2/ ...
supplementary_figures/    One folder per supplementary figure
  figS1/ ... figS7/
```

Each folder carries its own `README.md` (what the analysis does, how to run it)
and `FILES.md` (what every individual file in that folder is).

## The processing pipeline

The scNOMe-HiC Snakemake workflow is a standalone tool, released and described
separately, and is **not duplicated in this repository**:

<https://github.com/epifluidlab/sc_NOMeHiC_pipeline> — commit `a0456b9`

It takes raw FASTQ through demultiplexing, trimming, alignment (Bhmem),
BAM processing, QC, methylation calling (Bis-SNP) and per-bin methylation tables.
What lives here instead is, per dataset, the config that parameterizes it plus the
shell scripts that invoke it — so `data_processing/<dataset>/` records exactly how
the tool was run, and the tool itself records how each step works.

One exception: the bulk NOMe-HiC sample under `data_processing/bulk_scNOMeHiC/`
carries its own alignment and methylation-calling scripts, because that library's
protocol required aligning **without** `-pbat`, which the shared pipeline's
`rule mapping` hardcodes. See that folder's README.

## Running it

**See [RUNNING.md](RUNNING.md)** for prerequisites, the config keys you must change,
and the two entry points: raw multiplexed FASTQ (default, demultiplexes for you) or
GEO-downloaded reads (already demultiplexed).

## Layout conventions

- `data_processing/<dataset>/` holds everything that turns raw reads into the
  analysis-ready tables: pipeline config and drivers, QC, pseudobulk construction,
  and — where a dataset needed them — its own alignment and methylation-calling
  scripts. Steps are numbered in run order.
- `main_figures/figN/` and `supplementary_figures/figSN/` hold only the code that
  turns those analysis-ready tables into published panels.
- Where a figure folder needed exploratory or superseded code preserved for the
  record, it sits under that folder's `archive/` and is not part of the
  reproduction path.

## Data availability

<!-- FILL: GEO accession, processed-data location, any controlled-access notes -->

## Environment

See `env/` for the conda environment files and recorded R session info.

<!-- FILL: LICENSE, citation, contact -->
