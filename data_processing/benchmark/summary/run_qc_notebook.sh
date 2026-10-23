#!/bin/bash
#SBATCH -A b1042
#SBATCH -p genomics
#SBATCH -t 2:00:00
#SBATCH -N 1
#SBATCH --mem=64G
#SBATCH --cpus-per-task=4
#SBATCH --job-name=run_qc_nb
#SBATCH --output=summary/logs/run_qc_nb.out
#SBATCH --error=summary/logs/run_qc_nb.err

# Execute qc.ipynb end-to-end to regenerate all figures with the corrected data.
# Run a COPY at the benchmark root so the kernel CWD == benchmark/ and the notebook's
# relative paths (droplethic/, summary/, figures/) resolve correctly.
# conda on PATH; override with SCNOMEHIC_CONDA_SH for a different install.
# --- repo paths: edit paths.yaml at the repository root, not this file -------
_r="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]:-$0}")")" && pwd)"
while [ "$_r" != "/" ] && [ ! -f "$_r/paths.sh" ]; do _r="$(dirname "$_r")"; done
source "$_r/paths.sh"

source "${SCNOMEHIC_CONDA_SH:-${CONDA_SH}}"
conda activate scnomehic
cd ${WORK_ROOT}/benchmark
mkdir -p summary/logs

cp summary/qc.ipynb _tmp_qc_run.ipynb
echo "[$(date)] executing notebook ..."
jupyter nbconvert --to notebook --execute --inplace \
    --ExecutePreprocessor.timeout=1800 \
    _tmp_qc_run.ipynb
rc=$?
echo "[$(date)] nbconvert exit=$rc"
exit $rc
