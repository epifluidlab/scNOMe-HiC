#!/bin/bash
#SBATCH -A b1042
#SBATCH -p genomics
#SBATCH -t 3:00:00
#SBATCH -N 1
#SBATCH --mem=48G
#SBATCH --cpus-per-task=8
#SBATCH --job-name=scnome_hcg_pc
#SBATCH --output=logs/hcg_genome/scnome_hcg_percell.txt
#SBATCH --error=logs/hcg_genome/scnome_hcg_percell.err

# Per-cell (R1 union R2) destranded HCG for scnome -- correct merge of the two mates.
# conda on PATH; override with SCNOMEHIC_CONDA_SH for a different install.
# --- repo paths: edit paths.yaml at the repository root, not this file -------
_r="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]:-$0}")")" && pwd)"
while [ "$_r" != "/" ] && [ ! -f "$_r/paths.sh" ]; do _r="$(dirname "$_r")"; done
source "$_r/paths.sh"

source "${SCNOMEHIC_CONDA_SH:-${CONDA_SH}}"
conda activate scnomehic
B=/gpfs/projects/b1042/epifluidlab/yoshii/scnomehic_paper/benchmark
cd $B/summary
mkdir -p logs/hcg_genome
echo "[$(date)] scnome_hcg_percell.py"
python3 scnome_hcg_percell.py
echo "[$(date)] DONE"
