# FILES — data_processing/mixture_cellline

9 files. See `README.md` for the run order and what each step consumes and produces.

`$S` = `/gpfs/projects/b1198/epifluidlab/yoshii/sc_nomehic_cellline/snakemake`
`$F` = `/gpfs/projects/b1198/epifluidlab/yoshii/scnomehic_paper/fig2/codes`

| File | What it is | Origin |
|---|---|---|
| `00_config/config.yaml` | Snakemake config: `start_from: trimmed`, references and tool paths, methylation bin sizes, QC thresholds including the `cisnum_max_threshold: 3000000` doublet cap. | `$S/config.yaml` |
| `01_pipeline/01_run_pipeline.sh` | Snakemake driver against the shared pipeline (SLURM profile, `-j 1000`): align → bamprocess → QC → Bis-SNP → per-bin methylation for all 639 cells. Same template as every other dataset's driver. | rewritten from `$S/run_pipeline.sh` |
| `01_pipeline/02_hicluster.sh` | Runs the `hicluster_selected` target → the 100 kb and 250 kb Hi-C embeddings; the UMAP notebook uses 250 kb. Same template as `01_run_pipeline.sh`, plus the target. | rewritten from `$S/hicluster_driver_launch.sh` |
| `02_qc/qc_plots.ipynb` | The canonical QC (Python). Applies the config thresholds incl. the doublet cap → `QC/cellline_passed.txt` (441 of 639), and builds the cells × bins methylation matrices under `QC/methylation_matrices/`. Outputs preserved. | `$S/qc_plots.ipynb` |
| `02_qc/rebuild_methylation_matrices.py` | Standalone equivalent of the notebook's matrix-building step — per-cell `*_methylation.txt.gz` → pivot on bin id → one matrix per (context, bin size). **Edited: `USE_QC_PASSED_ONLY` False → True** so it builds over the 441 QC-passing cells, matching the notebook. | `$S/scripts/` |
| `03_pseudobulk/01_build_sc_pseudobulk_gch_250kb.{py,sh}` | Read-weighted GpC pseudobulk per cell type over 250 kb bins (Σmeth/Σtotal) → `sc_pseudobulk_GCH_250kb.tsv.gz`. Needs cell-type labels. | `$F/` |
| `03_pseudobulk/02_build_sc_pseudobulk_metilene_dmr.{py,sh}` | Same pooling over the metilene DMRs from `../bulk_others/03_differential/`, joined with bulk WGBS means → `sc_pseudobulk_metilene_dmr_top2000.tsv.gz`. | `$F/` |

## Edits made

The two drivers were **rewritten onto the repo-wide template** so every dataset is
run the same way — see `../gm12878_cellline/FILES.md` for the before/after table.
In short: `--rerun-triggers mtime` dropped (it suppressed re-runs after config
changes), tool paths made overridable, and submission standardised on `sbatch`.

Then two edits forced by the move:

- `rebuild_methylation_matrices.py`: `USE_QC_PASSED_ONLY = True` (was `False`). As
  shipped it built matrices over all 639 cells; the notebook filters to 441. The UMAP
  notebook intersects against the QC list itself, so this does not change any
  published result — it just keeps the script and notebook consistent.
- The two `.sh` wrappers called `python codes/<name>.py`, a path relative to the old
  analysis directory. They now locate the `.py` beside themselves
  (`$(dirname "$(readlink -f "$0")")/…`). The `cd "$WORK"` line is untouched, because
  the `.py` writes its outputs relative to it.

Everything else is verbatim. All scripts pass `bash -n` / `ast.parse`.

## Deliberately not included

- **`run_qc_refresh.py`** — a standalone re-implementation of the QC filter from
  2026-06-03. Superseded: the notebook wrote the final 441-cell list on 2026-06-12,
  while this script produced the 380-cell list now sitting in
  `cellline_passed_pre_doublet_filter.txt` (despite the name, that file is the older
  and smaller one). The script is also internally inconsistent — its comments say the
  transrate filter was removed while its mask still applies it — and it indexes two
  config keys (`transrate_threshold`, `reads_mapq30_threshold`) that no longer exist,
  so it would raise `KeyError` if run today.
- **`cellline_passed_pre_doublet_filter.txt`** — written only by the above; nothing
  reads it.
- **`make_qc_excel.py`** — QC spreadsheet formatting, presentation only.
- **`rerun_bistools*.sh`, `rerun_genebed_missing.sh`, `run_dryrun*.sh`** — recovery
  and dry-run helpers; operational history, not method.
- **The methylKit / 250 kb-HCG branch** — `dmr_methylkit_250kb.R/.sh` and
  `build_sc_pseudobulk_hcg_250kb.{py,sh}`. methylKit selected differential 250 kb
  tiles for a sc-vs-bulk methylation heatmap that is not a published panel; the
  published methylation figure uses the de-novo metilene DMRs instead.
- **The DiffBind branch** — `diffbind_atac.R/.sh`, `download_atac_bams.sh`,
  `build_sc_gch_peak_matrix.{py,sh}`, `sc_gch_sparsity.py`. The published
  accessibility panel selects its top-1000 bins from bulk ATAC *signal*, not from
  DiffBind peaks, so none of this is on its path.
