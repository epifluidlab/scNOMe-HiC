#!/bin/bash
# ============================================================================
# 03_trim.sh — Trim Galore on the extracted paired reads.
# --clip_R1 15 / --clip_R2 40 remove residual linker/barcode-side bases.
# Input order matters: first file = R1 (clip_R1), second = R2 (clip_R2).
# ============================================================================
#SBATCH --job-name=scwgbs_03_trim
#SBATCH --account=b1042
#SBATCH --partition=genomics
#SBATCH --time=08:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G
#SBATCH --output=code/logs/03_trim_%j.out
#SBATCH --error=code/logs/03_trim_%j.err
set -euo pipefail
cd "${SLURM_SUBMIT_DIR:-$(dirname "$0")/..}"
source code/config.sh
activate_env
mkdir -p "$D03"

echo "[$(date '+%F %T')] Trim Galore --paired --clip_R1 $CLIP_R1 --clip_R2 $CLIP_R2"
trim_galore --paired \
    --clip_R1 "$CLIP_R1" \
    --clip_R2 "$CLIP_R2" \
    --cores 4 \
    --gzip \
    --output_dir "$D03" \
    "$D02/${SAMPLE}_R1.extracted.fastq.gz" \
    "$D02/${SAMPLE}_R2.extracted.fastq.gz"

# Trim Galore names paired outputs *_val_1.fq.gz / *_val_2.fq.gz
echo "[$(date '+%F %T')] trimmed outputs:"
ls -lh "$D03"/*_val_*.fq.gz
