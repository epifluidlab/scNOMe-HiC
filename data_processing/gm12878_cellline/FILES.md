# FILES — data_processing/gm12878_cellline

15 files. See `README.md` for the run order and the input/output of each step.
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
| `make_qc_notebook.py` | Generator that writes `qc_plots.ipynb`. Edit this and re-run, rather than editing the notebook by hand. | `$GM/` |
| `qc_plots.ipynb` | Per-cell QC metrics, threshold filtering, and summary plots. Produces `QC/cellline_passed.txt` (180 of 188 cells) and the `figures/cellline_*` PDFs. Outputs preserved. | `$GM/` |
| `make_qc_excel.py` | Builds `QC/cellline_qc_table.xlsx` (3 sheets, human-readable headers) and the snake_case `.tsv`. Bisulfite conversion is reported as non-CpG methylation % (ACT trinucleotide rate). Needs pandas + openpyxl. | `$GM/` |

## 03_pseudobulk_methylation

Run in the order listed. All gated on `QC/cellline_passed.txt`.

| File | What it is | Origin |
|---|---|---|
| `merge_calmd_passed.sh` | Merges the 180 QC-passing `{prefix}.calmd.bam` into `merged.sorted.bam`, coordinate-sorted and indexed. Logs any missing BAMs. | `$GM/` |
| `call_methylation_array.sh` | SLURM array (`1-23`, one chromosome per task). Runs `bissnp_nomehic_usage.pl` on the pooled BAM — the same caller as the pipeline's `bistools` rule — re-genotyping SNPs at pooled depth. Skips chromosomes already complete. | `$GM/pseudobulk_methylation/` |
| `merge_methylation.sh` | Concatenates the 23 per-chromosome BEDs into genome-wide `{GCH,HCG}.6plus2.bed.gz`, then bins to 1/50/100/250 kb via the pipeline's `calcmethylation.py`. | `$GM/pseudobulk_methylation/` |
| `make_bedgraph_bigwig.sh` | Per-site BEDs → 4-column bedGraph (col 7 = methylation %) → bigWig. Collapses exact-duplicate coordinates by averaging so `bedGraphToBigWig` accepts the input. | `$GM/pseudobulk_methylation/` |

## 04_single_cell_matrices

| File | What it is | Origin |
|---|---|---|
| `make_table.sh` | Scans `07.bistools_snakemake/methylation/` and writes the two-column `sample_table_hcg.tsv` (cell, path). Edit the context and `OUT` to produce `sample_table_gch.tsv`, which `collapse.sh` also needs. | `$GM/` |
| `collapse.sh` | Five `methylation_collapse.py` invocations producing `GCH_{250kb,gene,1kb}.txt` and `HCG_{250kb,gene}.txt`. | `$GM/` |
| `methylation_collapse.py` | Collapses per-cell 6plus2 BEDs into cell × bin matrices over a supplied bin BED. | `$GM/` |
| `collapse.ipynb` | Interactive inspection of the collapsed matrices. Outputs preserved. | `$GM/` |

## Deliberately not included

- **The Snakemake workflow itself** — lives at
  `github.com/epifluidlab/sc_NOMeHiC_pipeline`, commit `a0456b9`. Pinned in
  `README.md` rather than duplicated.
- **`hic_comparison/scripts/`** (10 files: pseudobulk-vs-bulk `.hic` builds, SCC
  analysis) and **`ctcf_cgi_profiles/`** (7 files: CTCF/CGI deepTools profiles) —
  these generate figure panels, so they belong under `main_figures/` or
  `supplementary_figures/`.
- Recovery, validation and superseded-parameter scripts from the original working
  directory. They record operational history, not the method.
