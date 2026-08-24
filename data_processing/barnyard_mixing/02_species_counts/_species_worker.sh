#!/bin/bash
# Per-cell species read counter. Given a {cell}.calmd.bam, emit one TSV row:
#   cell  human_hq_reads  mouse_hq_reads  human_all_reads  mouse_all_reads
#
# Species is assigned by reference-contig name in the COMBINED hg38_mm10 genome:
#   mouse  = contig matches ^mm10_   (mm10_chr1, mm10_chrX, mm10_chrUn_..., ...)
#   human  = everything else         (chr1, chrX, chr*_random, chrM, ...)
#
# Two count sets per cell:
#   *_hq_reads  : high-quality reads used for the barnyard plot —
#                 proper-pair (-f 2), MapQ>=30 (-q 30), and excluding
#                 unmapped/mate-unmapped/secondary/QC-fail/DUPLICATE/supplementary
#                 (-F 3852 = 4+8+256+512+1024+2048). i.e. uniquely-mapped,
#                 deduplicated, primary reads.
#   *_all_reads : every mapped record per contig (samtools idxstats) — includes
#                 duplicates and low-MapQ; kept as a reference/denominator.
set -euo pipefail
export PATH=/gpfs/projects/b1198/epifluidlab/yoshii/software/conda/envs/scnomehic/bin:$PATH

bam="$1"
cell="$(basename "$bam" .calmd.bam)"

read hq_h hq_m < <(samtools view -f 2 -q 30 -F 3852 "$bam" \
  | awk '{ if ($3 ~ /^mm10_/) m++; else h++ } END { print h+0, m+0 }')

read all_h all_m < <(samtools idxstats "$bam" \
  | awk '$1!="*" { if ($1 ~ /^mm10_/) m+=$3; else h+=$3 } END { print h+0, m+0 }')

printf "%s\t%d\t%d\t%d\t%d\n" "$cell" "$hq_h" "$hq_m" "$all_h" "$all_m"
