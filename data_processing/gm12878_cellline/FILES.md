# FILES — data_processing/gm12878_cellline

17 files. See `README.md` for the run order and the input/output of each step.

`$S3`  = `/gpfs/projects/b1198/epifluidlab/yoshii/scnomehic_paper/s3`
`$CCP` = `$GM/ctcf_cgi_profiles`
`$S7` = `/gpfs/projects/b1198/epifluidlab/yoshii/scnomehic_paper/s7/code`
`$GM` = `/gpfs/projects/b1198/epifluidlab/yoshii/sc_nomehic_cellline/gm_sc_new`
`$PIPE` = `/gpfs/projects/b1198/epifluidlab/yoshii/software/sc_NOMeHiC_pipeline`

## 00_config

| File | What it is | Origin |
|---|---|---|
| `config.main_run.yaml` | The Snakemake config for this dataset: workdir, references, tool paths, `start_from: raw`, adapter clipping, methylation bin sizes (1/50/100/250 kb), QC thresholds. Record of the run, with one deliberate edit: `fragnum_threshold` raised 80,000 → 100,000 to match the other three datasets. Verified inert — the lowest `fragnum` among the 180 passing cells is 1,565,866, and no cell lies between the two cutoffs, so the passing set is unchanged. | `$PIPE/configs/config.yaml` |

## 01_pipeline

| File | What it is | Origin |
|---|---|---|
| `01_run_pipeline.sh` | SLURM driver (`sbatch`) for the full per-cell chain: demux → trim → align (Bhmem) → bamprocess → bisqc → bistools (Bis-SNP) → methylation. Identical to the mixture's driver apart from job name and config path. | rewritten from `/gpfs/projects/b1042/.../scnomehic/codes/run_pipeline_gm_sc_new.sh` (**scratch**, rescued) |

## 02_qc

| File | What it is | Origin |
|---|---|---|
| `qc_plots.ipynb` | Per-cell QC metrics, threshold filtering, and summary plots. Run top to bottom in Jupyter. Produces `QC/cellline_passed.txt` (180 of 188 cells) and the `figures/cellline_*` PDFs. GCH/HCG site counts come from the BisSNP-1.0.1 `.cyt.filtered.sort.` BEDs; WCG has no 1.0.1 output and is read from the BisSNP-0.90 path, for QC plots only. Outputs preserved. | `$GM/` |

## 03_pseudobulk

Pools the 180 QC-passing cells into a bulk-equivalent in three modalities — the
single-cell arm of the Figure 1 comparison. Run in the order listed.

| File | What it is | Origin |
|---|---|---|
| `01_merge_calmd_passed.sh` | Merges the 180 QC-passing `{prefix}.calmd.bam` into `merged.sorted.bam`, coordinate-sorted and indexed. Logs any missing BAMs. | `$GM/merge_calmd_passed.sh` |
| `02_call_methylation_array.sh` | SLURM array (`1-23`, one chromosome per task). Runs `bissnp_nomehic_usage.pl` on the pooled BAM — the same caller as the pipeline's `bistools` rule — re-genotyping SNPs at pooled depth. Skips chromosomes already complete. | `$GM/pseudobulk_methylation/` |
| `03_merge_methylation.sh` | Concatenates the 23 per-chromosome BEDs into genome-wide `{GCH,HCG}.6plus2.bed.gz` (**2 of the 3 modalities**), then bins to 1/50/100/250 kb via the pipeline's `calcmethylation.py`. | `$GM/pseudobulk_methylation/` |
| `04_build_pseudobulk_hic.sh` | Builds the pseudobulk contact map (**3rd modality**): per-cell `samtools view -q30 -f1 -F1804` → `sam2juicer_new.py` → 8-col short → sort → `juicer_tools pre -f DpnII`. The good-reads filter runs *before* sam2juicer, matching the bulk exactly so both arms exclude PCR duplicates. | `$GM/hic_comparison/scripts/build_pseudobulk_dedup_hic.sh` |
| `05_make_bedgraph_bigwig.sh` | Per-site BEDs → 4-column bedGraph (col 7 = methylation %) → bigWig tracks. Collapses exact-duplicate coordinates by averaging so `bedGraphToBigWig` accepts the input. | `$GM/pseudobulk_methylation/` |
| `04_saturation/00_config.sh` | Paths and parameters for the saturation chain. `CODE_DIR` now resolves to this folder, so the steps find each other wherever it is placed. | `$S7/config.sh` |
| `04_saturation/01_make_tasklist.sh` | Writes `tasks.tsv`: one `CELL⇥FRACTION` line per array task (180 cells × 6 fractions). | `$S7/make_tasklist.sh` |
| `04_saturation/02_run_one.sh` | One (cell, fraction): subsample the **pre-dedup** BAM → markdup → contact summary → Bis-SNP → one result row. Idempotent, cleans its own scratch. | `$S7/run_one.sh` |
| `04_saturation/03_submit_array.sbatch` | SLURM array wrapper for step 2. | `$S7/submit_array.sbatch` |
| `04_saturation/04_extract_full_depth.sh` | The f = 1.0 point taken from existing full-depth pipeline outputs rather than recomputed. | `$S7/extract_full_depth.sh` |
| `04_saturation/05_collect_results.sh` | Concatenates every per-task row into `saturation_results.tsv`. | `$S7/collect_results.sh` |
| `05_profiles/01_setup_regions.sh` | Stages the region BEDs used by `computeMatrix`: GM12878 CTCF peaks (TSS-excluded), an oriented CTCF motif set, and gencode v45 CGI / non-CGI TSS. | `$CCP/scripts/02_setup_regions.sh` |
| `05_profiles/02_plot_ctcf.sh` | CTCF metaprofile: GCH and HCG in one `computeMatrix`, then `plotProfile` / `plotHeatmap`. | `$S3/plotCTCF_pseudobulk.sh` |
| `05_profiles/03_plot_cgi.sh` | The same at TSS with both region sets in one matrix. Its heatmap is a Fig. S3 panel. | `$S3/plotCGI_pseudobulk.sh` |
| `06_benchmark_qc/extract_GCH_HCG_counts.py` | Per-cell counts of detected GCH and HCG loci from the per-cell methylation BEDs. | `$S1Q/extract_GCH_HCG_counts.py` |
| `06_benchmark_qc/01_extract_gch_hcg_counts.sh` | Runs the above; one line per dataset in the paper. The GM12878 line writes `gm_sc.gch_hcg_count.txt.gz`. | `$S1Q/extract_counts.sh` |
| `06_benchmark_qc/extract_trinuc_chrM.py` | Per-cell trinucleotide methylation from the per-cell `trinuc_methy` QC files. Used for both chrM and an autosome. | `$S1Q/extract_trinuc_chrM.py` |
| `06_benchmark_qc/02_extract_trinuc_chrM.sh` | Runs the above on chrM — the bisulfite non-conversion proxy. | `$S1Q/extractchrM.sh` |
| `06_benchmark_qc/03_extract_trinuc_autosome.sh` | The same on chr21 (chr19 for mouse) — the autosomal non-CpG methylation proxy. | `$S1Q/extractchr.sh` |

