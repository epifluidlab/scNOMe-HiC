#!/bin/bash
#SBATCH --job-name=gm_hicdump
#SBATCH --account=b1042
#SBATCH --partition=genomics
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=2
#SBATCH --mem=24G
#SBATCH --time=06:00:00
#SBATCH --output=${TMP_ROOT}/bulk_gm/pipeline/logs/11_hicdump_%j.out
#SBATCH --error=${TMP_ROOT}/bulk_gm/pipeline/logs/11_hicdump_%j.err

# Step 11: dump the reran GM12878 bulk .hic and the gm_sc_new pseudobulk .hic at
# 2.5Mb / 1Mb / 500kb per chromosome (juicer "observed NONE"), into one GM dumps
# dir, for the Fig. 1 Hi-C comparison notebook.
# --- repo paths: edit paths.yaml at the repository root, not this file -------
_r="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]:-$0}")")" && pwd)"
while [ "$_r" != "/" ] && [ ! -f "$_r/paths.sh" ]; do _r="$(dirname "$_r")"; done
source "$_r/paths.sh"

set -euo pipefail
source ${WORK_ROOT}/analysis/bulk_scNOMeHiC/00_paths.sh
module load java/jdk-17.0.2+8 2>/dev/null || module load java 2>/dev/null || true

# NEWBULK = the reran NON-PBAT 3-rep merged bulk (06c, built 2026-06-09 by 13d_).
# Was previously the PBAT 05_ output (${HICDIR}/...); superseded — see SESSION_NOTE_2026-06-09.
NEWBULK_HIC="${WORK}/06c.hic_merged_nopbat/bulk_GM12878_merged.mapQ30.hic"
PSEUDO_HIC="${WORK_ROOT}/gm12878_cellline/hic_comparison/gm_pseudobulk.mapQ30.hic"
DUMPS="${WORK}/hic_comparison/dumps"
mkdir -p "${DUMPS}" "${WORK}/logs"

# bin size -> label (must match the notebook's binsize_label / aliases)
declare -A LABELS=( [2500000]=2.5Mb [1000000]=1Mb [500000]=500kb )

dump_one() {
    local hic="$1" prefix="$2" bs="$3" lab="$4" chr="$5"
    local out="${DUMPS}/${prefix}_${lab}_${chr}.txt"
    [[ -s "${out}" ]] && return 0
    java -jar "${JUICER_JAR}" dump observed NONE "${hic}" "${chr}" "${chr}" BP "${bs}" "${out}" 2>/dev/null || true
}

echo "[$(date)] dumping GM bulk + pseudobulk at 2.5Mb/1Mb/500kb"
for chr in chr{1..22} chrX; do
    for bs in 2500000 1000000 500000; do
        lab="${LABELS[$bs]}"
        dump_one "${NEWBULK_HIC}" newbulk        "${bs}" "${lab}" "${chr}"
        dump_one "${PSEUDO_HIC}"  gm_pseudobulk   "${bs}" "${lab}" "${chr}"
    done
    echo "  ${chr} done"
done
echo "[$(date)] all dumps done -> ${DUMPS}"
ls "${DUMPS}" | sed -E 's/_chr[0-9XY]+\.txt//' | sort | uniq -c