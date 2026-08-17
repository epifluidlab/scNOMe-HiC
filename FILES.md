# scNOMeHiC_code — top-level file index

| Path | What it is |
|---|---|
| `README.md` | Repository overview, layout conventions, data availability. |
| `FILES.md` | This file. Index of top-level entries. Each subfolder keeps its own `FILES.md`. |
| `.gitignore` | Allowlist-style ignore rules. Everything is ignored except known source extensions, so data files cannot be committed by accident. |
| `env/` | Conda environment YAMLs, `requirements.txt`, recorded R `sessionInfo()`. |
| `data_processing/` | Per-dataset processing code: raw reads → analysis-ready matrices. |
| `main_figures/` | Code producing main-text figure panels, one folder per figure. |
| `supplementary_figures/` | Code producing supplementary figure panels, one folder per figure. |

## Status

The skeleton is in place; content is being migrated in section by section from the
original working directories:

| Destination | Source working directory |
|---|---|
| `data_processing/mouse_cortex/` | `../sc_nomehic/` |
| `data_processing/gm12878_cellline/` | `../sc_nomehic_cellline/` |
| `data_processing/mixture_cellline/` | `../sc_nomehic_cellline/` |
| `data_processing/meningioma/` | `../meningioma_scnomehic/` |
| `main_figures/figN/` | `../scnomehic_paper/figN/` |
| `supplementary_figures/figSN/` | `../scnomehic_paper/sN/` |

Files are **copied**, never moved — the original working directories are left
untouched.
