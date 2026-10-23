#!/bin/bash
#SBATCH -A b1042
#SBATCH -p genomics
#SBATCH -t 01:00:00
#SBATCH -N 1
#SBATCH --mem=32G
#SBATCH --cpus-per-task=8
#SBATCH --job-name=sc_pbulk_gch
#SBATCH --output=logs/sc_pseudobulk_gch_250kb.%j.out
#SBATCH --error=logs/sc_pseudobulk_gch_250kb.%j.err

# --- repo paths: edit paths.yaml at the repository root, not this file -------
_r="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]:-$0}")")" && pwd)"
while [ "$_r" != "/" ] && [ ! -f "$_r/paths.sh" ]; do _r="$(dirname "$_r")"; done
source "$_r/paths.sh"

set -eo pipefail
source ${CONDA_SH}
conda activate scnomehic
set -u

WORK=${WORK_ROOT}/analysis/fig2
cd "$WORK"; mkdir -p logs
export NCPU=8
echo "=== $(date) | host $(hostname) ==="
python "$(dirname "$(readlink -f "$0")")/01_build_sc_pseudobulk_gch_250kb.py"
echo "=== done $(date) ==="
