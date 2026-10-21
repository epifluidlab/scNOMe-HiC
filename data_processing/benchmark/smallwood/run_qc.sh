#!/bin/bash
#SBATCH -A b1042
#SBATCH -p genomics
#SBATCH -t 4:00:00
#SBATCH -N 1
#SBATCH --mem=16G
#SBATCH --cpus-per-task=1
#SBATCH --array=1-51
#SBATCH --job-name=qc.%a
#SBATCH --output=logs/04.qc_collect/qc.%a.out
#SBATCH --error=logs/04.qc_collect/qc.%a.err

# conda on PATH; override with SCNOMEHIC_CONDA_SH for a different install.
source "${SCNOMEHIC_CONDA_SH:-/projects/b1198/epifluidlab/yoshii/software/conda/etc/profile.d/conda.sh}"
cd /gpfs/projects/b1042/epifluidlab/yoshii/scnomehic_paper/benchmark/smallwood

conda activate scnomehic

mkdir -p logs/04.qc_collect
mkdir -p qc_stats

prefix=$(awk -v num="${SLURM_ARRAY_TASK_ID}" 'NR==num{print; exit}' acc_list.txt)

python smallwood_qc_per_cell.py \
    --cell_id ${prefix} \
    --project_dir . \
    --output_dir qc_stats \
    --mapq 30

