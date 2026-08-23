# FILES — data_processing/meningioma

14 files. See `README.md` for the run order and what each step consumes and produces.

`$M` = `/gpfs/projects/b1198/epifluidlab/yoshii/meningioma_scnomehic`
`$S` = `$M/snakemake`

| File | What it is | Origin |
|---|---|---|
| `README.md` | Run order, the 348 → 294 → 292 cell narrowing, copy-number rationale. | written for this repo |
| `FILES.md` | This file. | written for this repo |
| `00_config/config.yaml` | Self-contained snakemake config: `start_from: trimmed`, `trimmed_data: merged_trimmed`, hg38 references, the shared QC thresholds, methylation bins/regions. | `$S/config.yaml` |
| `00_config/config_hic_all3.yaml` | Layered on top of `config.yaml` for the hicluster step: the all-three-batch cell list and 250 kb embedding output dir. | `$S/config_hic_all3.yaml` |
| `01_pipeline/01_run_pipeline.sh` | Snakemake driver for the per-cell chain over all 348 cells. | `$S/run_pipeline.sh` |
| `02_qc/qc_plots.ipynb` | QC gate and methylation matrices; writes `QC/meningioma_passed.txt`. Python, 15 code cells, 39 figures, no errors. | `$S/qc_plots.ipynb` |
| `02_qc/remove_controls.py` | Removes the 7 named control / titration wells (blank, 10c, 100c, 1000c) from the passing lists. | `$S/code/remove_controls.py` |
| `02_qc/build_methylation_matrices_250kb.py` | GCH / HCG cell × bin matrices at 250 kb. | `$S/code/build_methylation_matrices_250kb.py` |
| `03_hic/01_hic_matrices.sh` | Per-cell Hi-C contact matrices (`scbam2hic` + `hicprocess`) for the QC-passed cells. | `$S/code/hic1_matrices.sh` |
| `03_hic/02_hic_usability_check.py` | Drops cells whose Hi-C would crash hicluster (needs a usable cis contact on every autosome). **294 → 292.** | `$S/code/hic_usability_check.py` |
| `03_hic/03_hicluster.sh` | `hicluster_selected` at 250 kb over the usable cells → `hicluster_250kb_embed_dir_all3/`. | `$S/code/hic2_run_all3.sh` |
| `04_cna/01_build_cna_1M.sh` | Per-cell fragment counts in 1 Mb bins from the alignment BEDs → `CNA.1M.txt`, the copy-number proxy. | `$S/code/build_cna_1M.sh` |
| `04_cna/count_fragment.py` | The binning worker the step above calls. Lived outside `snakemake/`, in `data_batch_3/`; shipped here so the step is self-contained. | `$M/data_batch_3/count_fragment.py` |
| `05_deconv/01_make_cell_lists.py` | Splits the 292 cells by **`cna_group`**: non-tumour = group 1 (chr22q intact, 96 cells), tumour = groups 2 and 3 (chr22q loss ± chr1p loss, 196). Prints the split against both cell-type annotations for the record. `SPLIT` switches it to an annotation column. | rewritten from `$S/code/deconv_make_cell_lists.py` |
| `05_deconv/02_combine_bam.sh` | Merges one group's per-cell BAMs into `combined_sorted_<group>.bam`. | `$S/code/deconv_combinebam.sh` |
| `05_deconv/03_run_deconv.sh` | SLURM driver: cell lists → merged BAMs → `wgbstools bam2pat` → `uxm deconv` against the Loyfer brain atlas → `output.csv`. | `$S/code/deconv_run.sh` |

## Edits made

Renumbered into run order (`hic1_matrices` → `03_hic/01_`, `hic2_run_all3` →
`03_hic/03_`, `build_cna_1M` → `04_cna/01_`). Two changes to what the scripts say
about themselves, no change to any command, parameter or data path:

- `01_build_cna_1M.sh` pointed at `$M/data_batch_3/count_fragment.py`, outside
  the migrated tree. Rewritten to resolve the sibling copy via `BASH_SOURCE`.
- `01_hic_matrices.sh` and `03_hicluster.sh` told the reader to run
  `code/01_unlock.sh` on a locked workdir — an operational helper not shipped
  here. Replaced with the equivalent `snakemake --unlock` command inline.

All scripts pass `bash -n` / `ast.parse`.

## Deliberately not included

- **`$S/code/build_qc_notebook.py`** — generator for `qc_plots.ipynb`. As with
  the other datasets, the notebook is the method and the generator is authoring
  tooling.
- **`$S/make_qc_excel.py` and `QC/meningioma_qc_table.{xlsx,tsv}`** — the QC
  spreadsheet. Reproduces the notebook's passing list exactly (verified against
  `meningioma_passed.txt`), so it adds a presentation format, not a result.
- **`$S/config_hic_batch23.yaml` and `$S/code/hic3_run_batch23.sh`** — the
  batch2+3-only run (142 cells). An alternative cell set that the final analysis
  does not use; `subset_clustering/250kb/batch2_3/` was abandoned in June.
  Note `02_hic_usability_check.py` still writes
  `QC/meningioma_passed_hicusable_batch23.txt` alongside the all-batch list, and
  its docstring still mentions `config_hic_batch23` — that is accurate about what
  the script does, so it was left alone. Nothing downstream reads that file.
- **`$S/code/{00_check_state,01_unlock,02_dryrun,03a_launch_detached,03b_launch_slurm_driver,04_status}.sh`**
  and the `monitor_*.sh` set — operational re-entry and progress-checking
  helpers for a run that was interrupted by cluster maintenance. Useful at the
  time, not part of the method.
- **`$S/code/deconv_*.{py,sh}`** — the deconvolution analysis. A separate
  question from preprocessing; not migrated pending a decision on whether it is
  a paper panel.
- **`$S/code/plotheatmap_src.py`** — vendored heatmap plotting used by the CNA
  *notebook* (sub-clone clustering and the heatmap figure), not by the count
  step here. It belongs with the figure code.
- **`$S/setup_merged_trimmed.sh`** — symlinked the three batches' already-trimmed
  FASTQs into one `merged_trimmed/` directory. That reflects how this dataset was
  stored locally (batch 1 had been trimmed by an older, non-snakemake pipeline),
  not how it should be re-run: from raw or demultiplexed reads the pipeline trims
  for itself. See the root `RUNNING.md`.

## Running this outside the original workdir

Every script keeps the absolute paths it ran with, as in the other datasets — the
`cd` at the top of each driver, `ROOT`/`OUTDIR`, and the `QC` path in
`remove_controls.py`. Point those at your own workdir before running.

`remove_controls.py` is safe either way: it removes the named wells by set
difference, so if a deposit does not include the control/titration wells it
simply reports removing none. It does not fail on their absence. Only two of the
seven listed wells passed QC in the original run (`MY_28_S210.ACTTGA`,
`MY_30_S212.CTTGTA`) — those two are the 296 → 294 difference.
