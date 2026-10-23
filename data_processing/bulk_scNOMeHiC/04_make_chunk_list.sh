#!/bin/bash
# Step 11a (run on the LOGIN node, NOT via sbatch): build the chunk manifest the
# alignment array reads. One line per staged chunk ("repN.chunkNNN"), sorted.
# Prints the SLURM array range to use for 05_align_nopbat.sh.
# --- repo paths: edit paths.yaml at the repository root, not this file -------
_r="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]:-$0}")")" && pwd)"
while [ "$_r" != "/" ] && [ ! -f "$_r/paths.sh" ]; do _r="$(dirname "$_r")"; done
source "$_r/paths.sh"

set -euo pipefail
source ${WORK_ROOT}/analysis/bulk_scNOMeHiC/00_paths.sh

mkdir -p "${ALN_NOPBAT}"

shopt -s nullglob
: > "${CHUNK_LIST}.tmp"
for f1 in "${CHUNK}"/rep*.chunk*.R1_val_1.fq.gz; do
    basename "${f1}" .R1_val_1.fq.gz >> "${CHUNK_LIST}.tmp"   # -> repN.chunkNNN
done
sort "${CHUNK_LIST}.tmp" > "${CHUNK_LIST}"
rm -f "${CHUNK_LIST}.tmp"

N=$(wc -l < "${CHUNK_LIST}")
echo "[$(date)] wrote ${N} chunks -> ${CHUNK_LIST}"
echo "Submit alignment with:  sbatch --array=1-${N} ${REPO}/05_align_nopbat.sh"
