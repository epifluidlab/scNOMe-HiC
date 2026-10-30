#!/bin/bash
#SBATCH -A b1042
#SBATCH -p genomics
#SBATCH -t 36:00:00
#SBATCH -N 1
#SBATCH --mem=64G
#SBATCH --cpus-per-task=8
#SBATCH --array=1-51
#SBATCH --job-name=qc
#SBATCH --output=logs/01.qc_trim/qc_trim.%a.txt
#SBATCH --error=logs/01.qc_trim/qc_trim.%a.err

# conda on PATH; override with SCNOMEHIC_CONDA_SH for a different install.
# --- repo paths: edit paths.yaml at the repository root, not this file -------
# SLURM copies a batch script to /var/spool/slurmd/<job>/slurm_script, so walking
# up from BASH_SOURCE cannot reach the repository. $SCNOMEHIC_REPO is tried first;
# submit with: sbatch --export=ALL,SCNOMEHIC_REPO=/path/to/repo
_r="${SCNOMEHIC_REPO:-}"
if [ -z "$_r" ] || [ ! -f "$_r/paths.sh" ]; then
    _r="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]:-$0}")")" && pwd)"
    while [ "$_r" != "/" ] && [ ! -f "$_r/paths.sh" ]; do _r="$(dirname "$_r")"; done
fi
[ -f "$_r/paths.sh" ] || { echo "ERROR: paths.sh not found. Set SCNOMEHIC_REPO to the repository root." >&2; exit 1; }
source "$_r/paths.sh"

source "${SCNOMEHIC_CONDA_SH:-${CONDA_SH}}"
cd ${WORK_ROOT}/benchmark/smallwood || { echo "ERROR: cd to working dir failed"; exit 1; }
conda activate scnomehic

infolder=01.fastq
outfolder=02.fastqc_out
outfolder_fq=03.trimmed_fastq

prefix=`cat acc_list.txt | awk -v num=${SLURM_ARRAY_TASK_ID} 'NR == num'`
echo ${prefix}
fastqc --outdir ${outfolder} -t 8 ${infolder}/${prefix}_1.fastq ${infolder}/${prefix}_2.fastq
echo "First fastqc Done"

trim_galore --paired_end -clip_r1 9 -clip_r2 9 -j 8 -o ${outfolder_fq} --gzip --fastqc --fastqc_args "--outdir ${outfolder} -t 8" ${infolder}/${prefix}_1.fastq ${infolder}/${prefix}_2.fastq
echo "Trimming Done"
