# Figure 3 — mouse cortex cell types

Mouse cortex scNOMe-HiC, **1,577 cells**. Cell types are derived **de novo** from this
paper's own data, then shown across three modalities: methylation, accessibility, and
3D contacts.

Inputs come from `../../data_processing/mouse_cortex/`.

| Notebook | Kernel | Published panels |
|---|---|---|
| `fig3_umap.ipynb` | R (`nomehic_r`) | `umap_fig4b_style.pdf`, `marker_gene_heatmap_HCG_gene.pdf`, `marker_gene_heatmap_GCH_gene.pdf` |
| `fig3_apa.ipynb` | Python (`hic_cooler`) | `all_diffloop_apa_powernorm_sharedcbar.pdf` |

> Both notebooks are copied whole, not yet trimmed.

## The annotation

`250kb_denovo/annotation/` is **canonical** — 1,577 cells, ten types:

| type | n | | type | n |
|---|---|---|---|---|
| IT-L5/6 | 249 | | ODC | 174 |
| ASC | 225 | | Inhib | 135 |
| IT-L2/3 | 199 | | MGC | 99 |
| CT-L6 | 193 | | OPC | 69 |
| IT-L4 | 176 | | PC/EC | 58 |

Everything downstream reads it: the UMAPs, the marker heatmaps, and the APA. The APA
cell table was checked against it cell-by-cell — **1,577/1,577 identical**.

Two other annotation directories exist in the source tree and are **not** canonical:
`annotation_k20_r0.3/` (a superseded scanpy intermediate, differing on 23 cells) and
`annotation_consensus12_backup/` (a retired 12-type consensus). Neither is shipped.

Clustering is a plain single-seed Leiden on the HCG Harmony embedding — `n_pc = 9`,
`K = 20`, `resolution = 0.8`, seed 42, on an unweighted `cccd::nng` kNN graph. Cluster
identities come from genome-wide Spearman correlation against the CEMBA isocortex
reference, with no hand-picked markers; the marker panel used for the heatmaps is
Liu et al. 2021 Supplementary Table 7, five genes per type, chosen independently of
these data.

## Re-executing `fig3_umap.ipynb`

The notebook now carries its outputs: 12 figures, no errors. Every cell has stored
output except §1/§2 (which print nothing) and **§4a/§6b**, which are deliberately
left unexecuted — see below.

**Reuse the saved embeddings; do not recompute them.** The outputs were produced by
re-running the notebook with four values loaded from `tables/` instead of recomputed:
the HCG and GCH SVDs (`hcg_svd_raw.txt` top-9, `gch_svd_raw.txt` top-20) and the HCG,
GCH and joint UMAP layouts. Two reasons, both verified rather than assumed:

1. **The annotation.** The labels on disk came from an **unseeded** `impute.knn`.
   Both calls are seeded now, so recomputing is deterministic but lands ~15 cells
   away (99.05 %, ARI 0.976) — which would desynchronise the APA, whose cell table
   matches the current annotation 1,577/1,577. Reusing the saved SVD reproduces the
   annotation **exactly: 1,577/1,577, zero disagreements**, with the same cluster
   sizes (249/225/199/193/176/174/135/99/69/58) and an §8a embedding checksum that
   matches the recorded value to the last digit.
2. **The UMAP layouts.** `write.table` stores the SVD to 15 significant digits.
   Harmony passes that ~1e-15 through unchanged, but `umap()`'s optimiser amplifies
   it into a visibly different layout (max |diff| ≈ 8 units). Clustering is immune —
   this is why the annotation still reproduces exactly — but the scatter panels would
   stop matching the published PDFs. `hic_umap` is unaffected, being read straight
   from the hicluster HDF5 with no round-trip.

With both reused, the regenerated figures match the shipped PDFs pixel-for-pixel:
all three marker heatmaps, `annotation_umaps_celltype`, `atlas_correlation_heatmap`
and `hic` are **identical**. `umap_fig4b_style` differs by a ~3 px offset from PDF
font metrics (headless vs interactive), with the point clouds matching to 0.4 % in
coloured-pixel count — a rendering difference, not a data one.

**Why the saved layouts and the code can disagree.** Cells like §8.7c.1 pick their
input with `if (exists("HCG.svd")) ... else rd_tab("hcg_svd_raw.txt")`. Run inside
a full session they use the full-precision in-memory SVDs; run standalone they
read the text tables, which `write.table` stored at 15 significant digits — lossy
for a double, ~5e-15 relative. `umap()` amplifies that into a visibly different
layout, which is exactly why the Harmony embedding above differs by 1e-15 while
its UMAP differs by 8 units.

§8.7c.1 was resolved on 2026-08-21 by **retiring its unreproducible saved layout**:
it now recomputes from the tables, deterministically (two independent recomputes
agree to 0.000e+00), and the figure was regenerated to match. The superseded files
are in `250kb_denovo/archive_superseded/*aug11_session_artifact*`.

§4b, §6c and §8.7a have the same fork and have **not** been resolved — their saved
layouts in `tables/` came from in-memory objects, so re-running those cells will
shift the Fig-3 panels. Reuse the saved layouts to reproduce the published
figures, or regenerate the panels as was done for §8.7c.1.

A full §4a→§9b pass from scratch is a multi-hour job: §4a's `impute.knn(maxp = "p")`
forces a full kNN over 10,381 bins. That is why §4a and §6b carry no stored output —
populating them honestly means paying that cost and accepting the ~15-cell shift.
With the shims, the whole notebook runs in **under four minutes**.

§8.5/§8.5b were edited after the original kernel run (restricted to the gene region,
plus a `Klh12` → `Klhl12` fix that restores ODC's fifth marker, 49 → 50 genes); their
stored outputs are now current. **§8e must run before §8.5** — it defines
`marker_lists`, and a stale kernel would otherwise plot the previous panel.

## The APA panel

Differential-loop APA at 25 kb across the ten types: each type's own loops piled up
in every type's Hi-C. The diagonal is the strict maximum of both its row and its
column for **10/10** types, from 34,150 confidently assigned loops out of 49,196.

This matters beyond the figure. **IT-L5/6 has no marker gene** in either mCG or GCH —
the annotation's one soft spot. Hi-C took no part in the clustering, the atlas
assignment, or the marker selection, so a clean IT-L5/6 diagonal (23.39 against 18.71
for its best competitor) is independent structural evidence that it is a real cell
type rather than a merge artefact. The same argument supports the merged `Inhib` group.

Colour scale is `PowerNorm(gamma=3)` with limits at the 1st/99.9th percentile across
all 100 panels and one shared colourbar. `GAMMA` in §6 is the knob worth retuning.
The gamma is a presentation choice, not a reproduction: no `_powernorm_sharedcbar`
version predates this analysis, so the contrast was tuned here.

## Not included

- **`scripts/regen_marker_heatmaps.R`** — a standalone reproduction of §8e + §8.5 +
  §8.5b + §8.5c, written to refresh the shipped PDFs without a kernel re-run. The
  notebook is the source of truth for these panels, so the script is not shipped.
- **`marker_gene_heatmap_*_gene_tss.*` and `*_gene_body.*`** — stale leftovers from an
  earlier three-region version; no longer produced.
- **`resolution_exploration.ipynb`**, `archive_superseded/`, and the `.bak` notebook
  copies — development history.
