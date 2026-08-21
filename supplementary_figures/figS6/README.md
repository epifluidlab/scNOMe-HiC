# Supplementary Figure S6 — replicate reproducibility (mouse cortex)

Two panels, both comparing the two biological replicates of the mouse-cortex
sc-NOMe-HiC run (rep1 = 702 cells, rep2 = 875, together the 1,577 QC-passing set).

| Panel | File | Made by |
|---|---|---|
| Reproducibility scatter, GCH + HCG | `repro_GCH_HCG_qnorm_plain.pdf` | §Figure 4b |
| Hi-C SCC violin, 95th-pct clip | `scc_violin_clip95.pdf` | §D-pub2 |

| Notebook | Kernel | Panels |
|---|---|---|
| `figS6_replicate_reproducibility.ipynb` | Python (`scnomehic_python`) | both |

## Inputs

Produced by `../../data_processing/mouse_cortex/04_replicate_comparison/`:

- `pseudobulk/{rep1,rep2}.{GCH,HCG}.250kb.pseudobulk.txt.gz` — step 1
- `results/scc_clip95to99/scc_clip_sweep.csv` — step 4

## Run order

Top to bottom. The cells are:

| § | What it does |
|---|---|
| config | paths, `CTXS`, `CTX_NAME` |
| load | `load_pb()` → `data`, the four pseudobulk tables |
| C2 | quantile-normalises GCH across replicates — **defines `quantile_normalize()`**, which Figure 4b calls |
| pub helpers | `FIG_DIR`, the `PUB` rcParams, `save_fig`, `density_scatter` |
| **Figure 4b** | **panel 1** — `repro_GCH_HCG_qnorm_plain` |
| D-pub | SCC violins from the main SCC table; defines `SCC_STYLE` and `RESLABS` |
| **D-pub2** | **panel 2** — `scc_violin_clip95..99` |

## Two things to know about the SCC panel

**1. The clip-95 SCC is saturated.** Measured from the shipped tables:

| resolution | raw SCC (min / median / max) | clip95 SCC |
|---|---|---|
| 1 Mb | 0.216 / **0.843** / 0.971 | 0.983 / **1.000** / 1.000 |
| 500 kb | 0.221 / **0.896** / 0.988 | 0.989 / **1.000** / 1.000 |
| 250 kb | 0.465 / **0.908** / 0.985 | 0.990 / **1.000** / 1.000 |

All three clip-95 violins collapse against the y = 1 ceiling. The processing
folder's README puts it plainly: on this deep pseudobulk the 95th-percentile clip
over-clips, and no clip percentile below 99 avoids it. **The raw SCC is the
informative version** — medians 0.84–0.91 with real spread — and it is written to
the same table (`scc_raw`) and plotted by the §D-pub cell as
`scc_violin_raw.pdf`. Figure S6 ships the clip-95 violin as a deliberate choice;
if a reviewer asks why every SCC is ~1.0, the raw panel is one cell away.

**2. Two cells write `scc_violin_clip95.pdf`.** §D-pub writes it from the
`scc_clip95` column of `results/scc/scc_by_chrom_and_resolution.csv`; §D-pub2
writes it again from `results/scc_clip95to99/scc_clip_sweep.csv`. In a
top-to-bottom run **§D-pub2 wins**, and that is the file on disk. Both sources
agree that clip95 saturates, so the figure is the same either way — but the
collision is real, and renaming one of them would be a sensible cleanup.

## Panel 1 detail

Figure 4b is the "plain Section-B style" scatter with larger text: per-250 kb-bin
rep1 vs rep2, one axis pair per context, with the identity line and Pearson /
Spearman annotated. **GCH is quantile-normalised, HCG is left raw** — the
`NORM_LBL` dict in the cell carries that distinction into the panel titles. The
normalisation is applied in memory in that cell; it does not read the
step-6 quantile-normalised pseudobulk on disk.

## Not included

- The `s6/` folder in `../../../scnomehic_paper/` holds an **older, unrelated**
  supplementary figure (accessibility / Hi-C QC UMAP panels, Jan 2026). The
  supplementary numbering has since been reshuffled; nothing from it is used here.
- Notebook sections A, B, C, D and E of the source notebook — distributions and
  KS, raw reproducibility, methylation ↔ accessibility correlation, the main SCC
  section, and Hi-C decay. None are S6 panels. See the processing folder's
  `FILES.md` for the matching excluded scripts.
