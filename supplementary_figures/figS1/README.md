# Supplementary Figure S1 — per-cell QC vs other single-cell methods

Per-cell yield and quality of scNOMe-HiC beside seven published single-cell
methods. Figure 1 shows three panels from the same comparison; S1 shows the rest.

## Panels

| File | Made by (cell in `fig1_benchmark_violins.ipynb`) |
|---|---|
| `readcount_beforeDedup_violin.pdf` | 33 |
| `mapq30rate_beforeDedup_violin.pdf` | 32 |
| `conversion_chrM_violin.pdf` | 42 |
| `hic_cis_n_violin_no_nagano.pdf` | 39 |
| `hic_cis_gt1kb_n_violin_no_nagano.pdf` | 39 |
| `hic_trans_ratio_violin.pdf` | 35 |

`hic_cis_gt1kb_n_violin_no_nagano.pdf` is also a Figure 1 panel.

## This folder ships no notebook

Every panel comes from `../../main_figures/fig1/fig1_benchmark_violins.ipynb`, from
the same cells that produce the Figure 1 benchmark panels. Cells 1–31 load eight
methods' QC tables and cells 32–42 draw every violin in one pass, so there is no
seam to split on; this folder documents the mapping instead of carrying a near-copy.

| Cell | Draws |
|---|---|
| 32 | mapping rate, before and after dedup |
| 33 | read count, before and after dedup |
| 35 | the four Hi-C metrics **including** Nagano — S1 takes the trans ratio |
| 39 | the same four **excluding** Nagano — S1 takes cis and cis > 1 kb |
| 41 | HCG and GCH detected loci (Figure 1) |
| 42 | bisulfite non-conversion, chrM and chr21/chr19 |

## Inputs

The scNOMe-HiC arm comes from
`../../data_processing/gm12878_cellline/06_benchmark_qc/`. The other methods'
arms come from the benchmark repository's `summary/` tables:

<https://github.com/yoshihiko1218/snomehic_benchmark> — commit `236719d`

The download, alignment and QC pipeline for each published dataset is in
`../../data_processing/benchmark/`. See `../../main_figures/fig1/README.md` for the
full input list and the list of methods compared.

## Notes

- `readcount_beforeDedup` and `mapq30rate_beforeDedup` are the **pre-deduplication**
  measures. Cells 32 and 33 also draw the post-dedup versions, which are not S1
  panels.
- The trans-ratio panel keeps Nagano et al.; the two cis panels drop it, because
  its contact counts sit far below the others and compress the axis. A ratio is
  scale-free, so it does not have that problem.
