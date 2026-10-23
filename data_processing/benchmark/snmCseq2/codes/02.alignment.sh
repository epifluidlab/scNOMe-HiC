#!/bin/bash
#SBATCH -A b1042
#SBATCH -p genomics
#SBATCH -t 36:00:00
#SBATCH -N 1
#SBATCH --mem=64G
#SBATCH --cpus-per-task=8
#SBATCH --array=154-250
#SBATCH --job-name=alignment
#SBATCH --output=logs/02.alignment/alignment.%a.txt
#SBATCH --error=logs/02.alignment/alignment.%a.err

# conda on PATH; override with SCNOMEHIC_CONDA_SH for a different install.
# --- repo paths: edit paths.yaml at the repository root, not this file -------
_r="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]:-$0}")")" && pwd)"
while [ "$_r" != "/" ] && [ ! -f "$_r/paths.sh" ]; do _r="$(dirname "$_r")"; done
source "$_r/paths.sh"

source "${SCNOMEHIC_CONDA_SH:-${CONDA_SH}}"
cd ${WORK_ROOT}/benchmark/snmCseq2

conda activate scnomehic

prefix=`cat acc_list.txt | awk -v num=${SLURM_ARRAY_TASK_ID} 'NR == num'`
echo ${prefix}

input=03.trimmed_fastq
out=05.align

# ----------------------------
# R1: PBAT mapping
# ----------------------------
bismark -bowtie2 --genome ${REFERENCE_ROOT}/mm10_bismark/ -pbat ${input}/${prefix}_1.clean.fq.gz -o ${out}/ 
bismark -bowtie2 -non_directional --genome ${REFERENCE_ROOT}/mm10_bismark/ ${input}/${prefix}_2.clean.fq.gz -o ${out}/ 

# bismark -bowtie2 --genome ${REFERENCE_ROOT}/hg38_bismark -pbat -1 ${input}/${prefix}_1.clean.fq.gz -2 ${input}/${prefix}_2.clean.fq.gz -o ${out}/ 
