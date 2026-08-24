# FILES — supplementary_figures/figS1

No notebook of its own. Every panel is drawn by
`../../main_figures/fig1/fig1_benchmark_violins.ipynb`; see `README.md` for the
cell-to-panel mapping.

| File | What it is |
|---|---|
| `README.md` | Panels, which cell draws each, and inputs. |
| `FILES.md` | This file. |

## Why no notebook here

The benchmark notebook loads eight methods' QC tables across 31 cells before any
figure is drawn, and its 11 plotting cells emit Figure 1 and Figure S1 panels
together. Extracting the S1 subset would duplicate nearly the whole notebook and
let the two copies drift. Same call as `../figS8/`, which points at
`main_figures/fig4/`.
