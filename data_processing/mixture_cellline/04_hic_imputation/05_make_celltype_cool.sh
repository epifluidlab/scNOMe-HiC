#!/bin/bash
#SBATCH --account=b1042
#SBATCH --partition=genomics
#SBATCH --job-name=lm25_step05_make_cool
#SBATCH --time=02:00:00
#SBATCH --mem=64G
#SBATCH --cpus-per-task=2
#SBATCH --output=${WORK_ROOT}/mixture_cellline/loop_majortype_25kb/logs/%x_%j.out
#SBATCH --error=${WORK_ROOT}/mixture_cellline/loop_majortype_25kb/logs/%x_%j.err
# STEP 05 — Build per-celltype Q/E/T cool files (and their *2.cool sum-of-squares).
# --- repo paths: edit paths.yaml at the repository root, not this file -------
_r="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]:-$0}")")" && pwd)"
while [ "$_r" != "/" ] && [ ! -f "$_r/paths.sh" ]; do _r="$(dirname "$_r")"; done
source "$_r/paths.sh"

set -eo pipefail

# conda on PATH; override with SCNOMEHIC_CONDA_SH for a different install.
source "${SCNOMEHIC_CONDA_SH:-${CONDA_SH}}"
conda activate hic_env

THIS_DIR=${WORK_ROOT}/mixture_cellline/loop_majortype_25kb
CELL_TABLE=$THIS_DIR/cell_table.tsv
ROOT=${TMP_ROOT}/loop_majortype_25kb
IMP_DIR=$ROOT/hicluster_impute
OUT_DIR=$ROOT/per_celltype
CHROM_FILE=${REFERENCE_ROOT}/hg38/autosomes.chrom.sizes
MAKE_COOL_PY="$(dirname "$(readlink -f "$0")")/make_celltype_cool.py"

mkdir -p "$OUT_DIR"

echo "[$(date +%H:%M:%S)] running make_celltype_cool.py"

python "$MAKE_COOL_PY" \
    --cell_table "$CELL_TABLE" \
    --in_dir "$IMP_DIR/" \
    --out_dir "$OUT_DIR/" \
    --chrom_sizes "$CHROM_FILE" \
    --mode pad2_std1_rp0.5_sqrtvc \
    --res 25000

echo "[$(date +%H:%M:%S)] done"
ls -la "$OUT_DIR"/GM12878/GM12878/*.cool 2>/dev/null
ls -la "$OUT_DIR"/IMR90/IMR90/*.cool 2>/dev/null
