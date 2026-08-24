#!/bin/bash
# ============================================================================
# 07_merge_dedup.sh — per-cell (SLURM ARRAY over passing cells):
#   sort R1 & R2 bams -> merge into one per-cell bam -> remove duplicates.
# Submit with:  sbatch --array=1-<Npass>%50 code/07_merge_dedup.sh
# ============================================================================
#SBATCH --job-name=scwgbs_07_dedup
#SBATCH --account=b1042
#SBATCH --partition=genomics
#SBATCH --time=02:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G
#SBATCH --output=code/logs/07_dedup_%A_%a.out
#SBATCH --error=code/logs/07_dedup_%A_%a.err
set -euo pipefail
cd "${SLURM_SUBMIT_DIR:-$(dirname "$0")/..}"
source code/config.sh
activate_env

CELL=$(sed -n "${SLURM_ARRAY_TASK_ID}p" "$D06/passing_cells.txt")
OUT=$D07/$CELL
mkdir -p "$OUT"

R1BAM=$D05/$CELL/R1/${CELL}_R1.bam
R2BAM=$D05/$CELL/R2/${CELL}_R2.bam

echo "[$(date '+%F %T')] [$CELL] sort R1 & R2"
samtools sort -@ "$THREADS" -o "$OUT/${CELL}_R1.sorted.bam" "$R1BAM"
samtools sort -@ "$THREADS" -o "$OUT/${CELL}_R2.sorted.bam" "$R2BAM"

echo "[$(date '+%F %T')] [$CELL] bamtools merge R1+R2"
bamtools merge \
    -in "$OUT/${CELL}_R1.sorted.bam" \
    -in "$OUT/${CELL}_R2.sorted.bam" \
    -out "$OUT/${CELL}.merged.bam"

echo "[$(date '+%F %T')] [$CELL] coordinate-sort merged"
samtools sort -@ "$THREADS" -o "$OUT/${CELL}.merged.sorted.bam" "$OUT/${CELL}.merged.bam"

echo "[$(date '+%F %T')] [$CELL] picard MarkDuplicates (remove)"
picard MarkDuplicates \
    INPUT="$OUT/${CELL}.merged.sorted.bam" \
    OUTPUT="$OUT/${CELL}.dedup.bam" \
    METRICS_FILE="$OUT/${CELL}.dup_metrics.txt" \
    REMOVE_DUPLICATES=true \
    ASSUME_SORT_ORDER=coordinate \
    VALIDATION_STRINGENCY=LENIENT

samtools index "$OUT/${CELL}.dedup.bam"
# clean up intermediates, keep dedup bam + metrics
rm -f "$OUT/${CELL}_R1.sorted.bam" "$OUT/${CELL}_R2.sorted.bam" \
      "$OUT/${CELL}.merged.bam" "$OUT/${CELL}.merged.sorted.bam"
echo "[$(date '+%F %T')] [$CELL] dedup bam: $OUT/${CELL}.dedup.bam"
