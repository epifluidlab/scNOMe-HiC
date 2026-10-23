#!/bin/bash
# Run unified QC comparison across all 9 benchmark methods.
# Edit paths to match where MappingSummary.csv.gz / qc_summary.csv files live.

# --- repo paths: edit paths.yaml at the repository root, not this file -------
_r="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]:-$0}")")" && pwd)"
while [ "$_r" != "/" ] && [ ! -f "$_r/paths.sh" ]; do _r="$(dirname "$_r")"; done
source "$_r/paths.sh"

cd /gpfs/projects/b1042/epifluidlab/yoshii/scnomehic_paper/benchmark/summary

# conda on PATH; override with SCNOMEHIC_CONDA_SH for a different install.
source "${SCNOMEHIC_CONDA_SH:-${CONDA_SH}}"
conda activate scnomehic

python compare_qc_all.py \
    --config datasets_all.csv \
    --output all_methods_qc
