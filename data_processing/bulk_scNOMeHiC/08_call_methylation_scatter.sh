#!/bin/bash
#SBATCH --job-name=gm_meth_scatter
#SBATCH --account=b1042
#SBATCH --partition=genomics
#SBATCH --array=1-25
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=48G
#SBATCH --time=48:00:00
#SBATCH --output=${TMP_ROOT}/bulk_gm/pipeline/logs/08_meth_scatter_%A_%a.out
#SBATCH --error=${TMP_ROOT}/bulk_gm/pipeline/logs/08_meth_scatter_%A_%a.err

# Step 08: call methylation on the ALREADY-MERGED 3-rep BAM, SCATTERED BY
# CHROMOSOME (array 1-25 = chr1-22,X,Y,M). The monolithic single-threaded BisSNP
# run on the full ~1.5B-read merged BAM was ~94h (over the 48h wall limit); the
# wrapper forbids --nt>1, so we parallelize with --interval chrN instead. Each
# task runs the bissnp non-directional wrapper restricted to one chromosome and
# writes into its own subdir (per-chr --prefix), so nothing collides.
# Concatenate + bin afterwards with 09_merge_beds_and_bin.sh.
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

BISTOOLS="${SOFTWARE_ROOT}/Bis-tools"
BISSNP_JAR="${BISTOOLS}/Bis-SNP/Bis-SNP.latest.jar"
VCF="${REFERENCE_ROOT}/hg38/Homo_sapiens_assembly38.dbsnp138.vcf"
SAMPLE="bulk_GM12878_merged"
MERGED="${METHCALL}/${SAMPLE}.calmd.bam"
BYCHR="${METHCALL}/bychrom"

mkdir -p "${BYCHR}" "${WORK}/logs"

# --- pick this task's chromosome deterministically from the .fai (read-only) ---
CHROM=$(grep -E '^chr([0-9]+|X|Y|M)[[:space:]]' "${REF}.fa.fai" | cut -f1 | sed -n "${SLURM_ARRAY_TASK_ID}p")
if [[ -z "${CHROM}" ]]; then
    echo "ERROR: no chromosome at array index ${SLURM_ARRAY_TASK_ID}" >&2
    exit 1
fi

if [[ ! -s "${MERGED}" ]] || ! samtools quickcheck "${MERGED}" 2>/dev/null; then
    echo "ERROR: merged BAM ${MERGED} missing/invalid. Run the merge (step 13) first." >&2
    exit 1
fi

PREFIX="${SAMPLE}.${CHROM}"
OUTDIR="${BYCHR}/${CHROM}"
GCH_BED="${OUTDIR}/${PREFIX}.cyt.filtered.sort.GCH.6plus2.bed.gz"
HCG_BED="${OUTDIR}/${PREFIX}.cyt.filtered.sort.HCG.6plus2.bed.gz"

# --- resume-aware: skip only if BOTH per-chr beds exist AND are intact gzip ---
if [[ -s "${GCH_BED}" && -s "${HCG_BED}" ]] && gzip -t "${GCH_BED}" 2>/dev/null && gzip -t "${HCG_BED}" 2>/dev/null; then
    echo "[$(date)] ${CHROM}: methylation beds present and intact. Skipping."
    exit 0
fi

# fresh attempt: clear any partial leftovers for this chromosome
rm -rf "${OUTDIR}"; mkdir -p "${OUTDIR}"

# Java 8 required by BisSNP/GATK 3.8.
module load java/jdk1.8.0_191
module load libpng
export BISTOOLS
JAVA8="$(command -v java)"

echo "[$(date)] ${CHROM}: calling methylation on ${MERGED} (-L ${CHROM})"
BAM_ABS="$(readlink -f "${MERGED}")"
LOG_ABS="${WORK}/logs/08_bissnp_${PREFIX}.log"
cd "${OUTDIR}"
perl "${BISTOOLS}/Bis-SNP/bissnp_nomehic_usage.pl" \
    --prefix "${PREFIX}" --mem 40 \
    --interval "${CHROM}" \
    --java8 "${JAVA8}" \
    "${BISSNP_JAR}" \
    "${BAM_ABS}" "${REF}.fa" "${VCF}" \
    > "${LOG_ABS}" 2>&1
gzip -f *.6plus2.bed *.strand.6plus2.bed *.GCH.txt *.HCG.txt *.cpgSummary.txt 2>/dev/null || true

# verify the two beds we need came out intact
if ! { [[ -s "${GCH_BED}" && -s "${HCG_BED}" ]] && gzip -t "${GCH_BED}" 2>/dev/null && gzip -t "${HCG_BED}" 2>/dev/null; }; then
    echo "[$(date)] ERROR: ${CHROM} did not produce intact GCH/HCG beds (see ${LOG_ABS})" >&2
    exit 1
fi
echo "[$(date)] ${CHROM}: done -> ${OUTDIR}"
