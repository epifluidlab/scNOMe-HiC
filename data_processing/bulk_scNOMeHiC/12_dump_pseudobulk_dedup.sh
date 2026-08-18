#!/bin/bash
#SBATCH --job-name=gm_psbdedup_dump
#SBATCH --account=b1042
#SBATCH --partition=genomics
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=2
#SBATCH --mem=24G
#SBATCH --time=02:00:00
#SBATCH --output=/scratch/jmj7858/scnomehic/bulk_gm/pipeline/logs/12_psbdedup_dump_%j.out
#SBATCH --error=/scratch/jmj7858/scnomehic/bulk_gm/pipeline/logs/12_psbdedup_dump_%j.err

# Step 12: dump the DEDUP pseudobulk .hic (gm_pseudobulk.dedup.mapQ30.hic) at
# 2.5Mb/1Mb/500kb per chr (juicer "observed NONE") into the SAME dumps dir used
# by the notebook, with prefix gm_pseudobulk_dedup -> so the notebook can switch
# PSEUDO to it while the original gm_pseudobulk dumps stay intact.
set -euo pipefail
source /gpfs/projects/b1198/epifluidlab/yoshii/sc_nomehic_cellline/bulk_gm_from_scratch/00_paths.sh
module load java/jdk-17.0.2+8 2>/dev/null || module load java 2>/dev/null || true

DEDUP_HIC="/gpfs/projects/b1198/epifluidlab/yoshii/sc_nomehic_cellline/gm_sc_new/hic_comparison/gm_pseudobulk.dedup.mapQ30.hic"
DUMPS="${WORK}/hic_comparison/dumps"
mkdir -p "${DUMPS}" "${WORK}/logs"
declare -A LABELS=( [2500000]=2.5Mb [1000000]=1Mb [500000]=500kb )

dump_one() {
    local bs="$1" lab="$2" chr="$3"
    local out="${DUMPS}/gm_pseudobulk_dedup_${lab}_${chr}.txt"
    [[ -s "${out}" ]] && return 0
    java -jar "${JUICER_JAR}" dump observed NONE "${DEDUP_HIC}" "${chr}" "${chr}" BP "${bs}" "${out}" 2>/dev/null || true
}

echo "[$(date)] dumping DEDUP pseudobulk at 2.5Mb/1Mb/500kb"
for chr in chr{1..22} chrX; do
    for bs in 2500000 1000000 500000; do
        dump_one "${bs}" "${LABELS[$bs]}" "${chr}"
    done
    echo "  ${chr} done"
done
echo "[$(date)] dedup pseudobulk dumps done -> ${DUMPS}/gm_pseudobulk_dedup_*"
ls "${DUMPS}"/gm_pseudobulk_dedup_* | wc -l
