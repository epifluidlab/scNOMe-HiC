#!/bin/bash
# Run the GM_F123 (human/mouse mixing) scNOMe-HiC pipeline — ALIGNMENT + QC ONLY.
# `--until qc` stops the DAG after mapping → bamprocess → qc, so bisqc /
# bistools / methylation (which need a combined dbSNP that doesn't exist) never
# run. Uses the scnomehic conda env (snakemake 8.25 + slurm executor plugin).
# ---- paths: edit ../../../paths.yaml, not this file -------------------------
HERE="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
source "${HERE}/../../paths.sh"
PIPELINE="${SCNOMEHIC_PIPELINE:-${SOFTWARE_ROOT}/sc_NOMeHiC_pipeline}"
CONDA_ENV="${SCNOMEHIC_ENV:-scnomehic}"
# Render the config template into the work tree with your paths substituted in.
CONFIG="$(bash "${HERE}/../../render_config.sh" barnyard_mixing config)"
WORKDIR="${WORK_ROOT}/barnyard_mixing"
mkdir -p "${WORKDIR}"
cd "${WORKDIR}"
[ -f "${PIPELINE}/Snakefile" ] || { echo "ERROR: pipeline not found at ${PIPELINE} (set software_root in paths.yaml, or export SCNOMEHIC_PIPELINE)" >&2; exit 1; }
SNK="${SNK:-snakemake}"

LOG="${WORKDIR}/logs/driver_$(date +%Y%m%d_%H%M%S).log"
mkdir -p "$(dirname "$LOG")"
echo "Snakemake driver log: $LOG"

exec "$SNK" \
  -s "${PIPELINE}/Snakefile" \
  --profile "${PIPELINE}/profiles/slurm" \
  --configfile "${CONFIG}" \
  --until qc \
  --rerun-incomplete \
  --rerun-triggers mtime \
  -j 10000 \
  > "$LOG" 2>&1
