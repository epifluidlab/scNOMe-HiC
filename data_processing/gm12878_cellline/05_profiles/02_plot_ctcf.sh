#!/bin/bash
#SBATCH --job-name=s3_ctcf_mat
#SBATCH --account=b1042
#SBATCH --partition=genomics
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=32G
#SBATCH --time=04:00:00
#SBATCH --output=/gpfs/projects/b1198/epifluidlab/yoshii/scnomehic_paper/s3/analysis/logs/s3_ctcf_mat_%j.out
#SBATCH --error=/gpfs/projects/b1198/epifluidlab/yoshii/scnomehic_paper/s3/analysis/logs/s3_ctcf_mat_%j.err

# ============================================================================
# CTCF metaplot for the GM12878 PSEUDOBULK NOMe tracks, both contexts in ONE
# matrix so GCH and HCG can be overlaid in a single figure.
#   GCH (accessibility) = green
#   HCG (methylation)   = black
#
# Parameters mirror the paper script s2/plotCTCF.sh:
#   --referencePoint center  -b/-a 2000  -bs 20  --skipZeros --averageTypeBins mean
# ONE deviation (deliberate): plotHeatmap gets --missingDataColor white. The
# per-site NOMe tracks cover only ~6.3% of bases, so at 20 bp bins ~27% of bins
# have no covered base -> NaN. deepTools' default paints NaN BLACK, which is what
# made the earlier heatmap look solid black. White keeps the true methylation
# magnitude (we do NOT use --missingDataAsZero, which would deflate values).
# ============================================================================
# --- repo paths: edit paths.yaml at the repository root, not this file -------
_r="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]:-$0}")")" && pwd)"
while [ "$_r" != "/" ] && [ ! -f "$_r/paths.sh" ]; do _r="$(dirname "$_r")"; done
source "$_r/paths.sh"

set -euo pipefail
export PATH="${CONDA_ENVS}/scnomehic/bin:$PATH"

S3=/gpfs/projects/b1198/epifluidlab/yoshii/scnomehic_paper/s3
PSB=/gpfs/projects/b1198/epifluidlab/yoshii/sc_nomehic_cellline/gm_sc_new/pseudobulk_methylation

GCH_BW="${PSB}/gm_pseudobulk_merged.GCH.methlevel.bw"   # accessibility
HCG_BW="${PSB}/gm_pseudobulk_merged.HCG.methlevel.bw"   # methylation
REGION=/gpfs/projects/b1198/epifluidlab/yoshii/sc_nomehic_cellline/gm_sc_new/ctcf_cgi_profiles/regions/CTCF_chipseq.GM12878.ENCFF960ZGP.optimalIDR.hg38.noTSS4kb.sort.bed

OUT_MAT="${S3}/analysis/ctcf/matrices"
OUT_FIG="${S3}/analysis/ctcf/figures"
mkdir -p "${OUT_MAT}" "${OUT_FIG}" "${S3}/analysis/logs"

FLANK=2000
BIN=20
NPROC="${SLURM_CPUS_PER_TASK:-8}"
GCH_COLOR="green"
HCG_COLOR="black"

TAG="GCH_HCG.CTCFnoTSS"
MAT="${OUT_MAT}/${TAG}.matrix.gz"
REGOUT="${OUT_MAT}/${TAG}.regions.bed"
PROF_PDF="${OUT_FIG}/${TAG}.profile.pdf"
PROF_TSV="${OUT_MAT}/${TAG}.profile.tsv"
HEAT_PDF="${OUT_FIG}/${TAG}.heatmap.pdf"

for f in "${GCH_BW}" "${HCG_BW}" "${REGION}"; do
    [[ -s "$f" ]] || { echo "ERROR: missing $f" >&2; exit 1; }
done

echo "[$(date)] [matrix] ${TAG}  (GCH + HCG in one matrix)"
computeMatrix reference-point \
    -S "${GCH_BW}" "${HCG_BW}" \
    -R "${REGION}" \
    --referencePoint center \
    -b "${FLANK}" -a "${FLANK}" \
    -bs "${BIN}" \
    --skipZeros --averageTypeBins mean \
    --numberOfProcessors "${NPROC}" \
    --samplesLabel "GCH (accessibility)" "HCG (methylation)" \
    -o "${MAT}" \
    --outFileSortedRegions "${REGOUT}"

echo "[$(date)] [profile overlay] ${TAG}"
# --perGroup puts BOTH samples in the SAME panel (one panel per region group)
plotProfile -m "${MAT}" \
    --perGroup \
    --colors "${GCH_COLOR}" "${HCG_COLOR}" \
    --plotTitle "GM12878 pseudobulk: GCH vs HCG @ CTCF (noTSS)" \
    --yAxisLabel "methylation level (%)" \
    --refPointLabel "CTCF" \
    --regionsLabel "CTCF noTSS" \
    --plotFileFormat pdf \
    --outFileName "${PROF_PDF}" \
    --outFileNameData "${PROF_TSV}"

echo "[$(date)] [heatmap] ${TAG}"
# green colormap for GCH, grey/black colormap for HCG (order matches -S)
plotHeatmap -m "${MAT}" \
    --colorMap Greens Greys \
    --missingDataColor white \
    --refPointLabel "CTCF" \
    --regionsLabel "CTCF noTSS" \
    --heatmapHeight 10 --heatmapWidth 6 \
    --yAxisLabel "methylation level (%)" \
    --plotFileFormat pdf \
    --outFileName "${HEAT_PDF}"

# PNG previews alongside the PDFs
plotProfile -m "${MAT}" --perGroup --colors "${GCH_COLOR}" "${HCG_COLOR}" \
    --plotTitle "GM12878 pseudobulk: GCH vs HCG @ CTCF (noTSS)" \
    --yAxisLabel "methylation level (%)" --refPointLabel "CTCF" \
    --regionsLabel "CTCF noTSS" --outFileName "${PROF_PDF%.pdf}.png"
plotHeatmap -m "${MAT}" --colorMap Greens Greys --missingDataColor white \
    --refPointLabel "CTCF" --regionsLabel "CTCF noTSS" \
    --heatmapHeight 10 --heatmapWidth 6 --yAxisLabel "methylation level (%)" \
    --outFileName "${HEAT_PDF%.pdf}.png"

echo "[$(date)] DONE"
ls -lh "${OUT_MAT}" "${OUT_FIG}"
