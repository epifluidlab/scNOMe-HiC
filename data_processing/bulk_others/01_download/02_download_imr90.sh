#!/usr/bin/env bash
# Download IMR90 bulk reference data for Figure 2 from ENCODE.
# Resumable (wget -c). Real files live under fig2/data/bulk/IMR90/{...}.
#
# IMR90 ground-truth (all GRCh38 / hg38):
#   WGBS  : ENCFF591PKF.bigBed  (methylation state at CpG, bigBed bed9+)
#   ATAC  : ENCFF770EAV.bigWig  (signal p-value)
#   Hi-C  : <TBD - awaiting link>
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

BASE=${WORK_ROOT}/analysis/fig2/data/bulk/IMR90

# WGBS methylation
cd "$BASE/methylation"
wget -c "https://www.encodeproject.org/files/ENCFF591PKF/@@download/ENCFF591PKF.bigBed" \
     -o ENCFF591PKF.download.log

# ATAC-seq
cd "$BASE/atac"
wget -c "https://www.encodeproject.org/files/ENCFF770EAV/@@download/ENCFF770EAV.bigWig" \
     -o ENCFF770EAV.download.log

echo "IMR90 downloads complete."
