# FILES — fig4/

`$A` = `meningioma_scnomehic/snakemake/subset_clustering/250kb/all_batches`

| File | What it is | Origin |
|---|---|---|
| `README.md` | Panels, the freeze, the two cell-type annotations. | written for this repo |
| `FILES.md` | This file. | written for this repo |
| `fig4_cna.ipynb` | Python, 5 code cells, kernel `scnomehic_python`. 1 Mb fragment counts → median-normalised copy-number heatmap → chr1p + chr22q sub-clone calling. Writes `figures/cna_approach3_chr1p_chr22q.{pdf,png}` and `tables/cna_approach3_clusters.txt`. 3 figures, no errors. | `$A/CNA.ipynb` |
| `fig4_umap.ipynb` | R, 16 code cells, kernel `nomehic_r`. Per-modality embeddings (HCG / Hi-C / GCH) → Harmony → UMAP + Leiden, joint embedding, cell-type annotation, the §8c four-panel figures, §8d concordance, §9 saves. 15 of 16 cells carry outputs — 11 figures, no errors. | `$A/subset_final_snakemake.ipynb` |

## What was trimmed

**`fig4_cna.ipynb`** — the source has 11 code cells; 5 are kept:

| kept | why |
|---|---|
| 0 | imports |
| 1 | loads `CNA.1M.txt` and builds the cell metadata |
| 2 | the base copy-number heatmap — the unclustered view the calling is read against |
| 3 | shared helpers for the chr22q calling: centromere positions, palettes, `SUBCLONE_N`, `MIN_CLONE`, `ARM_WEIGHT`, `norm22` |
| 6 | **Approach 3** — the panel, plus `cna_approach3_clusters.txt` |

Dropped: cells 4 and 5 (Approaches 1 and 2) and four trailing empty cells.
Markdown headers went with their code cells.

**`fig4_umap.ipynb`** is shipped whole. Its §7/§8/§8b/§8d sections are not
panels, but every one of them is on the path to §8c — §7 attaches the CNA groups,
§8 builds the joint embedding, §8b writes both annotations, §9 saves
`final_metadata.tsv`. §8d is the quantitative support for choosing the joint
annotation over the HCG one, so it is kept as the record of that decision.

Only the last cell is unexecuted, and it is empty.

## Deliberately not included

- **Approach 1 (`cna_approach1_chr22q_gmm`) and Approach 2
  (`cna_approach2_chr22q_weighted`)** — two earlier chr22q-only sub-clone
  callings. Approach 3 (chr1p + chr22q, three groups) is the published one and is
  what `cna_approach3_clusters.txt` — read by the UMAP notebook — comes from.
  The alternatives are superseded, not complementary.
- **`$A/cna_umap.ipynb`** — a third notebook, entirely unexecuted (0 of 8 cells),
  overlapping the CNA-coloured UMAPs that `fig4_umap.ipynb` §7/§8c already draw.
- **`$A/subset_final_snakemake_exploration.ipynb`** — the n_pc × k parameter
  sweep that fixed the locked settings (HCG 20/25, Hi-C 5/25, GCH 9/25, res 0.2).
  Exploration; the final notebook states the chosen values directly.
- **`$A/deconv/`** and `code/deconv_*` — the deconvolution analysis, pending a
  decision on whether it is a paper panel.
- **`250kb/batch2_3/`** — the 142-cell batch2+3 variant, abandoned in June.

## On `plotheatmap`

`fig4_cna.ipynb` is self-contained: the heatmap plotting is **defined inline** in
its first cell (~16 KB of vendored source), not imported. The separate
`$A/../../../code/plotheatmap_src.py` in the working tree is a second copy of the
same code, used by other scripts there; nothing in this repo depends on it, so it
is correctly excluded from `data_processing/meningioma/`.

That inline copy is why cell 0 is large and why it is kept despite producing no
output — every later cell calls into it.
