#!/bin/bash
# ============================================================================
# 09_build_allc.sh — per-cell (SLURM ARRAY over passing cells) construction of
# the methylpy-format allc file. This is the final step in scope; downstream
# GCG removal / feature matrix / clustering + scNOMeHiC comparison come later.
# Submit with:  sbatch --array=1-<Npass>%50 code/09_build_allc.sh
# ============================================================================
#SBATCH --job-name=scwgbs_09_allc
#SBATCH --account=b1042
#SBATCH --partition=genomics
#SBATCH --time=01:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=8G
#SBATCH --output=code/logs/09_allc_%A_%a.out
#SBATCH --error=code/logs/09_allc_%A_%a.err
set -euo pipefail
cd "${SLURM_SUBMIT_DIR:-$(dirname "$0")/..}"
source code/config.sh
activate_env

CELL=$(sed -n "${SLURM_ARRAY_TASK_ID}p" "$D06/passing_cells.txt")

echo "[$(date '+%F %T')] [$CELL] building allc"
python code/09_build_allc.py \
    --meth-dir "$D08/$CELL" \
    --cell "$CELL" \
    --genome-fa "$GENOME_FA" \
    --out "$D09/${CELL}/allc_${CELL}.tsv.gz"
echo "[$(date '+%F %T')] [$CELL] allc: $D09/${CELL}/allc_${CELL}.tsv.gz"
