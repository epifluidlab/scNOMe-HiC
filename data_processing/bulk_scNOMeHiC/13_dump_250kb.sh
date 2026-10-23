#!/bin/bash
#SBATCH --job-name=gm_dump250kb
#SBATCH --account=b1042
#SBATCH --partition=genomics
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=2
#SBATCH --mem=24G
#SBATCH --time=02:00:00
#SBATCH --output=${TMP_ROOT}/bulk_gm/pipeline/logs/13_dump250kb_%j.out
#SBATCH --error=${TMP_ROOT}/bulk_gm/pipeline/logs/13_dump250kb_%j.err

# Step 13: dump the from-scratch BULK and the DEDUP PSEUDOBULK .hic at 250kb per chr
# (juicer "observed NONE") into the notebook's dumps dir, so the comparison can add
# a 250kb resolution. Prefixes match the notebook: newbulk, gm_pseudobulk_dedup.
# --- repo paths: edit paths.yaml at the repository root, not this file -------
_r="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]:-$0}")")" && pwd)"
while [ "$_r" != "/" ] && [ ! -f "$_r/paths.sh" ]; do _r="$(dirname "$_r")"; done
source "$_r/paths.sh"

set -euo pipefail
source ${WORK_ROOT}/analysis/bulk_scNOMeHiC/00_paths.sh
module load java/jdk-17.0.2+8 2>/dev/null || module load java 2>/dev/null || true

# NEWBULK = reran NON-PBAT 3-rep merged bulk (06c, built 2026-06-09 by 13d_); was PBAT 05_ output, superseded.
NEWBULK_HIC="${WORK}/06c.hic_merged_nopbat/bulk_GM12878_merged.mapQ30.hic"
DEDUP_HIC="${WORK_ROOT}/gm12878_cellline/hic_comparison/gm_pseudobulk.dedup.mapQ30.hic"
DUMPS="${WORK}/hic_comparison/dumps"
mkdir -p "${DUMPS}" "${WORK}/logs"
BS=250000
LAB=250kb

dump_one() {
    local hic="$1" prefix="$2" chr="$3"
    local out="${DUMPS}/${prefix}_${LAB}_${chr}.txt"
    [[ -s "${out}" ]] && return 0
    java -jar "${JUICER_JAR}" dump observed NONE "${hic}" "${chr}" "${chr}" BP "${BS}" "${out}" 2>/dev/null || true
}

echo "[$(date)] dumping bulk + dedup pseudobulk at 250kb"
for chr in chr{1..22} chrX; do
    dump_one "${NEWBULK_HIC}" newbulk            "${chr}"
    dump_one "${DEDUP_HIC}"   gm_pseudobulk_dedup "${chr}"
    echo "  ${chr} done"
done
echo "[$(date)] 250kb dumps done -> ${DUMPS}"
ls "${DUMPS}"/*_250kb_* | wc -l
