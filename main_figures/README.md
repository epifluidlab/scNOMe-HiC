# main_figures

One folder per main-text figure. Each folder contains only the code that turns
analysis-ready tables (produced under `../data_processing/`) into published panels.

| Folder | Figure | Source working dir |
|---|---|---|
| `fig1/` | Single-cell pseudobulk vs bulk NOMe-HiC across three modalities: HCG methylation, GCH accessibility, Hi-C contacts — **migrated** | `../../sc_nomehic_cellline/` |
| `fig2/` | Cell-type mixture vs ground truth: UMAP, accessibility and methylation heatmaps — **migrated** (APA panel pending) | `../../scnomehic_paper/fig2/`, `../../sc_nomehic_cellline/snakemake/` |

Add `fig3/`, `fig4/`, … as those sections are migrated.

Each figure folder's `README.md` states which panels the code produces, which
input tables it reads, and the order to run things in. Exploratory or superseded
code kept for the record lives in that folder's `archive/` and is not part of the
reproduction path.
