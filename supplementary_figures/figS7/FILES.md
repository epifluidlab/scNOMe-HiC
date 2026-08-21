# FILES — figS7/

| File | What it is | Origin |
|---|---|---|
| `README.md` | Panels, where the code comes from, inputs, the re-run caveat. | written for this repo |
| `FILES.md` | This file. | written for this repo |
| `figS7_qc_panels.ipynb` | R, 4 code cells, kernel `nomehic_r`. §1 setup, §2 helpers, §8.7c.1 uncorrected joint embedding, §8.7c.2 the QC/batch panels. Carries its outputs — 1 figure, no errors. | `main_figures/fig3/fig3_umap.ipynb`, code cells 0, 1, 23, 24 |

## How it was assembled

Four cells lifted verbatim from `fig3_umap.ipynb` — no source edits, no path
rewriting, outputs carried over as-is rather than re-executed. Two markdown cells
were added: a title cell, and a `## §8.7c` section header explaining the jump from
§2 to §8.7c.

The original § numbers are kept deliberately. Renumbering them to §1–§4 would
break the correspondence with the Fig-3 notebook, where these panels also appear,
and the repo convention is not to change what code says about itself.

## Relationship to `main_figures/fig3/`

The same four cells exist in `fig3_umap.ipynb`. That notebook is the full
analysis; this one is the S7 extract. They are not independent copies of an
algorithm — they are the same cells, so a change to §8.7c must be made in both.
`fig3_umap.ipynb` is the source of truth.

## Inputs it reads

| Path (working tree, under `subset_clustering/250kb_denovo/`) | Written by |
|---|---|
| `tables/hcg_svd_raw.txt` | fig3_umap.ipynb §4a |
| `tables/hic_svd_raw.txt` | fig3_umap.ipynb §5a |
| `tables/gch_svd_raw.txt` | fig3_umap.ipynb §6b |
| `tables/joint_umap.txt` | fig3_umap.ipynb §8.7a |
| `tables/joint_umap_uncorrected.txt` | fig3_umap.ipynb §8.7c.1 |
| `annotation/metadata_with_cell_type.txt` | fig3_umap.ipynb §9 |

## Deliberately not included

- **`scnomehic_paper/s7/`** — library-complexity and saturation analysis
  (`s7_saturation*.pdf`, `s7_library_complexity.pdf`) with its own `code/`
  directory of SLURM scripts. That is an older supplementary figure from before
  the numbering was reshuffled, not this one, and shares no code with it.
- The rest of `fig3_umap.ipynb` — §3–§8.5c, §8.7a/b, §8.8, §9/§9b. Those are the
  Figure 3 panels and the annotation writeout, covered in `main_figures/fig3/`.
