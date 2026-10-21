# FILES — supplementary_figures/figS1

One notebook. The six violin panels are drawn by
`../../main_figures/fig1/fig1_benchmark_violins.ipynb`; see `README.md` for the
cell-to-panel mapping.

| File | What it is | Origin |
|---|---|---|
| `README.md` | Panels, which cell draws each, and inputs. | written for this repo |
| `FILES.md` | This file. | written for this repo |
| `figS1_contact_distance.ipynb` | Python, **4 code cells** (trimmed from 9), kernel `scnomehic_python`. Loads the three HOMER `petag` distribution tables, defines the loaders and `make_fig()`, and draws the full-depth log-binned curve zoomed to 10^5–10^8 bp → `hic_loglog_contact_vs_distance.fullonly.smoothed.zoom.pdf`. Outputs preserved. | `scnomehic_paper/fig1/codes/hic_qc_loglog/loglog_plots.ipynb` |

## Deliberately not included

- **`loglog_plots.ipynb` cells 7, 9, 11, 13** — the sequencing-depth table, the
  full-range (1 kb – 300 Mb) figures, the other two zoomed variants (all six curves,
  and the 100 M matched-depth subsample only), and the loop that regenerates every
  PNG/PDF variant to disk. The published panel is the full-depth zoomed curve only;
  `make_fig()` still takes the `full_only` / `sub_only` / `zoom` / `smoothed` flags,
  so any of the others can be redrawn in one call.
- **`plot_loglog.py`** — the batch equivalent of `figS1_contact_distance.ipynb`,
  emitting all 12 combined/full/sub × raw/smoothed/zoom variants. The notebook
  carries the same `make_fig()` and draws the published panel.

The read-pair download and the HiCsummary → `makeTagDirectory` chain that writes
the `petag` tables now lives in
`../../data_processing/bulk_others/05_hic_loglog/` (steps 01–04).

## Why the violin panels have no notebook here

The benchmark notebook loads eight methods' QC tables across 31 cells before any
figure is drawn, and its 11 plotting cells emit Figure 1 and Figure S1 panels
together. Extracting the S1 subset would duplicate nearly the whole notebook and
let the two copies drift. Same call as `../figS8/`, which points at
`main_figures/fig4/`.
