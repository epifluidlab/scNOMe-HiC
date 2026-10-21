# FILES — main_figures/fig2

4 notebooks, each trimmed or scoped to its published panels. See `README.md` for inputs, the run order, and the trims.

| File | What it is | Origin |
|---|---|---|
| `fig2_umap.ipynb` | R, **21 code cells** (trimmed from 32, plus §10), kernel `ir` (scnomehic env). SVD → Harmony → Leiden + UMAP over HCG, GCH, Hi-C and a joint embedding; §8–9 call cell types against bulk methylation and **write the cell-type labels the pseudobulk builders need**. Outputs preserved. | `sc_nomehic_cellline/snakemake/subset_clustering/250kb/subset_final_snakemake.ipynb` |
| `fig2_accessibility.ipynb` | R, **4 code cells** (trimmed from 26), kernel `scnomehic_diff`. Single-cell GpC pseudobulk vs bulk ATAC at 250 kb → two-row heatmap + colorbars. The DiffBind, per-peak sc GCH and RWR-imputation branches were removed entirely. Figure outputs preserved. | `scnomehic_paper/fig2/codes/fig2_accessibility.ipynb` |
| `fig2_apa.ipynb` | Python, **11 code cells**, kernel `hic_cooler`. Plotting only — the pile-up is cached in `apa_insituHCD.npz` by `bulk_others/04_hic_loops/05_apa_pileup_insitu.py`, which this notebook imports (as `step08_apa_insitu_defined`, its working-directory name) when `RECOMPUTE = True`. `LOOPSET` in §1 picks the loop definition; `hiccupsdiff` is the published one. §5 is the panel; §3–4 render the min-max and raw 2×N diagnostics and §6 runs the paired Mann–Whitney. Outputs preserved, no errors. | `sc_nomehic_cellline/snakemake/APA/insitu/loop_insitu_apa_plot.ipynb` |
| `fig2_methylation.ipynb` | R, **5 code cells** (trimmed from 17), kernel `scnomehic_diff`. Metilene de-novo DMRs → single-cell pseudobulk direction check → heatmap + colorbar. The methylKit 250 kb branch was removed entirely. Outputs preserved. | `scnomehic_paper/fig2/codes/fig2_methylation_250kb.ipynb` |

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
- **`sc_nomehic_cellline/snakemake/APA/insitu/loop_insitu_apa.ipynb`** — the previous APA notebook, which
  produced `APA_2xN_insitu_diffloops.pdf` and was carried here until 2026-10-20.
  **Circular**: it selected differential loops from `loopq`/`loopt`, statistics
  derived from the single-cell imputed Q/T matrices, then piled up O/E from those
  same Q matrices. Selection statistic and display statistic share the underlying
  data, so it cannot separate real biology from selection on noise. Replaced by the
  in-situ-defined route above, which also fixes a silently dropped chr22.
- **`scratchpad_modality_agreement.R`, `scratchpad_agreement_heatmap.R`** — the
  standalone first drafts of the inter-modality Leiden agreement analysis. Superseded:
  the published form lives in `fig2_umap.ipynb` §10a/§10b, which computes the metrics
  and draws `modality_leiden_agreement_heatmap.pdf`. The scratchpad heatmap differs —
  it keys fill on ARI with a blue scale; the published panel keys fill on % cells
  co-assigned with a red scale and labels ARI / NMI / kNN beneath each number.
