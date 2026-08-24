# Bulk NOMe-HiC — GM12878

Reprocessing of the bulk GM12878 NOMe-HiC sample (bT WGBS readout, 3 replicates,
SRA `SRR16978252` / `SRR16978253` / `SRR16978254`) from raw FASTQ to accessibility
(GCH), methylation (HCG) and Hi-C contacts.

This is the bulk arm of the Figure 1 comparison; the pseudobulk arm comes from the
180 QC-passing cells in `../gm12878_cellline/`.

`00_paths.sh` holds every shared path and variable and is sourced by all the
numbered scripts — edit it first when moving to another system.

## Run order

| Step | Script | In → Out |
|---|---|---|
| 01 | `01_download/download_sra.sh` | SRA accessions → `GM12878_bT_WGBS_rep{1,2,3}_{1,2}.fq.gz` |
| 02 | `02_trim.sh` | array 1–3; trim_galore (clip 15 5′, 5 3′) → `repN_val_{1,2}.fq.gz` |
| 03 | `03_chunk.sh` | array 1–3; `seqkit split2` at 20 M pairs → 53 chunks |
| 04 | `04_make_chunk_list.sh` | login node; writes the chunk manifest, prints the array range |
| 05 | `05_align_nopbat.sh` | array 1–53; Bhmem **without** `-pbat` / `-nonDirectional` |
| 06 | `06_merge_bamprocess_perrep.sh` | array 1–3; merge each rep's chunks → namesort/fixmate/markdup/calmd |
| 07 | `07_merge_reps_call_methylation.sh` | merge the 3 per-rep BAMs → `bulk_GM12878_merged.calmd.bam` |
| 08 | `08_call_methylation_scatter.sh` | array 1–25; Bis-SNP per chromosome on the merged BAM |
| 09 | `09_merge_beds_and_bin.sh` | concat per-chr → genome-wide `{GCH,HCG}.6plus2.bed.gz`, then bin at 1/50/100/250 kb |
| 10 | `10_hic_from_merged.sh` | merged BAM → good-reads filter → `sam2juicer_new.py` → `juicer_tools pre` → `.hic` |
| 11 | `11_dump_multires.sh` | `.hic` → per-chromosome text at 2.5 Mb / 1 Mb / 500 kb |
| 12 | `12_dump_pseudobulk_dedup.sh` | dedup pseudobulk `.hic` → the same three resolutions, prefix `gm_pseudobulk_dedup` |
| 13 | `13_dump_250kb.sh` | bulk + dedup pseudobulk `.hic` → 250 kb |

## Outputs

All on scratch (`$WORK = /scratch/jmj7858/scnomehic/bulk_gm/pipeline/`), never in
this repository.

| Modality | File |
|---|---|
| Accessibility | `06b.methylation_merged/bulk_GM12878_merged.cyt.filtered.sort.GCH.6plus2.bed.gz` |
| Methylation | `06b.methylation_merged/bulk_GM12878_merged.cyt.filtered.sort.HCG.6plus2.bed.gz` |
| Hi-C | `06c.hic_merged_nopbat/bulk_GM12878_merged.mapQ30.hic` |
| Binned tables | `06b.methylation_merged/bulk_GM12878_merged.{GCH,HCG}.{1kb,50kb,100kb,250kb}_methylation.txt.gz` |
| Hi-C dumps (both arms) | `hic_comparison/dumps/{newbulk,gm_pseudobulk_dedup}_{2.5Mb,1Mb,500kb,250kb}_{chr}.txt` |

The Figure 1 R notebook reads the GCH and HCG beds directly and does its own
binning; the Python notebook reads the dumps, selecting arms by prefix.

## Notes

- **Alignment runs without `-pbat`.** The single-cell pipeline's `rule mapping`
  hardcodes `-nonDirectional -pbat`; both are wrong for this bulk library's
  protocol. On chr22 the MAPQ ≥ 30 pass rate among deduplicated reads rose from 20%
  to 69% (~6.5× more usable contacts, `.hic` 4.7 GB vs 2.2 GB) with total mapped
  reads unchanged. The superseded `-pbat` pass is not included.
- **Chunking is parallelisation, not method.** The pipeline parallelises by cell, so
  each replicate's FASTQ is split into ~20 M-pair chunks staged as pipeline "cells".
  Chunks are merged back per replicate before any deduplication or methylation
  calling. Deduplication is per replicate, which is the correct unit — `markdup`
  identifies duplicates within one sequencing library.
- **Step 07 also calls methylation and bins, but only its merge is on the live
  path.** Its single-threaded Bis-SNP over the merged BAM projected to ~94 h against
  a 48 h wall limit, so those moved to steps 08 and 09. Run 07, then 08, then 09;
  every stage is resume-guarded, so 07's later steps skip themselves.
- **Step 11 also dumps `gm_pseudobulk.mapQ30.hic`**, the original pseudobulk that
  still contains marked PCR duplicates. That half is unused — the notebook reads
  `gm_pseudobulk_dedup` from step 12. The pseudobulk `.hic` inputs for steps 12–13
  come from `../gm12878_cellline/03_pseudobulk/04_build_pseudobulk_hic.sh`; the dumps
  live here because all three scripts write into this pipeline's shared dumps
  directory.
- Scripts keep the absolute paths they ran with, resolved through `00_paths.sh`.
  Original working directory: `sc_nomehic_cellline/bulk_gm_from_scratch`.
