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

# ---- system-specific; override by exporting these before running ----
PIPELINE=${SCNOMEHIC_PIPELINE:-/gpfs/projects/b1198/epifluidlab/yoshii/software/sc_NOMeHiC_pipeline}
CONDA_SH=${SCNOMEHIC_CONDA_SH:-/projects/b1198/epifluidlab/yoshii/software/conda/etc/profile.d/conda.sh}
CONDA_ENV=${SCNOMEHIC_ENV:-scnomehic}

HERE=$(dirname "$(readlink -f "$0")")
CONFIG="${HERE}/../00_config/config.yaml"

[ -f "${PIPELINE}/Snakefile" ] || { echo "ERROR: pipeline not found at ${PIPELINE} (set SCNOMEHIC_PIPELINE)" >&2; exit 1; }
[ -f "${CONFIG}" ]            || { echo "ERROR: config not found: ${CONFIG}" >&2; exit 1; }

source "${CONDA_SH}"
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
