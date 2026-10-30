#!/bin/bash
#SBATCH -A b1042
#SBATCH -p genomics
#SBATCH -t 24:00:00
#SBATCH -N 1
#SBATCH --mem=64G
#SBATCH --cpus-per-task=16
#SBATCH --array=1-11
#SBATCH --job-name=k562methy
#SBATCH --output=logs/04.k562_methy/methyext.%a.txt
#SBATCH --error=logs/04.k562_methy/methyext.%a.err

# K562 NOMe methylation extraction, run on the MERGED per-cell BAMs produced by
# codes/02k.merge_dedup_k562.sh (prefix = K562_NN, mates 1 and 2). Identical to
# codes/03.methy_extract.sh otherwise:
#   Step 1  bismark_methylation_extractor -s --ignore 6 --bedGraph --CX -> *.bismark.cov.gz
#   Step 2  coverage2cytosine --nome-seq -> NOMe CpG (ACG/TCG) and GpC (GCA/GCC/GCT)
#           reports, ambiguous GCG dropped automatically.

# conda on PATH; override with SCNOMEHIC_CONDA_SH for a different install.
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

source "${SCNOMEHIC_CONDA_SH:-${CONDA_SH}}"
conda activate scnomehic
set -o pipefail

cd ${WORK_ROOT}/benchmark/scnome || { echo "ERROR: cd failed"; exit 1; }
mkdir -p logs/04.k562_methy

BIS=${REFERENCE_ROOT}/hg38_bismark/
ALIGN=04.alignment
METHY=05.methy
mkdir -p ${METHY}

# Cell IDs (K562_01..K562_11), one per line; merged BAMs are <cell>_<mate>.rmdup.bam
LIST=acc_list_k562_cellids.txt
prefix=$(awk -v n=${SLURM_ARRAY_TASK_ID} 'NR==n' ${LIST})
echo "[$(date)] prefix=${prefix}"
if [ -z "${prefix}" ]; then echo "ERROR: empty prefix for task ${SLURM_ARRAY_TASK_ID}"; exit 1; fi

for mate in 1 2; do
    bam=${ALIGN}/${prefix}_${mate}.rmdup.bam
    if [ ! -s "${bam}" ]; then
        echo "  WARN: missing ${bam}, skipping"
        continue
    fi

    cov=${METHY}/${prefix}_${mate}.rmdup.bismark.cov.gz

    # ---- Step 1: genome-wide CX coverage (resume: skip if cov already present) ----
    if [ -s "${cov}" ]; then
        echo "  [skip] extractor done: ${cov}"
    else
        echo "  [run ] bismark_methylation_extractor ${bam}"
        bismark_methylation_extractor \
            -s --ignore 6 --comprehensive --multicore 4 \
            --bedGraph --CX \
            --genome_folder "${BIS}" \
            -o "${METHY}" \
            "${bam}"
    fi

    # ---- Step 2: NOMe CpG / GpC split with GCG removed (resume-aware) ----
    cpg=${METHY}/${prefix}_${mate}.NOMe.CpG_report.txt.gz
    gpc=${METHY}/${prefix}_${mate}.NOMe.GpC_report.txt.gz
    if [ -s "${cpg}" ] && [ -s "${gpc}" ]; then
        echo "  [skip] NOMe split done: ${cpg}"
    elif [ -s "${cov}" ]; then
        echo "  [run ] coverage2cytosine --nome-seq ${cov}"
        coverage2cytosine \
            --nome-seq \
            --genome_folder "${BIS}" \
            --dir "${METHY}" \
            --gzip \
            -o "${prefix}_${mate}" \
            "${cov}"
    else
        echo "  WARN: no cov for ${prefix}_${mate}, cannot run coverage2cytosine"
    fi
done

echo "[$(date)] DONE prefix=${prefix}"
