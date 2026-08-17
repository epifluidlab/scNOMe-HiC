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

## Layout conventions

- `data_processing/<dataset>/` holds everything that turns raw reads into the
  analysis-ready tables: Snakemake workflows, alignment and methylation-calling
  scripts, QC, normalization, and matrix construction.
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
