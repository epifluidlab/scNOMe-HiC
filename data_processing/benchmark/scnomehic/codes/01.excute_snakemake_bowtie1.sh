#!/bin/bash
#SBATCH -A b1042
#SBATCH -p genomics
#SBATCH -t 36:00:00
#SBATCH -N 1
#SBATCH --mem=64G
#SBATCH --cpus-per-task=10
#SBATCH --array=1-64
#SBATCH --job-name=scnomehic_align
#SBATCH --output=logs/02.alignment/snakemake_bowtie1.%a.out
#SBATCH --error=logs/02.alignment/snakemake_bowtie1.%a.err

# set -euo pipefail

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
conda activate mapping_bowtie1   # <-- use the env that has yap/snakemake deps

export PATH="$CONDA_PREFIX/bin:$PATH"

#yap start-from-cell-fastq --output_dir alignment/ --config_path codes/mapping_config.ini --fastq_pattern "fastq/*-R[12].fq.gz"

ALIGNMENT_FOLDER="alignment_bowtie1"

BASE="${WORK_ROOT}/benchmark/scnomehic"
CMD_FILE="${BASE}/${ALIGNMENT_FOLDER}/snakemake/snakemake_cmd.txt"

mkdir -p "${BASE}/${ALIGNMENT_FOLDER}/logs/02.alignment" "${BASE}/${ALIGNMENT_FOLDER}/.slurm_tmp"
cd "${BASE}/${ALIGNMENT_FOLDER}/snakemake"

# ---- sanity checks ----
if [[ ! -f "${CMD_FILE}" ]]; then
  echo "ERROR: CMD_FILE not found: ${CMD_FILE}" >&2
  exit 1
fi

N=$(grep -cve '^\s*$' "${CMD_FILE}" || true)
if [[ "${N}" -lt 1 ]]; then
  echo "ERROR: CMD_FILE has no commands." >&2
  exit 1
fi

if [[ "${SLURM_ARRAY_TASK_ID}" -gt "${N}" ]]; then
  echo "ERROR: array index ${SLURM_ARRAY_TASK_ID} exceeds number of commands ${N}" >&2
  exit 1
fi

# Pull the Nth non-empty line (1-indexed)
CMD=$(grep -ve '^\s*$' "${CMD_FILE}" | sed -n "${SLURM_ARRAY_TASK_ID}p")

echo "[$(date)] Task ${SLURM_ARRAY_TASK_ID}/${N}"
echo "CMD: ${CMD}"

# Ensure snakemake uses the resources we requested
export OMP_NUM_THREADS="${SLURM_CPUS_PER_TASK:-1}"
export TMPDIR="${BASE}/${ALIGNMENT_FOLDER}/.slurm_tmp/${SLURM_JOB_ID}_${SLURM_ARRAY_TASK_ID}"
mkdir -p "${TMPDIR}"

# Run
eval "${CMD}"
echo "[$(date)] DONE"
