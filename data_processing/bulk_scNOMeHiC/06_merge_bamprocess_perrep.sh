#!/bin/bash
#SBATCH --job-name=gm_bamproc_rep
#SBATCH --account=b1042
#SBATCH --partition=genomics
#SBATCH --array=1-3
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=16
#SBATCH --mem=64G
#SBATCH --time=48:00:00
#SBATCH --output=${TMP_ROOT}/bulk_gm/pipeline/logs/06_bamproc_rep_%A_%a.out
#SBATCH --error=${TMP_ROOT}/bulk_gm/pipeline/logs/06_bamproc_rep_%A_%a.err

# Step 12: per REPLICATE (array 1-3). Merge all of this rep's per-chunk BAMs into
# one raw BAM, then run bamprocess ONCE on the merge so PCR dedup (markdup) is
# done per LIBRARY (the biologically correct unit). Mirrors the pipeline's
# `rule bamprocess`: namesort | fixmate -m | coordsort | markdup | calmd.
# Output: ${BAMPROC_REP}/bulk_GM12878_repN.calmd.bam (+ .bai).
#
# Robustness (lessons from the alignment step): validate every input BAM, write
# RAW/CALMD to per-job temp files + quickcheck + atomic mv, and make the resume
# guard require a VALID calmd (not just non-empty) so a killed/overlapping job
# can never leave a truncated file that later looks "done".
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
export PATH="${SCNOMEHIC_ENV}/bin:${PATH}"

mkdir -p "${BAMPROC_REP}" "${WORK}/logs"
T="${SLURM_CPUS_PER_TASK}"
REP="rep${SLURM_ARRAY_TASK_ID}"
JOB="${SLURM_JOB_ID:-$$}"
TMP="${BAMPROC_REP}/tmp_${REP}_${JOB}"; mkdir -p "${TMP}"

RAW="${BAMPROC_REP}/bulk_GM12878_${REP}.raw.bam"
CALMD="${BAMPROC_REP}/bulk_GM12878_${REP}.calmd.bam"
LIST="${BAMPROC_REP}/${REP}_bam_list.txt"
RAW_TMP="${TMP}/raw.bam"
CALMD_TMP="${TMP}/calmd.bam"

# Resume-aware: only skip if the calmd BAM is actually VALID + indexed.
if [[ -s "${CALMD}" && -s "${CALMD}.bai" ]] && samtools quickcheck "${CALMD}" 2>/dev/null; then
    echo "[$(date)] ${CALMD} present and valid. Skipping."
    rm -rf "${TMP}"
    exit 0
fi

# --- collect this rep's per-chunk BAMs (exclude any stray .tmp. leftovers) ---
: > "${LIST}"
shopt -s nullglob
for b in "${ALN_NOPBAT}/${REP}.chunk"*.bam; do
    case "${b}" in *.tmp.*) continue;; esac
    echo "${b}" >> "${LIST}"
done
NB=$(wc -l < "${LIST}")
if [[ "${NB}" -eq 0 ]]; then
    echo "ERROR: no chunk BAMs for ${REP} in ${ALN_NOPBAT}" >&2
    exit 1
fi

# --- validate every input chunk BAM before merging ---
BAD=0
while IFS= read -r b; do
    samtools quickcheck "${b}" 2>/dev/null || { echo "BAD INPUT: ${b}" >&2; BAD=$((BAD+1)); }
done < "${LIST}"
if [[ "${BAD}" -ne 0 ]]; then
    echo "ERROR: ${BAD} invalid chunk BAM(s) for ${REP}; fix alignment before merging." >&2
    exit 1
fi
echo "[$(date)] ${REP}: ${NB} chunk BAMs validated, merging"

# --- merge raw chunk BAMs (tmp -> validate -> mv) ---
if ! { [[ -s "${RAW}" ]] && samtools quickcheck "${RAW}" 2>/dev/null; }; then
    samtools merge -@ "${T}" -f -b "${LIST}" "${RAW_TMP}"
    samtools quickcheck "${RAW_TMP}" 2>/dev/null || { echo "ERROR: merge produced invalid RAW" >&2; exit 1; }
    mv -f "${RAW_TMP}" "${RAW}"
fi

# --- bamprocess on the merged BAM (per-library dedup), mirrors rule bamprocess ---
samtools sort --threads "${T}" -T "${TMP}/n" -n "${RAW}" | \
samtools fixmate -m --threads "${T}" - - | \
samtools sort --threads "${T}" -T "${TMP}/c" - | \
samtools markdup -T "${TMP}/m" --threads "${T}" - - | \
samtools calmd --threads "${T}" -b - "${REF}.fa" 2>/dev/null > "${CALMD_TMP}"

samtools quickcheck "${CALMD_TMP}" 2>/dev/null || { echo "ERROR: bamprocess produced invalid CALMD" >&2; exit 1; }
mv -f "${CALMD_TMP}" "${CALMD}"
samtools index -@ "${T}" "${CALMD}"

echo "[$(date)] ${REP}: done -> ${CALMD} ($(du -h "${CALMD}" | cut -f1))"
rm -rf "${TMP}"
# keep ${RAW} for now; delete manually once the merged-rep methylation call succeeds.
