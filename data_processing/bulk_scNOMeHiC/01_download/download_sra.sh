#!/bin/bash
#SBATCH --job-name=gm_sra
#SBATCH --account=b1042
#SBATCH --partition=genomics
#SBATCH --array=0-2
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=24G
#SBATCH --time=24:00:00
#SBATCH --output=${WORK_ROOT}/analysis/bulk_scNOMeHiC/download_scripts/logs/sra_%A_%a.out
#SBATCH --error=${WORK_ROOT}/analysis/bulk_scNOMeHiC/download_scripts/logs/sra_%A_%a.err

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

SCRIPT_DIR="${WORK_ROOT}/analysis/bulk_scNOMeHiC/download_scripts"
DEST_DIR="${TMP_ROOT}/bulk_gm"
SRA_DIR="${DEST_DIR}/sra_tmp"
MANIFEST="${SCRIPT_DIR}/accessions.tsv"
THREADS=${SLURM_CPUS_PER_TASK:-8}

mkdir -p "${DEST_DIR}" "${SRA_DIR}"

module purge
module load sratoolkit/3.2.1

# Pick the accession for this array task (0-based -> line N+1)
LINE_NO=$(( SLURM_ARRAY_TASK_ID + 1 ))
ROW=$(sed -n "${LINE_NO}p" "${MANIFEST}")
SRR=$(printf '%s' "${ROW}" | cut -f1)
PREFIX=$(printf '%s' "${ROW}" | cut -f2)

R1="${DEST_DIR}/${PREFIX}_1.fq.gz"
R2="${DEST_DIR}/${PREFIX}_2.fq.gz"

echo "[$(date)] Task ${SLURM_ARRAY_TASK_ID}: ${SRR} -> ${PREFIX}_{1,2}.fq.gz"

# Resume-aware: skip if both mates already present and non-empty
if [[ -s "${R1}" && -s "${R2}" ]]; then
    echo "[$(date)] ${R1} and ${R2} already exist. Skipping."
    exit 0
fi

# 1) Download the SRA run (raise max-size; default cap is too small for these large runs)
echo "[$(date)] prefetch ${SRR} ..."
prefetch --max-size u --output-directory "${SRA_DIR}" "${SRR}"

# 2) Extract paired FASTQ. Use scratch for temp.
TMPDIR_RUN="${SRA_DIR}/tmp_${SRR}"
mkdir -p "${TMPDIR_RUN}"
echo "[$(date)] fasterq-dump ${SRR} ..."
fasterq-dump --split-files --threads "${THREADS}" \
    --temp "${TMPDIR_RUN}" \
    --outdir "${SRA_DIR}" \
    "${SRA_DIR}/${SRR}/${SRR}.sra"

# 3) Compress and rename to the GM12878 names
echo "[$(date)] gzip + rename ..."
pigz -p "${THREADS}" "${SRA_DIR}/${SRR}_1.fastq"
pigz -p "${THREADS}" "${SRA_DIR}/${SRR}_2.fastq"
mv "${SRA_DIR}/${SRR}_1.fastq.gz" "${R1}"
mv "${SRA_DIR}/${SRR}_2.fastq.gz" "${R2}"

# 4) Clean up intermediate SRA + temp for this run
rm -rf "${SRA_DIR}/${SRR}" "${TMPDIR_RUN}"

echo "[$(date)] Done: ${R1} ($(du -h "${R1}" | cut -f1)), ${R2} ($(du -h "${R2}" | cut -f1))"
