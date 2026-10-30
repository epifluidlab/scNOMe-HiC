#!/usr/bin/env bash
# Build a pseudobulk snATAC coverage bigWig from the ENCODE aggregate BAM.
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
