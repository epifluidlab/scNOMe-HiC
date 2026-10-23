#!/bin/bash
#SBATCH -A b1042
#SBATCH -p genomics
#SBATCH -t 36:00:00
#SBATCH -N 1
#SBATCH --mem=64G
#SBATCH --cpus-per-task=8
#SBATCH --array=1-250
#SBATCH --job-name=qc
#SBATCH --output=logs/01.trimming/trimming.%a.txt
#SBATCH --error=logs/01.trimming/trimming.%a.err

# conda on PATH; override with SCNOMEHIC_CONDA_SH for a different install.
# --- repo paths: edit paths.yaml at the repository root, not this file -------
_r="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]:-$0}")")" && pwd)"
while [ "$_r" != "/" ] && [ ! -f "$_r/paths.sh" ]; do _r="$(dirname "$_r")"; done
source "$_r/paths.sh"

source "${SCNOMEHIC_CONDA_SH:-${CONDA_SH}}"
cd ${WORK_ROOT}/benchmark/snmCseq2

conda activate scnomehic

infolder=01.fastq
outfolder=02.fastqc_out
outfolder_fq=03.trimmed_fastq
outfolder_2=04.fastqc_out_2

mkdir -p ${outfolder_fq}
mkdir -p ${outfolder}
mkdir -p ${outfolder_2}

prefix=`cat acc_list.txt | awk -v num=${SLURM_ARRAY_TASK_ID} 'NR == num'`
echo ${prefix}

fastqc --outdir ${outfolder} -t 8 ${infolder}/${prefix}_1.fastq ${infolder}/${prefix}_2.fastq
echo "First fastqc Done"

# ----------------------------
# Step 1: adapter + quality trimming
# ----------------------------
cutadapt -q 20 -m 62 \
  -a AGATCGGAAGAGCACACGTCTGAAC \
  -A AGATCGGAAGAGCGTCGTGTAGGGA \
  -o ${outfolder_fq}/${prefix}_1.adapt.fq.gz \
  -p ${outfolder_fq}/${prefix}_2.adapt.fq.gz \
  ${infolder}/${prefix}_1.fastq \
  ${infolder}/${prefix}_2.fastq

# ----------------------------
# Step 2: trim 16 bp from 5' end (PBAT-compatible)
# ----------------------------
cutadapt -u 16 -m 30 \
  -o ${outfolder_fq}/${prefix}_1.clean.fq.gz \
  -p ${outfolder_fq}/${prefix}_2.clean.fq.gz \
  ${outfolder_fq}/${prefix}_1.adapt.fq.gz \
  ${outfolder_fq}/${prefix}_2.adapt.fq.gz

# ----------------------------
# FastQC on final cleaned reads
# ----------------------------
fastqc --outdir ${outfolder_2} -t 8 \
  ${outfolder_fq}/${prefix}_1.clean.fq.gz \
  ${outfolder_fq}/${prefix}_2.clean.fq.gz

echo "FastQC done (clean)"
