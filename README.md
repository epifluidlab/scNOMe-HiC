# scNOMeHiC

Code accompanying the scNOMeHiC manuscript — single-cell joint profiling of
chromatin accessibility (GpC), DNA methylation (CpG) and 3D genome contacts (Hi-C)
from the same cell.

<!-- FILL: paper title, author list, journal, DOI once available -->
<!-- FILL: GEO / SRA accession for the raw sequencing data -->

## Layout

```
env/                      Conda / R environment definitions
data_processing/          Per-dataset processing: raw reads -> analysis-ready matrices
  mouse_cortex/             mouse cortex scNOMe-HiC (Fig. 3, S6)
  gm12878_cellline/         GM12878 cell line (Fig. 1, S3, S5)
  mixture_cellline/         GM12878 / IMR90 mixture (Fig. 2)
  meningioma/               primary meningioma (Fig. 4, S8)
  barnyard_mixing/          human/mouse species mixing (S4)
  bulk_scNOMeHiC/           bulk NOMe-HiC GM12878 (Fig. 1)
  bulk_others/              published bulk datasets used as ground truth (Fig. 2)
main_figures/             fig1/ … fig4/
supplementary_figures/    figS1/ … figS8/
```

Each folder carries a `README.md` (what the analysis does, the run order) and a
`FILES.md` (what every file in that folder is).

This is a **code-only** repository — no sequencing data, alignments or intermediate
matrices are tracked. Scripts keep the absolute paths they ran with; treat those as
a record of the original run, not as paths that will resolve elsewhere.

## The processing pipeline

The per-cell Snakemake workflow (demux → trim → align → BAM processing → QC →
Bis-SNP methylation calling → per-bin tables → contact matrices) is a separate
tool and is **not duplicated here**:

<https://github.com/epifluidlab/sc_NOMeHiC_pipeline> — commit `a0456b9`

Each dataset folder carries the config that parameterises it plus the scripts that
invoke it. One exception: `data_processing/bulk_scNOMeHiC/` carries its own
alignment and methylation-calling scripts, because that library's protocol required
aligning **without** `-pbat`, which the shared pipeline hardcodes.

## Running it

See **[RUNNING.md](RUNNING.md)** for prerequisites, the config keys you must change,
and the two entry points: raw multiplexed FASTQ (default) or GEO-downloaded reads
(already demultiplexed).

## Data availability

<!-- FILL: GEO accession, processed-data location, any controlled-access notes -->

## Environment

See `env/` for the conda environment files and recorded R session info.

<!-- FILL: LICENSE, citation, contact -->
