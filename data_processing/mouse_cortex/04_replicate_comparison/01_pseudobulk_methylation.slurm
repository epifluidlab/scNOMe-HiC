#!/bin/bash
#SBATCH -A b1042
#SBATCH -p genomics
#SBATCH -t 02:00:00
#SBATCH -N 1
#SBATCH --mem=32G
#SBATCH --cpus-per-task=1
#SBATCH --array=1-4
#SBATCH --job-name=pb_methy.%a
#SBATCH --output=${WORK_ROOT}/mouse_cortex/replicate_comparison/logs/pb_methy.%A_%a.out
#SBATCH --error=${WORK_ROOT}/mouse_cortex/replicate_comparison/logs/pb_methy.%A_%a.err
#
# Step 1: pseudobulk GCH (accessibility) + HCG (methylation) per replicate, 250kb.
# Pooled ratio: sum methylated_reads and total_reads across cells, then divide.
# Array tasks:  1=rep1/GCH  2=rep1/HCG  3=rep2/GCH  4=rep2/HCG
# --- repo paths: edit paths.yaml at the repository root, not this file -------
_r="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]:-$0}")")" && pwd)"
while [ "$_r" != "/" ] && [ ! -f "$_r/paths.sh" ]; do _r="$(dirname "$_r")"; done
source "$_r/paths.sh"

set -eo pipefail

source ~/.bashrc
conda activate scnomehic

BASE=${WORK_ROOT}/mouse_cortex
RC=${BASE}/replicate_comparison
LABEL=250kb

case "${SLURM_ARRAY_TASK_ID}" in
  1) REP=rep1; CTX=GCH ;;
  2) REP=rep1; CTX=HCG ;;
  3) REP=rep2; CTX=GCH ;;
  4) REP=rep2; CTX=HCG ;;
  *) echo "bad task id ${SLURM_ARRAY_TASK_ID}" >&2; exit 1 ;;
esac

echo "[$(date)] task ${SLURM_ARRAY_TASK_ID}: ${REP} ${CTX} ${LABEL}"

python "${RC}/code/01_pseudobulk_methylation.py" \
  --rep "${REP}" \
  --context "${CTX}" \
  --label "${LABEL}" \
  --cell_list "${RC}/cell_lists/${REP}.txt" \
  --methy_dir "${BASE}/08.methylation_snakemake" \
  --out_dir "${RC}/pseudobulk"

echo "[$(date)] done."
