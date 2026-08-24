#!/bin/bash
# ============================================================================
# 10_remove_gcg.sh — per-cell (SLURM ARRAY over passing cells) removal of
# GCG-context cytosines from the allc, to match NOMe-HiC CpG methylation
# (which uses HCG only; GCG is CpG/GpC-ambiguous and dropped).
# Output: $D10/<cell>/allc_<cell>.noGCG.tsv.gz
# Submit with:  sbatch --array=1-<Npass>%50 code/10_remove_gcg.sh
# ============================================================================
#SBATCH --job-name=scwgbs_10_noGCG
#SBATCH --account=b1042
#SBATCH --partition=genomics
#SBATCH --time=00:30:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=4G
#SBATCH --output=code/logs/10_noGCG_%A_%a.out
#SBATCH --error=code/logs/10_noGCG_%A_%a.err
set -euo pipefail
cd "${SLURM_SUBMIT_DIR:-$(dirname "$0")/..}"
source code/config.sh
activate_env

CELL=$(sed -n "${SLURM_ARRAY_TASK_ID}p" "$D06/passing_cells.txt")
ALLC=$D09/$CELL/allc_${CELL}.tsv.gz
if [[ ! -s "$ALLC" ]]; then echo "[$CELL] no allc — skipping"; exit 0; fi

echo "[$(date '+%F %T')] [$CELL] removing GCG cytosines"
python code/10_remove_gcg.py \
    --allc "$ALLC" \
    --genome-fa "$GENOME_FA" \
    --out "$D10/${CELL}/allc_${CELL}.noGCG.tsv.gz"
echo "[$(date '+%F %T')] [$CELL] -> $D10/${CELL}/allc_${CELL}.noGCG.tsv.gz"
