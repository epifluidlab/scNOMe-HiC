#!/bin/bash
# --- repo paths: edit paths.yaml at the repository root, not this file -------
_r="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]:-$0}")")" && pwd)"
while [ "$_r" != "/" ] && [ ! -f "$_r/paths.sh" ]; do _r="$(dirname "$_r")"; done
source "$_r/paths.sh"

set -euo pipefail
FASTQ_DIR="${WORK_ROOT}/benchmark/snmCAT/fastq_brain"
cd "${FASTQ_DIR}"
n=0
for f1 in *_1.fastq.gz; do
    p="${f1%_1.fastq.gz}"; f2="${p}_2.fastq.gz"
    [[ -s "${f2}" ]] || { echo "WARN: missing mate ${p}" >&2; continue; }
    ln -sf "${f1}" "${p}-R1.fq.gz"; ln -sf "${f2}" "${p}-R2.fq.gz"; n=$((n+1))
done
echo "Linked ${n} cells in ${FASTQ_DIR}"
