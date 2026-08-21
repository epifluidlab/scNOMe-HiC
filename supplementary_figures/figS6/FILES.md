# FILES — figS6/

| File | What it is | Origin |
|---|---|---|
| `README.md` | Panels, inputs, run order, the SCC clip caveat. | written for this repo |
| `FILES.md` | This file. | written for this repo |
| `figS6_replicate_reproducibility.ipynb` | Python, 7 code cells, kernel `scnomehic_python`. Loads the per-replicate 250 kb pseudobulk, quantile-normalises GCH, draws the reproducibility scatter, then draws the SCC violins from the clip sweep. All 7 cells carry outputs — 10 figures, no errors. | `sc_nomehic/snakemake/replicate_comparison/replicate_comparison.ipynb` |

## What was trimmed

The source notebook has 17 code cells; 7 are kept. Retained cells and why:

| kept | § | reason |
|---|---|---|
| 0 | config | paths, `CTXS`, `CTX_NAME` |
| 1 | load | builds `data`, read by Figure 4b |
| 5 | C2 | **defines `quantile_normalize()`**, which Figure 4b calls |
| 6 | pub helpers | `FIG_DIR`, `PUB`, `save_fig` |
| 11 | Figure 4b | **panel 1** |
| 13 | D-pub | **defines `SCC_STYLE` and `RESLABS`**, which §D-pub2 uses |
| 14 | D-pub2 | **panel 2** |

Cells 5, 13 and 6 are kept because a panel cell depends on a name they define,
not because they are panels themselves — cell 5 for `quantile_normalize`, cell 13
for `SCC_STYLE`/`RESLABS`, cell 6 for `save_fig`. Each also produces its own
intermediate figures, which are left in place.

Dropped: cells 2, 3, 4 (sections A–C: distributions/KS, raw reproducibility,
methylation ↔ accessibility), 7, 8, 9, 10 (publication Figures 1–4, superseded for
this figure by 4b), 12 (section D, the main SCC section) and 15, 16 (Hi-C decay,
summary). Markdown headers whose code cell was dropped went with them.

No cell source was edited and no path was rewritten; outputs are the originals.

## Inputs it reads

| Path (working tree) | Written by |
|---|---|
| `replicate_comparison/pseudobulk/{rep}.{GCH,HCG}.250kb.pseudobulk.txt.gz` | `04_replicate_comparison/01_pseudobulk_methylation.py` |
| `replicate_comparison/results/scc/scc_by_chrom_and_resolution.csv` | `04_replicate_comparison/03_scc_hicrep.py` |
| `replicate_comparison/results/scc_clip95to99/scc_clip_sweep.csv` | `04_replicate_comparison/04_scc_clip_sweep.py` |

## Deliberately not included

- **`scnomehic_paper/s6/`** — that folder is an older supplementary figure
  (accessibility and Hi-C QC UMAP panels, Jan 2026) from before the supplementary
  numbering was reshuffled. It is not this figure and shares no code with it.
- The other figures in `results/figures_pub/` — `repro_HCG`, `repro_GCH_qnorm`,
  `corr_methy_acc_{rep1,rep2}`, `repro_GCH_HCG_qnorm`, `scc_violin_raw`,
  `scc_violin_clip{96..99}`. Produced by cells that are kept or dropped as above,
  but not S6 panels themselves. `scc_violin_clip{96..99}` are still written by the
  retained §D-pub2 loop, since the sweep is what justifies the clip choice.
