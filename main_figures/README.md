# main_figures

One folder per main-text figure. Each contains only the code that turns
analysis-ready tables from `../data_processing/` into published panels.

| Folder | Figure | Source working dir |
|---|---|---|
| `fig1/` | Single-cell pseudobulk vs bulk NOMe-HiC: HCG methylation, GCH accessibility, Hi-C contacts | `../../sc_nomehic_cellline/` |
| `fig2/` | GM12878 / IMR90 mixture vs ground truth: UMAP, accessibility and methylation heatmaps, APA | `../../scnomehic_paper/fig2/`, `../../sc_nomehic_cellline/snakemake/` |
| `fig3/` | Mouse cortex cell types: de novo annotation, marker heatmaps, differential-loop APA | `../../sc_nomehic/` |
| `fig4/` | Meningioma: copy number and multi-modal clustering, 292 cells | `../../meningioma_scnomehic/snakemake/subset_clustering/250kb/all_batches/` |
| `fig5_fig6/` | Mouse cortex: concordance at the two ends of a contact (Fig. 5, Supplementary Figs. 9–12). GM12878 and IMR-90: X inactivation copy by copy (Fig. 6) | `reproduce/` of `epifluidlab/meth_concord` @ `9c6284f` |

`fig5_fig6/` works differently: its notebooks start from the per-cell BAM files
and run the whole analysis with the meth_concord package (`../software/README.md`).

Each folder's `README.md` lists the panels, the inputs, and the run order;
`FILES.md` says what every file in it is.
