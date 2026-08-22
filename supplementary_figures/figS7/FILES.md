# FILES — figS7/

| File | What it is | Origin |
|---|---|---|
| `README.md` | Panels, where the code comes from, inputs, the re-run caveat. | written for this repo |
| `FILES.md` | This file. | written for this repo |
| `figS7_qc_panels.ipynb` | R, 4 code cells, kernel `nomehic_r`. §1 setup, §2 helpers, §3 uncorrected joint embedding, §4 the QC/batch panels. Carries its outputs — 1 figure, no errors. | `main_figures/fig3/fig3_umap.ipynb`, code cells 0, 1, 23, 24 (its §1, §2, §8.7c.1, §8.7c.2) |

## How it was assembled

Four cells lifted from `fig3_umap.ipynb` — no path rewriting, outputs carried
over as-is rather than re-executed. Two markdown cells were added: a title cell
and a section header for §3.

**Renumbered §1–§4.** The cells arrive as fig3's §1, §2, §8.7c.1 and §8.7c.2;
carrying §8.7c into a four-cell notebook left the reader hunting for a §3 through
§8.7b that are not here. The section comments were renumbered to match, and every
reference that genuinely points at the Fig-3 notebook now names it. Two dead
lines went with the renumber — `PARENT` and `REF_DIR`, the latter commented as
feeding a §8d concordance check that is in neither notebook; nothing referenced
either.

## Relationship to `main_figures/fig3/`

The same four cells exist in `fig3_umap.ipynb`. That notebook is the full
analysis; this one is the S7 extract. They are not independent copies of an
algorithm — they are the same cells, so a change to §3/§4 here (§8.7c there)
must be made in both.
`fig3_umap.ipynb` is the source of truth.

## Inputs it reads

| Path (working tree, under `subset_clustering/250kb_denovo/`) | Written by |
|---|---|
| `tables/hcg_svd_raw.txt` | fig3_umap.ipynb §4a |
| `tables/hic_svd_raw.txt` | fig3_umap.ipynb §5a |
| `tables/gch_svd_raw.txt` | fig3_umap.ipynb §6b |
| `tables/joint_umap.txt` | fig3_umap.ipynb §8.7a |
| `tables/joint_umap_uncorrected.txt` | fig3_umap.ipynb §8.7c.1 — **regenerated 2026-08-21**; the previous file was an unreproducible session artifact, now in `archive_superseded/` |
| `annotation/metadata_with_cell_type.txt` | fig3_umap.ipynb §9 |

## Deliberately not included

- **`scnomehic_paper/s7/`** — library-complexity and saturation analysis
  (`s7_saturation*.pdf`, `s7_library_complexity.pdf`) with its own `code/`
  directory of SLURM scripts. That is an older supplementary figure from before
  the numbering was reshuffled, not this one, and shares no code with it.
- The rest of `fig3_umap.ipynb` — §3–§8.5c, §8.7a/b, §8.8, §9/§9b. Those are the
  Figure 3 panels and the annotation writeout, covered in `main_figures/fig3/`.
