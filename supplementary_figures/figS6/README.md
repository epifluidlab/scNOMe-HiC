# Supplementary Figure S6 — replicate reproducibility (mouse cortex)

The two biological replicates of the mouse-cortex run (rep1 = 702 cells,
rep2 = 875; together the 1,577 QC-passing set).

## Panels

| File | Made by |
|---|---|
| `repro_GCH_HCG_qnorm_plain.pdf` | `figS6_replicate_reproducibility.ipynb` §5 |
| `scc_violin_clip95.pdf` | `figS6_replicate_reproducibility.ipynb` §7 |

## Files

| File | What it is |
|---|---|
| `figS6_replicate_reproducibility.ipynb` | Python (`scnomehic_python`), 7 code cells. §1 paths · §2 loads the pseudobulk tables · §3 defines `quantile_normalize()` · §4 figure helpers · **§5 panel 1** · §6 computes SCC from the dumps · **§7 panel 2**. Runs top to bottom. |

## Inputs

From `../../data_processing/mouse_cortex/04_replicate_comparison/`:

- `pseudobulk/{rep1,rep2}.{GCH,HCG}.250kb.pseudobulk.txt.gz` — step 1
- `results/scc/dumps/{rep}_{res}_{chrom}.txt` — step 3, 120 juicer dumps

SCC is computed in the notebook (dumps → dense matrix → 95th-percentile clip →
cooler → `hicrepSCC(H=3)`, ~15 s for all 60 chromosome × resolution pairs), matching
how `main_figures/fig1` computes its SCC.

## Notes

- **The clip-95 SCC is saturated** — all three violins sit against y = 1:

  | resolution | raw SCC (min / median / max) | clip95 median |
  |---|---|---|
  | 1 Mb | 0.216 / 0.843 / 0.971 | 1.000 |
  | 500 kb | 0.221 / 0.896 / 0.988 | 1.000 |
  | 250 kb | 0.465 / 0.908 / 0.985 | 1.000 |

  On this deep pseudobulk the 95th-percentile clip over-clips, and no percentile
  below 99 avoids it. The raw SCC has real spread (medians 0.84–0.91). S6 ships the
  clip-95 violin for consistency with the cell-line SCC panel, which uses the same
  formula. `scc_raw` is also computed, so the raw violin is one `scc_violin("scc_raw", …)`
  call away using the helper already defined in §7.
- In §5, **GCH is quantile-normalised and HCG is left raw** — the `NORM_LBL` dict
  carries that into the panel titles. The normalisation happens in memory in that
  cell; it does not read a normalised table from disk.
