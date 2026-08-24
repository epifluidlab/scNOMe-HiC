# Mouse cortex — single-cell NOMe-HiC processing

Mouse cortex scNOMe-HiC, **1,577 cells**, clustered at 250 kb. Figure panels are in
`../../main_figures/fig3/`; Supplementary Fig. S6 in `../../supplementary_figures/figS6/`.

Pipeline: <https://github.com/epifluidlab/sc_NOMeHiC_pipeline>. Running from scratch:
[../../RUNNING.md](../../RUNNING.md). This dataset ran from `start_from: trimmed`.

## Run order

| Step | What it is |
|---|---|
| `00_config/config.yaml` | Snakemake config. Hicluster at 100 kb and 250 kb; `selected_cells_file: QC/cortex_passed.txt`. |
| `01_pipeline/01_run_pipeline.sh` | Align → bamprocess → QC → Bis-SNP → per-bin methylation. |
| `01_pipeline/02_hicluster.sh` | `hicluster_selected` at 100 kb and 250 kb. Runs **after** `02_qc`, over the QC-passing whitelist. |
| `02_qc/qc_plots.ipynb` | QC gate and cells × bins matrices. Writes `QC/cortex_passed.txt`. |
| `02_qc/build_hcg_counts.R`, `build_gch_counts.R` | Per-cell `mc`/`cov` count matrices at TSS, gene body and both combined. 21,800 genes × 1,577 cells. |
| `03_hic_loops/01_impute_missing_25kb.sh` | SLURM array: `generatematrix-cell` → `impute-cell` → `loop-bkg-cell` at 25 kb. |
| `03_hic_loops/02_call_loops.sh` → `make_celltype_cool.py` | Per cell type: `loop-sumcell-chr` → `loop-mergechr` → `.loop.bedpe`, plus Q/T/E `.cool`. |
| `03_hic_loops/cell_table_all1577_25kb.tsv` | `cell_id ⇥ cell_type` for all 1,577 cells. Rebuild if the labels change. |
| `04_replicate_comparison/` | rep1 vs rep2 reproducibility — see that folder's README. |

## Outputs

| Product | Path |
|---|---|
| QC-passing cell list | `QC/cortex_passed.txt` |
| Cells × bins matrices | `QC/methylation_matrices/methylation_matrix_{HCG,GCH}_{100kb,250kb}.tsv.gz` |
| Per-cell count matrices | `QC/methylation_matrices/{HCG,GCH}_{gene,gene_tss,gene_body}_counts.rds` |
| Hi-C embeddings | `06.hiccluster_snakemake/hicluster_{100kb,250kb}_embed_dir/` |
| Per-type loops and coolers | `<cell_type>.loop.bedpe`, `<cell_type>.{Q,T,E}.cool` |

## Notes

- The count matrices exist because `methylation_matrix_*.tsv.gz` stores fractions
  only, which cannot support Σmc/Σcov pooling. The Fig. 3 marker heatmaps use the
  read-weighted pooling.
- `make_celltype_cool.py` here differs from the copy in
  `../mixture_cellline/04_hic_imputation/`; each dataset carries its own.
- Per-cell 25 kb imputation is annotation-independent — a relabelling repeats only
  `02_call_loops.sh`.
- Scripts keep the absolute paths they ran with:
  `sc_nomehic/snakemake` and `sc_nomehic/hic/loop_final`.
