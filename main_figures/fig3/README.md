# Figure 3 — mouse cortex cell types

Mouse cortex scNOMe-HiC, **1,577 cells**, ten cell types called de novo from this
paper's own data. Inputs come from `work/mouse_cortex/`, written by
`../../data_processing/mouse_cortex/`.

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

Of 49,196 loops in the union call, **5,826 are confidently assigned** to a cell
type, and **2,051** of those survive the minimum-separation cut and are piled up
(20,510 windows). The diagonal is the strict maximum of both its row and its
column for **8/10** cell types.

- Loop specificity: `FC_THRESH = 2` — a loop is assigned to a cell type when fc(Q)
  and fc(T) both exceed 2 against the mean of the other nine.
- Minimum separation: `MIN_SEP = 2 * HALF` (20 bins, 500 kb). A window spans
  +/-HALF on both axes, so a shorter loop's window crosses the main diagonal,
  where `E` is a constant 1.0 by construction rather than a measured O/E. Since
  the APA score divides by the bottom-left corner — the corner nearest the
  diagonal — that contamination biases every score. See "Two bugs" below.
- Cell-type order is IT-L2/3, IT-L4, IT-L5/6, CT-L6, Inhib, ASC, ODC, OPC, MGC,
  PC/EC. §5 permutes the cached `apa_25kb.npz` if `LEG` has been reordered since it
  was built; without that guard a reordering would silently mislabel every panel.
- Per-panel APA scores are reported as a table in §7 rather than drawn over the grid.

### Per-cell-type scores

| cell type | APA score | windows |
|---|---|---|
| IT-L2/3 | 4.27 | 215 |
| IT-L4 | 4.82 | 214 |
| IT-L5/6 | 3.54 | 59 |
| CT-L6 | 4.58 | 45 |
| Inhib | 4.34 | 408 |
| ASC | 7.04 | 33 |
| ODC | 4.09 | 17 |
| OPC | 7.98 | 465 |
| MGC | 4.58 | 193 |
| PC/EC | 9.52 | 402 |

**ODC (17 loops) and IT-L5/6 (59 loops) are too thinly populated to carry a
per-panel claim**, and both score below a rival cell type (ODC 4.09 against ASC
5.39; IT-L5/6 3.54 against PC/EC 3.94). Read the panel grid as a whole, not
those two cells.

An earlier version of this file argued that IT-L5/6's "clean diagonal (23.39 vs
18.71)" was independent evidence that it is a real cell type, since Hi-C took no
part in the clustering or the annotation. **That argument does not survive the
fixes below** — the 23.39 came from a corrupted pile-up, and on corrected data
IT-L5/6 does not win its own row. IT-L5/6 still has no marker gene in either mCG
or GCH, so it now rests on the atlas correlation alone.

### Two bugs, fixed 2026-10-23

**1. The O/E lower triangle was never filled.** `E` was written only at
`(i, i+k)` for `k >= 0`. A loop window pixel `(a, b)` lands in the unwritten half
whenever `a - b >` the loop's span in bins, so 65% of loops contributed zeros to
the lower-left of their window. Those zeros also pinned the per-window minimum at
zero, flattening the min-max normalisation. The lower-left half of the published
panel averaged 0.40x the upper-right; the bottom-left corner pixel was 7.9x
darker than the top-right. Because the APA score is centre / bottom-left-corner,
every score was inflated several-fold. Contact matrices are symmetric, so §5 now
mirrors: `E = E + E.T - np.diag(np.diag(E))`.

**2. The pile-up cache was keyed on existence alone.** Re-running §2 and §4 with
a different loop set and then reloading `apa_25kb.npz` silently reused the old
pile-up. That is what happened to the Aug-2026 panel: 340,660 windows from a loop
set that `loop_assignments.tsv` no longer described (it holds 58,240 unfiltered).
§5 now records a per-group loop fingerprint in the npz and recomputes, with a
printed explanation, when it does not match.

Measured on the same loop set, so only the fill differs:

| variant | panel symmetry | corners agree | on-diagonal | contrast |
|---|---|---|---|---|
| neither fix | 0.56 | 3.93 | 15.39 | 2.35 |
| mirror only | 1.11 | 0.65 | 2.65 | 1.78 |
| **mirror + MIN_SEP (published)** | **1.00** | **1.09** | **5.48** | **2.34** |

Mirroring alone overshoots because the short loops it readmits cross the diagonal;
the separation cut is what makes both diagnostics come out clean. The contrast
between matched and mismatched cell types — what the panel actually claims — is
2.34, essentially unchanged from the uncorrected 2.35, but now for the right
reason. The absolute scores move by ~3x.

`../../data_processing/bulk_others/04_hic_loops/apa_pileup_insitu.py`, which does
the same pile-up for Figure 2, was checked and is unaffected: its own distance
filter keeps its panels symmetric (measured 0.99 at flank 8, 0.97 at flank 10).
