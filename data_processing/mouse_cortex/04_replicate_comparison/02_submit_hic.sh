#!/bin/bash
# Step 2 submit: launch per-replicate BAM-merge -> .hic jobs (rep1 and rep2).
# Each replicate is one SLURM job on genomics. Large intermediates go to b1042.
#
# Usage: bash 02_submit_hic.sh
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

set -eo pipefail

BASE=${WORK_ROOT}/mouse_cortex
RC=${BASE}/replicate_comparison
WORKER=${RC}/code/02_merge_bam_to_hic.sh
chmod +x "${WORKER}"

BAM_DIR=${BASE}/04.alignment_snakemake
RE_SITE=${RC}/hic/mm10_DpnII.txt
JUICER=${SOFTWARE_ROOT}/juicer/juicer_tools.jar
SAM2JUICER=${SOFTWARE_ROOT}/bisulfiteHic/src/python/sam2juicer_new.py

TMP_ROOT=${TMP_ROOT}/replicate_comparison

for REP in rep1 rep2; do
    CELL_LIST=${RC}/cell_lists/${REP}.txt
    TMP=${TMP_ROOT}/${REP}
    mkdir -p "${TMP}/namesort_tmp" "${TMP}/sort_tmp"

    BAM_LIST=${TMP}/bam_list.txt
    MERGED_COORD=${TMP}/${REP}.coordsort.bam
    NAMESORTED_BAM=${TMP}/${REP}.namesorted.bam
    HIC_TXT=${TMP}/${REP}.hic.txt.gz
    HIC_SORTED=${TMP}/${REP}.hic.sorted.txt.gz
    OUT_HIC=${RC}/hic/${REP}.mapQ30.hic

    EXPORT="ALL,REP=${REP},CELL_LIST=${CELL_LIST},BAM_DIR=${BAM_DIR},BAM_LIST=${BAM_LIST}"
    EXPORT+=",MERGED_COORD=${MERGED_COORD},NAMESORTED_BAM=${NAMESORTED_BAM}"
    EXPORT+=",NAMESORT_TMP=${TMP}/namesort_tmp,HIC_TXT=${HIC_TXT}"
    EXPORT+=",SORT_TMP=${TMP}/sort_tmp,HIC_SORTED=${HIC_SORTED}"
    EXPORT+=",OUT_HIC=${OUT_HIC},RE_SITE=${RE_SITE},SAM2JUICER=${SAM2JUICER},JUICER=${JUICER}"

    JID=$(sbatch --parsable \
        --job-name=rc_hic_${REP} \
        --output=${RC}/logs/hic_${REP}.%j.out \
        --error=${RC}/logs/hic_${REP}.%j.err \
        -A b1042 -p genomics \
        -t 48:00:00 -N 1 --mem=128G --cpus-per-task=16 \
        --export="${EXPORT}" \
        "${WORKER}")
    echo "[${REP}] submitted job ${JID}  -> ${OUT_HIC}"
done
