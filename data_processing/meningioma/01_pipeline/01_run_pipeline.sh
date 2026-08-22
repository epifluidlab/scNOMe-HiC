#!/bin/bash
# Run the consolidated meningioma scNOMe-HiC pipeline (data_batch_1/2/3 together).
# Uses the scnomehic conda env (snakemake 8.25 + slurm executor plugin).
cd /gpfs/projects/b1198/epifluidlab/yoshii/meningioma_scnomehic/snakemake

PIPELINE=/gpfs/projects/b1198/epifluidlab/yoshii/software/sc_NOMeHiC_pipeline
SNK=/gpfs/projects/b1198/epifluidlab/yoshii/software/conda/envs/scnomehic/bin/snakemake

LOG=/gpfs/projects/b1198/epifluidlab/yoshii/meningioma_scnomehic/snakemake/logs/driver_$(date +%Y%m%d_%H%M%S).log
mkdir -p "$(dirname "$LOG")"
echo "Snakemake driver log: $LOG"

exec "$SNK" \
  -s "${PIPELINE}/Snakefile" \
  --profile "${PIPELINE}/profiles/slurm" \
  --configfile config.yaml \
  --rerun-incomplete \
  --rerun-triggers mtime \
  -j 10000 \
  > "$LOG" 2>&1
