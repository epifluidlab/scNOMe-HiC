#!/bin/bash
# ─────────────────────────────────────────────────────────────────────────────
# Mouse cortex — Hi-C clustering at 100 kb and 250 kb, restricted to the
# QC-passing cells listed in `selected_cells_file` (QC/cortex_passed.txt).
# Run after 02_qc, which writes that list.
#
# Every dataset in this repository runs the same workflow with the same flags;
# only the config differs. The config also decides where the run starts
# (`start_from: raw | demultiplexed | trimmed`) — see ../../../RUNNING.md.
#
# Submit:   sbatch 02_hicluster.sh
# Dry run:  bash   02_hicluster.sh -n
# ─────────────────────────────────────────────────────────────────────────────
#SBATCH --job-name=scnh_cortex_hic
#SBATCH --account=b1042
#SBATCH --partition=genomicslong
#SBATCH --time=7-00:00:00
#SBATCH --nodes=1
#SBATCH --cpus-per-task=2
#SBATCH --mem=8G
#SBATCH --output=scnh_cortex_hic_driver.%j.out
#SBATCH --error=scnh_cortex_hic_driver.%j.err

set -eo pipefail

# ---- paths: edit ../../../paths.yaml, not this file -------------------------
HERE="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
source "${HERE}/../../paths.sh"
PIPELINE="${SCNOMEHIC_PIPELINE:-${SOFTWARE_ROOT}/sc_NOMeHiC_pipeline}"
CONDA_ENV="${SCNOMEHIC_ENV:-scnomehic}"
# Render the config template into the work tree with your paths substituted in.
CONFIG="$(bash "${HERE}/../../render_config.sh" mouse_cortex config)"
WORKDIR="${WORK_ROOT}/mouse_cortex"
mkdir -p "${WORKDIR}"
cd "${WORKDIR}"
[ -f "${PIPELINE}/Snakefile" ] || { echo "ERROR: pipeline not found at ${PIPELINE} (set software_root in paths.yaml, or export SCNOMEHIC_PIPELINE)" >&2; exit 1; }

if [ -n "${CONDA_SH}" ]; then source "${CONDA_SH}"; fi
command -v conda >/dev/null || { echo "ERROR: conda not on PATH (set conda_sh in paths.yaml)" >&2; exit 1; }
conda activate "${CONDA_ENV}"
module load java/jdk-17.0.2+8 2>/dev/null || module load java 2>/dev/null || true

echo "=== driver start: $(date) on $(hostname) ==="
echo "    pipeline : ${PIPELINE}"
echo "    config   : ${CONFIG}"

# --rerun-incomplete redoes outputs left half-written by a killed job: required
# to resume, and a no-op on a clean run. Snakemake's default rerun triggers are
# left in place, so editing a rule or a config parameter correctly invalidates
# the affected steps.
exec snakemake \
  -s "${PIPELINE}/Snakefile" \
  hicluster_selected \
  --configfile "${CONFIG}" \
  --profile "${PIPELINE}/profiles/slurm" \
  --rerun-incomplete \
  -j 1000 \
  -p \
  "$@"
