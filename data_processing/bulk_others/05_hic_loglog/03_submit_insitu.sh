#!/bin/bash
# Submit the HOMER log-log pipeline for the ENCODE in-situ Hi-C sample.
# Runs BOTH the 100M-cap subsample and the full-depth version.
# Run this AFTER the ENCFF447ERX.pairs.gz download finishes.
# --- repo paths: edit paths.yaml at the repository root, not this file -------
# SLURM copies a batch script to /var/spool/slurmd/<job>/slurm_script, so walking
# up from BASH_SOURCE cannot reach the repository. $SCNOMEHIC_REPO is tried first;
# submit with: sbatch --export=ALL,SCNOMEHIC_REPO=/path/to/repo
_r="${SCNOMEHIC_REPO:-}"
if [ -z "$_r" ] || [ ! -f "$_r/paths.sh" ]; then
    _r="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]:-$0}")")" && pwd)"
    while [ "$_r" != "/" ] && [ ! -f "$_r/paths.sh" ]; do _r="$(dirname "$_r")"; done
fi
[ -f "$_r/paths.sh" ] || { echo "ERROR: paths.sh not found. Set SCNOMEHIC_REPO to the repository root." >&2; exit 1; }
source "$_r/paths.sh"

set -euo pipefail
PAIRS=${TMP_ROOT}/insitu_hic/pairs/ENCFF447ERX.pairs.gz
SP="$(dirname "$(readlink -f "${BASH_SOURCE[0]:-$0}")")/02_sample_pipeline.sh"
# sanity: file present and gzip intact
if ! pigz -t "$PAIRS" 2>/dev/null; then
  echo "ERROR: $PAIRS missing or not a complete gzip — download not finished?" >&2
  exit 1
fi
# subsample (100M cap)
sbatch --job-name=qc_insitu \
  --export=ALL,NAME=insitu_hic,SRC=$PAIRS,FMT=pairs,TARGET=100000000 \
  "$SP"
# full depth
sbatch --job-name=qc_insitu_full --mem=96G --time=48:00:00 \
  --export=ALL,NAME=insitu_hic_full,SRC=$PAIRS,FMT=pairs,TARGET=0 \
  "$SP"
