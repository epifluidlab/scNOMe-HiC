# Figure 1 — single-cell pseudobulk vs bulk, and vs other single-cell methods

Two things. First, pooling the 180 QC-passing GM12878 cells reproduces bulk
NOMe-HiC in all three modalities. Second, per-cell yield compares favourably with
published single-cell methods.

## Panels

| File | Made by |
|---|---|
| `newbulk_locus_HCG_methylation_minCT_10.pdf` | `fig1_methylation_accessibility.ipynb` |
| `newbulk_acc_250kb_GCH_quantileNorm.pdf` | `fig1_methylation_accessibility.ipynb` |
| `gm_heatmap_chr1_combined_main_dot.pdf` | `fig1_hic_comparison.ipynb` |
| `hcg_loci_violin.pdf`, `gch_loci_violin.pdf` | `fig1_benchmark_violins.ipynb`, cell 41 |
| `hic_cis_gt1kb_n_violin_no_nagano.pdf` | `fig1_benchmark_violins.ipynb`, cell 39 |

`fig1_hic_comparison.ipynb` also produces `gm_scc_raw_clip95_only_1Mb.pdf` and
`gm_scc_rawclip_by_resolution.pdf`, which are not placed in Figure 1.
`fig1_benchmark_violins.ipynb` produces six more panels used in Supplementary
Figure S1 — see `../../supplementary_figures/figS1/`.

## Files

| File | What it is |
|---|---|
| `fig1_methylation_accessibility.ipynb` | R 4.4.2 (`nomehic_r`), 4 code cells. Bins the per-site BEDs itself, then draws the locus methylation panel and the quantile-normalised 250 kb accessibility panel. |
| `fig1_hic_comparison.ipynb` | Python 3.12.8 (`scnomehic_python`), 6 code cells. Reads juicer text dumps, draws the chr1 heatmap and computes HiCRep SCC. |
| `fig1_benchmark_violins.ipynb` | Python (`scnomehic_python`), 42 code cells, 33 figures. Cross-technology per-cell QC: cells 1–31 load each method's QC tables, cells 32–42 draw the violins. |

## Inputs

**Pseudobulk vs bulk** — the four per-site `.6plus2.bed.gz` files:

| File | Produced by |
|---|---|
| `gm_pseudobulk_merged.{HCG,GCH}.6plus2.bed.gz` | `gm12878_cellline/03_pseudobulk/03_merge_methylation.sh` |
| `bulk_GM12878_merged.cyt.filtered.sort.{HCG,GCH}.6plus2.bed.gz` | `bulk_scNOMeHiC/09_merge_beds_and_bin.sh` |

plus per-chromosome juicer dumps at 2.5 Mb / 1 Mb / 500 kb / 250 kb, prefixed
`newbulk` and `gm_pseudobulk_dedup`, from `bulk_scNOMeHiC/11_dump_multires.sh`,
`12_dump_pseudobulk_dedup.sh`, `13_dump_250kb.sh`.

**Benchmark violins** — the scNOMe-HiC arm from
`gm12878_cellline/06_benchmark_qc/` (`gm_sc.gch_hcg_count.txt.gz`,
`chrM_gch_hcg/gm.{chr21,chrM}.txt.gz`) and the alignment summaries in
`04.alignment_snakemake/`; the other methods' arms from the benchmark repository's
`summary/` tables:

```
summary/qc_tables/{align,hic}.csv          summary/conversion_percell.csv
summary/gch_hcg_counts/all_methods.summary.txt
summary/trinuc/{scnome,smallwood,snmCseq2,snmCseq3}.chr{19,21}.txt
summary/hic_cache/hic_df.csv
```

## The benchmark repository

The processing for the other single-cell methods — download, alignment and QC for
each published dataset — is in `../../data_processing/benchmark/`, copied from

<https://github.com/yoshihiko1218/snomehic_benchmark> — commit `236719d`

Methods compared: Droplet Hi-C (Chang et al. 2025), scNOMe-seq (Pott et al. 2017),
scWGBS (Smallwood et al. 2014), snmC-seq2 (Luo et al. 2018), snm3C-seq (Liu et al.
2023), snmCAT-seq (Luo et al. 2022), and scNOMe-HiC.

## Notes

- The accessibility panel is quantile-normalised. This is rank-preserving, so
  Spearman is unchanged (0.756 raw and normalised, n = 11,670) while Pearson rises
  0.622 → 0.743. The raw Pearson was depressed by the differing marginals of a
  180-cell pool and a deep bulk library, not by disagreement.
- SCC is computed on **raw** counts with a 95th-percentile clip, keeping all bins
  (`drop_lowcov=False`, since dropping bins would corrupt the genomic distances
  HiCRep uses). chr4 is excluded as an outlier.
- The chr1 heatmap *is* IC-balanced, at 1 Mb with low-coverage bins dropped, 2400
  dpi. Balancing is for visual comparability only; it is not used for SCC.
- **The `_no_nagano` suffix is vestigial.** Nagano et al. (scHi-C) is loaded into
  `hic_df` — 15 cells — but plotted nowhere: cell 34 sets `dataset_order` to
  droplethic / snmCseq3 / scnomehic, so cell 35's panels exclude it just as cell 39's
  explicitly-named `_no_nagano` ones do. Both sets show the same three datasets. The
  original reason for dropping it was that its contact counts sit far below the
  others and compress the axis.
- Methyl-HiC never enters the notebook. Neither it nor Nagano is carried in
  `data_processing/benchmark/`.
- All three notebooks keep the absolute paths they ran with; the benchmark notebook
  writes into a relative `figures/` directory and so must be run from the benchmark
  repository root.
