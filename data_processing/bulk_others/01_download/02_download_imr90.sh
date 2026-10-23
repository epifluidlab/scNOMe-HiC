#!/usr/bin/env bash
# Download IMR90 bulk reference data for Figure 2 from ENCODE.
# Resumable (wget -c). Real files live under fig2/data/bulk/IMR90/{...}.
#
# IMR90 ground-truth (all GRCh38 / hg38):
#   WGBS  : ENCFF591PKF.bigBed  (methylation state at CpG, bigBed bed9+)
#   ATAC  : ENCFF770EAV.bigWig  (signal p-value)
#   Hi-C  : <TBD - awaiting link>
# --- repo paths: edit paths.yaml at the repository root, not this file -------
_r="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]:-$0}")")" && pwd)"
while [ "$_r" != "/" ] && [ ! -f "$_r/paths.sh" ]; do _r="$(dirname "$_r")"; done
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
