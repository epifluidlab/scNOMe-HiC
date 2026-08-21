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
| `04_scc_clip_sweep.py` | Sweeps the per-chromosome clip percentile and recomputes SCC at each, reusing step 3's dumps. | `code/03b_scc_clip_sweep.py` |
| `04_submit_clip_95to99.slurm` | Step 4 job at `--pcts 95,96,97,98,99`, writing `results/scc_clip95to99/`. This is the sweep Figure S6 plots. | `code/03b_submit_clip_95to99.slurm` |
| `cell_lists/rep1.txt` | 702 `scNH_c57cortex_*` cell ids. | `cell_lists/rep1.txt` |
| `cell_lists/rep2.txt` | 875 `batch2_*` cell ids. | `cell_lists/rep2.txt` |

Renumbering: step `3b` became step `04` so the folder reads 01–04 in run order.
Two self-references were rewritten to match — the `Step 3b:` docstring header in
`04_scc_clip_sweep.py`, and the `${RC}/code/03b_scc_clip_sweep.py` path inside
`04_submit_clip_95to99.slurm` (now a sibling path). No command, parameter or data
path was changed. All scripts pass `bash -n` / `ast.parse`.

## Deliberately not included

- **`code/03b_submit_clip_sweep.slurm`** — the earlier 95..100 sweep, writing
  `results/scc_clipsweep/`. Figure S6 plots the 95–99 sweep
  (`results/scc_clip95to99/`) instead, and nothing else reads the 95..100 output.
  Same `04_scc_clip_sweep.py` driver, different `--pcts` and `--out_dir`, so it
  can be reproduced from the shipped script if wanted.
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
