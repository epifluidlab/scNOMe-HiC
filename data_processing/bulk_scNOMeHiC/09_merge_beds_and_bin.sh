#!/bin/bash
#SBATCH --job-name=gm_meth_bin
#SBATCH --account=b1042
#SBATCH --partition=genomics
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=128G
#SBATCH --time=12:00:00
#SBATCH --output=${TMP_ROOT}/bulk_gm/pipeline/logs/09_meth_bin_%j.out
#SBATCH --error=${TMP_ROOT}/bulk_gm/pipeline/logs/09_meth_bin_%j.err

# Step 09: concatenate the per-chromosome 6plus2 beds from 13b into genome-wide
# GCH/HCG per-base beds, then bin into fixed-bin methylation tables (1kb/50kb/
# 100kb/250kb). Run AFTER all 13b array tasks finish.
#
# Two PHASES, ordered so the cheap concatenation always completes first:
#   PHASE 1 (low memory): concatenate GCH + HCG genome-wide beds. These feed the
#           notebook (via the per-site conversion in the Fig. 1 comparison code) and must not be blocked.
#   PHASE 2 (high memory): bin each context. calcmethylation.py loads the whole
#           bed into pandas + groupby -> needs ~tens of GB for genome-wide GCH;
#           a previous 16G run was OOM-killed, hence --mem=128G here.
# --- repo paths: edit paths.yaml at the repository root, not this file -------
_r="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]:-$0}")")" && pwd)"
while [ "$_r" != "/" ] && [ ! -f "$_r/paths.sh" ]; do _r="$(dirname "$_r")"; done
source "$_r/paths.sh"

set -euo pipefail
source ${WORK_ROOT}/analysis/bulk_scNOMeHiC/00_paths.sh
export PATH="${SCNOMEHIC_ENV}/bin:${PATH}"

SCRIPTS="${PIPELINE}/scripts"
SAMPLE="bulk_GM12878_merged"
BYCHR="${METHCALL}/bychrom"

mapfile -t CHROMS < <(grep -E '^chr([0-9]+|X|Y|M)[[:space:]]' "${REF}.fa.fai" | cut -f1)

# ---------------- PHASE 1: concatenate genome-wide per-base beds ----------------
for ctx in GCH HCG; do
    OUT_BED="${METHCALL}/${SAMPLE}.cyt.filtered.sort.${ctx}.6plus2.bed.gz"
    if [[ -s "${OUT_BED}" ]] && gzip -t "${OUT_BED}" 2>/dev/null; then
        echo "[$(date)] ${ctx}: concatenated bed present + intact, skip"
        continue
    fi
    parts=()
    missing=0
    for c in "${CHROMS[@]}"; do
        f="${BYCHR}/${c}/${SAMPLE}.${c}.cyt.filtered.sort.${ctx}.6plus2.bed.gz"
        if [[ -s "${f}" ]] && gzip -t "${f}" 2>/dev/null; then
            parts+=("${f}")
        else
            echo "WARN: missing/!intact ${ctx} bed for ${c}: ${f}" >&2
            missing=$((missing+1))
        fi
    done
    if [[ "${missing}" -ne 0 ]]; then
        echo "ERROR: ${missing} ${ctx} per-chr bed(s) missing; rerun those 13b tasks first." >&2
        exit 1
    fi
    # concatenated gzip streams are valid gzip; zcat/pandas read them fine.
    # tmp -> mv so a killed job never leaves a partial concatenated bed.
    cat "${parts[@]}" > "${OUT_BED}.tmp"
    gzip -t "${OUT_BED}.tmp" 2>/dev/null || { echo "ERROR: concatenated ${ctx} bed not intact" >&2; exit 1; }
    mv -f "${OUT_BED}.tmp" "${OUT_BED}"
    echo "[$(date)] ${ctx}: concatenated ${#CHROMS[@]} chroms -> ${OUT_BED}"
done

# ---------------- PHASE 2: bin into fixed-bin methylation tables ----------------
declare -A BINS=( [1kb]=1000 [50kb]=50000 [100kb]=100000 [250kb]=250000 )
for ctx in GCH HCG; do
    OUT_BED="${METHCALL}/${SAMPLE}.cyt.filtered.sort.${ctx}.6plus2.bed.gz"
    for lab in "${!BINS[@]}"; do
        OUT="${METHCALL}/${SAMPLE}.${ctx}.${lab}_methylation.txt.gz"
        if [[ -s "${OUT}" ]] && gzip -t "${OUT}" 2>/dev/null; then
            echo "[$(date)] ${OUT} present + intact, skip"; continue
        fi
        echo "[$(date)] binning ${ctx} @ ${lab} -> ${OUT}"
        python "${SCRIPTS}/calcmethylation.py" \
            --outfile "${OUT}.tmp.gz" \
            --bed_path "${OUT_BED}" \
            --context "${ctx}" \
            --bin_size "${BINS[$lab]}" \
            --chrom_size_filepath "${REF}.chrom.sizes"
        mv -f "${OUT}.tmp.gz" "${OUT}"
    done
done

echo "[$(date)] merged-rep methylation binning done -> ${METHCALL}"
ls -lh "${METHCALL}/${SAMPLE}".{GCH,HCG}.*_methylation.txt.gz 2>/dev/null || true
