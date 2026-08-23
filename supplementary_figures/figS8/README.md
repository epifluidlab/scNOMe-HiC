# Supplementary Figure S8 — meningioma, annotation comparison and concordance

Meningioma, 292 cells. Two things Figure 4 shows only one side of.

| Panel | File | Made by |
|---|---|---|
| Four-panel UMAPs, **joint** annotation | `final_umap_fig4b_joint.pdf` | `fig4_umap.ipynb` §8c |
| Four-panel UMAPs, **HCG** annotation | `final_umap_fig4b_hcg.pdf` | `fig4_umap.ipynb` §8c |
| Embedding–CNA concordance, **kNN purity and ARI** facets | `embedding_cna_concordance_signif.pdf` | `fig4_umap.ipynb` §8d |

## This folder ships no notebook of its own

Every panel here comes from **`../../main_figures/fig4/fig4_umap.ipynb`**, and
from the same two cells that produce the Figure 4 panels:

- **§8c** draws all three four-panel figures in one cell —
  `final_umap_fig4b_{joint,hcg,cna}.pdf`. Figure 4 uses the joint one; S8 uses the
  joint and HCG ones side by side.
- **§8d** draws one faceted figure containing kNN purity, ARI and NMI. Figure 4
  uses the NMI facet; S8 uses the other two.

Extracting those cells into a standalone notebook here would duplicate almost all
of `fig4_umap.ipynb` — §8c needs the three per-modality embeddings, the joint
embedding and both annotations, which is nearly the whole notebook. Unlike
`figS7/`, where §8.7c was genuinely separable and reads its inputs from disk,
there is no clean seam. So this folder documents the mapping and points at fig4
rather than carrying a near-copy that could drift out of step.

## The two annotations

The joint and HCG panels differ because §8b writes two cell-type annotations from
the same cells:

| | tumor1 | monocyte | tumor2 |
|---|---|---|---|
| `cell_type_joint` | 122 | 91 | 79 |
| `cell_type_hcg` | 118 | 108 | 66 |

They disagree on **17 cells**, all at the monocyte/tumor2 boundary. Figure 4 uses
the joint annotation; showing both here is the point of the panel — it makes the
disagreement visible rather than asserting one is right.

## Splitting the concordance figure

`embedding_cna_concordance_signif.pdf` is a single faceted figure: three metrics
across four embeddings, with bootstrap 95% CIs and Holm-adjusted significance
brackets. The notebook does not emit the facets separately, so the main-figure /
supplementary split is made at layout time. If you would rather the notebook
emitted them as separate files, that is a small change to §8d — say so and it can
be done.
