#!/bin/bash
# Detached launcher for the cellline hicluster_selected driver.
# Runs both 100kb and 250kb resolutions (default from rules/hiccluster.smk).
# Survives shell exit via nohup + setsid.

cd /gpfs/projects/b1198/epifluidlab/yoshii/sc_nomehic_cellline/snakemake

PIPELINE=/gpfs/projects/b1198/epifluidlab/yoshii/software/sc_NOMeHiC_pipeline

# scnomehic env on PATH so `snakemake --executor slurm` resolves the plugin
export PATH=/projects/b1198/epifluidlab/yoshii/software/conda/envs/scnomehic/bin:${PATH}

exec snakemake \
  -s ${PIPELINE}/Snakefile \
  hicluster_selected \
  --configfile config.yaml \
  --profile ${PIPELINE}/profiles/slurm \
  --rerun-triggers mtime \
  --rerun-incomplete \
  -j 1000
