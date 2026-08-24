# scNOMeHiC_code — top-level file index

| Path | What it is |
|---|---|
| `README.md` | Repository overview, layout conventions, data availability. |
| `RUNNING.md` | How to run the pipeline from scratch: prerequisites, machine-specific config keys, and the raw-FASTQ vs GEO entry points. |
| `FILES.md` | This file. Index of top-level entries. Each subfolder keeps its own `FILES.md`. |
| `.gitignore` | Minimal — only auto-generated junk (`__pycache__`, `.ipynb_checkpoints`, …). Everything in this repo is copied in deliberately, so nothing else is filtered. |
| `env/` | Conda environment YAMLs, `requirements.txt`, recorded R `sessionInfo()`. |
| `data_processing/` | Per-dataset processing code: raw reads → analysis-ready matrices. |
| `main_figures/` | Code producing main-text figure panels, one folder per figure. |
| `supplementary_figures/` | Code producing supplementary figure panels, one folder per figure. |

## Status

Migrated section by section from the original working directories. Files are
**copied**, never moved — the originals are left untouched.

| Destination | Source working directory |
|---|---|
| `data_processing/mouse_cortex/` | `../sc_nomehic/` |
| `data_processing/gm12878_cellline/`, `mixture_cellline/`, `bulk_scNOMeHiC/` | `../sc_nomehic_cellline/` |
| `data_processing/meningioma/` | `../meningioma_scnomehic/` |
| `data_processing/barnyard_mixing/`, `bulk_others/`, `published_singlecell/` | `../scnomehic_paper/{s3,fig2,s2_new}/` |
| `main_figures/figN/` | `../scnomehic_paper/figN/` |
| `supplementary_figures/figSN/` | `../scnomehic_paper/sN/` — but the numbering was reshuffled; see that folder's `README.md` |

Two upstream repositories are referenced rather than duplicated: the per-cell
Snakemake workflow (`epifluidlab/sc_NOMeHiC_pipeline` @ `a0456b9`) and the
cross-method benchmark (`yoshihiko1218/snomehic_benchmark` @ `236719d`).

**Outstanding:** the paper metadata in `README.md` (`<!-- FILL -->` markers), a
LICENSE, and the git remote.
