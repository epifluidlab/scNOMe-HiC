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

## Why §8.7c.1 reuses the saved layout

§8.7c.1 loads `tables/joint_umap_uncorrected.txt` when it exists and only
recomputes when it does not. That guard is deliberate.

`umap()` is **not reproducible across re-runs of this cell**. It reads the raw
SVDs from `tables/`, which `write.table` stored to 15 significant digits, and that
rounding moves the resulting layout about as much as changing the random seed
does. Measured on a 700-cell subsample at k = 30:

| comparison | neighbour overlap |
|---|---|
| saved layout vs a fresh recompute | 0.750 |
| fresh recompute vs another seed, identical data | 0.734 |

The saved layout sits *inside* the seed-to-seed baseline. And all three preserve
the high-dimensional neighbourhoods equally well — 0.464 (saved), 0.466 (fresh),
0.4655 (alt seed) — so the saved layout is not stale, and recomputing is not more
correct. It is a different draw of the same structure.

Because neither is more correct, the notebook reuses the published one, which
keeps panel A's "before correction" half identical to the shipped figure. Delete
`joint_umap_uncorrected.txt` to force a fresh embedding; expect the panel to look
different if you do.

The same instability affects §4b, §6c and §8.7a in the Fig-3 UMAP notebook, whose
README documents it — reuse the saved embeddings there rather than recomputing.

## Not included

The `s7/` folder in `../../../scnomehic_paper/` holds an **older, unrelated**
supplementary figure (library-complexity and sequencing-saturation curves, Jun
2026). The supplementary numbering has since been reshuffled; none of that code
is used here.
