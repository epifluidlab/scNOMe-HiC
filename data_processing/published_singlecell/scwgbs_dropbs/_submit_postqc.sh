#!/bin/bash
# ============================================================================
# _submit_postqc.sh — SLURM launcher job. Runs after QC (06) completes; reads
# passing_cells.txt and submits the per-cell array steps 07->08->09 sized to
# the number of passing cells (unknown until QC has run). Chained via aftercorr
# so each cell flows 07->08->09 independently.
# ============================================================================
#SBATCH --job-name=scwgbs_launch_postqc
#SBATCH --account=b1042
#SBATCH --partition=genomics
#SBATCH --time=00:10:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=2G
#SBATCH --output=code/logs/launch_postqc_%j.out
#SBATCH --error=code/logs/launch_postqc_%j.err
set -euo pipefail
cd "${SLURM_SUBMIT_DIR:-$(dirname "$0")/..}"
source code/config.sh

PASS="$D06/passing_cells.txt"
if [[ ! -s "$PASS" ]]; then
    echo "ERROR: $PASS missing/empty — QC produced no passing cells"; exit 1
fi
n=$(wc -l < "$PASS")
THROTTLE=50
echo "[$(date '+%F %T')] submitting postqc arrays for $n passing cells"

j7=$(sbatch --parsable --array=1-${n}%${THROTTLE} code/07_merge_dedup.sh)
j8=$(sbatch --parsable --dependency=aftercorr:$j7 --array=1-${n}%${THROTTLE} code/08_call_methylation.sh)
j9=$(sbatch --parsable --dependency=aftercorr:$j8 --array=1-${n}%${THROTTLE} code/09_build_allc.sh)
echo "[$(date '+%F %T')] dedup=$j7 methyl=$j8 allc=$j9 ; allc -> $D09/<cell>/allc_<cell>.tsv.gz"
