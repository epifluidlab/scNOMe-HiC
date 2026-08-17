# Bulk NOMe-HiC — GM12878

Reprocessing of the bulk GM12878 NOMe-HiC sample (bT WGBS readout, 3 replicates,
SRA `SRR16978252` / `SRR16978253` / `SRR16978254`) from raw FASTQ to the three
modalities that the pseudobulk comparison needs: **accessibility (GCH)**,
**methylation (HCG)**, and **Hi-C contacts**.

This is the bulk arm of the Figure 1 comparison. The matching pseudobulk arm is
built from the 180 QC-passing single cells in `../gm12878_cellline/`.

## Strategy

The `sc_NOMeHiC` pipeline parallelizes by *cell*. A bulk replicate is one huge
sample, so each replicate's trimmed FASTQ is **split into ~20 M-read-pair chunks**,
each staged as a pipeline "cell" (`prefix=repN`, `index=chunkNNN`) — 53 chunks in
total. Alignment then fans out across SLURM. Demultiplexing is skipped.

Chunking is a **parallelization strategy, not part of the method**: chunks are
merged back per replicate before any deduplication or methylation calling, so
splitting affects wall-clock time only, not the results. Steps 03–06 are where
that machinery lives; the biological flow is trim → align → deduplicate per
replicate → merge replicates → call methylation → bin → build contact map.

Deduplication is done **per replicate**, which is the correct unit: `markdup`
identifies PCR duplicates within a sequencing library, so the three replicates
must be deduplicated separately before being merged.

### Alignment is run WITHOUT `-pbat`

This is the one methodological decision worth flagging. The single-cell pipeline's
`rule mapping` hardcodes `-nonDirectional -pbat`; both flags are wrong for this
bulk library's protocol. `05_align_nopbat.sh` removes them.

The difference is large: on chr22 the MAPQ ≥ 30 pass rate among deduplicated reads
rose from **20 % to 69 %**, giving ~6.5× more usable contacts and a final `.hic` of
4.7 GB rather than 2.2 GB. Total mapped reads were essentially unchanged
(2.0532 B vs 2.0532 B), so this is an alignment-confidence gain, not a change in
input depth.

An earlier `-pbat` pass exists in the original working directory. It is superseded
and deliberately not included here.

## Run order

`00_paths.sh` holds every shared path and variable and is sourced by all the
numbered scripts — edit it first when moving to another system.

| Step | Script | In → Out |
|---|---|---|
| 01 | `01_download/download_sra.sh` | SRA accessions → `GM12878_bT_WGBS_rep{1,2,3}_{1,2}.fq.gz` |
| 02 | `02_trim.sh` | array 1-3; trim_galore (clip 15 5′, 5 3′) → `repN_val_{1,2}.fq.gz` |
| 03 | `03_chunk.sh` | array 1-3; `seqkit split2` at 20 M pairs → 53 chunks named `repN.chunkNNN.R{1,2}_val_{1,2}.fq.gz` |
| 04 | `04_make_chunk_list.sh` | (login node) writes the chunk manifest, prints the array range |
| 05 | `05_align_nopbat.sh` | array 1-53; Bhmem **without** `-pbat`/`-nonDirectional` → `04b.alignment_nopbat/repN.chunkNNN.bam` |
| 06 | `06_merge_bamprocess_perrep.sh` | array 1-3; merge each rep's chunks → namesort/fixmate/markdup/calmd → `05b.bamprocess_perrep/bulk_GM12878_repN.calmd.bam` |
| 07 | `07_merge_reps_call_methylation.sh` | merge the 3 per-rep BAMs → `06b.methylation_merged/bulk_GM12878_merged.calmd.bam` — **see the note below** |
| 08 | `08_call_methylation_scatter.sh` | array 1-25; Bis-SNP per chromosome on the merged BAM |
| 09 | `09_merge_beds_and_bin.sh` | concat per-chr → genome-wide `{GCH,HCG}.6plus2.bed.gz`, then bin at 1/50/100/250 kb |
| 10 | `10_hic_from_merged.sh` | merged BAM → good-reads filter → `sam2juicer_new.py` → `juicer_tools pre` → `bulk_GM12878_merged.mapQ30.hic` |

### Note on step 07

Step 07 does three things: (1) merge the three per-replicate BAMs, (2) call
methylation on the merge, (3) bin the result. **Only step (1) is on the live
path.** Its monolithic single-threaded Bis-SNP call over the ~1.5 B-read merged BAM
projected to ~94 h against a 48 h wall limit, so methylation calling was moved to
`08_` (scattered by chromosome, `--interval chrN`) and binning to `09_`.

Run `07_` for the merged BAM, then run `08_` and `09_`. Every stage is
resume-guarded on the presence of its outputs, so `07_`'s steps (2) and (3) skip
themselves once `09_` has produced the beds and tables.

## Outputs

All heavy outputs live on scratch (`$WORK` = `/scratch/jmj7858/scnomehic/bulk_gm/pipeline/`),
never in this repository.

| Modality | File |
|---|---|
| Accessibility | `06b.methylation_merged/bulk_GM12878_merged.cyt.filtered.sort.GCH.6plus2.bed.gz` (1.8 G) |
| Methylation | `06b.methylation_merged/bulk_GM12878_merged.cyt.filtered.sort.HCG.6plus2.bed.gz` (222 M) |
| Hi-C | `06c.hic_merged_nopbat/bulk_GM12878_merged.mapQ30.hic` (4.7 G) |
| Binned tables | `06b.methylation_merged/bulk_GM12878_merged.{GCH,HCG}.{1kb,50kb,100kb,250kb}_methylation.txt.gz` |

Those three modality files are what the Figure 1 comparison reads, alongside their
pseudobulk counterparts.

## Notes on paths

Every script keeps the absolute paths it ran with, and all of them resolve through
`00_paths.sh`. Scratch is not backed up: the intermediates listed above may no
longer exist, though the three comparison files were copied into the Figure 1 data
directory. Original working directory:
`/gpfs/projects/b1198/epifluidlab/yoshii/sc_nomehic_cellline/bulk_gm_from_scratch`.
