#!/bin/bash
#SBATCH --account=b1042
#SBATCH --partition=genomics
#SBATCH --job-name=s7_sat
#SBATCH --time=12:00:00
#SBATCH --mem=64G
#SBATCH --cpus-per-task=4
#SBATCH --output=${WORK_ROOT}/analysis/s7/logs/%x_%A_%a.out
#SBATCH --error=${WORK_ROOT}/analysis/s7/logs/%x_%A_%a.err
# Saturation array: one task per (cell, fraction) line in tasks.tsv.
# Submit with:  sbatch --array=1-<N>%<throttle> submit_array.sbatch
# (01_make_tasklist.sh prints <N>; throttle caps concurrent tasks, e.g. %150)
# --- repo paths: edit paths.yaml at the repository root, not this file -------
_r="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]:-$0}")")" && pwd)"
while [ "$_r" != "/" ] && [ ! -f "$_r/paths.sh" ]; do _r="$(dirname "$_r")"; done
source "$_r/paths.sh"

set -euo pipefail

# sbatch copies this script to a spool dir, so BASH_SOURCE cannot locate the
# siblings -- resolve from the submit directory instead.
CODE_DIR="${SLURM_SUBMIT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"
TASKS=${CODE_DIR}/tasks.tsv

LINE=$(sed -n "${SLURM_ARRAY_TASK_ID}p" "$TASKS")
CELL=$(echo "$LINE" | cut -f1)
FRAC=$(echo "$LINE" | cut -f2)
echo "array task ${SLURM_ARRAY_TASK_ID}: CELL=$CELL FRAC=$FRAC on $(hostname)"

bash "${CODE_DIR}/02_run_one.sh" "$CELL" "$FRAC"
