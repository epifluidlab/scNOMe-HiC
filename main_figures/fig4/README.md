# Figure 4 — meningioma: copy number and multi-modal clustering

Human meningioma, two patients, **292 cells** (348 sequenced → 294 pass methylation
QC → 292 survive the Hi-C usability gate). Inputs come from
`../../data_processing/meningioma/`.

| Panel | File | Made by |
|---|---|---|
| Copy-number heatmap, three sub-clone groups | `cna_approach3_chr1p_chr22q.pdf` | `fig4_cna.ipynb`, Approach 3 |
| Four-panel UMAPs coloured by cell type | `final_umap_fig4b_joint.pdf` | `fig4_umap.ipynb` §8c |

`final_umap_fig4b_joint.pdf` also appears in **Supplementary Figure S8**, beside
`final_umap_fig4b_hcg.pdf` — the same four panels under the HCG-based annotation.

| Notebook | Kernel | Produces |
|---|---|---|
| `fig4_cna.ipynb` | Python (`scnomehic_python`) | the copy-number heatmap, and `tables/cna_approach3_clusters.txt` |
| `fig4_umap.ipynb` | R (`nomehic_r`) | the per-modality and joint embeddings, the cell-type annotation, and the §8c panels |

**Run `fig4_cna.ipynb` first.** It writes the CNA group labels that the UMAP
notebook reads in §7 and colours by throughout.

## Copy number

Fragment counts in 1 Mb bins (`04_cna/01_build_cna_1M.sh`) stand in for copy
number. The notebook median-normalises, clusters cells, and calls sub-clones.

**Approach 3** is the one that ships: chr1p **and** chr22q together, giving three
groups — normal/diploid, 22q-loss, and 1p+22q-loss. chr22q is the NF2 locus, the
canonical meningioma driver. Two earlier approaches (chr22q GMM alone; chr22q as
a weighted feature) are not included — see `FILES.md`.

The base heatmap cell is kept ahead of it: it is the unclustered copy-number view
the sub-clone calling is read against.

## The embeddings are frozen — read this before re-running

`fig4_umap.ipynb` computes three Harmony embeddings and four UMAP layouts. Those
are **not portable**: the same code on the same input gives a different layout
under a different R build. Measured on this dataset — the chain is bit-identical
across processes within one environment, but R 4.3.3 and R 4.4.2 disagree, and
the figures published in July were not reproduced by either. The Leiden labels
are unaffected: every cluster, cell type and CNA group reproduced exactly.

So each embedding is computed once and cached at full precision:

```
tables/frozen/{HCG,HIC,GCH}_harm.rds
tables/frozen/{HCG,HIC,GCH,JOINT}_umap.rds
```

`freeze()` in §1 loads these when present and only computes when they are absent,
so re-running the notebook reproduces the figures exactly rather than redrawing
them. `.rds` rather than a text table is deliberate — a 15-significant-digit text
round-trip is by itself enough to move a UMAP.

**Delete `tables/frozen/` to recompute from scratch**, and expect a different
layout if the environment has changed since. The kernel is pinned to `nomehic_r`
for the same reason.

## Cell-type annotation

§8b writes **two** annotations, and both are kept because both are published:

| | tumor1 | monocyte | tumor2 | used by |
|---|---|---|---|---|
| `cell_type_joint` | 122 | 91 | 79 | **Figure 4** and S8 |
| `cell_type_hcg` | 118 | 108 | 66 | S8 only |

They disagree on 17 cells, at the monocyte/tumor2 boundary. **The paper uses
`cell_type_joint`** — Leiden on the joint embedding, so all three modalities
contribute. §8d supports that choice quantitatively: the joint embedding tracks
the CNA groups better than any single modality.

## Inputs

From `../../data_processing/meningioma/`:

- `subset_clustering/250kb/CNA.1M.txt` — 1 Mb fragment counts (step `04_cna`)
- `QC/methylation_matrices/methylation_matrix_{GCH,HCG}_250kb.tsv.gz` (step `02_qc`)
- `06.hiccluster_snakemake/hicluster_250kb_embed_dir_all3/` (step `03_hic`)
- `QC/meningioma_passed_hicusable.txt` — the 292-cell set
