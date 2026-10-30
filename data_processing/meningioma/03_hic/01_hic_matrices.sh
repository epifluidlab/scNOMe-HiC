#!/bin/bash
# HiC Stage 1 — per-cell HiC contact matrices (scbam2hic + hicprocess) for the
# methylation-QC-passed cells. These hic_matrix.txt.gz files are the input to
# the notebook's HiC usability check. Per-cell + cell-set-independent, so this
# work is shared by BOTH later runs (all3 and batch23).
#
# Run from snakemake/ AFTER methylation QC has written QC/meningioma_passed.txt.
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

set -euo pipefail
cd ${WORK_ROOT}/meningioma

PIPELINE=${SOFTWARE_ROOT}/sc_NOMeHiC_pipeline
SNK=${CONDA_ENVS}/scnomehic/bin/snakemake
PASSED=QC/meningioma_passed.txt

[ -f "$PASSED" ] || { echo "ERROR: $PASSED missing (run methylation QC first)"; exit 1; }
if ls .snakemake/locks/* >/dev/null 2>&1; then
  echo "ERROR: workdir locked. Clear it with: snakemake -s \"${PIPELINE}/Snakefile\" --configfile config.yaml --unlock"; exit 1
fi

# Build explicit hic_matrix targets for every passed cell.
targets=()
while IFS= read -r c; do
  [ -n "$c" ] || continue
  targets+=("06.hiccluster_snakemake/${c}.hic_matrix.txt.gz")
done < "$PASSED"
echo "Stage 1: requesting ${#targets[@]} hic_matrix files (scbam2hic + hicprocess)."

LOG=logs/driver_hic1_matrices_$(date +%Y%m%d_%H%M%S).log
echo "Driver log: $LOG"
exec "$SNK" "${targets[@]}" \
  -s "${PIPELINE}/Snakefile" \
  --profile "${PIPELINE}/profiles/slurm" \
  --configfile config.yaml \
  --rerun-incomplete --rerun-triggers mtime \
  -j 1000 \
  > "$LOG" 2>&1
