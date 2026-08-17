#!/bin/bash
#SBATCH --job-name=gm_hic_nopbat
#SBATCH --account=b1042
#SBATCH --partition=genomicslong
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=24
#SBATCH --mem=200G
#SBATCH --time=4-00:00:00
#SBATCH --output=/scratch/jmj7858/scnomehic/bulk_gm/pipeline/logs/10_hic_nopbat_%j.out
#SBATCH --error=/scratch/jmj7858/scnomehic/bulk_gm/pipeline/logs/10_hic_nopbat_%j.err

# Step 10: build the bulk .hic from the RERAN (non-PBAT) 3-rep merged BAM.
# Unlike the superseded PBAT flow, the input here is ALREADY merged + deduped:
#   - 06_ merged each rep's chunk BAMs and ran bamprocess (markdup) per LIBRARY
#   - 07_ merged the 3 per-rep calmd BAMs into bulk_GM12878_merged.calmd.bam
# So we do NOT re-merge or re-bamprocess; we just extract Hi-C contacts and
# build the .hic, following the canonical recipe used throughout this paper:
#   good-reads filter (-q 30 -f 1 -F 1804) -> sam2juicer_new.py -f DpnII
#   -> LC_ALL=C sort -k2,2d -k6,6d -> juicer_tools pre -q 30 ... hg38
set -euo pipefail
source /gpfs/projects/b1198/epifluidlab/yoshii/sc_nomehic_cellline/bulk_gm_from_scratch/00_paths.sh
export PATH="${SCNOMEHIC_ENV}/bin:${PATH}"
module load java/jdk-17.0.2+8

T="${SLURM_CPUS_PER_TASK}"
HICDIR_NOPBAT="${WORK}/06c.hic_merged_nopbat"
TMP="${HICDIR_NOPBAT}/tmp"
mkdir -p "${HICDIR_NOPBAT}" "${TMP}" "${WORK}/logs"

MERGED_CALMD="${METHCALL}/bulk_GM12878_merged.calmd.bam"   # produced by 13_ step 1
GOOD="${HICDIR_NOPBAT}/bulk_GM12878_merged.good_reads.bam"
HICTXT="${HICDIR_NOPBAT}/bulk_GM12878_merged.hic.txt.gz"
HICSORT="${HICDIR_NOPBAT}/bulk_GM12878_merged.hic.sorted.txt.gz"
HICOUT="${HICDIR_NOPBAT}/bulk_GM12878_merged.mapQ30.hic"

# --- 0. sanity: the reran merged calmd BAM must exist + be valid ---
[[ -s "${MERGED_CALMD}" ]] || { echo "ERROR: missing ${MERGED_CALMD} (run 13_ first)" >&2; exit 1; }
samtools quickcheck "${MERGED_CALMD}" 2>/dev/null || { echo "ERROR: ${MERGED_CALMD} failed quickcheck" >&2; exit 1; }
echo "[$(date)] input merged calmd BAM: ${MERGED_CALMD} ($(du -h "${MERGED_CALMD}" | cut -f1))"

# --- 1. Hi-C contact extraction (mirrors rule scbam2hic / step 4 of 05_) ---
if [[ ! -s "${HICTXT}" ]]; then
    echo "[$(date)] filtering good reads + sam2juicer"
    samtools view -bh -q 30 -f 1 -F 1804 "${MERGED_CALMD}" > "${GOOD}"
    python "${BISHIC}/src/python/sam2juicer_new.py" -s "${GOOD}" -f "${DPNII}" | gzip -nc > "${HICTXT}"
fi

# --- 2. sort contacts (mirrors step 5 of 05_) ---
if [[ ! -s "${HICSORT}" ]]; then
    echo "[$(date)] sorting contacts"
    zcat "${HICTXT}" | sort --parallel="${T}" -S 180G -T "${TMP}" -k2,2d -k6,6d | gzip -nc > "${HICSORT}"
fi

# --- 3. build .hic ---
echo "[$(date)] juicer pre -> ${HICOUT}"
java -Xmx192G -jar "${JUICER_JAR}" pre -q 30 -f "${DPNII}" "${HICSORT}" "${HICOUT}" hg38

echo "[$(date)] reran bulk Hi-C done -> ${HICOUT} ($(du -h "${HICOUT}" | cut -f1))"
rm -rf "${TMP}"
