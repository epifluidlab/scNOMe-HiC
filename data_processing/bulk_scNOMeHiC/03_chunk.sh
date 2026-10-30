#!/bin/bash
#SBATCH --job-name=gm_chunk
#SBATCH --account=b1042
#SBATCH --partition=genomics
#SBATCH --array=1-3
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=16G
#SBATCH --time=12:00:00
#SBATCH --output=${TMP_ROOT}/bulk_gm/pipeline/logs/03_chunk_%A_%a.out
#SBATCH --error=${TMP_ROOT}/bulk_gm/pipeline/logs/03_chunk_%A_%a.err

# Step 2: split each rep's trimmed pair into chunks of CHUNK_READS read-pairs and
# stage them into the pipeline trimmed dir, named so the pipeline treats each
# chunk as one "cell": {prefix=repN}.{index=chunkNNN}.R{1,2}_val_{1,2}.fq.gz
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
source ${WORK_ROOT}/analysis/bulk_scNOMeHiC/00_paths.sh
activate_scnomehic
mkdir -p "${CHUNK}" "${WORK}/logs"

REP="rep${SLURM_ARRAY_TASK_ID}"
IN1="${TRIMWHOLE}/${REP}_val_1.fq.gz"
IN2="${TRIMWHOLE}/${REP}_val_2.fq.gz"
TMP="${CHUNK}/_split_${REP}"

echo "[$(date)] ${REP}: splitting into ${CHUNK_READS}-pair chunks"

# Resume-aware: if any final chunk for this rep exists, assume done
if ls "${CHUNK}/${REP}.chunk"*".R1_val_1.fq.gz" >/dev/null 2>&1; then
    echo "[$(date)] chunks for ${REP} already present. Skipping."
    exit 0
fi

rm -rf "${TMP}"; mkdir -p "${TMP}"

# seqkit keeps R1/R2 in sync; -s = sequences (read-pairs) per chunk
seqkit split2 -1 "${IN1}" -2 "${IN2}" -s "${CHUNK_READS}" -O "${TMP}" -j "${SLURM_CPUS_PER_TASK}" -f

# Rename seqkit's *.part_NNN.fq.gz to the pipeline cell convention.
shopt -s nullglob
for f1 in "${TMP}"/*_val_1.part_*.fq.gz; do
    # extract zero-padded part number
    num="$(echo "${f1}" | sed -E 's/.*part_0*([0-9]+)\.fq\.gz/\1/')"
    cnum="$(printf 'chunk%03d' "${num}")"
    f2="${f1/_val_1.part_/_val_2.part_}"
    mv "${f1}" "${CHUNK}/${REP}.${cnum}.R1_val_1.fq.gz"
    mv "${f2}" "${CHUNK}/${REP}.${cnum}.R2_val_2.fq.gz"
done
rm -rf "${TMP}"

N=$(ls "${CHUNK}/${REP}.chunk"*".R1_val_1.fq.gz" 2>/dev/null | wc -l)
echo "[$(date)] ${REP}: created ${N} chunks in ${CHUNK}"
