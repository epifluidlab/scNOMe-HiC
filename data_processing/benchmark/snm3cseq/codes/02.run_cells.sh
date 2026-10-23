#!/bin/bash
#SBATCH -A b1042
#SBATCH -p genomics
#SBATCH -t 6:00:00
#SBATCH -N 1 -n 1 --cpus-per-task=10 --mem=32G
#SBATCH --job-name=snm3c_02_cell
#SBATCH --output=${WORK_ROOT}/benchmark/snm3c_100/logs/cell_%a.out
#SBATCH --error=${WORK_ROOT}/benchmark/snm3c_100/logs/cell_%a.out
#
# STEP 02 -- one array task per YAP Group (= one cell), each `snakemake -j 10`.
# All 100 run concurrently instead of a 50h sequential loop.
# --- repo paths: edit paths.yaml at the repository root, not this file -------
_r="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]:-$0}")")" && pwd)"
while [ "$_r" != "/" ] && [ ! -f "$_r/paths.sh" ]; do _r="$(dirname "$_r")"; done
source "$_r/paths.sh"

set +u
source ${CONDA_SH}
conda activate mapping
export PATH="$CONDA_PREFIX/bin:$PATH"
W=${WORK_ROOT}/benchmark/snm3c_100
CMD_FILE=$W/alignment/snakemake/snakemake_cmd.txt
i=$((SLURM_ARRAY_TASK_ID + 1))
CMD=$(grep -ve '^[[:space:]]*$' "$CMD_FILE" | sed -n "${i}p")
[ -z "$CMD" ] && { echo "no command at index $i"; exit 0; }
export OMP_NUM_THREADS=10
export TMPDIR="$W/.tmp/${SLURM_ARRAY_TASK_ID}"; mkdir -p "$TMPDIR"
echo "[$(date)] task $SLURM_ARRAY_TASK_ID -> $CMD"
eval "$CMD"
echo "[$(date)] exit=$? task $SLURM_ARRAY_TASK_ID DONE"
