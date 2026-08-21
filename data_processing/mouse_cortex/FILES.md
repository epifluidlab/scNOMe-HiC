# FILES — data_processing/mouse_cortex

10 files. See `README.md` for the run order and what each step consumes and produces.

`$S` = `/gpfs/projects/b1198/epifluidlab/yoshii/sc_nomehic/snakemake`
`$L` = `/gpfs/projects/b1198/epifluidlab/yoshii/sc_nomehic/hic/loop_final`

| File | What it is | Origin |
|---|---|---|
| `00_config/config.yaml` | Snakemake config: `start_from: trimmed`, references and tool paths, `hicluster_resolutions: [100 kb, 250 kb]`, `selected_cells_file: QC/cortex_passed.txt`, QC thresholds. | `$S/config.yaml` |
| `01_pipeline/01_run_pipeline.sh` | Snakemake driver for the per-cell chain. Same repo-wide template as the other datasets — differs only in job name and config path. | rewritten from `$S/run_pipeline.sh` |
| `01_pipeline/02_hicluster.sh` | Runs `hicluster_selected` at 100 kb and 250 kb over the QC-passing whitelist. Same template plus the target. | rewritten from `$S/run_hicluster_selected.sh` |
| `02_qc/qc_plots.ipynb` | QC gate and cells × bins matrices; §7 writes `QC/cortex_passed.txt`, the whitelist the hicluster step consumes. Outputs preserved. | `$S/qc_plots.ipynb` |
| `02_qc/build_hcg_counts.R` | Per-cell HCG `mc`/`cov` count matrices at TSS, gene-body and combined regions (21,800 genes × 1,577 cells), `mclapply` over QC-passed cells. Needed because the fraction matrices cannot support Σmc/Σcov pooling. | `$S/QC/methylation_matrices/` |
| `02_qc/build_gch_counts.R` | The GCH mirror — `mc` = accessible reads. GCH methylation is chromatin accessibility. | `$S/QC/methylation_matrices/` |
| `03_hic_loops/01_impute_missing_25kb.sh` | SLURM array: `generatematrix-cell` → `impute-cell` → `loop-bkg-cell` at 25 kb for the cells missing that resolution. | `$L/impute_missing_25kb.sh` |
| `03_hic_loops/02_call_loops.sh` | SLURM array, one task per cell type: `loop-sumcell-chr` → `loop-mergechr` → `make_celltype_cool.py`, over all 1,577 cells. | `$L/call_loops_1577.sh` |
| `03_hic_loops/make_celltype_cool.py` | Builds the per-cell-type Q/T/E `.cool` files. **Distinct from the mixture dataset's copy of the same filename** — the two versions differ. | `sc_nomehic/hic/` |
| `03_hic_loops/cell_table_all1577_25kb.tsv` | `cell_id ⇥ cell_type`, 1,577 cells, 10 types. A manifest, not an analysis output: derived from `250kb_denovo/annotation/cell_type_table.tsv` with the `batch<N>_` prefix stripped. Shipped because `02_call_loops.sh` requires it and no script builds it. | `$L/` |

## Edits made

Two, both forced by the move:

- The two pipeline drivers were rewritten onto the repo-wide template (see
  `../gm12878_cellline/FILES.md` for the before/after). The originals hardcoded a
  timestamped log path and ran via `exec` under nohup.
- `02_call_loops.sh` called `"${HIC}/make_celltype_cool.py"` from a sibling directory;
  it now resolves the helper beside itself.

Everything else is verbatim. All scripts pass `bash -n` / `ast.parse`.

## Deliberately not included

- **Batch-merge steps** — `merge_batch1.sh`, `merge_batch1_v2.sh`, `merge_batch2.sh`
  and the `merged_trimmed*/` staging. What a reader downloads from GEO is already
  merged and demultiplexed, so the merge predates any reproducible entry point.
- **The 1,143-cell predecessors** — `call_loops_final.sh` and
  `cell_table_final_25kb.tsv`. Superseded by the 1,577-cell versions; the earlier
  Hi-C cell types split Pvalb/Vip, had no IT-L5/6, and placed 389 cells in IT-L4
  where the final annotation places 176.
- **`make_apa_figure.py`** — a batch-script duplicate of the APA notebook's logic. The
  notebook is the entry point and is verified end-to-end, so it is what ships. The two
  have since diverged: the script's `--gamma` default is 2.0 while the notebook ships
  `GAMMA = 3`, so running the script would not reproduce the figure.
- **`run_hicluster_selected_resume.sh`, `run_hicluster_concat_only.sh`** — partial
  re-entry points for interrupted runs; operational, not method.
- **`make_qc_excel.py`** — QC spreadsheet formatting, as with the other datasets.
- **`archive_superseded/`** in the clustering folder, and the retired annotations
  `annotation_k20_r0.3/` and `annotation_consensus12_backup/`. Only `annotation/` is
  canonical — see `../../main_figures/fig3/README.md`.
