#!/bin/bash
# Run unified QC comparison across all 9 benchmark methods.
# Edit paths to match where MappingSummary.csv.gz / qc_summary.csv files live.

cd /gpfs/projects/b1042/epifluidlab/yoshii/scnomehic_paper/benchmark/summary

# conda on PATH; override with SCNOMEHIC_CONDA_SH for a different install.
source "${SCNOMEHIC_CONDA_SH:-/projects/b1198/epifluidlab/yoshii/software/conda/etc/profile.d/conda.sh}"
conda activate scnomehic

python compare_qc_all.py \
    --config datasets_all.csv \
    --output all_methods_qc
