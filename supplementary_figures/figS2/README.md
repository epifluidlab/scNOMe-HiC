# Supplementary Figure S2 — scNOMe-HiC vs published single-cell assays

Each scNOMe-HiC modality compared, in GM12878, against an independent single-cell
assay of the same thing: methylation against scWGBS and sci-MET, accessibility
against snATAC, contacts against sci-Hi-C.

## Panels

| File | Made by |
|---|---|
| `three_way_persite_corr_bars.pdf` | `figS2_methylation_persite.ipynb`, last cell |
| `R_gch_vs_snatac_qnorm.pdf` | `figS2_accessibility.ipynb`, last cell |
| `schic_scc_rawclip_by_resolution.pdf` | `figS2_schic_scc.ipynb`, §7 |

## Files

| File | What it is |
|---|---|
| `figS2_methylation_persite.ipynb` | R (`nomehic_r`), 12 code cells, 8 figures. Per-CpG HCG for scNOMe-HiC, Drop-BS scWGBS and sci-MET; smoothScatter grids and correlation bars for each pair, then the three-way panel. |
| `figS2_accessibility.ipynb` | R (`scnomehic`), 2 code cells, 1 figure. Per-peak GCH vs snATAC over the merged DNase peaks, quantile-normalised. |
| `figS2_schic_scc.ipynb` | Python (`scnomehic`), 9 code cells, 5 figures. Recomputes HiCRep SCC from the contact dumps, then draws the boxplots, per-chromosome bars, example heatmaps, matched-bin scatter and the by-resolution panel. |

The three notebooks are unrelated and run in any order.

## Inputs

All from `../../data_processing/published_singlecell/`, plus the GM12878 pseudobulk
from `../../data_processing/gm12878_cellline/03_pseudobulk/`:

| Input | Produced by |
|---|---|
| `work/13_persite/wgbs_pseudobulk_HCG.cpgmerged.tsv.gz` | `scwgbs_dropbs/13b_merge_cpg_strands.py` |
| `work/scmet/sciMET_pseudobulk_HCG.cpgmerged.tsv.gz` | `scimet/13_to_hcg.py` |
| `gm_pseudobulk_merged.HCG.6plus2.bed.gz` | `gm12878_cellline/03_pseudobulk/03_merge_methylation.sh` |
| `data/peak_signal.tab`, `data/peak_gch_coverage.tab` | `snatac_dnase/05_scatter.sh`, `06_gch_coverage.sh` |
| `work/dump_multires/{nomehic,schic_gm}_{res}_{chr}.txt` | `schic/03_rebin_hg38.py`, `04_dump_nomehic.sh` |

## Reported statistics

Per-CpG Pearson r, by minimum coverage on both sides:

| pair | ≥ 1 | ≥ 2 | ≥ 3 |
|---|---|---|---|
| Drop-BS vs NOMe-HiC | 0.607 | 0.661 | 0.699 |
| sci-MET vs NOMe-HiC | 0.589 | 0.649 | 0.676 |
| sci-MET vs Drop-BS | 0.595 | 0.688 | 0.744 |

Accessibility: 54,010 DNase peaks, Pearson r = 0.524, Spearman ρ = 0.567.

Hi-C SCC, 95th-percentile clip, median over 23 chromosomes: 0.902 at 500 kb, 0.954
at 1 Mb, 0.948 at 2.5 Mb.

## Notes

- The methylation panel is the point of the three-way design: scNOMe-HiC agrees with
  each external platform about as well as the two external platforms agree with each
  other, so the residual disagreement is single-cell sampling depth, not the assay.
- All three comparisons are pseudobulk vs pseudobulk. Per-cell SCC at these
  resolutions is too sparse to be informative, and sci-MET cannot be demultiplexed
  at all (see `published_singlecell/scimet/METHODS.md`).
- The sci-Hi-C SCC stops at 500 kb because the published matrices are binned at
  500 kb.
