#!/bin/bash
# Run the GM_F123 (human/mouse mixing) scNOMe-HiC pipeline — ALIGNMENT + QC ONLY.
# `--until qc` stops the DAG after mapping → bamprocess → qc, so bisqc /
# bistools / methylation (which need a combined dbSNP that doesn't exist) never
# run. Uses the scnomehic conda env (snakemake 8.25 + slurm executor plugin).
cd /gpfs/projects/b1198/epifluidlab/yoshii/scnomehic_paper/s3/snakemake

PIPELINE=/gpfs/projects/b1198/epifluidlab/yoshii/software/sc_NOMeHiC_pipeline
SNK=/gpfs/projects/b1198/epifluidlab/yoshii/software/conda/envs/scnomehic/bin/snakemake

LOG=logs/driver_$(date +%Y%m%d_%H%M%S).log
mkdir -p logs
echo "Snakemake driver log: $LOG"

exec "$SNK" \
  -s "${PIPELINE}/Snakefile" \
  --profile "${PIPELINE}/profiles/slurm" \
  --configfile config.yaml \
  --until qc \
  --rerun-incomplete \
  --rerun-triggers mtime \
  -j 10000 \
  > "$LOG" 2>&1
