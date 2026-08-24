# Supplementary Figure S8 — meningioma, annotation comparison and concordance

Meningioma, 292 cells. Two things Figure 4 shows only one side of.

## Panels

| File | Made by |
|---|---|
| `final_umap_fig4b_joint.pdf` — four-panel UMAPs, joint annotation | `../../main_figures/fig4/fig4_umap.ipynb` §8c |
| `final_umap_fig4b_hcg.pdf` — the same panels, HCG annotation | `../../main_figures/fig4/fig4_umap.ipynb` §8c |
| `embedding_cna_concordance_signif.pdf`, kNN-purity and ARI facets | `../../main_figures/fig4/fig4_umap.ipynb` §8d |

## This folder ships no notebook

Both panels come from cells in `fig4_umap.ipynb` that also produce Figure 4 panels:

- **§8c** draws `final_umap_fig4b_{joint,hcg,cna}.pdf` in one cell. Figure 4 uses the
  joint one; S8 uses joint and HCG side by side.
- **§8d** draws one faceted figure with kNN purity, ARI and NMI. Figure 4 uses the
  NMI facet; S8 uses the other two. The split is made at layout, not by the notebook.

§8c needs the three per-modality embeddings, the joint embedding and both
annotations — nearly the whole notebook — so there is no clean seam to extract, and
this folder points at fig4 rather than carrying a near-copy.

## The two annotations

§8b writes two cell-type annotations from the same cells:

| | tumor1 | monocyte | tumor2 |
|---|---|---|---|
| `cell_type_joint` | 122 | 91 | 79 |
| `cell_type_hcg` | 118 | 108 | 66 |

They disagree on 17 cells, all at the monocyte/tumor2 boundary. Figure 4 uses the
joint annotation; showing both here makes the disagreement visible.

## Notes

- `embedding_cna_concordance_signif.pdf` is one faceted figure: three metrics across
  four embeddings, with bootstrap 95% CIs and Holm-adjusted significance brackets.
