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
| `hcg_loci_violin.pdf`, `gch_loci_violin.pdf` | `fig1_benchmark_violins.ipynb`, cell 38 |
| `hic_cis_gt1kb_n_violin_no_nagano.pdf` | `fig1_benchmark_violins.ipynb`, cell 36 |

`fig1_hic_comparison.ipynb` also produces `gm_scc_raw_clip95_only_1Mb.pdf` and
`gm_scc_rawclip_by_resolution.pdf`, which are not placed in Figure 1.
`fig1_benchmark_violins.ipynb` produces six more panels used in Supplementary
Figure S1 — see `../../supplementary_figures/figS1/`.

## Files

| File | What it is |
|---|---|
| `fig1_methylation_accessibility.ipynb` | R 4.4.2 (`nomehic_r`), 4 code cells. Bins the per-site BEDs itself, then draws the locus methylation panel and the quantile-normalised 250 kb accessibility panel. |
| `fig1_hic_comparison.ipynb` | Python 3.12.8 (`scnomehic_python`), 6 code cells. Reads juicer text dumps, draws the chr1 heatmap and computes HiCRep SCC. |
| `fig1_benchmark_violins.ipynb` | Python (`scnomehic_python`), 39 code cells, 33 figures. Cross-technology per-cell QC: cells 1–28 load each method's QC tables, cells 29–39 draw the violins. |

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
- **scHi-C (Nagano et al.) has been removed from the notebook.** It was loaded but
  plotted nowhere — `dataset_order` excluded it before every panel was drawn — so the
  `_no_nagano` filenames no longer distinguish anything. They are kept because those
  are the files used in the figures. Verified: running the pre-edit and post-edit
  code in the same kernel gives **pixel-identical panels**.
- Methyl-HiC never entered the notebook at all. Neither method is in
  `data_processing/benchmark/`.
- Cells 32 and 36 draw the same four Hi-C metrics over the same three datasets,
  under the plain and `_no_nagano` filenames respectively. Both are needed: Fig. S1
  takes the trans ratio from cell 32, and Fig. 1 and S1 take the cis panels from
  cell 36.
- All three notebooks keep the absolute paths they ran with; the benchmark notebook
  writes into a relative `figures/` directory and so must be run from the benchmark
  repository root.

## Data update 2026-09-09 — snm3C-seq replaced, Droplet Hi-C deduplicated

Two source datasets behind the Hi-C panels were wrong and have been rebuilt.
Panels regenerated 2026-09-15 by running cells 29–39 from the benchmark root.
Cells 1–28 no longer run — cells 21, 22 and 26 read `MappingSummary.csv.gz` files
removed by the scratch purge — but none of them feed a panel.

**snm3C-seq.** The `snmCseq3` arm was GSE213259, which GEO records as
`Library strategy: snmC-seq2` — a methylome-only assay with no proximity
ligation, mislabelled snm3C-seq. Replaced with 100 cells of genuine snm3C-seq
(PRJNA658701, study title `[CEMBA snm3C-seq]`), randomly sampled (seed
20260827) from 5,398 runs and processed with YAP `m3c` under a config
byte-identical to YAP's shipped default except `min_gap=1000`. The internal key
stays `snmCseq3`; the displayed label already read "snm3C-seq (Liu et al. 2023)",
which is now correct for the first time.

**Droplet Hi-C.** The previous source was pre-deduplication — snakemake had
stopped at `pairtools_sort`, so step 9 never ran. `pairtools dedup` measured a
**61.1% duplicate rate** (chr21 spot-check gave 59.3%; the paper's own
174,600 → 73,813 arithmetic implies ~58%). Cells restricted to barcodes with
≥10,000 unique pairs, recovering 3,646 of the previous 3,668.

| dataset | metric | before | after |
|---|---|---|---|
| snm3C-seq | cis > 1 kb | 8,372 | **114,980** |
| snm3C-seq | cis | 649,748 | 496,616 |
| snm3C-seq | uniquely mapped fragments | 1,495,454 | 1,644,522 |
| snm3C-seq | MAPQ30 rate | 74.04% | 88.37% |
| snm3C-seq | HCG loci | 1,165,000 | 744,442 |
| Droplet Hi-C | cis > 1 kb | 8,535 | **3,048** |
| Droplet Hi-C | cells | 3,668 | 3,646 |

scNOMe-HiC is unchanged (187 cells, 31,884).

### A cache bug that silenced updates

Cell 31 builds `hic_df` with `cis_per_million_uniqmapq30`, but cell 35's
`REQUIRED` list and cell 36 use `cis_per_million_mapped`. The check therefore
failed even after a fresh upstream run, and cell 35 fell through to the on-disk
cache — so **Fig 1D and S1D plotted the cache, not the table just built**. Cell 35
now aliases the column, and `summary/hic_cache/hic_df.csv` has been rebuilt from
the new `hic.csv`. Cell 32 (→ S1E) was never affected; it reads cell 31 directly.

### Rebuild scripts (in the benchmark repo's `summary/`)

| script | what it does |
|---|---|
| `build_snm3c_new_arms.py` | builds all six arms for the new 100 cells from `MappingSummary.csv.gz` + ALLC. HCG uses `hcg_lib.classify()` against mm10 (GCG removed by reference lookup) — the same definition as every other dataset. |
| `patch_summary_tables.py` | swaps the `snmCseq3` rows in `frag_counts_all.tsv`, the two trinuc files, `conversion_percell.csv` and `all_methods.summary.txt` |
| `build_qc_tables.py` | edited: snm3C hic from `snm3c_new_hic.tsv`, droplethic hic from the deduplicated per-cell table |

Originals are in `summary/_backups_20260909/`; the notebook in
`fig1_benchmark_violins.ipynb.bak_20260909`.
