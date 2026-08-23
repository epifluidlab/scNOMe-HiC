#!/bin/bash
# Merge the per-cell BAMs for the cells in a list into one sorted BAM.
# Usage: bash combinebam.sh <group> <cell_list_file>
#   e.g. bash combinebam.sh tumor cell_tumor.txt  -> combined_sorted_tumor.bam
# Per-cell BAMs live in the new run's alignment output, named <cell>.calmd.sorted_by_name.filtered.bam
set -euo pipefail
group="$1"; list="$2"
ALIGN=/gpfs/projects/b1198/epifluidlab/yoshii/meningioma_scnomehic/snakemake/04.alignment_snakemake

bams=""
missing=0; found=0
while read -r cell; do
  [ -z "$cell" ] && continue
  b="${ALIGN}/${cell}.calmd.sorted_by_name.filtered.bam"
  if [ -f "$b" ]; then
    bams="${bams} ${b}"; found=$((found+1))
  else
    echo "MISSING: $b" >&2; missing=$((missing+1))
  fi
done < "$list"

echo "group=${group}  bams_found=${found}  missing=${missing}"
if [ -z "$bams" ]; then echo "no BAMs to merge for ${group}"; exit 1; fi

samtools merge -f -@ 8 "combined_${group}.bam" ${bams}
samtools sort  -@ 8 -o "combined_sorted_${group}.bam" "combined_${group}.bam"
samtools index "combined_sorted_${group}.bam"
rm -f "combined_${group}.bam"
echo "wrote combined_sorted_${group}.bam"
