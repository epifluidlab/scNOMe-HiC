#!/bin/bash
# ============================================================================
# 08_call_methylation.sh — per-cell (SLURM ARRAY over passing cells) methylKit
# per-cytosine methylation calling on the deduplicated bam.
# Submit with:  sbatch --array=1-<Npass>%50 code/08_call_methylation.sh
# ============================================================================
#SBATCH --job-name=scwgbs_08_meth
#SBATCH --account=b1042
#SBATCH --partition=genomics
#SBATCH --time=02:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=2
#SBATCH --mem=12G
#SBATCH --output=code/logs/08_meth_%A_%a.out
#SBATCH --error=code/logs/08_meth_%A_%a.err
set -euo pipefail
cd "${SLURM_SUBMIT_DIR:-$(dirname "$0")/..}"
source code/config.sh
activate_env "$ENV_R"        # methylKit lives in the separate R env

CELL=$(sed -n "${SLURM_ARRAY_TASK_ID}p" "$D06/passing_cells.txt")
DEDUP=$D07/$CELL/${CELL}.dedup.bam
OUT=$D08/$CELL
mkdir -p "$OUT"

echo "[$(date '+%F %T')] [$CELL] methylKit processBismarkAln"
Rscript code/08_call_methylation.R "$DEDUP" "$CELL" "hg38" "$OUT"
echo "[$(date '+%F %T')] [$CELL] methylation tables in $OUT"
