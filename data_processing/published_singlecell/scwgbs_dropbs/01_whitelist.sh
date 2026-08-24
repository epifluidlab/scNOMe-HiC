#!/bin/bash
# ============================================================================
# 01_whitelist.sh — identify the cell-barcode whitelist with umi_tools.
# Barcode = R2 bases 25-39 (15 bp) after the 24 bp constant TAAGTAGAAGATGGTATATGAGAT.
# ============================================================================
#SBATCH --job-name=scwgbs_01_whitelist
#SBATCH --account=b1042
#SBATCH --partition=genomics
#SBATCH --time=08:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G
#SBATCH --output=code/logs/01_whitelist_%j.out
#SBATCH --error=code/logs/01_whitelist_%j.err
set -euo pipefail
cd "${SLURM_SUBMIT_DIR:-$(dirname "$0")/..}"
source code/config.sh
activate_env
mkdir -p "$D01"

echo "[$(date '+%F %T')] umi_tools whitelist on $R2"
umi_tools whitelist \
    --stdin "$R2" \
    --error-correct-threshold=1 \
    --extract-method=regex \
    --bc-pattern="$BC_PATTERN" \
    --set-cell-number=$N_CELLS \
    --log2stderr \
    --stdout "$D01/whitelist.txt"

echo "[$(date '+%F %T')] whitelist barcodes: $(wc -l < "$D01/whitelist.txt")"
