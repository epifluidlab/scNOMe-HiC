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

## Do not re-execute `fig3_umap.ipynb`

Its stored outputs are **not all current** — §8.5/§8.5b were edited after the last
kernel run (restricted to the gene region, plus a `Klh12` → `Klhl12` fix that restores
ODC's fifth marker, 49 → 50 genes) — and the notebook is partly unexecuted.

Re-running would not simply refresh them. The shipped annotation came from an
**unseeded** run; both `impute.knn` calls are now seeded, so a rerun is deterministic
but lands ~15 cells away from the shipped labels (99.05 % agreement, ARI 0.976). A
full §4a→§9b pass is also a multi-hour job, because §4a's `impute.knn(maxp = "p")`
forces a full kNN over 10,381 bins.

So the stale outputs are a documented fact rather than something to repair. The
figures on disk are current; running §8e → §8.5 → §8.5b → §8.5c in order reproduces
them, and **§8e must run first** since it defines `marker_lists`.

## The APA panel

Differential-loop APA at 25 kb across the ten types: each type's own loops piled up
in every type's Hi-C. The diagonal is the strict maximum of both its row and its
column for **10/10** types, from 34,150 confidently assigned loops out of 49,196.

This matters beyond the figure. **IT-L5/6 has no marker gene** in either mCG or GCH —
the annotation's one soft spot. Hi-C took no part in the clustering, the atlas
assignment, or the marker selection, so a clean IT-L5/6 diagonal (23.39 against 18.71
for its best competitor) is independent structural evidence that it is a real cell
type rather than a merge artefact. The same argument supports the merged `Inhib` group.

Colour scale is `PowerNorm(gamma=0.5)` with limits at the 1st/99.5th percentile across
all 100 panels and one shared colourbar. `GAMMA` in §6 is the knob worth retuning.

## Not included

- **`scripts/regen_marker_heatmaps.R`** — a standalone reproduction of §8e + §8.5 +
  §8.5b + §8.5c, written to refresh the shipped PDFs without a kernel re-run. The
  notebook is the source of truth for these panels, so the script is not shipped.
- **`marker_gene_heatmap_*_gene_tss.*` and `*_gene_body.*`** — stale leftovers from an
  earlier three-region version; no longer produced.
- **`resolution_exploration.ipynb`**, `archive_superseded/`, and the `.bak` notebook
  copies — development history.
