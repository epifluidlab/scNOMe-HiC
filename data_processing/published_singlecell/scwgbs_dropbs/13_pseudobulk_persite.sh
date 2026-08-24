#!/bin/bash
# ============================================================================
# 13_pseudobulk_persite.sh — aggregate all GCG-free allc into a scWGBS
# pseudobulk per CpG SITE (for the per-locus comparison to NOMe-HiC).
# ============================================================================
#SBATCH --job-name=scwgbs_13_persite
#SBATCH --account=b1042
#SBATCH --partition=genomics
#SBATCH --time=04:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=2
#SBATCH --mem=64G
#SBATCH --output=code/logs/13_persite_%j.out
#SBATCH --error=code/logs/13_persite_%j.err
set -euo pipefail
cd "${SLURM_SUBMIT_DIR:-$(dirname "$0")/..}"
source code/config.sh
activate_env
mkdir -p "$WORK/13_persite"

python code/13_pseudobulk_persite.py \
    --allc-glob "$D10/*/allc_*.noGCG.tsv.gz" \
    --out "$WORK/13_persite/wgbs_pseudobulk_HCG.persite.tsv.gz"
echo "[$(date '+%F %T')] done"
