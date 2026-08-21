# 04_replicate_comparison — rep1 vs rep2 reproducibility

Compares the two biological replicates of the mouse-cortex sc-NOMe-HiC run across
methylation, accessibility and Hi-C. Produces the tables behind **Supplementary
Figure S6** (`../../../supplementary_figures/figS6/`).

The 1,577 QC-passing cells split by prefix:

| Replicate | Cell prefix | Cells | Samplesheet |
|---|---|---|---|
| **rep1** | `scNH_c57cortex_*` | 702 | `scNH_micecortex_rep1` |
| **rep2** | `batch2_*` | 875 | `samplesheet_sc_micecortex_rep2` |

Cell lists are in `cell_lists/`; together they are the same 1,577 cells as
`QC/cortex_passed.txt`.

## Run order

| Step | Script | Input → output |
|---|---|---|
| 1 | `01_pseudobulk_methylation.py` (`.slurm`, array 1–4) | per-cell GCH/HCG counts → `pseudobulk/{rep}.{GCH,HCG}.250kb.pseudobulk.{txt.gz,bedGraph}` |
| 2 | `02_merge_bam_to_hic.sh` via `02_submit_hic.sh` | per-cell `04.alignment_snakemake/{cell}.calmd.bam` → merged, name-sorted → `sam2juicer_new.py -f mm10_DpnII` → `juicer pre -q 30` → `hic/{rep1,rep2}.mapQ30.hic` |
| 3 | `03_scc_hicrep.py` (`03_submit_scc.slurm`) | the two `.hic` → per-chrom cool dumps → `hicrepSCC(H=3)` at 1 Mb / 500 kb / 250 kb → `results/scc/` |
| 4 | `04_scc_clip_sweep.py` (`04_submit_clip_95to99.slurm`) | reuses step 3's cached dumps → SCC at clip percentiles 95–99 → `results/scc_clip95to99/` |

Steps 1 and 2 are independent; 3 needs 2; 4 needs 3's `results/scc/dumps/`.

```bash
sbatch 01_pseudobulk_methylation.slurm
bash   02_submit_hic.sh                                  # returns the rep1/rep2 job ids
sbatch --dependency=afterok:<rep1>:<rep2> 03_submit_scc.slurm
sbatch --dependency=afterok:<scc job>     04_submit_clip_95to99.slurm
```

## Method choices that matter

- **Pseudobulk methylation is a pooled ratio**, not a mean of per-cell rates: sum
  `methylated_reads` and sum `total_reads` across a replicate's cells per 250 kb
  bin, *then* divide. GCH is accessibility, HCG is CpG methylation. This matches
  the read-weighted estimator used everywhere else in the paper.
- **Hi-C** reuses the `cortex_pseudobulk` stream_B recipe, genome `mm10`,
  MAPQ ≥ 30, DpnII sites.
- **SCC** is `hicrep.hicrepSCC(H=3)` per chromosome (chr1–19, chrX), mirroring the
  cell-line `compute_scc_tidy.py`.

## The clip percentile — read this before reusing the SCC

Step 4 sweeps a per-chromosome clip at the 95th–99th percentile. On this deep
pseudobulk **the clip saturates**: median SCC is exactly 1.000 at the 95th
percentile for all three resolutions, and only at the 99th does 1 Mb fall to
0.577. Raw SCC is the informative version.

| resolution | raw SCC (min / median / max) | clip95 SCC |
|---|---|---|
| 1 Mb | 0.216 / **0.843** / 0.971 | 0.983 / **1.000** / 1.000 |
| 500 kb | 0.221 / **0.896** / 0.988 | 0.989 / **1.000** / 1.000 |
| 250 kb | 0.465 / **0.908** / 0.985 | 0.990 / **1.000** / 1.000 |

Both `scc_raw` and `scc_clip95` are written, so either can be plotted. Figure S6
uses the clip-95 violin; see that folder's README.

## Outputs

| Product | Path (in the working tree) |
|---|---|
| Pseudobulk methylation/accessibility | `pseudobulk/{rep}.{GCH,HCG}.250kb.pseudobulk.txt.gz` |
| Per-replicate Hi-C | `hic/{rep1,rep2}.mapQ30.hic` |
| SCC per chrom × resolution | `results/scc/scc_by_chrom_and_resolution.csv` (`scc_raw`, `scc_clip95`) |
| SCC clip sweep 95–99 | `results/scc_clip95to99/scc_clip_sweep.csv` |

Large intermediates (merged BAMs, sorted pair files) were written to b1042 scratch
and are not part of the analysis outputs.

## Notes on paths

Scripts keep the absolute paths they ran with. Original working directory:
`/gpfs/projects/b1198/epifluidlab/yoshii/sc_nomehic/snakemake/replicate_comparison`.
