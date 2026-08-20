#!/bin/bash
# ─────────────────────────────────────────────────────────────────────────────
# Shared driver for the sc_NOMeHiC Snakemake pipeline.
#
# Every dataset runs the same workflow; only the config differs. The config also
# decides where the run starts (`start_from: raw | demultiplexed | trimmed`) —
# see ../RUNNING.md.
#
# Usage:
#   sbatch data_processing/run_pipeline.sh <config.yaml> [snakemake args...]
#   bash   data_processing/run_pipeline.sh <config.yaml> [snakemake args...]
#
# Examples:
#   sbatch data_processing/run_pipeline.sh gm12878_cellline/00_config/config.main_run.yaml
#   sbatch data_processing/run_pipeline.sh mixture_cellline/00_config/config.yaml
#
#   # a specific target instead of the default `all` (mixture only needs this):
#   sbatch data_processing/run_pipeline.sh mixture_cellline/00_config/config.yaml hicluster_selected
#
#   # dry run
#   bash data_processing/run_pipeline.sh mixture_cellline/00_config/config.yaml -n
#
# This is a long-lived *driver*: it holds a small allocation and submits each
# rule as its own SLURM job via the pipeline's profile.
# ─────────────────────────────────────────────────────────────────────────────
#SBATCH --job-name=scnomehic_driver
#SBATCH --account=b1042
#SBATCH --partition=genomicslong
#SBATCH --time=7-00:00:00
#SBATCH --nodes=1
#SBATCH --cpus-per-task=2
#SBATCH --mem=8G
#SBATCH --output=scnomehic_driver.%j.out
#SBATCH --error=scnomehic_driver.%j.err

set -eo pipefail

CONFIG=${1:?usage: [sbatch|bash] run_pipeline.sh <config.yaml> [snakemake args...]}
shift

# Override with e.g. SCNOMEHIC_PIPELINE=/path/to/clone when running elsewhere.
PIPELINE=${SCNOMEHIC_PIPELINE:-/gpfs/projects/b1198/epifluidlab/yoshii/software/sc_NOMeHiC_pipeline}
CONDA_SH=${SCNOMEHIC_CONDA_SH:-/projects/b1198/epifluidlab/yoshii/software/conda/etc/profile.d/conda.sh}
CONDA_ENV=${SCNOMEHIC_ENV_NAME:-scnomehic}

[ -f "$CONFIG" ]              || { echo "ERROR: config not found: $CONFIG" >&2; exit 1; }
[ -f "$PIPELINE/Snakefile" ]  || { echo "ERROR: pipeline not found at $PIPELINE (set SCNOMEHIC_PIPELINE)" >&2; exit 1; }
CONFIG=$(readlink -f "$CONFIG")

source "$CONDA_SH"
conda activate "$CONDA_ENV"
module load java/jdk-17.0.2+8 2>/dev/null || module load java 2>/dev/null || true

echo "=== driver start: $(date) on $(hostname) ==="
echo "    pipeline : $PIPELINE"
echo "    config   : $CONFIG"
echo "    extra    : $*"

# --rerun-incomplete: redo outputs left half-written by a killed job. Required to
#   resume at all, and a no-op on a clean run.
# Snakemake's default rerun triggers are left alone, so changing a rule or a
#   config parameter correctly invalidates the affected steps.
exec snakemake \
  -s "${PIPELINE}/Snakefile" \
  --configfile "${CONFIG}" \
  --profile "${PIPELINE}/profiles/slurm" \
  --rerun-incomplete \
  -j 1000 \
  -p \
  "$@"
