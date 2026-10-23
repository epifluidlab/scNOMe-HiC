#!/usr/bin/env bash
# ============================================================================
# Split the combined CGI-vs-nonCGI matrix into SEPARATE per-region-set figures,
# each still showing BOTH marks overlaid (GCH=green, HCG=black):
#   - GCH_HCG.TSS_CGI.*     -> CGI TSS only
#   - GCH_HCG.TSS_nonCGI.*  -> non-CGI TSS only
#
# Uses `computeMatrixOperations subset --group` so NOTHING is recomputed: the
# values are byte-identical to the combined matrix produced by
# 03_plot_cgi.sh (SLURM 7586934).
# ============================================================================
# --- repo paths: edit paths.yaml at the repository root, not this file -------
_r="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]:-$0}")")" && pwd)"
while [ "$_r" != "/" ] && [ ! -f "$_r/paths.sh" ]; do _r="$(dirname "$_r")"; done
source "$_r/paths.sh"

set -euo pipefail
export PATH="${CONDA_ENVS}/scnomehic/bin:$PATH"

S3=/gpfs/projects/b1198/epifluidlab/yoshii/scnomehic_paper/s3
OUT_MAT="${S3}/analysis/tss_cgi/matrices"
OUT_FIG="${S3}/analysis/tss_cgi/figures"
COMBINED="${OUT_MAT}/GCH_HCG.TSS_CGI_vs_nonCGI.matrix.gz"

GRP_CGI="gencode.v45.TSS.UCSC_CGI.hg38.primary_assembly.gene_ensemble_id.sort.bed"
GRP_NON="gencode.v45.TSS.no_UCSC_CGI_plus_shore_2kb.hg38.primary_assembly.gene_ensemble_id.canonical.bed"

GCH_COLOR="green"
HCG_COLOR="black"

[[ -s "${COMBINED}" ]] || { echo "ERROR: missing ${COMBINED}" >&2; exit 1; }

# $1 = output tag, $2 = group name in the matrix, $3 = human label
make_one() {
    local TAG="$1" GRP="$2" LABEL="$3"
    local MAT="${OUT_MAT}/${TAG}.matrix.gz"
    local PROF="${OUT_FIG}/${TAG}.profile"
    local HEAT="${OUT_FIG}/${TAG}.heatmap"

    echo "[$(date +%T)] subset -> ${TAG}  (${LABEL})"
    computeMatrixOperations subset -m "${COMBINED}" --group "${GRP}" -o "${MAT}"

    for EXT in pdf png; do
        plotProfile -m "${MAT}" \
            --perGroup \
            --colors "${GCH_COLOR}" "${HCG_COLOR}" \
            --regionsLabel "${LABEL}" \
            --plotTitle "GM12878 pseudobulk: GCH vs HCG @ ${LABEL}" \
            --yAxisLabel "methylation level (%)" \
            --refPointLabel "TSS" \
            --outFileName "${PROF}.${EXT}" \
            $( [[ "${EXT}" == "pdf" ]] && echo "--outFileNameData ${OUT_MAT}/${TAG}.profile.tsv" )

        plotHeatmap -m "${MAT}" \
            --colorMap Greens Greys \
            --missingDataColor white \
            --refPointLabel "TSS" \
            --regionsLabel "${LABEL}" \
            --heatmapHeight 10 --heatmapWidth 6 \
            --yAxisLabel "methylation level (%)" \
            --outFileName "${HEAT}.${EXT}"
    done
}

make_one "GCH_HCG.TSS_CGI"    "${GRP_CGI}" "CGI TSS"
make_one "GCH_HCG.TSS_nonCGI" "${GRP_NON}" "non-CGI TSS"

echo "[$(date +%T)] DONE"
ls -lh "${OUT_FIG}"
