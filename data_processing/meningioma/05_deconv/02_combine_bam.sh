#!/bin/bash
# Merge the per-cell BAMs for the cells in a list into one sorted BAM.
# Usage: bash combinebam.sh <group> <cell_list_file>
#   e.g. bash combinebam.sh tumor cell_tumor.txt  -> combined_sorted_tumor.bam
# Per-cell BAMs live in the new run's alignment output, named <cell>.calmd.sorted_by_name.filtered.bam
# --- repo paths: edit paths.yaml at the repository root, not this file -------
_r="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]:-$0}")")" && pwd)"
while [ "$_r" != "/" ] && [ ! -f "$_r/paths.sh" ]; do _r="$(dirname "$_r")"; done
source "$_r/paths.sh"

set -euo pipefail
group="$1"; list="$2"
ALIGN=${WORK_ROOT}/meningioma/04.alignment_snakemake

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
