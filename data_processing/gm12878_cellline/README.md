# GM12878 — single-cell NOMe-HiC processing

GM12878 4-plex scNOMe-HiC: **188 cells**, hg38, **180 pass QC**. The single-cell arm
of the Figure 1 comparison; the bulk arm is `../bulk_scNOMeHiC/`.

Pipeline: <https://github.com/epifluidlab/sc_NOMeHiC_pipeline>, commit
`a0456b972f07690ef0425cc852583660c036f277`. Running from scratch:
[../../RUNNING.md](../../RUNNING.md). This dataset ran from `start_from: raw`.

## Run order

| Step | What it is |
|---|---|
| `00_config/config.main_run.yaml` | Snakemake config: references, tool paths, adapter clipping, methylation bins (1/50/100/250 kb), QC thresholds. |
| `01_pipeline/01_run_pipeline.sh` | Driver for the per-cell chain: demultiplex → trim → align (Bhmem) → Bis-SNP → per-bin methylation. |
| `02_qc/qc_plots.ipynb` | QC gate and summary plots. Writes `QC/cellline_passed.txt` (180 cells). |
| `03_pseudobulk/01_merge_calmd_passed.sh` | Merges the 180 passing `calmd.bam` into `merged.sorted.bam`. |
| `03_pseudobulk/02_call_methylation_array.sh` | SLURM array, one chromosome per task. Bis-SNP on the pooled BAM. |
| `03_pseudobulk/03_merge_methylation.sh` | Concatenates to `gm_pseudobulk_merged.{GCH,HCG}.6plus2.bed.gz` and bins. |
| `03_pseudobulk/04_build_pseudobulk_hic.sh` | Per-cell filter → `sam2juicer_new.py` → `juicer_tools pre` → pseudobulk `.hic`. |
| `03_pseudobulk/05_make_bedgraph_bigwig.sh` | bedGraph and bigWig tracks from the per-site BEDs. |
| `04_saturation/` | Sequencing saturation (Supplementary Fig. S5) — steps 00–05. |
| `05_profiles/` | CTCF and TSS metaprofiles (Supplementary Fig. S3) — steps 01–03. |
| `06_benchmark_qc/` | Per-cell GCH/HCG loci counts and chrM/autosome trinucleotide methylation — the scNOMe-HiC arm of the Figure 1 / S1 cross-method comparison. |

`04_saturation` subsamples reads and re-measures four metrics at each depth
(fractions 0.05–0.8 plus full depth). `05_profiles` runs deepTools `computeMatrix`
on the pseudobulk bigwigs from step 3.

`06_benchmark_qc` runs `extract_GCH_HCG_counts.py` over the per-cell methylation
BEDs and `extract_trinuc_chrM.py` over the per-cell trinucleotide QC files. Both
`.sh` wrappers carry one line per dataset in the paper; the GM12878 lines are the
ones Figure 1 and S1 use.

## Outputs

| Product | Path |
|---|---|
| QC-passing cell list | `QC/cellline_passed.txt` |
| Per-cell QC metrics | `QC/cellline_qc_summary.txt` |
| Per-cell per-site methylation | `07.bistools_snakemake/methylation/*/*.{GCH,HCG}.6plus2.bed.gz` |
| Pseudobulk accessibility | `pseudobulk_methylation/gm_pseudobulk_merged.GCH.6plus2.bed.gz` |
| Pseudobulk methylation | `pseudobulk_methylation/gm_pseudobulk_merged.HCG.6plus2.bed.gz` |
| Pseudobulk contacts | `hic_comparison/gm_pseudobulk.dedup.mapQ30.hic` |
| Pseudobulk tracks | `pseudobulk_methylation/gm_pseudobulk_merged.{GCH,HCG}.methlevel.bw` |
| Per-cell benchmark QC | `gm_sc.gch_hcg_count.txt.gz`, `chrM_gch_hcg/gm.{chr21,chrM}.txt.gz` |

## Notes

- `fragnum_threshold` is 100,000 here; it was 80,000 as run. Inert — the lowest
  `fragnum` among the 180 passing cells is 1,565,866, so the passing set is
  identical. This is the only departure from the config as run.
- Pseudobulk re-calls Bis-SNP at pooled depth rather than summing per-cell calls,
  so SNPs are re-genotyped at full coverage.
- Step 04's good-reads filter runs before `sam2juicer`, matching the bulk arm so
  both exclude PCR duplicates.
- `04_saturation` subsamples the **pre-dedup** BAM with a fixed seed, so depths are
  nested and each cell's curve is monotonic.
- `05_profiles` passes `--missingDataColor white`; `--missingDataAsZero` is not used
  because it would treat "not measured" as "unmethylated".
- No per-cell Hi-C contact-matrix step: nothing here reads
  `06.hiccluster_snakemake/*.hic_matrix.txt.gz`.
- The other single-cell methods in the Figure 1 / S1 comparison are processed in a
  separate repository, <https://github.com/yoshihiko1218/snomehic_benchmark>
  (commit `236719d`), which is referenced rather than duplicated here.
- Scripts keep the absolute paths they ran with. Original working directories:
  `sc_nomehic_cellline/gm_sc_new`, and `scnomehic_paper/s1/QC` for `06_benchmark_qc`.
