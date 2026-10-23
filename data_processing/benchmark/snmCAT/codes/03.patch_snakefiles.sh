#!/bin/bash
# --- repo paths: edit paths.yaml at the repository root, not this file -------
_r="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]:-$0}")")" && pwd)"
while [ "$_r" != "/" ] && [ ! -f "$_r/paths.sh" ]; do _r="$(dirname "$_r")"; done
source "$_r/paths.sh"

set -euo pipefail
BISMARK_REF="${REFERENCE_ROOT}/hg38_bismark"
STAR_REF="${REFERENCE_ROOT}/hg38/star_2.7.10a_gencode.v36_sjdb100"
MAPPING_DIR="/gpfs/projects/b1042/epifluidlab/yoshii/scnomehic_paper/benchmark/snmCAT/mapping_brain"
n=0
for sf in "${MAPPING_DIR}"/Group*/Snakefile; do
    grep -qE "^bismark_reference = " "$sf" || sed -i "0,/^CELL_IDS = /s##bismark_reference = '${BISMARK_REF}'\nCELL_IDS = #" "$sf"
    grep -qE "^star_reference = " "$sf"    || sed -i "0,/^CELL_IDS = /s##star_reference = '${STAR_REF}'\nCELL_IDS = #" "$sf"
    sed -i "s#^nome_flag_str = .*#nome_flag_str = '--nome'#" "$sf"
    n=$((n+1))
done
echo "Patched ${n} Snakefiles (brain, --nome)."
