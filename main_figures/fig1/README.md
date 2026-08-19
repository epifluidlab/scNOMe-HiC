# Figure 1 — single-cell pseudobulk vs bulk NOMe-HiC

Demonstrates that pooling the single cells reproduces bulk NOMe-HiC across all
three modalities: **CpG methylation (HCG)**, **chromatin accessibility (GCH)**, and
**3D contacts (Hi-C)**.

Both arms are produced entirely by `../../data_processing/`; these notebooks only
read those outputs and plot. Two notebooks rather than one, because the panels use
different languages.

| Notebook | Kernel | Published panel |
|---|---|---|
| `fig1_methylation_accessibility.ipynb` | R 4.4.2 (`nomehic_r`) | `newbulk_locus_HCG_methylation_minCT_10.pdf`, `newbulk_acc_250kb_GCH_quantileNorm.pdf` |
| `fig1_hic_comparison.ipynb` | Python 3.12.8 (`scnomehic_python`) | `gm_heatmap_chr1_combined_main_dot.pdf` |

Both notebooks have been trimmed to the cells on the path to those panels — see
[Trimming](#trimming).

## Inputs

### `fig1_methylation_accessibility.ipynb` (R, 4 code cells)

Reads the per-site `.6plus2.bed.gz` files **directly** and does its own binning and
coverage filtering — it does not use the pre-binned `*_methylation.txt.gz` tables.

| Variable | File | Produced by |
|---|---|---|
| `PB_HCG` | `gm_pseudobulk_merged.HCG.6plus2.bed.gz` | `gm12878_cellline/03_pseudobulk/03_merge_methylation.sh` |
| `PB_GCH` | `gm_pseudobulk_merged.GCH.6plus2.bed.gz` | ↑ same |
| `BK_HCG` | `bulk_GM12878_merged.cyt.filtered.sort.HCG.6plus2.bed.gz` | `bulk_scNOMeHiC/09_merge_beds_and_bin.sh` |
| `BK_GCH` | `bulk_GM12878_merged.cyt.filtered.sort.GCH.6plus2.bed.gz` | ↑ same |
| `BLACKLIST` | `reference/hg38/hg38-blacklist.v2.bed` | external reference |

Cell order: setup (loads `m_hcg`, `m_gch`) → HCG locus panel → 250 kb GCH raw
(builds `m`) → 250 kb GCH quantile-normalized.

### `fig1_hic_comparison.ipynb` (Python, 6 code cells)

Reads per-chromosome juicer **text dumps**, not `.hic` files. Arms are selected by
filename prefix: `BULK = "newbulk"`, `PSEUDO = "gm_pseudobulk_dedup"`.

| Input | Produced by |
|---|---|
| `dumps/newbulk_{2.5Mb,1Mb,500kb}_{chr}.txt` | `bulk_scNOMeHiC/11_dump_multires.sh` |
| `dumps/gm_pseudobulk_dedup_{2.5Mb,1Mb,500kb}_{chr}.txt` | `bulk_scNOMeHiC/12_dump_pseudobulk_dedup.sh` |
| `dumps/{both}_250kb_{chr}.txt` | `bulk_scNOMeHiC/13_dump_250kb.sh` |

Cell order: setup → helper definitions (`load_matrix`, `ic_balance`, `prep_pair`,
`compute_scc`) → chr1 heatmap → SCC computation → SCC at 1 Mb → SCC across
resolutions.

**The SCC measure is raw contacts with a 95th-percentile clip**, not IC-balanced:

```python
sc_r, bk_r = prep_pair(chrom, BIN_SCC, balance=False)      # raw
compute_scc(clip95(sc_r), clip95(bk_r), chrom, BIN_SCC)
```

chr4 is excluded as an outlier. Note this differs from the chr1 heatmap, which
*is* IC-balanced — balancing makes the heatmap visually comparable, while SCC is
scored on raw counts with only the outlier clip. SCC also keeps all bins
(`drop_lowcov=False`): removing bins would corrupt the genomic distances HiCRep
depends on.

## Panels

**Published in Figure 1:**

- `newbulk_locus_HCG_methylation_minCT_10.pdf` — per-locus CpG methylation,
  pseudobulk vs bulk, minimum coverage 10
- `newbulk_acc_250kb_GCH_quantileNorm.pdf` — 250 kb GpC accessibility,
  quantile-normalized
- `gm_heatmap_chr1_combined_main_dot.pdf` — chr1 contact matrix, upper triangle
  bulk / lower triangle pseudobulk, IC-balanced at 1 Mb with low-coverage bins
  dropped, rendered at 2400 dpi

**Also produced, not placed in Figure 1:**

- `newbulk_acc_250kb_GCH.pdf` — the un-normalized 250 kb panel. Its cell builds the
  `m` matrix that the quantile-normalized panel requires, so it stays.
- `gm_scc_raw_clip95_only_1Mb.pdf` — SCC at 1 Mb, publication styling.
- `gm_scc_rawclip_by_resolution.pdf` — SCC at 1 Mb / 500 kb / 250 kb. This is the
  panel destined for **Supplementary Figure S1**, kept here because the
  calculation lives with the Figure 1 comparison; S1 will get its own notebook.

## Trimming

Both notebooks were reduced to the cells leading to the published panels. Retained
cells keep their source **and outputs** byte-identical; only the cells listed below
were removed.

`fig1_methylation_accessibility.ipynb` — 12 → 4 code cells. Dropped: the
minimum-coverage sweep variants (`minCT_5_10_15_20`, `minCT_10_20_50_100`, and its
quantile-normalized twin) and the bin- and locus-blacklist variants, along with the
two cells that built `df_binBL` / `df_locusBL`.

`fig1_hic_comparison.ipynb` — 11 → 6 code cells, in two passes.

First pass dropped the all-chromosome multi-page heatmap PDF and two empty cells;
that cell also defined `BIN_HEATMAP = 1_000_000`, which the chr1 heatmap needs, so
that line moved into the heatmap cell.

Second pass removed the SCC method exploration — raw vs IC-balanced, the
apples-to-apples re-clip, and IC across resolutions — keeping only the published
raw + 95th-percentile-clip measure. The published boxplot read `keep_c` from one of
the dropped cells, so the computation was rewritten as a single cell that builds
only the `SCC_raw_clip95` column. The raw arm is untouched: same
`prep_pair(..., balance=False)`, same `clip95`, same `compute_scc`, so the values
are unchanged. Verified that `prep_pair` returns `None` only when a dump is empty —
a check made before the balance branch — so removing the balanced arm cannot change
which chromosomes are included.

The removed cells remain in git history and in the original working directories.

## Running

Both notebooks keep the absolute paths they ran with and write figures back into
their original working directories. Point `FIGDIR` / `OUT_FIG_DIR` at this folder's
`figures/` when re-running from the repository.

Outputs are preserved in both notebooks, so the panels can be reviewed without
re-executing.
