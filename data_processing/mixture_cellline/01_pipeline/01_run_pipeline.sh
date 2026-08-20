#!/bin/bash
# Resume the sc_nomehic_cellline pipeline.
cd /gpfs/projects/b1198/epifluidlab/yoshii/sc_nomehic_cellline/snakemake

PIPELINE=/gpfs/projects/b1198/epifluidlab/yoshii/software/sc_NOMeHiC_pipeline
SNK=/gpfs/projects/b1198/epifluidlab/yoshii/software/conda/envs/scnomehic/bin/snakemake

LOG=/gpfs/projects/b1198/epifluidlab/yoshii/sc_nomehic_cellline/snakemake/logs/driver_$(date +%Y%m%d_%H%M%S).log
mkdir -p "$(dirname "$LOG")"
echo "Snakemake driver log: $LOG"

# --rerun-triggers mtime: skip the "code/params changed" re-run trigger for the
# mapping rule (the enzyme_list refactor is benign for the existing outputs).
exec "$SNK" \
  -s "${PIPELINE}/Snakefile" \
  --profile "${PIPELINE}/profiles/slurm" \
  --configfile config.yaml \
  --rerun-incomplete \
  --rerun-triggers mtime \
  -j 1000 \
  > "$LOG" 2>&1
