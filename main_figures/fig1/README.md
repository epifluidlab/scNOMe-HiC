# Figure 1 — single-cell pseudobulk vs bulk NOMe-HiC

Demonstrates that pooling the single cells reproduces bulk NOMe-HiC across all
three modalities: **CpG methylation (HCG)**, **chromatin accessibility (GCH)**, and
**3D contacts (Hi-C)**.

Both arms are produced entirely by `../../data_processing/`; these notebooks only
read those outputs and plot. Two notebooks rather than one, because the panels use
different languages.

| Notebook | Kernel | Panels |
|---|---|---|
| `fig1_methylation_accessibility.ipynb` | R 4.4.2 (`nomehic_r`) | per-locus HCG methylation, per-locus and 250 kb GCH accessibility |
| `fig1_hic_comparison.ipynb` | Python 3.12.8 (`scnomehic_python`) | chr1 contact-matrix heatmap, HiCRep SCC |

## Inputs

### `fig1_methylation_accessibility.ipynb` (R)

Reads the per-site `.6plus2.bed.gz` files **directly** and does its own binning and
coverage filtering — it does not use the pre-binned `*_methylation.txt.gz` tables.

| Variable | File | Produced by |
|---|---|---|
| `PB_HCG` | `gm_pseudobulk_merged.HCG.6plus2.bed.gz` | `gm12878_cellline/03_pseudobulk/03_merge_methylation.sh` |
| `PB_GCH` | `gm_pseudobulk_merged.GCH.6plus2.bed.gz` | ↑ same |
| `BK_HCG` | `bulk_GM12878_merged.cyt.filtered.sort.HCG.6plus2.bed.gz` | `bulk_scNOMeHiC/09_merge_beds_and_bin.sh` |
| `BK_GCH` | `bulk_GM12878_merged.cyt.filtered.sort.GCH.6plus2.bed.gz` | ↑ same |
| `BLACKLIST` | `reference/hg38/hg38-blacklist.v2.bed` | external reference |

### `fig1_hic_comparison.ipynb` (Python)

Reads per-chromosome juicer **text dumps**, not `.hic` files. Arms are selected by
filename prefix: `BULK = "newbulk"`, `PSEUDO = "gm_pseudobulk_dedup"`.

| Input | Produced by |
|---|---|
| `dumps/newbulk_{2.5Mb,1Mb,500kb}_{chr}.txt` | `bulk_scNOMeHiC/11_dump_multires.sh` |
| `dumps/gm_pseudobulk_dedup_{2.5Mb,1Mb,500kb}_{chr}.txt` | `bulk_scNOMeHiC/12_dump_pseudobulk_dedup.sh` |
| `dumps/{both}_250kb_{chr}.txt` | `bulk_scNOMeHiC/13_dump_250kb.sh` |

`CHROM_MAIN = chr1` is the chromosome shown in the heatmap. SCC is computed with
**HiCRep inside the notebook** — it builds temporary `.cool` files to IC-balance
before scoring, so no external SCC script is involved.

## Outputs

`fig1_methylation_accessibility.ipynb` → `figures/`

- `newbulk_locus_HCG_methylation_minCT_10.pdf` — per-locus HCG, min coverage 10
- `newbulk_locus_GCH_accessibility_minCT_5_10_15_20.pdf` — per-locus GCH across
  coverage thresholds
- `newbulk_acc_250kb_GCH.pdf` and five variants — 250 kb GCH accessibility, raw vs
  quantile-normalized, with and without bin/locus blacklisting

`fig1_hic_comparison.ipynb` → `figures/`

- `gm_scc_rawclip_by_resolution.pdf`, `gm_scc_IC_by_resolution.pdf` — SCC across
  2.5 Mb / 1 Mb / 500 kb / 250 kb
- `gm_scc_raw_vs_IC_1Mb.pdf`, `gm_scc_rawclip_vs_ICclip_1Mb.pdf`,
  `gm_scc_raw_clip95_only_1Mb.pdf` — normalization comparisons at 1 Mb

The chr1 heatmap renders inline; unlike the SCC panels it has no `savefig` call, so
it needs one added if the panel is to be exported as a file.

## Running

Both notebooks keep the absolute paths they ran with and write figures back into
their original working directories. Point `FIGDIR` / `OUT_FIG_DIR` at this folder's
`figures/` when re-running from the repository.

Outputs are preserved in both notebooks, so the panels can be reviewed without
re-executing.
