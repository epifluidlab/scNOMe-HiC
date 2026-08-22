# FILES — figS6/

| File | What it is | Origin |
|---|---|---|
| `README.md` | Panels, inputs, run order, the SCC clip caveat. | written for this repo |
| `FILES.md` | This file. | written for this repo |
| `figS6_replicate_reproducibility.ipynb` | Python, 7 code cells, kernel `scnomehic_python`. Loads the per-replicate 250 kb pseudobulk, quantile-normalises GCH, draws the reproducibility scatter, **computes the Hi-C SCC from the step-3 juicer dumps**, then draws the clip-95 violin. All 7 cells carry outputs — 4 figures, no errors. Runs in ~20 s. | `sc_nomehic/snakemake/replicate_comparison/replicate_comparison.ipynb` |

## What was trimmed

The source notebook has 17 code cells; 6 are kept. Retained cells and why:

| source cell | source name | § here | reason |
|---|---|---|---|
| 0 | config | §1 | paths, `CTXS`, `CTX_NAME` |
| 1 | load | §2 | builds `data`, read by §5 |
| 5 | C2 | §3 | **defines `quantile_normalize()`**, which §5 calls |
| 6 | pub helpers | §4 | `FIG_DIR`, `PUB`, `save_fig` |
| 11 | Figure 4b | **§5** | **panel 1** |
| — | — | §6 | **added for this repo**: computes the `scc` table from the dumps, replacing the `pd.read_csv` the next cell used to do |
| 13 | D-pub | **§7** | **panel 2** — `scc_violin_clip95` only |

Sections were renumbered 1–7 for this notebook. The source names are kept in the
table above so the provenance stays checkable, but nothing in the notebook still
refers to a C2, Figure 4, Section B or D-pub2 that is not in it.

§3 and §4 are kept because a panel cell depends on a name they define, not
because they are panels themselves — §3 for `quantile_normalize`, §4 for
`save_fig`. §3 also produces its own intermediate figures, left in place.

Dropped: cells 2, 3, 4 (sections A–C: distributions/KS, raw reproducibility,
methylation ↔ accessibility), 7, 8, 9, 10 (publication Figures 1–4, superseded for
this figure by 4b), 12 (section D, the main SCC section), **14 (§D-pub2, the
clip-percentile sweep 95–99)** and 15, 16 (Hi-C decay, summary). Markdown headers
whose code cell was dropped went with them.

**On dropping the source notebook's D-pub2.** It swept clip percentiles 95–99 and
wrote a violin per percentile, including a second `scc_violin_clip95.pdf` that
overwrote the one §7 draws.
Verified before removing it: its clip-95 values are bit-identical to the
`scc_clip95` values §6 computes (60/60 rows, max difference 0), and re-running
the trimmed notebook reproduces `scc_violin_clip95.png` **pixel-identically** to
the shipped file. So nothing about the panel changed — the notebook simply no
longer computes four percentiles it never plotted in the figure.

One cell was **added** rather than lifted: §6, which computes SCC from the
juicer dumps. It is the SCC half of the original `03_scc_hicrep.py` batch script,
moved into the notebook so the figure and its statistic live together — the same
arrangement `main_figures/fig1` uses. Its dump parsing, `H=3` smoothing,
resolutions, chromosome list and 95th-percentile clip are the script's, unchanged,
and it reproduces that script's `scc_by_chrom_and_resolution.csv` **bit-identically**
for both columns across all 60 rows. §7 lost only its `pd.read_csv` line, since
`scc` now comes from §6.

Otherwise the only source edits are the section renumbering and the reworded
cross-references; no path or parameter was changed.

## Inputs it reads

| Path (working tree) | Written by |
|---|---|
| `replicate_comparison/pseudobulk/{rep}.{GCH,HCG}.250kb.pseudobulk.txt.gz` | `04_replicate_comparison/01_pseudobulk_methylation.py` |
| `replicate_comparison/results/scc/dumps/{rep}_{res}_{chrom}.txt` | `04_replicate_comparison/03_dump_hic.py` |

## Deliberately not included

- **`scnomehic_paper/s6/`** — that folder is an older supplementary figure
  (accessibility and Hi-C QC UMAP panels, Jan 2026) from before the supplementary
  numbering was reshuffled. It is not this figure and shares no code with it.
- The other figures in `results/figures_pub/` — `repro_HCG`, `repro_GCH_qnorm`,
  `corr_methy_acc_{rep1,rep2}`, `repro_GCH_HCG_qnorm`, `scc_violin_raw`,
  `scc_violin_clip{96..99}`. Produced by cells that are kept or dropped as above,
  but not S6 panels themselves. `scc_violin_clip{96..99}` and `scc_violin_raw` are
  **no longer produced at all** — the sweep cell was dropped and the raw call
  removed, so the notebook draws exactly one SCC violin. Stale copies of those
  files may remain in the working tree's `results/figures_pub/`; they are
  orphaned. The `scc_violin()` helper still takes a column argument, so raw can be
  drawn again with a one-line call.
