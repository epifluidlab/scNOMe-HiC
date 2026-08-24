# Supplementary Figure S5 — sequencing saturation (GM12878)

How much of each library's complexity the sequencing captured. 180 QC-passing cells.

## Panels

| File | Made by |
|---|---|
| `s5_saturation.pdf` | `figS5_saturation.ipynb` §3 |

Also drawn, not panels: `s5_library_complexity` (§4, unique molecules vs raw
fragments) and `s5_saturation_byfraction` (§5, the same curves against subsample
fraction). Both are how the fit was checked.

## Files

| File | What it is |
|---|---|
| `figS5_saturation.ipynb` | Python (`python3`), 7 code cells. Reads every `results/*.tsv`, checks completeness (180 cells × 7 fractions), fits `y = Ymax·N/(N+K)` per curve, and plots. |

## Inputs

Per-(cell, fraction) result files from
`../../data_processing/gm12878_cellline/04_saturation/` (steps 00–05).

Four metrics per depth:

| metric | meaning |
|---|---|
| `HCG_loci` | CpG methylation positions detected |
| `GCH_loci` | GpC accessibility positions detected |
| `cis` | intra-chromosomal contacts, MAPQ 30, deduplicated |
| `cis_1kb` | cis contacts spanning more than 1 kb |

Fractions: 0.05, 0.1, 0.2, 0.4, 0.6, 0.8, plus 1.0 taken from the full-depth
pipeline outputs rather than recomputed.

## Notes

- The chain subsamples the **pre-dedup** BAM and re-runs de-duplication at each
  depth. Subsampling an already-deduplicated BAM would thin a unique set and give a
  straight line with no saturation to measure.
- `samtools view -s` uses a fixed seed, so the depths are nested (0.2 ⊂ 0.4 ⊂ …) and
  each cell's curve is monotonic by construction.
- §3 reports `Ymax`, `K`, and the percentage of saturation reached at full depth.
