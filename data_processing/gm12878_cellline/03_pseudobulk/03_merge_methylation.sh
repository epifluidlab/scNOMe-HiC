#!/bin/bash
# ─────────────────────────────────────────────────────────────────────────────
# After call_methylation_array.sh finishes for all chromosomes: concatenate the
# per-chromosome GCH/HCG 6plus2 BEDs into genome-wide per-site BEDs, then bin them
# (1kb/50kb/100kb/250kb) with the pipeline's calcmethylation.py.
#
# Submit AFTER the array completes:  sbatch 03_merge_methylation.sh
# ─────────────────────────────────────────────────────────────────────────────
#SBATCH --job-name=psb_methyl_merge
#SBATCH --account=b1042
#SBATCH --partition=genomics
#SBATCH --nodes=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=32G
#SBATCH --time=08:00:00
#SBATCH --output=${WORK_ROOT}/gm12878_cellline/pseudobulk_methylation/logs/psb_methyl_merge_%j.out
#SBATCH --error=${WORK_ROOT}/gm12878_cellline/pseudobulk_methylation/logs/psb_methyl_merge_%j.err

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
source ${CONDA_SH}
conda activate scnomehic

OUTROOT=${WORK_ROOT}/gm12878_cellline/pseudobulk_methylation
REF=${REFERENCE_ROOT}/hg38/GCA_000001405.15_GRCh38_no_alt_analysis_set
SCRIPTS=${SOFTWARE_ROOT}/sc_NOMeHiC_pipeline/scripts
CHROMS=(chr1 chr2 chr3 chr4 chr5 chr6 chr7 chr8 chr9 chr10 chr11 chr12 chr13 \
        chr14 chr15 chr16 chr17 chr18 chr19 chr20 chr21 chr22 chrX)
BINS=(1000 50000 100000 250000)
declare -A LAB=( [1000]=1kb [50000]=50kb [100000]=100kb [250000]=250kb )

for CTX in GCH HCG; do
    MERGED="${OUTROOT}/gm_pseudobulk_merged.${CTX}.6plus2.bed"
    echo "[$(date)] concatenating ${CTX} across chromosomes -> ${MERGED}.gz"
    : > "${MERGED}"
    for CHR in "${CHROMS[@]}"; do
        f="${OUTROOT}/${CHR}/gm_pseudobulk_merged.${CHR}.cyt.filtered.sort.${CTX}.6plus2.bed.gz"
        if [[ -s "${f}" ]]; then
            zcat "${f}" >> "${MERGED}"
        else
            echo "  WARN: missing ${f}"
        fi
    done
    LC_ALL=C sort --parallel=4 -S 16G -k1,1 -k2,2n "${MERGED}" | gzip -c > "${MERGED}.gz"
    rm -f "${MERGED}"
    echo "  ${CTX} sites: $(zcat ${MERGED}.gz | wc -l)"

    # bin into fixed-size methylation tables (same as pipeline rule `methylation`)
    for bs in "${BINS[@]}"; do
        out="${OUTROOT}/gm_pseudobulk_merged.${CTX}.${LAB[$bs]}_methylation.txt.gz"
        echo "[$(date)] binning ${CTX} @ ${LAB[$bs]} -> ${out}"
        python "${SCRIPTS}/calcmethylation.py" \
            --outfile "${out}" \
            --bed_path "${MERGED}.gz" \
            --context "${CTX}" \
            --bin_size "${bs}" \
            --chrom_size_filepath "${REF}.chrom.sizes"
    done
done
echo "[$(date)] pseudobulk merged-BAM methylation done -> ${OUTROOT}"
ls -la "${OUTROOT}"/gm_pseudobulk_merged.*.6plus2.bed.gz "${OUTROOT}"/gm_pseudobulk_merged.*_methylation.txt.gz
