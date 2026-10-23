#!/bin/bash
# Dry-run of the updated sc_NOMeHiC_pipeline against gm_sc_new (hg38).
# Shows what the default rule all (trim -> align -> bamproc -> bisqc -> methylation,
# NO hicluster) would run, given existing outputs. Resume-aware via mtime triggers.
# --- repo paths: edit paths.yaml at the repository root, not this file -------
_r="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]:-$0}")")" && pwd)"
while [ "$_r" != "/" ] && [ ! -f "$_r/paths.sh" ]; do _r="$(dirname "$_r")"; done
source "$_r/paths.sh"

set -eo pipefail

source ${CONDA_SH}
conda activate scnomehic
module load java/jdk-17.0.2+8 2>/dev/null || true

PIPELINE=${SOFTWARE_ROOT}/sc_NOMeHiC_pipeline
cd "${PIPELINE}"

snakemake \
  -s "${PIPELINE}/Snakefile" \
  --configfile "${PIPELINE}/configs/config.yaml" \
  --rerun-triggers mtime \
  -np 2>&1 | tail -80
