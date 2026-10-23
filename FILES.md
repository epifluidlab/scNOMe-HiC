# scNOMeHiC_code — top-level file index

| Path | What it is |
|---|---|
| `README.md` | Repository overview, paper metadata, setup, layout conventions, data availability. |
| `CITATION.cff` | Machine-readable citation. Journal reference and DOI added on acceptance. |
| `LICENSE` | MIT, matching the Liu lab's `bisulfiteHic`. Covers the code here only — not the data, references, or external tools. |
| `paths.yaml` | Where data, references, tools and outputs live. The one file a user edits. Relative values resolve against the repository root; `paths.local.yaml` (ignored) overrides it, and `$SCNOMEHIC_PATHS` overrides both. |
| `paths.sh`, `paths.py`, `paths.R` | Three-line loaders that read `paths.yaml` and expose `DATA_ROOT` / `DATA`, `REFERENCE`, `SOFTWARE`, `WORK`, `TMP`, `CONDA_SH`. One per language used in this repo; all three read the same file and agree. |
| `data/` | Placeholder tree for the sequencing reads the user downloads from GEO. Structure and READMEs tracked, contents ignored. |
| `reference/` | Placeholder tree for genomes, dbSNP, restriction sites and genome bins. Same arrangement. |
| `software/` | Placeholder for the external tools the user installs. Same arrangement. |
| `work/` | Placeholder tree for everything the pipeline generates, one subtree per dataset plus `analysis/` and `tmp/`. Same arrangement. |
| `RUNNING.md` | How to run the pipeline from scratch: prerequisites, machine-specific config keys, and the raw-FASTQ vs GEO entry points. |
| `FILES.md` | This file. Index of top-level entries. Each subfolder keeps its own `FILES.md`. |
| `.gitignore` | Auto-generated junk (`__pycache__`, `.ipynb_checkpoints`, …), the internal session notes, `paths.local.yaml`, and the contents of `data/`, `reference/`, `software/` and `work/` — those four keep their folder structure and READMEs tracked and nothing else. Code is copied in deliberately, so no code is filtered. |
| `supplemental table.xlsx` | Supplementary Tables 1-5: per-cell QC for each dataset plus the benchmark dataset descriptions. Built from the per-dataset `02_qc/qc_plots.ipynb` outputs. `QC pass` marks the cells each dataset's figures actually use, so for mouse cortex and meningioma it also applies the downstream Hi-C-usability check on top of the config thresholds (cortex 1,580 -> 1,577; meningioma 294 -> 292). |
| `env/` | Conda environment files for all five environments (`*.yml`, plus pip and R package lists), and `env/README.md` mapping every notebook to the environment it needs. |
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

The per-cell Snakemake workflow (`epifluidlab/sc_NOMeHiC_pipeline` @ `a0456b9`)
is referenced rather than duplicated. The cross-method benchmark
(`yoshihiko1218/snomehic_benchmark` @ `236719d`) is carried, code only, in
`data_processing/benchmark/`.

Remote: <https://github.com/yoshihiko1218/scNOMe-HiC> (`origin`, branch `main`).

**Outstanding before this repository can be made public:**

- Three `<!-- FILL -->` markers in `README.md`: the journal and DOI (on acceptance),
  the SRA accession, and the controlled-access repository for the meningioma raw
  reads. The GEO accession (GSE346089) is filled in.
- Code for **Figures 5 and 6** (contact-linked epigenetic concordance;
  allele-resolved X inactivation), which is not in this repository.
