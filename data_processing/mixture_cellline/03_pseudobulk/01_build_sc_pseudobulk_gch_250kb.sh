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

set -eo pipefail
source /projects/b1198/epifluidlab/yoshii/software/conda/etc/profile.d/conda.sh
conda activate scnomehic
set -u

WORK=/gpfs/projects/b1198/epifluidlab/yoshii/scnomehic_paper/fig2
cd "$WORK"; mkdir -p logs
export NCPU=8
echo "=== $(date) | host $(hostname) ==="
python "$(dirname "$(readlink -f "$0")")/01_build_sc_pseudobulk_gch_250kb.py"
echo "=== done $(date) ==="
