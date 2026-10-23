#!/usr/bin/env bash
# Build a pseudobulk snATAC coverage bigWig from the ENCODE aggregate BAM.
# --- repo paths: edit paths.yaml at the repository root, not this file -------
_r="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]:-$0}")")" && pwd)"
while [ "$_r" != "/" ] && [ ! -f "$_r/paths.sh" ]; do _r="$(dirname "$_r")"; done
source "$_r/paths.sh"

set -euo pipefail
BASE=${WORK_ROOT}/analysis/s2_new/atac_dnase_gm12878
DATA="$BASE/data"
THREADS="${THREADS:-8}"
BAM="$DATA/ENCFF995ATT.bam"
cd "$DATA"

[[ -s "$BAM" ]] || { echo "ERROR: BAM missing: $BAM"; exit 2; }

if [[ ! -s "$BAM.bai" ]]; then
  echo "[snatac] indexing BAM..."
  samtools index -@ "$THREADS" "$BAM"
fi

echo "[snatac] bamCoverage (CPM, bs25, ignore dups, MAPQ>=30)..."
bamCoverage -b "$BAM" -o snatac.cpm.bw \
  --normalizeUsing CPM \
  --binSize 25 \
  --minMappingQuality 30 \
  --ignoreDuplicates \
  -p "$THREADS"
echo "[snatac] wrote snatac.cpm.bw"
bigWigInfo snatac.cpm.bw | sed -n '1,8p'
