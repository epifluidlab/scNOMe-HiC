#!/bin/bash
#SBATCH --job-name=gm_align_nopbat
#SBATCH --account=b1042
#SBATCH --partition=genomics
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=16
#SBATCH --mem=120G
#SBATCH --time=24:00:00
#SBATCH --output=${TMP_ROOT}/bulk_gm/pipeline/logs/05_align_nopbat_%A_%a.out
#SBATCH --error=${TMP_ROOT}/bulk_gm/pipeline/logs/05_align_nopbat_%A_%a.err

# Step 11: align ONE chunk (selected by SLURM array index from chunk_list.txt)
# with bisulfiteHic Bhmem. SAME command as the pipeline's `rule mapping` EXCEPT
# BOTH `-pbat` and `-nonDirectional` are removed (different, directional protocol).
# Output: ${ALN_NOPBAT}/repN.chunkNNN.bam  (raw, name-sorted by the aligner).
# --- repo paths: edit paths.yaml at the repository root, not this file -------
_r="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]:-$0}")")" && pwd)"
while [ "$_r" != "/" ] && [ ! -f "$_r/paths.sh" ]; do _r="$(dirname "$_r")"; done
source "$_r/paths.sh"

set -euo pipefail
source ${WORK_ROOT}/analysis/bulk_scNOMeHiC/00_paths.sh
export PATH="${SCNOMEHIC_ENV}/bin:${PATH}"
module load java/jdk-17.0.2+8

mkdir -p "${ALN_NOPBAT}" "${WORK}/logs"

if [[ ! -s "${CHUNK_LIST}" ]]; then
    echo "ERROR: ${CHUNK_LIST} missing. Run 04_make_chunk_list.sh first." >&2
    exit 1
fi

STEM=$(sed -n "${SLURM_ARRAY_TASK_ID}p" "${CHUNK_LIST}")   # repN.chunkNNN
if [[ -z "${STEM}" ]]; then
    echo "ERROR: no chunk at line ${SLURM_ARRAY_TASK_ID} of ${CHUNK_LIST}" >&2
    exit 1
fi

R1="${CHUNK}/${STEM}.R1_val_1.fq.gz"
R2="${CHUNK}/${STEM}.R2_val_2.fq.gz"
OUT="${ALN_NOPBAT}/${STEM}.bam"
TMP="${ALN_NOPBAT}/${STEM}.tmp.${SLURM_JOB_ID:-$$}.bam"   # per-job temp; never collides
ENZYME_LIST="${REF}.DpnII.span_region.bedgraph"

echo "[$(date)] aligning ${STEM} (no -pbat) -> ${OUT}"

# Resume-aware: only skip if the existing BAM is actually VALID (not a truncated
# leftover from a cancelled/overlapping job). samtools quickcheck verifies the
# BGZF EOF block + readable header.
if [[ -s "${OUT}" ]] && samtools quickcheck "${OUT}" 2>/dev/null; then
    echo "[$(date)] ${OUT} present and valid. Skipping."
    exit 0
fi
rm -f "${TMP}"

# Write to a per-job TMP first, validate, then atomically move into place so a
# killed job can never leave a partial file that later looks "done".
java -Xmx120G -Djava.library.path="${BISHIC}/jbwa/jbwa-1.0.0/src/main/native" \
    -cp "${BISHIC}/target/bisulfitehic-0.38-jar-with-dependencies.jar:${BISHIC}/jbwa/jbwa-1.0.0/jbwa.jar" \
    main.java.edu.mit.compbio.bisulfitehic.mapping.Bhmem "${REF}.fa" \
    "${TMP}" "${R1}" "${R2}" \
    -t "${SLURM_CPUS_PER_TASK}" -rgId "${STEM}" -rgSm NOMeHiC \
    -buffer 10000 -enzymeList "${ENZYME_LIST}" -outputMateDiffChr

if ! samtools quickcheck "${TMP}" 2>/dev/null; then
    echo "[$(date)] ERROR: ${STEM} alignment produced an invalid BAM (${TMP})" >&2
    rm -f "${TMP}"
    exit 1
fi
mv -f "${TMP}" "${OUT}"

echo "[$(date)] ${STEM}: done -> ${OUT} ($(du -h "${OUT}" | cut -f1))"
