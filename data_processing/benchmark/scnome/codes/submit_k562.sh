#!/bin/bash
# Submit the K562 per-cell pipeline as a dependency chain (11 cells = consecutive
# SRR pairs). Reuses existing per-run bismark BAMs (trim+align already done), so
# the chain is: merge+dedup (per cell) -> NOMe methylation extraction (per cell).
# QC (04.qc_* steps) is run separately afterward.
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

cd ${WORK_ROOT}/benchmark/scnome

j1=$(sbatch --parsable codes/02k.merge_dedup_k562.sh)
echo "02k.merge_dedup_k562.sh   -> ${j1}"

j2=$(sbatch --parsable --dependency=afterok:${j1} codes/03k.methy_extract_k562.sh)
echo "03k.methy_extract_k562.sh -> ${j2}  (afterok ${j1})"

echo ""
echo "Submitted K562 chain: ${j1} -> ${j2}"
echo "Monitor: squeue -u jmj7858"
