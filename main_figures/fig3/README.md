# Figure 3 — mouse cortex cell types

Mouse cortex scNOMe-HiC, **1,577 cells**, ten cell types called de novo from this
paper's own data. Inputs come from `../../data_processing/mouse_cortex/`.

## Panels

| File | Made by |
|---|---|
| `umap_fig4b_style.pdf` | `fig3_umap.ipynb` |
| `marker_gene_heatmap_HCG_gene.pdf`, `marker_gene_heatmap_GCH_gene.pdf` | `fig3_umap.ipynb` |
| `all_diffloop_apa_powernorm_sharedcbar.pdf` | `fig3_apa.ipynb` |

## Files

| File | What it is |
|---|---|
| `fig3_umap.ipynb` | R (`nomehic_r`), 28 code cells, 12 figures. SVD → Harmony → Leiden over HCG, GCH and Hi-C; atlas correlation to name the clusters; UMAPs and marker heatmaps. |
| `fig3_apa.ipynb` | Python (`hic_cooler`), 7 code cells. Differential-loop APA at 25 kb, each cell type's loops piled up in every cell type's Hi-C. |

## The annotation

`250kb_denovo/annotation/` is canonical — 1,577 cells:

| type | n | | type | n |
|---|---|---|---|---|
| IT-L5/6 | 249 | | ODC | 174 |
| ASC | 225 | | Inhib | 135 |
| IT-L2/3 | 199 | | MGC | 99 |
| CT-L6 | 193 | | OPC | 69 |
| IT-L4 | 176 | | PC/EC | 58 |

Leiden on the HCG Harmony embedding: `n_pc = 9`, `K = 20`, `resolution = 0.8`,
seed 42, unweighted `cccd::nng` kNN graph. Cluster identities come from genome-wide
Spearman correlation against the CEMBA isocortex reference. Markers for the heatmaps
are Liu et al. 2021 Supplementary Table 7, five genes per type.

## Re-running `fig3_umap.ipynb`

**Reuse the saved embeddings in `tables/`; do not recompute them.** §4a/§6b carry no
stored output for this reason — their `impute.knn(maxp = "p")` over 10,381 bins is a
multi-hour job, and the labels on disk came from an unseeded call, so recomputing
lands ~15 cells away (99.05%, ARI 0.976) and would desynchronise the APA cell table.
Reading the saved SVDs reproduces the annotation exactly (1,577/1,577). With the
saved values the notebook runs in under four minutes.

Note also that a saved 15-significant-digit text table is enough to move a UMAP
layout visibly, even though clustering is unaffected. §8.7c.1 recomputes its layout
from those tables deterministically; §4b, §6c and §8.7a use the in-memory embeddings.

**§8e must run before §8.5** — it defines `marker_lists`.

## The APA panel

34,150 of 49,196 loops are confidently assigned. The diagonal is the strict maximum
of both its row and its column for **10/10** cell types.

- Loop specificity: `FC_THRESH = 2` — a loop is assigned to a cell type when fc(Q)
  and fc(T) both exceed 2 against the mean of the other nine.
- Colour scale: `PowerNorm(gamma=2)`, fixed `vmin = 0.2`, `vmax = 0.75`, one shared
  colourbar. The limits are deliberately not percentile-derived — the 1st percentile
  is the empty corner (~0.02), which drags nearly every pixel up the colour axis.
- Cell-type order is IT-L2/3, IT-L4, IT-L5/6, CT-L6, Inhib, ASC, ODC, OPC, MGC,
  PC/EC. §5 permutes the cached `apa_25kb.npz` if `LEG` has been reordered since it
  was built; without that guard a reordering would silently mislabel every panel.
- Per-panel APA scores are reported as a table in §7 rather than drawn over the grid.

IT-L5/6 has no marker gene in either mCG or GCH. Hi-C took no part in the
clustering, the atlas assignment or the marker selection, so its clean diagonal
(23.39 vs 18.71 for its best competitor) is independent evidence that it is a real
cell type. The same holds for the merged `Inhib` group.
