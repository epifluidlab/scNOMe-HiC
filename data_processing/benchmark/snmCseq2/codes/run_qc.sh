#!/bin/bash
#SBATCH -A b1042
#SBATCH -p genomics
#SBATCH -t 2:00:00
#SBATCH -N 1
#SBATCH --mem=8G
#SBATCH --cpus-per-task=1
#SBATCH --array=1-250
#SBATCH --job-name=snmcseq2_qc
#SBATCH --output=logs/04.qc/qc.%a.out
#SBATCH --error=logs/04.qc/qc.%a.err

# conda on PATH; override with SCNOMEHIC_CONDA_SH for a different install.
# --- repo paths: edit paths.yaml at the repository root, not this file -------
_r="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]:-$0}")")" && pwd)"
while [ "$_r" != "/" ] && [ ! -f "$_r/paths.sh" ]; do _r="$(dirname "$_r")"; done
source "$_r/paths.sh"

source "${SCNOMEHIC_CONDA_SH:-${CONDA_SH}}"
cd /gpfs/projects/b1042/epifluidlab/yoshii/scnomehic_paper/benchmark/snmCseq2

conda activate scnomehic

mkdir -p logs/04.qc
mkdir -p qc_stats

prefix=$(awk -v num="${SLURM_ARRAY_TASK_ID}" 'NR==num{print; exit}' acc_list.txt)
echo "Cell: ${prefix}"

# Determine genome from task ID (mirrors 02.alignment.sh and 03.summary.sh)
if [ "${SLURM_ARRAY_TASK_ID}" -le 153 ]; then
    genome="hg38"
else
    genome="mm10"
fi
echo "Genome: ${genome}"

python codes/snmcseq2_qc_per_cell.py \
    --cell_id "${prefix}" \
    --project_dir . \
    --output_dir qc_stats \
    --genome "${genome}" \
    --mapq 30
