# Figure 4 — meningioma: copy number and multi-modal clustering

Human meningioma, two patients, **292 cells** (348 sequenced → 294 pass methylation
QC → 292 survive the Hi-C usability gate). Inputs come from
`../../data_processing/meningioma/`.

| Panel | File | Made by |
|---|---|---|
| Copy-number heatmap, three sub-clone groups | `cna_approach3_chr1p_chr22q.pdf` | `fig4_cna.ipynb`, Approach 3 |
| Four-panel UMAPs coloured by cell type | `final_umap_fig4b_joint.pdf` | `fig4_umap.ipynb` §8c |
| Embedding–CNA concordance, **NMI facet** | `embedding_cna_concordance_signif.pdf` | `fig4_umap.ipynb` §8d |
| Tumour vs non-tumour cell-type deconvolution | `celltype_difference_barplot.pdf` | `fig4_deconv_barplot.ipynb` |

**Also in Supplementary Figure S8:** `final_umap_fig4b_joint.pdf` beside
`final_umap_fig4b_hcg.pdf` (the same four panels under the HCG annotation), and
the **kNN-purity and ARI facets** of the concordance figure.

§8d draws all three metrics as one faceted figure —
`embedding_cna_concordance_signif.pdf` contains kNN purity, ARI and NMI side by
side. The main figure uses the NMI facet and S8 the other two, so the split is
made when the panel is laid out, not by the notebook.

| Notebook | Kernel | Produces |
|---|---|---|
| `fig4_cna.ipynb` | Python (`scnomehic_python`) | the copy-number heatmap, and `tables/cna_approach3_clusters.txt` |
| `fig4_umap.ipynb` | R (`nomehic_r`) | the per-modality and joint embeddings, the cell-type annotation, the §8c panels and the §8d concordance |
| `fig4_deconv_barplot.ipynb` | Python (`scnomehic`) | the tumour vs non-tumour difference barplot, from `deconv/output.csv` |

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

**Verified, not assumed.** A second run reported `[frozen]` for all seven
embeddings with none recomputed, and `final_umap_{hcg,hic,gch,joint}.tsv` and
`final_metadata.tsv` all came back **bit-identical**. Note this buys
reproducibility rather than speed — the two runs took 313 s and 320 s, because
the imputation and SVD ahead of Harmony still run each time. Those are
deterministic (checked across three separate processes), so they are a cost, not
a risk.

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

## Deconvolution — note the annotation

The deconvolution splits cells into tumour and non-tumour, merges their BAMs,
and runs UXM against the Loyfer brain atlas; the barplot is the per-cell-type
fraction difference (non-tumour − tumour). The chain is
`../../data_processing/meningioma/05_deconv/`, and the barplot is drawn here from
its `output.csv`.

**The split is copy-number driven**, which is the definition that matches what
the deconvolution asks: chr22q carries NF2, the truncal meningioma event, so
"has the driver lesion" defines tumour rather than any methylation clustering.

```
cna_group 1  chr22q intact             ->  non-tumour   96 cells
cna_group 2  chr22q loss               ->  tumour      196 cells
cna_group 3  chr22q loss + chr1p loss  ->  tumour
```

An earlier version split on `cell_type_hcg` (184 / 108). That was changed because
it disagreed with copy number on **30 cells** — 21 cells with a 22q loss were
pooled into the non-tumour methylome, and 9 diploid cells into the tumour one.
The published-but-superseded outputs are kept in `deconv/published_hcg_split/`.

Worth noting as independent support for the annotation choice: the CNA split
disagrees with `cell_type_joint` on only **13** cells against **30** for
`cell_type_hcg` — the same ordering §8d finds.

To split on an annotation instead, set `SPLIT` in
`05_deconv/01_make_cell_lists.py`; the BAM merge and UXM step then have to be
redone, which is the expensive part (job 3894488, 1 h 07 m).

Changing the split moved the deconvolution modestly: the largest shift is
**Blood-Mono+Macro at 0.046**, then Megakaryocytes 0.030, Smooth-Muscle 0.021 and
Microglia 0.019, across 42 atlas cell types. The direction of the barplot is
unchanged — the contamination the old split carried was real, but not large
enough to reverse the result.

## Inputs

From `../../data_processing/meningioma/`:

- `subset_clustering/250kb/CNA.1M.txt` — 1 Mb fragment counts (step `04_cna`)
- `QC/methylation_matrices/methylation_matrix_{GCH,HCG}_250kb.tsv.gz` (step `02_qc`)
- `06.hiccluster_snakemake/hicluster_250kb_embed_dir_all3/` (step `03_hic`)
- `QC/meningioma_passed_hicusable.txt` — the 292-cell set
