# FILES — figS8/

| File | What it is | Origin |
|---|---|---|
| `README.md` | The three panels, which cells produce them, and why this folder ships no notebook. | written for this repo |
| `FILES.md` | This file. | written for this repo |

## No notebook here — by design

All three S8 panels come from `../../main_figures/fig4/fig4_umap.ipynb`, and from
the same two cells that produce Figure 4's:

| Panel | Cell |
|---|---|
| `final_umap_fig4b_joint.pdf` | §8c |
| `final_umap_fig4b_hcg.pdf` | §8c |
| `embedding_cna_concordance_signif.pdf`, kNN-purity and ARI facets | §8d |

§8c draws all three four-panel figures in one cell, and §8d draws all three
metrics as one faceted figure. Neither has a seam to cut along: §8c needs the
three per-modality embeddings, the joint embedding and both cell-type
annotations — nearly the whole notebook.

This differs from `figS7/`, where §8.7c was genuinely separable because those
cells read their inputs from disk and could stand alone. Extracting here would
mean shipping a near-duplicate of `fig4_umap.ipynb` that could drift out of step
with it, so this folder documents the mapping instead.

## Consequence worth knowing

Because `final_umap_fig4b_hcg.pdf` is an S8 panel, **§8b must keep writing both
cell-type annotations** even though the paper uses `cell_type_joint`. If the HCG
panel were ever dropped from S8, `cell_type_hcg` would become dead weight in the
Fig-4 notebook and could be trimmed with it.
