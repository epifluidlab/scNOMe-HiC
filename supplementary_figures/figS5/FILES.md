# FILES — figS5/

| File | What it is | Origin |
|---|---|---|
| `README.md` | The panel, what is measured, and the two design choices behind the curve. | written for this repo |
| `FILES.md` | This file. | written for this repo |
| `figS5_saturation.ipynb` | Python, 7 code cells, kernel `python3`. Collects every per-(cell, fraction) result, runs completeness and sanity checks, fits Michaelis–Menten, and draws three views. All 7 cells carry outputs — 3 figures, no errors. | `scnomehic_paper/s7/code/saturation_analysis.ipynb` |

Shipped whole: §1 collects, §2 checks completeness (180 cells × 7 fractions),
§3 fits and draws **the panel**, §4 and §5 are the supporting views. Every cell is
on the path to §3 or is one of those views.

## Deliberately not included

- **`scnomehic_paper/s7/code/plot_saturation.py`** — an earlier standalone
  4-panel plot, superseded by the notebook, which is described in that folder's
  own README as "the main deliverable".
- **`find_missing.sh`, `rerun_full_depth.sh`, `recover_f06.sh`** — operational
  helpers for resubmitting failed array indices and repairing the f = 1.0 point
  after a bed-glob fix. Useful during the run, not part of the method.
- **`tasks.tsv`, `saturation_results.tsv`, `saturation_fit_summary.tsv`** —
  generated: the first by `01_make_tasklist.sh`, the other two by
  `05_collect_results.sh` and the notebook.
