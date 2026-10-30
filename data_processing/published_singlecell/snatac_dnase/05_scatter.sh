#!/usr/bin/env bash
# Per-peak GCH vs snATAC signal over merged DNase peaks -> raw matrix, then scatter.
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
DATA="$BASE/data"; FIG="$BASE/figures"
THREADS="${THREADS:-8}"
GCH=${WORK_ROOT}/gm12878_cellline/pseudobulk_methylation/gm_pseudobulk_merged.GCH.methlevel.bw
SNATAC="$DATA/snatac.cpm.bw"
PEAKS="$DATA/dnase_peaks.merged.bed"

echo "[scatter] multiBigwigSummary over peaks"
multiBigwigSummary BED-file -b "$GCH" "$SNATAC" \
  --labels GCH snATAC --BED "$PEAKS" -p "$THREADS" \
  -o "$DATA/peak_summary.npz" --outRawCounts "$DATA/peak_signal.tab"

python "$BASE/scripts/05_scatter.py" "$DATA/peak_signal.tab" "$FIG/gch_vs_snatac_scatter.pdf"
echo "[scatter] done"
