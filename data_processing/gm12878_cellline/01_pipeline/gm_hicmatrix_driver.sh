#!/bin/bash
# Generate ONLY per-cell hic_matrix.txt.gz for the 188 GM QC cells
# (rules scbam2hic + hicprocess; no impute/embed clustering).
# Usage:
#   bash gm_hicmatrix_driver.sh -n     # dry run
#   bash gm_hicmatrix_driver.sh        # real run (submits SLURM jobs)
set -euo pipefail

GM=/gpfs/projects/b1198/epifluidlab/yoshii/sc_nomehic_cellline/gm_sc_new
PIPELINE=/gpfs/projects/b1198/epifluidlab/yoshii/software/sc_NOMeHiC_pipeline
cd "$GM"

export PATH=/projects/b1198/epifluidlab/yoshii/software/conda/envs/scnomehic/bin:${PATH}

# Build target list: one hic_matrix.txt.gz per QC prefix (workdir-relative).
mapfile -t TARGETS < <(awk 'NF{print "06.hiccluster_snakemake/" $0 ".hic_matrix.txt.gz"}' QC/cellline_prefixes_used.txt)
echo "targets: ${#TARGETS[@]}"

EXTRA=("$@")   # pass -n for dry run

# bissnp_jar is required at parse time by the (unused-here) bistools rule but is
# absent from gm's config; supply it so parsing succeeds. Harmless: no bistools
# job is in this target set (confirmed by dry run: only scbam2hic + hicprocess).
BISSNP_JAR=/gpfs/projects/b1198/epifluidlab/yoshii/software/Bis-tools/Bis-SNP/Bis-SNP.latest.jar

exec snakemake \
  -s "${PIPELINE}/Snakefile" \
  "${TARGETS[@]}" \
  --configfile configs/config.yaml \
  --config bissnp_jar="${BISSNP_JAR}" \
  --profile "${PIPELINE}/profiles/slurm" \
  --rerun-triggers mtime \
  --rerun-incomplete \
  -j 1000 \
  "${EXTRA[@]}"
