# Figure 1 — single-cell pseudobulk vs bulk NOMe-HiC

Pooling the 180 QC-passing GM12878 cells reproduces bulk NOMe-HiC in all three
modalities: CpG methylation (HCG), accessibility (GCH), and 3D contacts (Hi-C).

## Panels

| File | Made by |
|---|---|
| `newbulk_locus_HCG_methylation_minCT_10.pdf` | `fig1_methylation_accessibility.ipynb` |
| `newbulk_acc_250kb_GCH_quantileNorm.pdf` | `fig1_methylation_accessibility.ipynb` |
| `gm_heatmap_chr1_combined_main_dot.pdf` | `fig1_hic_comparison.ipynb` |
| `gm_scc_raw_clip95_only_1Mb.pdf`, `gm_scc_rawclip_by_resolution.pdf` | `fig1_hic_comparison.ipynb` (not placed in Fig. 1; the by-resolution one is the Supplementary Fig. S1 panel) |

## Files

| File | What it is |
|---|---|
| `fig1_methylation_accessibility.ipynb` | R 4.4.2 (`nomehic_r`), 4 code cells. Bins the per-site BEDs itself, then draws the locus methylation panel and the quantile-normalised 250 kb accessibility panel. |
| `fig1_hic_comparison.ipynb` | Python 3.12.8 (`scnomehic_python`), 6 code cells. Reads juicer text dumps, draws the chr1 heatmap and computes HiCRep SCC. |

## Inputs

Methylation / accessibility — the four per-site `.6plus2.bed.gz` files:

| File | Produced by |
|---|---|
| `gm_pseudobulk_merged.{HCG,GCH}.6plus2.bed.gz` | `gm12878_cellline/03_pseudobulk/03_merge_methylation.sh` |
| `bulk_GM12878_merged.cyt.filtered.sort.{HCG,GCH}.6plus2.bed.gz` | `bulk_scNOMeHiC/09_merge_beds_and_bin.sh` |

Hi-C — per-chromosome juicer dumps at 2.5 Mb / 1 Mb / 500 kb / 250 kb, prefixed
`newbulk` (bulk) and `gm_pseudobulk_dedup` (pseudobulk), from
`bulk_scNOMeHiC/11_dump_multires.sh`, `12_dump_pseudobulk_dedup.sh`,
`13_dump_250kb.sh`.

## Notes

- The accessibility panel is quantile-normalised. This is rank-preserving, so
  Spearman is unchanged (0.756 raw and normalised, n = 11,670) while Pearson rises
  0.622 → 0.743. The raw Pearson was depressed by the differing marginals of a
  180-cell pool and a deep bulk library, not by disagreement.
- SCC is computed on **raw** counts with a 95th-percentile clip, keeping all bins
  (`drop_lowcov=False`, since dropping bins would corrupt the genomic distances
  HiCRep uses). chr4 is excluded as an outlier.
- The chr1 heatmap *is* IC-balanced, at 1 Mb with low-coverage bins dropped, 2400 dpi.
  Balancing is for visual comparability only; it is not used for SCC.
- Both notebooks keep the absolute paths they ran with. Point `FIGDIR` /
  `OUT_FIG_DIR` at this folder's `figures/` when re-running from the repository.
