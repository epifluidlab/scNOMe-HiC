# Supplementary Figure S7 — QC / batch diagnostics on the integrated UMAP

Mouse cortex, 1,577 QC-passing cells. Panels A–F drawn on the joint
three-modality embedding, showing that the biological-replicate split is removed
by Harmony and that no per-cell QC measure structures the embedding.

| Panel | Colour |
|---|---|
| A (×2) | biological replicate, **before** and **after** Harmony |
| B | library-prep batch (date) |
| C | uniquely aligned reads, log10 |
| D | % aligned reads (MAPQ ≥ 30) |
| E | bisulfite incomplete-conversion rate (chrM non-CpG) |
| F | % cis reads |

| Notebook | Kernel | Output |
|---|---|---|
| `figS7_qc_panels.ipynb` | R (`nomehic_r`) | `joint_umap_qc_panels.{pdf,png}` |

## Where this code comes from

These are **§1, §2 and §8.7c of `../../main_figures/fig3/fig3_umap.ipynb`**, kept
under their original section numbers so they stay traceable to that notebook. The
extraction is self-contained because both §8.7c cells were written to be
resume-friendly: each falls back to reading from disk when the in-session object
is absent.

| § | What it does | Reads if not in session |
|---|---|---|
| §1 | setup — `WORKDIR`, `OUT_TAB`, `OUT_FIG`, libraries | — |
| §2 | helpers — `ggsave_both` | — |
| §8.7c.1 | rebuilds the **uncorrected** (pre-Harmony) joint embedding, the "before" half of panel A | `tables/{hcg,hic,gch}_svd_raw.txt` |
| §8.7c.2 | draws the panels | `annotation/metadata_with_cell_type.txt`, `tables/joint_umap.txt`, `tables/joint_umap_uncorrected.txt` |

So it runs without the §4–§8 embedding chain, against
`subset_clustering/250kb_denovo/{tables,annotation}/`.

## Inputs

All from `../../data_processing/mouse_cortex/`:

- `tables/{hcg,hic,gch}_svd_raw.txt` — pre-Harmony SVDs (§4a / §5a / §6b)
- `tables/joint_umap.txt` — the Harmony-corrected joint layout (§8.7a)
- `tables/joint_umap_uncorrected.txt` — the uncorrected layout, if reusing it
- `annotation/metadata_with_cell_type.txt` — 1,577 cells × 32 fields. Panels B–F
  read `library_prep_date`, `mapq30num`, `mapq30rate`, `noncpg_chrM`, `cisnum`,
  `transnum` from it; the cell asserts `library_prep_date` is present rather than
  reading any sample sheet ad hoc.

## One caveat if you re-run it

§8.7c.1 **recomputes** the uncorrected joint UMAP rather than loading the cached
one — its disk fallback covers the input SVDs, not the output layout. `umap()` is
sensitive enough that a recomputed layout can differ visibly from
`tables/joint_umap_uncorrected.txt` while carrying the same structure, so the
"before correction" half of panel A may not land pixel-identical to the shipped
figure. The stored outputs in this notebook were produced against the shipped
layout. Load `joint_umap_uncorrected.txt` before running §8.7c.2 if you need to
reproduce the shipped panel exactly.

The same point applies to the Fig-3 UMAP notebook and is documented there.

## Not included

The `s7/` folder in `../../../scnomehic_paper/` holds an **older, unrelated**
supplementary figure (library-complexity and sequencing-saturation curves, Jun
2026). The supplementary numbering has since been reshuffled; none of that code
is used here.
