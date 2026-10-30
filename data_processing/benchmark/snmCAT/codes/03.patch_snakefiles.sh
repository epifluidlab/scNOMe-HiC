#!/bin/bash
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
BISMARK_REF="${REFERENCE_ROOT}/hg38_bismark"
STAR_REF="${REFERENCE_ROOT}/hg38/star_2.7.10a_gencode.v36_sjdb100"
MAPPING_DIR="${WORK_ROOT}/benchmark/snmCAT/mapping_brain"
n=0
for sf in "${MAPPING_DIR}"/Group*/Snakefile; do
    grep -qE "^bismark_reference = " "$sf" || sed -i "0,/^CELL_IDS = /s##bismark_reference = '${BISMARK_REF}'\nCELL_IDS = #" "$sf"
    grep -qE "^star_reference = " "$sf"    || sed -i "0,/^CELL_IDS = /s##star_reference = '${STAR_REF}'\nCELL_IDS = #" "$sf"
    sed -i "s#^nome_flag_str = .*#nome_flag_str = '--nome'#" "$sf"
    n=$((n+1))
done
echo "Patched ${n} Snakefiles (brain, --nome)."
