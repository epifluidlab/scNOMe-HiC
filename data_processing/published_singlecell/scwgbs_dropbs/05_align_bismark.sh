#!/bin/bash
# ============================================================================
# 05_align_bismark.sh — per-cell Bismark (bowtie2) alignment. SLURM ARRAY:
# one task per cell (index -> line in $CELL_LIST). R1 and R2 are aligned
# separately as single-end libraries: R2 default (directional), R1 with --pbat.
# Submit with:  sbatch --array=1-<Ncells>%50 code/05_align_bismark.sh
# ============================================================================
#SBATCH --job-name=scwgbs_05_align
#SBATCH --account=b1042
#SBATCH --partition=genomics
#SBATCH --time=04:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=6
#SBATCH --mem=24G
#SBATCH --output=code/logs/05_align_%A_%a.out
#SBATCH --error=code/logs/05_align_%A_%a.err
set -euo pipefail
cd "${SLURM_SUBMIT_DIR:-$(dirname "$0")/..}"
source code/config.sh
activate_env

BC=$(sed -n "${SLURM_ARRAY_TASK_ID}p" "$CELL_LIST")
CELL=cell_${BC}
OUT=$D05/$CELL
mkdir -p "$OUT/R1" "$OUT/R2" "$OUT/tmp"

# per-cell fastqs written by _split_percell.py
R1FQ=$D04/percell/${CELL}_R1.fastq.gz
R2FQ=$D04/percell/${CELL}_R2.fastq.gz
if [[ ! -s "$R1FQ" || ! -s "$R2FQ" ]]; then
    echo "[$CELL] missing/empty per-cell fastq (R1=$R1FQ R2=$R2FQ) — skipping"; exit 0
fi

# NOTE: bismark 0.24.2 forbids --basename together with --multicore; per-cell
# inputs are small, so single-core alignment is fine (and lower memory).
echo "[$(date '+%F %T')] [$CELL] Bismark R2 (default/directional)"
bismark --bowtie2 --genome "$GENOME_DIR" \
    --single_end "$R2FQ" \
    --basename "${CELL}_R2" --temp_dir "$OUT/tmp" -o "$OUT/R2"

echo "[$(date '+%F %T')] [$CELL] Bismark R1 (--pbat)"
bismark --bowtie2 --pbat --genome "$GENOME_DIR" \
    --single_end "$R1FQ" \
    --basename "${CELL}_R1" --temp_dir "$OUT/tmp" -o "$OUT/R1"

echo "[$(date '+%F %T')] [$CELL] done"
