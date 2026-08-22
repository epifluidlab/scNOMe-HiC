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

The cells come from **`../../main_figures/fig3/fig3_umap.ipynb`**, where these
panels are §8.7c. They are renumbered §1–§4 here so the notebook reads in its own
order; the table below gives both names. The extraction is self-contained because
the §8.7c cells were written to be resume-friendly: each falls back to reading
from disk when the in-session object is absent.

| here | in `fig3_umap.ipynb` | What it does | Reads if not in session |
|---|---|---|---|
| §1 | §1 | setup — `WORKDIR`, `OUT_TAB`, `OUT_FIG`, libraries | — |
| §2 | §2 | helpers — `ggsave_both` | — |
| §3 | §8.7c.1 | rebuilds the **uncorrected** (pre-Harmony) joint embedding, the "before" half of panel A | `tables/{hcg,hic,gch}_svd_raw.txt` |
| §4 | §8.7c.2 | draws the panels | `annotation/metadata_with_cell_type.txt`, `tables/joint_umap.txt` |

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

## §3 recomputes — and that is deliberate

§3 rebuilds the uncorrected joint embedding from `tables/{hcg,hic,gch}_svd_raw.txt`
every time. It is **deterministic**: two independent recomputes — one a standalone
`Rscript`, one through the notebook — agree to `0.000e+00`. Run this notebook and
you get exactly the layout it shows.

That was not true before 2026-08-21. The layout previously on disk
(`joint_umap_uncorrected.txt`, written 2026-08-11 23:28) could not be regenerated
by any code path, and differed from a recompute by up to **13.0 units**.

The cause was a precision fork in the cell:

```r
hcg_raw <- if (exists("HCG.svd")) HCG.svd[, seq_len(9), drop = FALSE] else rd_tab("hcg_svd_raw.txt")
```

The Aug-11 layout was produced in a live session where §4a–§6b had already run, so
the cell used the **full-precision in-memory** SVDs. Any standalone run takes the
`else` branch and reads the text files, which `write.table` stored at 15
significant digits — a lossy round-trip for a double (it alters ~93 % of values at
~5e-15 relative). `umap()` is chaotic enough at that scale to reorganise the
layout: elsewhere in this pipeline a 1e-15 difference in the Harmony embedding
moved the UMAP by 8 units.

Neither layout was more faithful to the data — measured neighbourhood
preservation was 0.464 (Aug-11) against 0.466 (recompute), and the two differed
from each other no more than two random seeds do. So the unreproducible one was
retired in favour of the one the notebook can regenerate.

The superseded files are kept in
`250kb_denovo/archive_superseded/joint_umap_uncorrected.aug11_session_artifact.txt`
and the matching `joint_umap_qc_panels.aug11_session_artifact.{pdf,png}`.

**§8.7c.1 in the Fig-3 notebook — §3 here — was the only cell with this fork.**
§4b, §6c and §8.7a there contain no `exists()` branch and read no tables — they take their input
from the in-memory embeddings, so they are deterministic and a full run reproduces
them exactly. Their separate caveat is the unseeded `impute.knn` in §4a/§6b, which
is documented in that folder's README and is unrelated to serialisation.

## Not included

The `s7/` folder in `../../../scnomehic_paper/` holds an **older, unrelated**
supplementary figure (library-complexity and sequencing-saturation curves, Jun
2026). The supplementary numbering has since been reshuffled; none of that code
is used here.
