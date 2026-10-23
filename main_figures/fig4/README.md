# Figure 4 — meningioma: copy number and multi-modal clustering

Human meningioma, two patients, **292 cells** (348 sequenced → 294 pass methylation
QC → 292 pass the Hi-C usability gate). Inputs come from
`../../data_processing/meningioma/`.

## Panels

| File | Made by |
|---|---|
| `cna_approach3_chr1p_chr22q.pdf` | `fig4_cna.ipynb` |
| `final_umap_fig4b_joint.pdf` | `fig4_umap.ipynb` §8c |
| `embedding_cna_concordance_signif.pdf` (NMI facet) | `fig4_umap.ipynb` §8d |
| `celltype_difference_barplot.pdf` | `fig4_deconv_barplot.ipynb` |

Supplementary Fig. S8 uses `final_umap_fig4b_hcg.pdf` beside the joint one, and the
kNN-purity and ARI facets of the concordance figure. §8d draws all three metrics as
one faceted PDF; the split between Fig. 4 and S8 is made at layout.

## Files

| File | What it is |
|---|---|
| `fig4_cna.ipynb` | Python (`scnomehic_python`), 5 code cells. 1 Mb fragment counts → median normalisation → sub-clone calling. Writes `tables/cna_approach3_clusters.txt`. |
| `fig4_umap.ipynb` | R (`nomehic_r`), 16 code cells. Three Harmony embeddings and four UMAPs, the cell-type annotation, the §8c panels and the §8d concordance. |
| `fig4_deconv_barplot.ipynb` | Python (`scnomehic`), 1 code cell. Tumour vs non-tumour cell-type difference barplot from `deconv/output.csv`. |

**Run `fig4_cna.ipynb` first** — it writes the CNA group labels the UMAP notebook
reads in §7.

## Copy number

Fragment counts in 1 Mb bins stand in for copy number. The shipped call (Approach 3)
uses chr1p and chr22q together, giving three groups: diploid, 22q-loss, and
1p+22q-loss. chr22q carries NF2, the canonical meningioma driver. The unclustered
heatmap cell is kept ahead of it as the view the calling is read against.

## Cell-type annotation

§8b writes two annotations; both are published:

| | tumor1 | macrophage | tumor2 | used by |
|---|---|---|---|---|
| `cell_type_joint` | 122 | 91 | 79 | **Figure 4** and S8 |
| `cell_type_hcg` | 118 | 108 | 66 | S8 only |

They disagree on 17 cells, at the macrophage/tumor2 boundary. The paper uses
`cell_type_joint`; §8d supports that — the joint embedding tracks the CNA groups
better than any single modality.

## Deconvolution

`../../data_processing/meningioma/05_deconv/` splits cells into tumour and
non-tumour, merges their BAMs and runs UXM against the Loyfer brain atlas. The split
is **copy-number driven**:

```
cna_group 1  chr22q intact             ->  non-tumour   96 cells
cna_group 2  chr22q loss               ->  tumour      196 cells
cna_group 3  chr22q loss + chr1p loss  ->  tumour
```

To split on an annotation instead, set `SPLIT` in `05_deconv/01_make_cell_lists.py`
and redo the BAM merge and UXM step (~1 h).

## Inputs

From `work/meningioma/` — the output of `../../data_processing/meningioma/`:

- `subset_clustering/250kb/CNA.1M.txt` — 1 Mb fragment counts (step `04_cna`)
- `QC/methylation_matrices/methylation_matrix_{GCH,HCG}_250kb.tsv.gz` (step `02_qc`)
- `06.hiccluster_snakemake/hicluster_250kb_embed_dir_all3/` (step `03_hic`)
- `QC/meningioma_passed_hicusable.txt` — the 292-cell set

## Notes

- **The embeddings are frozen.** `fig4_umap.ipynb` caches its three Harmony
  embeddings and four UMAP layouts at full precision in `tables/frozen/*.rds`;
  `freeze()` in §1 loads them when present. Harmony/UMAP output is not portable
  across R builds (R 4.3.3 and R 4.4.2 disagree), so re-running without the cache
  redraws the panels rather than reproducing them. The Leiden labels are unaffected —
  every cluster, cell type and CNA group reproduces exactly. Delete
  `tables/frozen/` to recompute from scratch.
- An earlier deconvolution split used `cell_type_hcg` (184 / 108); its outputs are
  kept in `deconv/published_hcg_split/`. Switching to the CNA split moved the
  barplot by at most 0.046 (Blood-Mono+Macro) across 42 atlas cell types and did not
  change its direction.