`$S1Q` = `scnomehic_paper/s1/QC`.

## Renumbering

Files in `03_pseudobulk/` were prefixed with their run order; the originals carried
no numbering and were spread across three directories (`$GM/`,
`$GM/pseudobulk_methylation/`, `$GM/hic_comparison/scripts/`).

Renaming meant updating what the scripts say about themselves. **Only these were
changed:**

- `Submit: sbatch <name>` lines, to match the new filenames
- `01_merge_calmd_passed.sh`: "Run `qc_plots.ipynb` first" → `../02_qc/qc_plots.ipynb`,
  and a comment pointing at a sibling working directory that is not in this repo
- `04_build_pseudobulk_hic.sh`: its two references to scripts not included here —
  the bulk comparison point now reads `../../bulk_scNOMeHiC/10_hic_from_merged.sh`,
  and the superseded pseudobulk builders are described rather than named

Commands, parameters, and data paths are untouched. All scripts pass `bash -n`.

## Deliberately not included

- **The Snakemake workflow itself** — lives at
  `github.com/epifluidlab/sc_NOMeHiC_pipeline`, commit `a0456b9`. Pinned in
  `README.md` rather than duplicated.
- **The superseded pseudobulk Hi-C builders** — `build_pseudobulk_hic.sh` and
  `finalize_pseudobulk_hic.sh` / `_v2` / `_v3`. The first ran sam2juicer directly on
  calmd BAMs that still contained marked duplicates, so it included ~56 % PCR
  duplicates while the bulk excluded them; the rest are format and performance
  iterations of it.
- **`gm_hicmatrix_driver.sh` and its config** — built per-cell
  `06.hiccluster_snakemake/*.hic_matrix.txt.gz`, which nothing in the analysis or
  figure code reads. That config also carried a broken `bisulfitehic` path, so its
  run produced 188 empty files.
- **`make_qc_notebook.py`** — the generator that wrote `qc_plots.ipynb`. Tooling for
  authoring the notebook, not part of the method.
- **`make_qc_excel.py`** — formats the QC metrics into a spreadsheet for reading.
- **The cell × bin matrix collapse** — `make_table.sh`, `collapse.sh`,
  `methylation_collapse.py`, `collapse.ipynb`. These ran and produced
  `GCH_{250kb,gene,1kb}.txt.gz` and `HCG_{250kb,gene}.txt.gz` in the working
  directory, but **nothing consumes them.** An exhaustive search of every notebook,
  script and R file in `scnomehic_paper/` and `sc_nomehic_cellline/` found no
  reference to them. The apparent hits are filename collisions: `fig2` builds its
  own 250 kb pseudobulk straight from the per-cell 6plus2 beds and names the output
  `*_250kb`; `subset_clustering` reads `methylation_matrices/` from a *different*
  dataset's working directory; `s2_new` builds its own tables.
- **`hic_comparison/scripts/` dump and SCC code** (`dump_2.5Mb.sh`,
  `scc_analysis.py`, `build_bulk_*.sh`, `validate_pairfilter*.sh`) and
  **`ctcf_cgi_profiles/`** — these consume the outputs above to make figure panels,
  so they belong under `main_figures/` or `supplementary_figures/`.
- **The rest of `scnomehic_paper/s1/QC/`** — `runBisQC_cellline.sh`,
  `run_summary.sh`, `run_preseq_gc_extrap.sh`, `complexity/`, and the per-dataset
  cell lists and BAM manifests. Pipeline re-runs and library-complexity work behind
  an earlier version of the S1 panels; the current ones come from the benchmark
  repository.
- Recovery, validation and superseded-parameter scripts from the original working
  directory. They record operational history, not the method.
