#!/bin/bash
# ============================================================================
# 11_align.sh — per-chunk (SLURM ARRAY) TrimGalore + Bismark (hg38) of the
# sci-MET genomic read, single-end directional (as tested: best mapping).
# Trimming follows the paper: -a AGATCGGAAGAGC, --clip_R1 6 (random-priming bias).
# Submit: sbatch --array=1-<Nchunks>%40 code/scmet/11_align.sh
# ============================================================================
#SBATCH --job-name=sciMET_11_align
#SBATCH --account=b1042
#SBATCH --partition=genomics
#SBATCH --time=6:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=6
#SBATCH --mem=24G
#SBATCH --output=code/scmet/logs/11_align_%A_%a.out
#SBATCH --error=code/scmet/logs/11_align_%A_%a.err
set -eu
cd "${SLURM_SUBMIT_DIR:-$(dirname "$0")/../..}"
source code/config.sh
activate_env

CHUNKDIR=work/scmet/chunks
OUT=work/scmet/align
CHUNK=$(sed -n "${SLURM_ARRAY_TASK_ID}p" "$CHUNKDIR/chunk_list.txt")
FQ=$CHUNKDIR/${CHUNK}.fq.gz
mkdir -p "$OUT/$CHUNK/tmp"

echo "[$(date '+%F %T')] [$CHUNK] TrimGalore"
trim_galore -a AGATCGGAAGAGC --clip_R1 6 --cores 4 --gzip -o "$OUT/$CHUNK" "$FQ" >/dev/null 2>&1
TF=$(ls "$OUT/$CHUNK"/*_trimmed.fq.gz | head -1)

echo "[$(date '+%F %T')] [$CHUNK] Bismark hg38 (SE directional)"
bismark --bowtie2 --genome "$GENOME_DIR" --single_end "$TF" \
    --basename "$CHUNK" --temp_dir "$OUT/$CHUNK/tmp" -o "$OUT/$CHUNK"
# keep only the bam; drop trimmed fq + tmp
rm -f "$TF"; rm -rf "$OUT/$CHUNK/tmp"
echo "[$(date '+%F %T')] [$CHUNK] done: $OUT/$CHUNK/${CHUNK}.bam"
