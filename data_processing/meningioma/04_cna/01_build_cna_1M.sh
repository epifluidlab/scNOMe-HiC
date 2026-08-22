#!/bin/bash
# Generate per-cell 1Mb fragment-count table (copy-number proxy) from the new
# consolidated run's BEDs, for the QC-passed cells (covers both dim-reduction sets).
# Mirrors data_batch_*/09.cna.sh (count_fragment.py).
set -euo pipefail
cd /gpfs/projects/b1198/epifluidlab/yoshii/meningioma_scnomehic/snakemake

PY=/gpfs/projects/b1198/epifluidlab/yoshii/software/conda/envs/scnomehic/bin/python
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CF="${HERE}/count_fragment.py"
CHROM=/gpfs/projects/b1198/epifluidlab/yoshii/reference/hg38/autosomes.chrom.sizes
OUTDIR=subset_clustering/250kb
mkdir -p "$OUTDIR"

"$PY" "$CF" \
  --chrom_size_filepath "$CHROM" \
  --prefix_file QC/meningioma_passed.txt \
  --bed_directory 04.alignment_snakemake \
  --binsize 1000000 \
  --outfile "$OUTDIR/CNA.1M.txt"
echo "wrote $OUTDIR/CNA.1M.txt"
