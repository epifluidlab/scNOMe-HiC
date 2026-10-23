#!/bin/bash
#SBATCH -A b1042
#SBATCH -p genomics
#SBATCH -t 36:00:00
#SBATCH -N 1
#SBATCH --mem=64G
#SBATCH --cpus-per-task=10
#SBATCH --array=1-64
#SBATCH --job-name=snmCAT_brain
#SBATCH --output=/gpfs/projects/b1042/epifluidlab/yoshii/scnomehic_paper/benchmark/snmCAT/codes/logs/04.map/snakemake.%a.out
#SBATCH --error=/gpfs/projects/b1042/epifluidlab/yoshii/scnomehic_paper/benchmark/snmCAT/codes/logs/04.map/snakemake.%a.err
# conda on PATH; override with SCNOMEHIC_CONDA_SH for a different install.
# --- repo paths: edit paths.yaml at the repository root, not this file -------
_r="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]:-$0}")")" && pwd)"
while [ "$_r" != "/" ] && [ ! -f "$_r/paths.sh" ]; do _r="$(dirname "$_r")"; done
source "$_r/paths.sh"

source "${SCNOMEHIC_CONDA_SH:-${CONDA_SH}}"
conda activate mapping
export PATH="$CONDA_PREFIX/bin:$PATH"
BASE="/gpfs/projects/b1042/epifluidlab/yoshii/scnomehic_paper/benchmark/snmCAT"
CMD_FILE="${BASE}/mapping_brain/snakemake/snakemake_cmd.txt"
mkdir -p "${BASE}/codes/logs/04.map" "${BASE}/mapping_brain/.slurm_tmp"
N=$(grep -cve '^\s*$' "${CMD_FILE}")
if [[ "${SLURM_ARRAY_TASK_ID}" -gt "${N}" ]]; then echo "idx>${N} skip"; exit 0; fi
CMD=$(grep -ve '^\s*$' "${CMD_FILE}" | sed -n "${SLURM_ARRAY_TASK_ID}p")
echo "[$(date)] Task ${SLURM_ARRAY_TASK_ID}/${N}: ${CMD}"
export TMPDIR="${BASE}/mapping_brain/.slurm_tmp/${SLURM_JOB_ID}_${SLURM_ARRAY_TASK_ID}"; mkdir -p "${TMPDIR}"
eval "${CMD} --rerun-incomplete --unlock" || true
eval "${CMD} --rerun-incomplete"
echo "[$(date)] DONE"
