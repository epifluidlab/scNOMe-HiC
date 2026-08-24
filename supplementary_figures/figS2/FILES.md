# FILES — supplementary_figures/figS2

3 notebooks, copied whole. See `README.md` for the panels, inputs and statistics.

| File | What it is | Origin |
|---|---|---|
| `figS2_methylation_persite.ipynb` | R, 12 code cells, kernel `nomehic_r`. Per-CpG HCG across scNOMe-HiC, Drop-BS scWGBS and sci-MET. Cells 1–4 Drop-BS vs NOMe-HiC, 6–8 sci-MET vs NOMe-HiC, 10 both side by side, 12–14 sci-MET vs scWGBS, **16 the three-way panel**. Outputs preserved. | `s2_new/code/13_persite_compare_nomehic.ipynb` |
| `figS2_accessibility.ipynb` | R, 5 code cells, kernel `scnomehic`. Loads `peak_signal.tab` + `peak_gch_coverage.tab`, quantile-normalises, draws the smoothScatter. §2 is the panel; §3 is the coverage > 10 variant. Outputs preserved. | `s2_new/atac_dnase_gm12878/analysis_figures_R.ipynb` |
| `figS2_schic_scc.ipynb` | Python, 9 code cells, kernel `scnomehic`. Self-contained: reads the dumps and recomputes HiCRep SCC rather than reading a table. §7 is the panel. Outputs preserved. | `s2_new/schic_gm12878/analysis_scc.ipynb` |

Renamed only — no cell edits, no path rewriting. All three keep the absolute paths
they ran with and write their figures back into the source tree; point the `FIG` /
`fig_outdir` variable at this folder's `figures/` when re-running from the repository.

**Notebook `figS2_methylation_persite.ipynb` must run under SLURM, not on a login
node.** On the login node the R kernel is killed part-way with `DeadKernelError`
despite ample free memory (a per-user arbiter, not RAM: under SLURM the same
notebook finishes in 4.5 min at 5.2 G MaxRSS).

## Environment

Kernels `nomehic_r` (R 4.4.2) and `scnomehic`. Neither is captured in `../../env/` yet.

## Not included

| File | Why not |
|---|---|
| `atac_dnase_gm12878/analysis_figures.ipynb` | The Python version of the accessibility analysis, plus the deepTools quartile profiles. The published panel is the R smoothScatter. |
| `code/12_compare_nomehic.ipynb`, `14_bulkwgbs_compare_nomehic.ipynb`, `code/scmet/15_compare_3way.ipynb`, `16_methylation_levels.ipynb` | The 250 kb binned comparisons. The S2 panel is per-CpG-site. |
| `code/scmet/_add_three_way_bars.py`, `_add_sci_vs_wgbs.py`, `_fix_combined_bars.py`, `_fix_pdf_glyphs.py` | Scripts that appended or patched cells in the persite notebook. The notebook now carries those cells; the patchers are authoring tooling. |
| `atac_dnase_gm12878/figures/*_quartiles.*`, `gch_vs_snatac_scatter.*`, `schic_gm12878/figures/schic_scc_{boxplots_by_percentile,by_chrom_bar,example_heatmaps,matched_bin_scatter}.*` | Supporting figures drawn by the retained notebooks, but not S2 panels. |
