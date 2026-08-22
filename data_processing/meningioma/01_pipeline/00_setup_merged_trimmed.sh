#!/bin/bash
# Consolidate trimmed fastqs from the three meningioma data batches into a
# single merged_trimmed/ directory (symlinks) so the consolidated snakemake
# project can auto-discover every (prefix, index) cell across all three batches.
#
#   data_batch_1/03.trimmed_fastq          (old non-snakemake pipeline output)
#   data_batch_2/03.trimmed_fastq_snakemake
#   data_batch_3/03.trimmed_fastq_snakemake
#
# Only the paired val files the `mapping` rule consumes are linked:
#   {prefix}.{index}.R1_val_1.fq.gz  and  {prefix}.{index}.R2_val_2.fq.gz
set -euo pipefail

ROOT=/gpfs/projects/b1198/epifluidlab/yoshii/meningioma_scnomehic
DEST=${ROOT}/snakemake/merged_trimmed
mkdir -p "${DEST}"

declare -a SRC=(
  "${ROOT}/data_batch_1/03.trimmed_fastq"
  "${ROOT}/data_batch_2/03.trimmed_fastq_snakemake"
  "${ROOT}/data_batch_3/03.trimmed_fastq_snakemake"
)

n=0
for d in "${SRC[@]}"; do
  for f in "${d}"/*.R1_val_1.fq.gz "${d}"/*.R2_val_2.fq.gz; do
    [ -e "${f}" ] || continue
    ln -sf "$(readlink -f "${f}")" "${DEST}/$(basename "${f}")"
    n=$((n+1))
  done
done

echo "Linked ${n} files into ${DEST}"
echo "R1_val_1 cells: $(ls "${DEST}"/*.R1_val_1.fq.gz 2>/dev/null | wc -l)"
echo "R2_val_2 cells: $(ls "${DEST}"/*.R2_val_2.fq.gz 2>/dev/null | wc -l)"
