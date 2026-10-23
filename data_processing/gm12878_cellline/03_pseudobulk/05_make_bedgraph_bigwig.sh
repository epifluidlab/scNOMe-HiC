#!/bin/bash
#SBATCH --job-name=psb_bg2bw
#SBATCH --account=b1042
#SBATCH --partition=genomics
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=48G
#SBATCH --time=06:00:00
#SBATCH --output=${WORK_ROOT}/gm12878_cellline/pseudobulk_methylation/logs/psb_bg2bw_%j.out
#SBATCH --error=${WORK_ROOT}/gm12878_cellline/pseudobulk_methylation/logs/psb_bg2bw_%j.err

# Convert the genome-wide pseudobulk 6plus2 per-site methylation beds into
# 4-column bedGraph (chrom start end methylation%) and then bigWig.
#   value  = column 7 (methylation percentage, 0-100)
#   filter = none (all sites, including coverage=1)
# bedGraphToBigWig requires: plain-text, sorted by -k1,1 -k2,2n, NO overlapping
# intervals. All 6plus2 rows are single-base, so the only possible overlap is an
# exact-duplicate coordinate -> we collapse those by averaging (awk pass).
# --- repo paths: edit paths.yaml at the repository root, not this file -------
_r="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]:-$0}")")" && pwd)"
while [ "$_r" != "/" ] && [ ! -f "$_r/paths.sh" ]; do _r="$(dirname "$_r")"; done
source "$_r/paths.sh"

set -euo pipefail

OUTROOT=${WORK_ROOT}/gm12878_cellline/pseudobulk_methylation
REF=${REFERENCE_ROOT}/hg38/GCA_000001405.15_GRCh38_no_alt_analysis_set
CHROMSIZES="${REF}.chrom.sizes"
BG2BW=${CONDA_ENVS}/scnomehic/bin/bedGraphToBigWig
TMP="${OUTROOT}/tmp_bg2bw"
mkdir -p "${TMP}" "${OUTROOT}/logs"

for CTX in HCG GCH; do
    IN="${OUTROOT}/gm_pseudobulk_merged.${CTX}.6plus2.bed.gz"
    BG="${OUTROOT}/gm_pseudobulk_merged.${CTX}.methlevel.bedgraph"
    BW="${OUTROOT}/gm_pseudobulk_merged.${CTX}.methlevel.bw"

    if [[ ! -s "${IN}" ]]; then echo "ERROR: missing ${IN}" >&2; exit 1; fi

    if [[ -s "${BG}" ]]; then
        echo "[$(date)] ${CTX}: bedGraph present, skipping build -> ${BG}"
    else
        echo "[$(date)] ${CTX}: extracting cols 1,2,3,7 -> sort -> collapse dups"
        # strip track/header lines, keep only chr* data rows, print 4-col bedGraph
        zcat "${IN}" \
          | awk -F'\t' 'BEGIN{OFS="\t"} $1 ~ /^chr/ && NF>=8 {print $1,$2,$3,$7}' \
          | LC_ALL=C sort --parallel=8 -S 40G -T "${TMP}" -k1,1 -k2,2n \
          | awk -F'\t' 'BEGIN{OFS="\t"}
                {
                  # collapse exact-duplicate (chrom,start,end) by averaging value
                  key=$1"\t"$2"\t"$3
                  if (key==pk){ sum+=$4; n++ }
                  else {
                    if (pk!=""){ print pkey, sum/n }
                    pk=key; pkey=$1"\t"$2"\t"$3; sum=$4; n=1
                  }
                }
                END{ if(pk!="") print pkey, sum/n }' > "${BG}.tmp"
        mv -f "${BG}.tmp" "${BG}"
        echo "[$(date)] ${CTX}: bedGraph rows = $(wc -l < "${BG}")  -> ${BG}"
    fi

    echo "[$(date)] ${CTX}: bedGraphToBigWig -> ${BW}"
    "${BG2BW}" "${BG}" "${CHROMSIZES}" "${BW}"
    echo "[$(date)] ${CTX}: done  bedGraph=$(du -h "${BG}"|cut -f1)  bigwig=$(du -h "${BW}"|cut -f1)"
done

rm -rf "${TMP}"
echo "[$(date)] ALL DONE"
ls -lh "${OUTROOT}"/gm_pseudobulk_merged.*.methlevel.{bedgraph,bw}
