# Supplementary Figure S6 — replicate reproducibility (mouse cortex)

Two panels, both comparing the two biological replicates of the mouse-cortex
sc-NOMe-HiC run (rep1 = 702 cells, rep2 = 875, together the 1,577 QC-passing set).

| Panel | File | Made by |
|---|---|---|
| Reproducibility scatter, GCH + HCG | `repro_GCH_HCG_qnorm_plain.pdf` | §5 |
| Hi-C SCC violin, 95th-pct clip | `scc_violin_clip95.pdf` | §7 |

| Notebook | Kernel | Panels |
|---|---|---|
| `figS6_replicate_reproducibility.ipynb` | Python (`scnomehic_python`) | both |

## Inputs

Produced by `../../data_processing/mouse_cortex/04_replicate_comparison/`:

- `pseudobulk/{rep1,rep2}.{GCH,HCG}.250kb.pseudobulk.txt.gz` — step 1
- `results/scc/dumps/{rep}_{res}_{chrom}.txt` — step 3, 120 juicer dumps

**The SCC is computed in this notebook**, not read from a table — dumps → dense
matrix → 95th-percentile clip → cooler → `hicrepSCC(H=3)`, about 15 s for all 60
chromosome × resolution pairs. This matches `main_figures/fig1`, which computes
its single-cell-vs-bulk SCC the same way. Verified bit-identical to the values the
old batch script wrote (60/60 rows, max difference 0).

## Run order

Top to bottom. The cells are:

| § | What it does |
|---|---|
| §1 | paths, `CTXS`, `CTX_NAME` |
| §2 | `load_pb()` → `data`, the four pseudobulk tables |
| §3 | quantile-normalises GCH across replicates — **defines `quantile_normalize()`**, which §5 calls |
| §4 | `FIG_DIR`, the `PUB` rcParams, `save_fig`, `density_scatter` |
| **§5** | **panel 1** — `repro_GCH_HCG_qnorm_plain` |
| §6 | SCC from the dumps → the `scc` table (`scc_raw` and `scc_clip95`) |
| **§7** | **panel 2** — `scc_violin_clip95` |

Sections are numbered for this notebook. In the source notebook the same cells are
C2, the publication-figure helpers, Figure 4b and D-pub.

## Two things to know about the SCC panel

**1. The clip-95 SCC is saturated.** Measured from the shipped tables:

| resolution | raw SCC (min / median / max) | clip95 SCC |
|---|---|---|
| 1 Mb | 0.216 / **0.843** / 0.971 | 0.983 / **1.000** / 1.000 |
| 500 kb | 0.221 / **0.896** / 0.988 | 0.989 / **1.000** / 1.000 |
| 250 kb | 0.465 / **0.908** / 0.985 | 0.990 / **1.000** / 1.000 |

All three clip-95 violins collapse against the y = 1 ceiling. On this deep
pseudobulk the 95th-percentile clip over-clips, and no clip percentile below 99
avoids it. The raw SCC has real spread — medians 0.84–0.91 — and is the more
informative statistic, but Figure S6 ships the clip-95 violin as a deliberate
choice, for consistency with the cell-line SCC panel which uses the same formula.

The notebook plots **only** clip-95. `scc_raw` is still written to
`scc_by_chrom_and_resolution.csv` by step 3, so if a reviewer asks why every SCC
is ~1.0, the raw violin is one `scc_violin("scc_raw", …)` call away — the helper
that draws it is already defined in the same cell.

**2. Only the 95th percentile is kept.** The source notebook also had a cell
(its D-pub2) sweeping clip percentiles 95–99 and writing a violin for each, which
wrote `scc_violin_clip95.pdf` a second time. That cell was dropped: its clip-95
values are **bit-identical** to the `scc_clip95` values §6 computes (verified
across all 60 chrom × resolution rows, max difference 0), and the figure it
produced is **pixel-identical**. Dropping it removed a filename collision and made
the 95–99 processing step unnecessary.

## §5 detail

§5 is the plain-style scatter with larger text: per-250 kb-bin
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
