# supplementary_figures

One folder per supplementary figure. Same convention as `../main_figures/`: only
the code that turns analysis-ready tables into panels.

| Folder | Figure | Source working dir |
|---|---|---|
| `figS1/` | <!-- FILL --> | `../../scnomehic_paper/s1/` |
| `figS2/` | <!-- FILL --> | `../../scnomehic_paper/s2/`, `../../scnomehic_paper/s2_new/` |
| `figS3/` | GCH/HCG metaprofiles at CTCF sites and CGI vs non-CGI TSS | `../../scnomehic_paper/s3/` |
| `figS4/` | Species mixing (barnyard) and per-site GCH/HCG distributions | `../../scnomehic_paper/s3/`, `s3/snakemake/` |
| `figS5/` | Sequencing saturation, GM12878 | `../../scnomehic_paper/s7/` |
| `figS6/` | Replicate reproducibility, mouse cortex (rep1 vs rep2) | `../../sc_nomehic/snakemake/replicate_comparison/` |
| `figS7/` | QC / batch diagnostics on the integrated UMAP, mouse cortex | `../../sc_nomehic/snakemake/subset_clustering/250kb_denovo/`, via `main_figures/fig3/` |
| `figS8/` | Meningioma: joint vs HCG annotation, and the concordance metrics Fig. 4 does not show | via `main_figures/fig4/fig4_umap.ipynb` — no notebook of its own |

Each folder's `README.md` lists the panels, the inputs, and the run order;
`FILES.md` says what every file in it is.

## Migration notes

- `figS1/` and `figS2/` are not migrated yet. `s2` and `s2_new` both exist in the
  source tree; which parts belong in `figS2/` is still to be decided.
- The supplementary numbering was reshuffled after `scnomehic_paper/` was laid out.
  `scnomehic_paper/s6/` (accessibility / Hi-C QC UMAP panels) and `s7/` (library
  complexity and saturation) are **not** the current S6 and S7. Check the source
  directory, not the `sN` number.
