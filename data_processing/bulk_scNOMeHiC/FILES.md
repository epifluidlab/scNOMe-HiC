# FILES — data_processing/bulk_scNOMeHiC

12 files. See `README.md` for the run order and the input/output of each step.

Source: `/gpfs/projects/b1198/epifluidlab/yoshii/sc_nomehic_cellline/bulk_gm_from_scratch`

| File | What it is | Original name |
|---|---|---|
| `00_paths.sh` | Shared paths and variables sourced by every numbered script: repo/scratch dirs, pipeline and tool locations, reference, replicate→FASTQ map, chunk size, SLURM account. Defines `activate_scnomehic`. Edit this first when relocating. | `00_paths.sh` |
| `01_download/` | SRA download of the 3 replicates. Has its own `FILES.md`. | `download_scripts/` |
| `02_trim.sh` | SLURM array 1-3. trim_galore per replicate (`clip_R1/R2=15`, 3′ clip 5) → `repN_val_{1,2}.fq.gz`. Resume-aware. | `01_trim.sh` |
| `03_chunk.sh` | SLURM array 1-3. `seqkit split2` each trimmed replicate into 20 M-read-pair chunks, renamed to the pipeline's cell convention. 53 chunks total. Resume-aware. | `02_chunk.sh` |
| `04_make_chunk_list.sh` | Login-node helper. Builds the chunk manifest and prints the `--array=1-N` range for the next step. | `11_make_chunk_list.sh` |
| `05_align_nopbat.sh` | SLURM array 1-53. Aligns one chunk with Bhmem, **with `-pbat` and `-nonDirectional` removed** — the key protocol correction (see README). Writes to a per-job temp file, `samtools quickcheck`s it, then moves atomically, so a partial file never looks complete. | `11_align_nopbat.sh` |
| `06_merge_bamprocess_perrep.sh` | SLURM array 1-3. Merges each replicate's chunk BAMs, then bamprocess (namesort / fixmate / markdup / calmd) **once per replicate** — deduplication's correct unit is the sequencing library. Resume-aware. | `12_merge_bamprocess_perrep.sh` |
| `07_merge_reps_call_methylation.sh` | Merges the 3 per-replicate calmd BAMs into one bulk BAM. Also contains a monolithic methylation call and binning that were **superseded by 08 and 09** — see the README note; those stages self-skip once 09's outputs exist. | `13_merge_reps_call_methylation.sh` |
| `08_call_methylation_scatter.sh` | SLURM array 1-25 (chr1-22, X, Y, M). Bis-SNP non-directional wrapper on the merged BAM, one chromosome per task via `--interval`, each writing to its own subdirectory. Replaces the single-threaded call that would have taken ~94 h. | `13b_call_methylation_scatter.sh` |
| `09_merge_beds_and_bin.sh` | Two phases: concatenate the per-chromosome 6plus2 beds into genome-wide GCH/HCG per-base beds (cheap, runs first so downstream work is never blocked), then bin each context at 1/50/100/250 kb with `calcmethylation.py` (memory-hungry — 128 G, after a 16 G run was OOM-killed). | `13c_merge_beds_and_bin.sh` |
| `10_hic_from_merged.sh` | Builds the bulk `.hic` from the merged, already-deduplicated BAM: good-reads filter (`-q 30 -f 1 -F 1804`) → `sam2juicer_new.py -f DpnII` → sort → `juicer_tools pre -q 30`. Resume-guarded at each stage. | `13d_hic_from_merged.sh` |

## Renumbering

The originals were numbered in the order they were *written*, across two attempts
at the protocol (`01`–`05` for the `-pbat` pass, `11`–`13d` for the corrected
non-PBAT pass). They are renumbered here `00`–`10` in **run order**.

Renaming the files meant updating what they say about themselves, so these edits
were made — and nothing else:

- SLURM log filename stems, so a log matches the script that wrote it
  (e.g. `logs/13d_hic_nopbat_%j.out` → `logs/10_hic_nopbat_%j.out`)
- `Step NN:` headers
- cross-references between scripts (e.g. `04_make_chunk_list.sh` now points at
  `05_align_nopbat.sh`)
- three references to scripts that are not in this folder: `00_paths.sh`'s
  strategy blurb described the superseded `-pbat` Hi-C route; `09_`'s reference to
  the notebook per-site converter; `10_`'s "mirrors steps 4-5 of
  `05_merge_bam_hic.sh`", which now spells the recipe out instead

Commands, parameters, and file paths are untouched. The originals remain in
`bulk_gm_from_scratch/` with their historical numbering.

## Deliberately not included

- **The `-pbat` generation** — `03_config.yaml`, `03_run_pipeline.sh`,
  `04_merge_methylation.{py,sh}`, `05_merge_bam_hic.sh`. Superseded: aligning with
  `-pbat` dropped the chr22 MAPQ ≥ 30 pass rate to 20 % (vs 69 % without it).
- **The failed direct-S3 download** — `download_array.sh`, `files.tsv`; the
  buckets are requester-pays and returned 403.
- **Comparison and dump scripts** — `14_persite_for_notebook.sh`,
  `_concat_{bulk,pbulk}_HCG.sh`, `06_scc_analysis.py`, `06_dump_and_scc.sh`,
  `08_dump_gm_hic.sh`, `08b_dump_kr.sh`, `09_dump_pseudobulk_dedup.sh`,
  `10_dump_250kb.sh`, and the `07_*` notebook-wiring scripts. These build the
  Figure 1 comparison from the outputs above, so they belong in the figure folder.
- **Monitoring helpers** — `final_monitor.sh`, `health_probe.sh`,
  `progress_check.sh`, `verify_and_dryrun.sh`, `verify_restart.sh`, `wait_job.sh`.
  Operational, not method.
