# FILES — mouse_cortex/04_replicate_comparison/

| File | What it is | Origin |
|---|---|---|
| `README.md` | Run order, method choices, the clip-saturation caveat. | written for this repo |
| `FILES.md` | This file. | written for this repo |
| `01_pseudobulk_methylation.py` | Pools per-cell GCH/HCG counts per 250 kb bin for one replicate — sums methylated and total reads, then divides. | `code/01_pseudobulk_methylation.py` |
| `01_pseudobulk_methylation.slurm` | SLURM array 1–4: rep1/GCH, rep1/HCG, rep2/GCH, rep2/HCG. | `code/01_pseudobulk_methylation.slurm` |
| `02_merge_bam_to_hic.sh` | Worker: merge a replicate's `calmd` BAMs → name-sort → `sam2juicer_new.py` → sort → `juicer pre -q 30` → multi-resolution `.hic`. | `code/02_merge_bam_to_hic.sh` |
| `02_submit_hic.sh` | Submits the worker for rep1 and rep2 and prints the two job ids (needed for the step-3 dependency). | `code/02_submit_hic.sh` |
| `03_scc_hicrep.py` | Dumps both `.hic` to per-chrom cool, runs `hicrepSCC(H=3)` at 1 Mb / 500 kb / 250 kb, writes the SCC table and a violin. Also leaves the cached dumps that step 4 reuses. | `code/03_scc_hicrep.py` |
| `03_submit_scc.slurm` | Step 3 job. Submit with `--dependency=afterok:` on the two step-2 jobs. | `code/03_submit_scc.slurm` |
| `cell_lists/rep1.txt` | 702 `scNH_c57cortex_*` cell ids. | `cell_lists/rep1.txt` |
| `cell_lists/rep2.txt` | 875 `batch2_*` cell ids. | `cell_lists/rep2.txt` |

No command, parameter or data path was changed from the originals. All scripts
pass `bash -n` / `ast.parse`.

## Deliberately not included

- **`code/03b_scc_clip_sweep.py` and both its submitters** — the clip-percentile
  sweeps (95..100 and 95–99). Figure S6 plots only the 95th percentile, and step 3
  already writes that as the `scc_clip95` column: the sweep's clip-95 values are
  **bit-identical** to it across all 60 chrom × resolution rows. So the sweep is
  not on the figure's path. It was used during development to establish that no
  clip below the 99th percentile escapes saturation — a result recorded in the
  README rather than recomputed.
- **`code/04_methy_acc_compare.py` + `04_submit_methy.slurm`** — rep1-vs-rep2
  distribution/KS and methylation–accessibility correlation tables. Feeds the
  notebook's exploratory sections A–C and the `repro_HCG` / `corr_methy_acc_*`
  figures, none of which are Figure S6 panels.
- **`code/05_hic_decay.py` + `05_submit_decay.slurm`** — contact-distance decay
  P(s) and coverage. Notebook section E; not a Figure S6 panel.
- **`code/06_qnorm_accessibility.py` + `06_submit_qnorm.slurm` + `util_qnorm.py`**
  — quantile-normalised GCH pseudobulk written to disk. The Figure S6 panel does
  **not** read these: the notebook cell defines its own `quantile_normalize` and
  applies it in memory to the step-1 pseudobulk. The two implementations are
  duplicates and algorithmically identical — same reference (mean of the per-rank
  sorted values), same average-rank + linear interpolation; `util_qnorm.py` only
  adds a NaN guard that raises instead of propagating. So dropping it cannot
  change the panel. Only the in-notebook copy is on the figure's path.
- **`__pycache__/`**, `logs/`, and the `results/` and `pseudobulk/` output trees —
  generated, not source.
