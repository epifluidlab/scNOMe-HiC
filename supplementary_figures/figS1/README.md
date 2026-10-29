# Supplementary Figure S1 — per-cell QC vs other single-cell methods

Per-cell yield and quality of scNOMe-HiC beside six published single-cell
methods. Figure 1 shows three panels from the same comparison; S1 shows the rest.

## Panels

| File | Made by (cell in `fig1_benchmark_violins.ipynb`) |
|---|---|
| `mapq30count_beforeDedup_violin.pdf` | 36 |
| `mapq30rate_beforeDedup_violin.pdf` | 35 |
| `conversion_chrM_violin.pdf` | 47 |
| `hic_cis_n_violin_no_nagano.pdf` | 42 |
| `hic_cis_gt1kb_n_violin_no_nagano.pdf` | 42 |
| `hic_trans_ratio_violin.pdf` | 38 |

| File | Made by |
|---|---|
| `hic_loglog_contact_vs_distance.fullonly.smoothed.zoom.pdf` | `figS1_contact_distance.ipynb` |

`hic_cis_gt1kb_n_violin_no_nagano.pdf` is also a Figure 1 panel.

## The violin panels have no notebook here

The six violins come from `../../main_figures/fig1/fig1_benchmark_violins.ipynb`, from
the same cells that produce the Figure 1 benchmark panels. Cells 1–34 load the
methods' QC tables and cells 35–47 draw every violin in one pass, so there is no
seam to split on; this folder documents the mapping instead of carrying a near-copy.

The contact-vs-distance panel is unrelated to that notebook and ships here as
`figS1_contact_distance.ipynb`.

| Cell | Draws |
|---|---|
| 35 | uniquely-mapped MAPQ ≥ 30 **rate**, before and after dedup |
| 36 | uniquely-mapped MAPQ ≥ 30 **count**, before and after dedup |
| 38 | the four Hi-C metrics — S1 takes the trans ratio |
| 42 | the same four, re-drawn under `_no_nagano` names — S1 takes cis and cis > 1 kb |
| 45 | HCG and GCH detected loci (Figure 1) |
| 47 | bisulfite non-conversion, chrM and chr21/chr19 |

## Contact frequency vs. distance

`figS1_contact_distance.ipynb` draws the HOMER log-log decay for three GM12878
samples — bulk NOMe-HiC, pseudobulk NOMe-HiC and ENCODE in-situ Hi-C — at full
depth, log-binned 20/decade, zoomed to 10^5–10^8 bp.

It reads `<sample>_full.petag.FreqDistribution_1000.txt`, which HOMER
`makeTagDirectory` writes from a HiCsummary read-pair file. Those tables are produced
by `../../data_processing/bulk_others/05_hic_loglog/` (steps 01–04): download the
ENCODE `ENCFF447ERX.pairs.gz` read pairs (~115 GB), convert each sample's read-pair
file to HiCsummary, downsample, and run `makeTagDirectory`. The notebook starts from
the small per-sample distribution tables those steps emit.

## Inputs

The scNOMe-HiC arm comes from
`../../data_processing/gm12878_cellline/06_benchmark_qc/`. The other methods'
arms come from the benchmark repository's `summary/` tables:

<https://github.com/yoshihiko1218/snomehic_benchmark> — commit `236719d`

The download, alignment and QC pipeline for each published dataset is in
`../../data_processing/benchmark/`. See `../../main_figures/fig1/README.md` for the
full input list and the list of methods compared.

## Notes

- `mapq30count_beforeDedup` and `mapq30rate_beforeDedup` are the **pre-deduplication**
  measures. The same cells also draw the post-dedup versions, which are not S1 panels.
- **S1B and S1C are two views of the same quantity.** `mapq30_*` is the MAPQ ≥ 30
  subset of the uniquely-mapped fragments; `rate_*` is that subset as a percentage of
  them. S1B is the count, S1C the rate.
- S1B previously plotted `uniq_preDedup`, the uniquely-mapped count with **no** MAPQ
  filter, under the name `readcount_beforeDedup_violin.pdf`. Changed 2026-10-21 to the
  MAPQ ≥ 30 count, and renamed so the filename matches what it shows.
- **All four Hi-C panels show the same three datasets** — droplethic, snmCseq3 and
  scnomehic. scHi-C (Nagano et al.) has been removed from the notebook; the
  `_no_nagano` filenames are kept only because they are the files used in the
  figures, and no longer distinguish anything.

## Data update 2026-09-09

The `snmCseq3` arm (wrong assay — GSE213259 is snmC-seq2, methylome-only) has
been replaced with 100 cells of genuine snm3C-seq (PRJNA658701), and Droplet Hi-C
has been deduplicated (61.1% duplicate rate; it was previously pre-dedup because
snakemake stopped at `pairtools_sort`). Panels regenerated 2026-09-15.

Affected panels: **S1A** (conversion), **S1B** (uniquely mapped, MAPQ ≥ 30 count),
**S1C** (uniquely mapped, MAPQ ≥ 30 rate), **S1D** (cis contacts), **S1E** (trans
fraction).
See `../../main_figures/fig1/README.md` for the before/after table, the
rebuild scripts, and the cell-35 cache bug that had been silencing updates to
S1D.
