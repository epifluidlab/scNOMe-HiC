#!/bin/bash
#SBATCH --job-name=gm_meth_merged
#SBATCH --account=b1042
#SBATCH --partition=genomics
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=16
#SBATCH --mem=64G
#SBATCH --time=48:00:00
#SBATCH --output=${TMP_ROOT}/bulk_gm/pipeline/logs/07_meth_merged_%j.out
#SBATCH --error=${TMP_ROOT}/bulk_gm/pipeline/logs/07_meth_merged_%j.err

# Step 07: merge the 3 per-rep bamprocessed (calmd, dedup) BAMs into ONE bulk
# BAM, then CALL METHYLATION on the merge with the non-directional bissnp wrapper
# (mirrors `rule bistools`), and bin the per-base GCH/HCG beds (mirrors
# `rule methylation`) at 1kb/50kb/100kb/250kb.
#   merged.calmd.bam -> {GCH,HCG}.6plus2.bed.gz -> *_methylation.txt.gz
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
T="${SLURM_CPUS_PER_TASK}"

BISTOOLS="${SOFTWARE_ROOT}/Bis-tools"
BISSNP_JAR="${BISTOOLS}/Bis-SNP/Bis-SNP.latest.jar"
VCF="${REFERENCE_ROOT}/hg38/Homo_sapiens_assembly38.dbsnp138.vcf"
SCRIPTS="${PIPELINE}/scripts"
SAMPLE="bulk_GM12878_merged"

mkdir -p "${METHCALL}" "${WORK}/logs"
MERGED="${METHCALL}/${SAMPLE}.calmd.bam"

# --- 1. merge the 3 per-rep calmd BAMs (already coord-sorted + MD-tagged) ---
if [[ ! -s "${MERGED}" || ! -s "${MERGED}.bai" ]]; then
    REP_BAMS=()
    for r in rep1 rep2 rep3; do
        b="${BAMPROC_REP}/bulk_GM12878_${r}.calmd.bam"
        [[ -s "${b}" ]] || { echo "ERROR: missing ${b}" >&2; exit 1; }
        REP_BAMS+=("${b}")
    done
    echo "[$(date)] merging ${#REP_BAMS[@]} per-rep calmd BAMs -> ${MERGED}"
    samtools merge -@ "${T}" -f "${MERGED}" "${REP_BAMS[@]}"
    samtools index -@ "${T}" "${MERGED}"
fi

# --- 2. methylation calling (bissnp non-directional wrapper, mirrors rule bistools) ---
# Java 8 required by BisSNP/GATK 3.8. Use the cluster module's java8 binary.
module load java/jdk1.8.0_191
module load libpng
export BISTOOLS
JAVA8="$(command -v java)"

GCH_BED="${METHCALL}/${SAMPLE}.cyt.filtered.sort.GCH.6plus2.bed.gz"
HCG_BED="${METHCALL}/${SAMPLE}.cyt.filtered.sort.HCG.6plus2.bed.gz"

if [[ ! -s "${GCH_BED}" || ! -s "${HCG_BED}" ]]; then
    echo "[$(date)] calling methylation on ${MERGED}"
    BAM_ABS="$(readlink -f "${MERGED}")"
    LOG_ABS="${WORK}/logs/07_bissnp_${SAMPLE}.log"
    pushd "${METHCALL}" >/dev/null
    perl "${BISTOOLS}/Bis-SNP/bissnp_nomehic_usage.pl" \
        --prefix "${SAMPLE}" --mem 56 \
        --java8 "${JAVA8}" \
        "${BISSNP_JAR}" \
        "${BAM_ABS}" "${REF}.fa" "${VCF}" \
        > "${LOG_ABS}" 2>&1
    gzip -f *.6plus2.bed *.strand.6plus2.bed *.GCH.txt *.HCG.txt *.cpgSummary.txt 2>/dev/null || true
    popd >/dev/null
fi

# --- 3. bin per-base beds into fixed-bin methylation tables (mirrors rule methylation) ---
declare -A BINS=( [1kb]=1000 [50kb]=50000 [100kb]=100000 [250kb]=250000 )
for ctx in GCH HCG; do
    BED="${METHCALL}/${SAMPLE}.cyt.filtered.sort.${ctx}.6plus2.bed.gz"
    [[ -s "${BED}" ]] || { echo "WARN: missing ${BED}, skipping ${ctx}" >&2; continue; }
    for lab in "${!BINS[@]}"; do
        OUT="${METHCALL}/${SAMPLE}.${ctx}.${lab}_methylation.txt.gz"
        if [[ -s "${OUT}" ]]; then echo "[$(date)] ${OUT} exists, skip"; continue; fi
        echo "[$(date)] binning ${ctx} @ ${lab} -> ${OUT}"
        python "${SCRIPTS}/calcmethylation.py" \
            --outfile "${OUT}" \
            --bed_path "${BED}" \
            --context "${ctx}" \
            --bin_size "${BINS[$lab]}" \
            --chrom_size_filepath "${REF}.chrom.sizes"
    done
done

echo "[$(date)] merged-rep methylation done -> ${METHCALL}"
