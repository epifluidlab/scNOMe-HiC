# FILES — main_figures/fig2

3 notebooks. `fig2_umap.ipynb` is trimmed to §1–§7 + §9; the other two are still
copied whole. See `README.md` for inputs, the run order, and the trims.

| File | What it is | Origin |
|---|---|---|
| `fig2_umap.ipynb` | R, **19 code cells** (trimmed from 32), kernel `scnomehic`. SVD → Harmony → Leiden + UMAP over HCG, GCH, Hi-C and a joint embedding; §8–9 call cell types against bulk methylation and **write the cell-type labels the pseudobulk builders need**. Outputs preserved. | `sc_nomehic_cellline/snakemake/subset_clustering/250kb/subset_final_snakemake.ipynb` |
| `fig2_accessibility.ipynb` | R, 26 code cells, kernel `scnomehic_diff`. Bulk-vs-pseudobulk GpC accessibility at 250 kb. Published panels are the two-row heatmap and its colorbars; the earlier parts (DiffBind, per-peak sc GCH, RWR imputation) are development. Outputs preserved. | `scnomehic_paper/fig2/codes/fig2_accessibility.ipynb` |
| `fig2_methylation.ipynb` | R, 17 code cells, kernel `scnomehic_diff`. Published panels are the metilene-DMR heatmap and its colorbar; the earlier parts are the methylKit 250 kb branch. Outputs preserved. | `scnomehic_paper/fig2/codes/fig2_methylation_250kb.ipynb` |

Renamed only — no cell edits, no path rewriting.

## Environment

Two kernels: `scnomehic` (the UMAP notebook) and `scnomehic_diff` (the two heatmap
notebooks). The latter is built by `../../env/create_diff_env.sh`.

## Not included

- **`build_methylation_notebook.py`, `build_accessibility_notebook.py`** — the
  generators that assemble these notebooks from cell sources. Authoring tooling, not
  method; the same call we made for the QC notebook in Figure 1.
- **`subset_final_snakemake_exploration.ipynb`** and the `.bak` copy — the
  parameter-sweep notebook that informed the final clustering settings.
- **`run_gch_sweep.R`, `run_gch_6c_replay.R`, `run_joint_embedding.R`,
  `diag_gch_9c_vs_canonical.R`, `diag_harmony_stability.R`** — standalone runners and
  diagnostics from `subset_clustering/250kb/`. The diagnostics investigated why the
  canonical GCH UMAP differed from the exploration version (Harmony has two stable
  attractors depending on k-means init). Useful history, not the published path.
- **`scratchpad_modality_agreement.R`, `scratchpad_agreement_heatmap.R`** — the
  inter-modality Leiden agreement analysis (ARI 0.833 HCG↔HiC, 0.714 HCG↔GCH, 0.616
  HiC↔GCH). A separate result, not one of the panels listed here.
- **The APA notebook** — `loop_insitu_apa.ipynb`, still to be migrated along with its
  loop-calling chain.
