#!/bin/bash
# HiC Stage 3 — RUN 1: hicluster impute + embed for ALL THREE BATCHES.
# Full cascade (generatematrix -> imputecell -> imputelist -> concatcells ->
# mergechrom) on the HiC-usable passed cells. Writes the per-cell impute hdf5s
# (shared, unsuffixed) + the all3 embedding (hicluster_250kb_embed_dir_all3/).
#
# Prereqs: Stage 1 matrices done + notebook HiC usability check has written
# QC/meningioma_passed_hicusable.txt.
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

[ -f QC/meningioma_passed_hicusable.txt ] || {
  echo "ERROR: QC/meningioma_passed_hicusable.txt missing — run the notebook HiC usability check first."; exit 1; }
if ls .snakemake/locks/* >/dev/null 2>&1; then
  echo "ERROR: workdir locked. Clear it with: snakemake -s \"${PIPELINE}/Snakefile\" --configfile config.yaml --unlock"; exit 1
fi
echo "Run 1 (all3): $(wc -l < QC/meningioma_passed_hicusable.txt) HiC-usable cells, 250kb."

LOG=logs/driver_hic2_all3_$(date +%Y%m%d_%H%M%S).log
echo "Driver log: $LOG"
exec "$SNK" hicluster_selected \
  -s "${PIPELINE}/Snakefile" \
  --profile "${PIPELINE}/profiles/slurm" \
  --configfile config.yaml config_hic_all3.yaml \
  --rerun-incomplete --rerun-triggers mtime \
  -j 1000 \
  > "$LOG" 2>&1
