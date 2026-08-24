# 04_replicate_comparison — rep1 vs rep2 reproducibility

Compares the two biological replicates of the mouse-cortex run across methylation,
accessibility and Hi-C. Produces the tables behind Supplementary Figure S6
(`../../../supplementary_figures/figS6/`).

The 1,577 QC-passing cells split by prefix:

| Replicate | Cell prefix | Cells | Samplesheet |
|---|---|---|---|
| rep1 | `scNH_c57cortex_*` | 702 | `scNH_micecortex_rep1` |
| rep2 | `batch2_*` | 875 | `samplesheet_sc_micecortex_rep2` |

Cell lists are in `cell_lists/`; together they are `QC/cortex_passed.txt`.

## Run order

| Step | Script | Input → output |
|---|---|---|
| 1 | `01_pseudobulk_methylation.py` (`.slurm`, array 1–4) | per-cell GCH/HCG counts → `pseudobulk/{rep}.{GCH,HCG}.250kb.pseudobulk.{txt.gz,bedGraph}` |
| 2 | `02_merge_bam_to_hic.sh` via `02_submit_hic.sh` | per-cell `*.calmd.bam` → merged, name-sorted → `sam2juicer_new.py -f mm10_DpnII` → `juicer pre -q 30` → `hic/{rep1,rep2}.mapQ30.hic` |
| 3 | `03_dump_hic.py` (`03_submit_dump.slurm`) | the two `.hic` → `juicer_tools dump observed NONE` per chromosome at 1 Mb / 500 kb / 250 kb → `results/scc/dumps/` (120 files) |

Steps 1 and 2 are independent; 3 needs 2.

```bash
sbatch 01_pseudobulk_methylation.slurm
bash   02_submit_hic.sh                                  # returns the rep1/rep2 job ids
sbatch --dependency=afterok:<rep1>:<rep2> 03_submit_dump.slurm
```

## Outputs

| Product | Path |
|---|---|
| Pseudobulk methylation/accessibility | `pseudobulk/{rep}.{GCH,HCG}.250kb.pseudobulk.txt.gz` |
| Per-replicate Hi-C | `hic/{rep1,rep2}.mapQ30.hic` |
| Per-chromosome contact dumps | `results/scc/dumps/{rep}_{res}_{chrom}.txt` — 120 files, ~104 MB |

## Notes

- **SCC is not computed here** — the Figure S6 notebook computes it from these
  dumps (~15 s), the same split `main_figures/fig1` uses. Only the dump needs to be
  a batch step: 120 juicer_tools invocations against ~230 MB `.hic` files.
- Pseudobulk methylation is a **pooled ratio**: sum `methylated_reads` and sum
  `total_reads` across a replicate's cells per 250 kb bin, then divide — not a mean
  of per-cell rates. GCH is accessibility, HCG is CpG methylation.
- Hi-C reuses the `cortex_pseudobulk` stream_B recipe: mm10, MAPQ ≥ 30, DpnII sites.
- Large intermediates (merged BAMs, sorted pair files) went to b1042 scratch and are
  not analysis outputs.
- Scripts keep the absolute paths they ran with. Original working directory:
  `sc_nomehic/snakemake/replicate_comparison`.
