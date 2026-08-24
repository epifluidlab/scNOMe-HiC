#!/bin/bash
# ============================================================================
# 06_qc_filter.sh — filter out cells with low mapping efficiency / few raw reads
# based on the Bismark SE reports. Produces $D06/passing_cells.txt used by the
# downstream per-cell array steps. Thresholds come from config.sh (tunable).
# ============================================================================
#SBATCH --job-name=scwgbs_06_qc
#SBATCH --account=b1042
#SBATCH --partition=genomics
#SBATCH --time=00:30:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=4G
#SBATCH --output=code/logs/06_qc_%j.out
#SBATCH --error=code/logs/06_qc_%j.err
set -euo pipefail
cd "${SLURM_SUBMIT_DIR:-$(dirname "$0")/..}"
source code/config.sh
activate_env
mkdir -p "$D06"

python code/_parse_bismark_qc.py \
    --align-dir "$D05" \
    --min-map-eff "$MIN_MAP_EFF" \
    --min-reads "$MIN_READS" \
    --out-table "$D06/qc_metrics.tsv" \
    --out-pass "$D06/passing_cells.txt"

echo "[$(date '+%F %T')] QC table: $D06/qc_metrics.tsv"
echo "[$(date '+%F %T')] passing cells: $(wc -l < "$D06/passing_cells.txt")"
