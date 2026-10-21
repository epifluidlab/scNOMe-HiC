# data/

Where downloaded reads and pipeline outputs live. **Empty in the repository** —
only the folder structure and these READMEs are tracked; everything else is
ignored by git.

One folder per dataset, matching `../data_processing/`:

| Folder | Dataset | Supplementary table |
|---|---|---|
| `gm12878_cellline/` | GM12878 cell line | Table 1 |
| `mixture_cellline/` | GM12878 / IMR90 mixture | Table 3 |
| `mouse_cortex/` | Mouse cortex | Table 4 |
| `meningioma/` | Meningioma | Table 5 |

## What to put where

GEO carries **per-cell** FASTQs, so demultiplexing is already done. Put each
dataset's reads in its own `01.demul_fastq_snakemake/` and name them:

```
{prefix}.{index}.R1.fastq.gz
{prefix}.{index}.R2.fastq.gz
```

`{prefix}` is the library, `{index}` the cell barcode — e.g.
`scNH_GM_4plex_1_S1.ATCACG.R1.fastq.gz`. Rename the GEO filenames to this pattern
if they differ; barcodes are derived from the filenames.

Then set `start_from: "demultiplexed"` in that dataset's
`../data_processing/<dataset>/00_config/`, point `demul_data` at the folder, and
run its `01_pipeline/01_run_pipeline.sh`. See `../RUNNING.md`, Entry point B.

The pipeline writes its numbered output folders (`03.trimmed_fastq_snakemake/`,
`04.alignment_snakemake/`, `07.bistools_snakemake/`, …) alongside
`01.demul_fastq_snakemake/` inside the same dataset folder.
