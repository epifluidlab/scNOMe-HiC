#!/bin/bash
# Step 2 worker: per-replicate merge of per-cell CALMD BAMs -> name-sort ->
# sam2juicer -> sort -> juicer pre -> multi-resolution .hic.
#
# Adapted from cortex_pseudobulk/stream_B_merge_bam/step1_hic_generation/
# hicpre_B_from_scratch_calmd.sh (identical recipe; grouping = replicate, and
# BAMs read from 04.alignment_snakemake/{cell}.calmd.bam).
#
# Required env vars (set via sbatch --export from 02_submit_hic.sh):
#   REP CELL_LIST BAM_DIR MERGED_COORD NAMESORTED_BAM NAMESORT_TMP
#   HIC_TXT SORT_TMP HIC_SORTED OUT_HIC RE_SITE SAM2JUICER JUICER BAM_LIST
set -eo pipefail

source ~/.bashrc
conda activate scnomehic
module load java/jdk-17.0.2+8

: "${REP:?}" "${CELL_LIST:?}" "${BAM_DIR:?}" "${BAM_LIST:?}" "${MERGED_COORD:?}"
: "${NAMESORTED_BAM:?}" "${NAMESORT_TMP:?}" "${HIC_TXT:?}" "${SORT_TMP:?}" "${HIC_SORTED:?}"
: "${OUT_HIC:?}" "${RE_SITE:?}" "${SAM2JUICER:?}" "${JUICER:?}"

echo "[$(date)] [${REP}] Building BAM list from ${CELL_LIST} + ${BAM_DIR} ..."
> "${BAM_LIST}"
missing=0
while IFS= read -r cell || [[ -n "${cell}" ]]; do
    [[ -z "${cell}" ]] && continue
    f="${BAM_DIR}/${cell}.calmd.bam"
    if [[ -f "${f}" ]]; then
        echo "${f}" >> "${BAM_LIST}"
    else
        echo "[WARN] Missing BAM: ${f}" >&2
        missing=$((missing + 1))
    fi
done < "${CELL_LIST}"

N_BAMS=$(wc -l < "${BAM_LIST}")
echo "[$(date)] [${REP}] BAMs in merge list: ${N_BAMS}  missing: ${missing}"
if [[ "${N_BAMS}" -eq 0 ]]; then
    echo "ERROR: no BAMs to merge" >&2
    exit 1
fi

echo "[$(date)] [${REP}] samtools merge (${N_BAMS} BAMs) -> coordsorted BAM ..."
samtools merge -f -@ 8 -b "${BAM_LIST}" -o "${MERGED_COORD}"
echo "[$(date)] [${REP}] Merge done: $(du -h "${MERGED_COORD}" | cut -f1)"

echo "[$(date)] [${REP}] Name-sorting merged BAM ..."
samtools sort -n -@ 8 -T "${NAMESORT_TMP}/tmp" "${MERGED_COORD}" -o "${NAMESORTED_BAM}"
echo "[$(date)] [${REP}] Name-sort done."
rm -f "${MERGED_COORD}"
echo "[$(date)] [${REP}] Removed coordsorted merge to save disk."

echo "[$(date)] [${REP}] Running sam2juicer on name-sorted BAM ..."
python "${SAM2JUICER}" -s "${NAMESORTED_BAM}" -f "${RE_SITE}" \
    | pigz -p 4 -c > "${HIC_TXT}"
echo "[$(date)] [${REP}] Pairs: $(pigz -dc "${HIC_TXT}" | wc -l)"

echo "[$(date)] [${REP}] Sorting pairs ..."
pigz -dc "${HIC_TXT}" \
    | LC_ALL=C sort --parallel=14 -S 90G \
        -T "${SORT_TMP}" \
        -k2,2d -k6,6d -k3,3n -k7,7n \
    | pigz -p 4 -c > "${HIC_SORTED}"
echo "[$(date)] [${REP}] Sorted pairs: $(pigz -dc "${HIC_SORTED}" | wc -l)"

echo "[$(date)] [${REP}] Running juicer pre (multi-res) ..."
java -Xmx112G -jar "${JUICER}" pre \
    -q 30 \
    -f "${RE_SITE}" \
    -r 2500000,1000000,500000,250000,100000,50000,25000,10000,5000 \
    "${HIC_SORTED}" \
    "${OUT_HIC}" \
    mm10

echo "[$(date)] [${REP}] Output: ${OUT_HIC}  ($(du -h "${OUT_HIC}" | cut -f1))"
echo "[$(date)] [${REP}] Step 2 done."
