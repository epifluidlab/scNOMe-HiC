#!/bin/bash
#SBATCH --job-name=s3_cgi_mat
#SBATCH --account=b1042
#SBATCH --partition=genomics
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=32G
#SBATCH --time=04:00:00
#SBATCH --output=/gpfs/projects/b1198/epifluidlab/yoshii/scnomehic_paper/s3/analysis/logs/s3_cgi_mat_%j.out
#SBATCH --error=/gpfs/projects/b1198/epifluidlab/yoshii/scnomehic_paper/s3/analysis/logs/s3_cgi_mat_%j.err

# ============================================================================
# TSS CGI vs non-CGI metaplot for the GM12878 PSEUDOBULK NOMe tracks.
# GCH and HCG go into ONE matrix, and BOTH region sets into the same matrix, so
# `plotProfile --perGroup` yields one panel per region group (CGI TSS /
# non-CGI TSS) with both marks overlaid:
#   GCH (accessibility) = green
#   HCG (methylation)   = black
#
# Parameters mirror the paper script s2/plotCGI.sh:
#   --referencePoint TSS  -b/-a 2000  -bs 20  --skipZeros --averageTypeBins mean
# Same deliberate deviation as 02_plot_ctcf.sh: plotHeatmap gets
# --missingDataColor white (per-site NOMe tracks cover only ~6.3% of bases, so a
# fraction of 20 bp bins are NaN and deepTools' default paints NaN BLACK).
# We do NOT use --missingDataAsZero, which would deflate the methylation values.
# ============================================================================
set -euo pipefail
export PATH="/projects/b1198/epifluidlab/yoshii/software/conda/envs/scnomehic/bin:$PATH"

S3=/gpfs/projects/b1198/epifluidlab/yoshii/scnomehic_paper/s3
PSB=/gpfs/projects/b1198/epifluidlab/yoshii/sc_nomehic_cellline/gm_sc_new/pseudobulk_methylation
REGDIR=/gpfs/projects/b1198/epifluidlab/yoshii/sc_nomehic_cellline/gm_sc_new/ctcf_cgi_profiles/regions

GCH_BW="${PSB}/gm_pseudobulk_merged.GCH.methlevel.bw"   # accessibility
HCG_BW="${PSB}/gm_pseudobulk_merged.HCG.methlevel.bw"   # methylation
REGION_CGI="${REGDIR}/gencode.v45.TSS.UCSC_CGI.hg38.primary_assembly.gene_ensemble_id.sort.bed"
REGION_NONCGI="${REGDIR}/gencode.v45.TSS.no_UCSC_CGI_plus_shore_2kb.hg38.primary_assembly.gene_ensemble_id.canonical.bed"

OUT_MAT="${S3}/analysis/tss_cgi/matrices"
OUT_FIG="${S3}/analysis/tss_cgi/figures"
mkdir -p "${OUT_MAT}" "${OUT_FIG}" "${S3}/analysis/logs"

FLANK=2000
BIN=20
NPROC="${SLURM_CPUS_PER_TASK:-8}"
GCH_COLOR="green"
HCG_COLOR="black"

TAG="GCH_HCG.TSS_CGI_vs_nonCGI"
MAT="${OUT_MAT}/${TAG}.matrix.gz"
REGOUT="${OUT_MAT}/${TAG}.regions.bed"
PROF_PDF="${OUT_FIG}/${TAG}.profile.pdf"
PROF_TSV="${OUT_MAT}/${TAG}.profile.tsv"
HEAT_PDF="${OUT_FIG}/${TAG}.heatmap.pdf"

for f in "${GCH_BW}" "${HCG_BW}" "${REGION_CGI}" "${REGION_NONCGI}"; do
    [[ -s "$f" ]] || { echo "ERROR: missing $f" >&2; exit 1; }
done
echo "[$(date)] CGI TSS regions:     $(wc -l < "${REGION_CGI}")"
echo "[$(date)] non-CGI TSS regions: $(wc -l < "${REGION_NONCGI}")"

echo "[$(date)] [matrix] ${TAG}  (GCH + HCG x CGI + nonCGI in one matrix)"
computeMatrix reference-point \
    -S "${GCH_BW}" "${HCG_BW}" \
    -R "${REGION_CGI}" "${REGION_NONCGI}" \
    --referencePoint TSS \
    -b "${FLANK}" -a "${FLANK}" \
    -bs "${BIN}" \
    --skipZeros --averageTypeBins mean \
    --numberOfProcessors "${NPROC}" \
    --samplesLabel "GCH (accessibility)" "HCG (methylation)" \
    -o "${MAT}" \
    --outFileSortedRegions "${REGOUT}"

echo "[$(date)] [profile overlay] ${TAG}"
# --perGroup => one panel per REGION group, both marks overlaid inside it
plotProfile -m "${MAT}" \
    --perGroup \
    --colors "${GCH_COLOR}" "${HCG_COLOR}" \
    --regionsLabel "CGI TSS" "non-CGI TSS" \
    --plotTitle "GM12878 pseudobulk: GCH vs HCG @ TSS (CGI vs non-CGI)" \
    --yAxisLabel "methylation level (%)" \
    --refPointLabel "TSS" \
    --plotFileFormat pdf \
    --outFileName "${PROF_PDF}" \
    --outFileNameData "${PROF_TSV}"

echo "[$(date)] [heatmap] ${TAG}"
plotHeatmap -m "${MAT}" \
    --colorMap Greens Greys \
    --missingDataColor white \
    --refPointLabel "TSS" \
    --regionsLabel "CGI TSS" "non-CGI TSS" \
    --heatmapHeight 10 --heatmapWidth 6 \
    --yAxisLabel "methylation level (%)" \
    --plotFileFormat pdf \
    --outFileName "${HEAT_PDF}"

# PNG previews
plotProfile -m "${MAT}" --perGroup --colors "${GCH_COLOR}" "${HCG_COLOR}" \
    --regionsLabel "CGI TSS" "non-CGI TSS" \
    --plotTitle "GM12878 pseudobulk: GCH vs HCG @ TSS (CGI vs non-CGI)" \
    --yAxisLabel "methylation level (%)" --refPointLabel "TSS" \
    --outFileName "${PROF_PDF%.pdf}.png"
plotHeatmap -m "${MAT}" --colorMap Greens Greys --missingDataColor white \
    --refPointLabel "TSS" --regionsLabel "CGI TSS" "non-CGI TSS" \
    --heatmapHeight 10 --heatmapWidth 6 --yAxisLabel "methylation level (%)" \
    --outFileName "${HEAT_PDF%.pdf}.png"

echo "[$(date)] DONE"
ls -lh "${OUT_MAT}" "${OUT_FIG}"
