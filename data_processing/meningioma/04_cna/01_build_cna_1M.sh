#!/bin/bash
# Generate per-cell 1Mb fragment-count table (copy-number proxy) from the new
# consolidated run's BEDs, for the QC-passed cells (covers both dim-reduction sets).
# Mirrors data_batch_*/09.cna.sh (count_fragment.py).
# --- repo paths: edit paths.yaml at the repository root, not this file -------
_r="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]:-$0}")")" && pwd)"
while [ "$_r" != "/" ] && [ ! -f "$_r/paths.sh" ]; do _r="$(dirname "$_r")"; done
source "$_r/paths.sh"

set -euo pipefail
cd ${WORK_ROOT}/meningioma

PY=${CONDA_ENVS}/scnomehic/bin/python
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CF="${HERE}/count_fragment.py"
CHROM=${REFERENCE_ROOT}/hg38/autosomes.chrom.sizes
OUTDIR=subset_clustering/250kb
mkdir -p "$OUTDIR"

"$PY" "$CF" \
  --chrom_size_filepath "$CHROM" \
  --prefix_file QC/meningioma_passed.txt \
  --bed_directory 04.alignment_snakemake \
  --binsize 1000000 \
  --outfile "$OUTDIR/CNA.1M.txt"
echo "wrote $OUTDIR/CNA.1M.txt"
