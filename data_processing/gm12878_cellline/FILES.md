# FILES — data_processing/gm12878_cellline

5 files. See `README.md` for the run order and the input/output of each step.
Every file was copied unmodified from the original working directories; the
"Origin" column records where each came from.

`$GM` = `/gpfs/projects/b1198/epifluidlab/yoshii/sc_nomehic_cellline/gm_sc_new`
`$PIPE` = `/gpfs/projects/b1198/epifluidlab/yoshii/software/sc_NOMeHiC_pipeline`

## 00_config

| File | What it is | Origin |
|---|---|---|
| `config.main_run.yaml` | Snakemake config that drove the main pipeline run: workdir, references, tool paths, `start_from: raw`, adapter clipping, methylation bin sizes (1/50/100/250 kb), QC thresholds. Authoritative record of the run. | `$PIPE/configs/config.yaml` |
| `config.hicmatrix.yaml` | Smaller, earlier config used only by `gm_hicmatrix_driver.sh`. Omits `bissnp_jar` (injected on the command line) and points at `bisulfitehic` rather than `bisulfiteHic`. | `$GM/configs/config.yaml` |

## 01_pipeline

| File | What it is | Origin |
|---|---|---|
| `run_pipeline_gm_sc_new.sh` | SLURM driver (`sbatch`) for the full per-cell chain: demux → trim → align (Bhmem) → bamprocess → bisqc → bistools (Bis-SNP) → methylation. Runs Snakemake with the SLURM profile, which submits each rule as a child job. | `/gpfs/projects/b1042/.../scnomehic/codes/` — **scratch**, rescued here |
| `gm_hicmatrix_driver.sh` | Builds per-cell `hic_matrix.txt.gz` (rules `scbam2hic` + `hicprocess` only). `-n` for a dry run. | `$GM/` |

## 02_qc

| File | What it is | Origin |
|---|---|---|
| `qc_plots.ipynb` | Per-cell QC metrics, threshold filtering, and summary plots. Run top to bottom in Jupyter. Produces `QC/cellline_passed.txt` (180 of 188 cells) and the `figures/cellline_*` PDFs. Outputs preserved. | `$GM/` |

## Deliberately not included

- **The Snakemake workflow itself** — lives at
  `github.com/epifluidlab/sc_NOMeHiC_pipeline`, commit `a0456b9`. Pinned in
  `README.md` rather than duplicated.
- **`make_qc_notebook.py`** — the generator that wrote `qc_plots.ipynb`. Tooling for
  authoring the notebook, not part of the method; the notebook itself is what runs.
- **`make_qc_excel.py`** — formats the QC metrics into a spreadsheet for reading.
  Presentation only; the QC numbers it reads are already produced by the notebook.
- **`hic_comparison/scripts/`** (10 files: pseudobulk-vs-bulk `.hic` builds, SCC
  analysis) and **`ctcf_cgi_profiles/`** (7 files: CTCF/CGI deepTools profiles) —
  these generate figure panels, so they belong under `main_figures/` or
  `supplementary_figures/`.
- Recovery, validation and superseded-parameter scripts from the original working
  directory. They record operational history, not the method.

## Still to come

Downstream of the QC gate, pending review:

- **Pseudobulk methylation** — merge QC-passing BAMs, re-call with Bis-SNP at pooled
  depth by chromosome, merge and bin, then build bedGraph/bigWig tracks.
  (`merge_calmd_passed.sh`, `call_methylation_array.sh`, `merge_methylation.sh`,
  `make_bedgraph_bigwig.sh`)
- **Cell × bin matrices** — collapse per-cell 6plus2 BEDs into `{GCH,HCG}_{250kb,gene}`
  and `GCH_1kb` matrices. (`make_table.sh`, `collapse.sh`, `methylation_collapse.py`,
  `collapse.ipynb`)
