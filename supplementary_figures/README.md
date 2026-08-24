# supplementary_figures

One folder per supplementary figure. Same convention as `../main_figures/`: only
the code that turns analysis-ready tables into panels.

| Folder | Figure | Source working dir |
|---|---|---|
| `figS1/` | Per-cell QC vs six published single-cell methods | `snomehic_benchmark` — no notebook of its own, see `main_figures/fig1/` |
| `figS2/` | scNOMe-HiC vs published single-cell assays: scWGBS/sci-MET, snATAC, sci-Hi-C | `../../scnomehic_paper/s2_new/` |
| `figS3/` | GCH/HCG metaprofiles at CTCF sites and CGI vs non-CGI TSS | `../../scnomehic_paper/s3/` |
| `figS4/` | Species mixing (barnyard) and per-site GCH/HCG distributions | `../../scnomehic_paper/s3/`, `s3/snakemake/` |
| `figS5/` | Sequencing saturation, GM12878 | `../../scnomehic_paper/s7/` |
| `figS6/` | Replicate reproducibility, mouse cortex (rep1 vs rep2) | `../../sc_nomehic/snakemake/replicate_comparison/` |
| `figS7/` | QC / batch diagnostics on the integrated UMAP, mouse cortex | `../../sc_nomehic/snakemake/subset_clustering/250kb_denovo/`, via `main_figures/fig3/` |
| `figS8/` | Meningioma: joint vs HCG annotation, and the concordance metrics Fig. 4 does not show | via `main_figures/fig4/fig4_umap.ipynb` — no notebook of its own |

Each folder's `README.md` lists the panels, the inputs, and the run order;
`FILES.md` says what every file in it is.

## Migration notes

- `scnomehic_paper/s2/` is an older, unrelated
  analysis (CTCF/CGI metaprofiles and loop-methylation concordance); the current S2
  comes from `s2_new/` only. Likewise `scnomehic_paper/s1/` holds an earlier version
  of the S1 violins; the current ones come from the benchmark repository.
- The supplementary numbering was reshuffled after `scnomehic_paper/` was laid out.
  `scnomehic_paper/s6/` (accessibility / Hi-C QC UMAP panels) and `s7/` (library
  complexity and saturation) are **not** the current S6 and S7. Check the source
  directory, not the `sN` number.
