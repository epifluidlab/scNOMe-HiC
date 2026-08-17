#!/bin/bash
#SBATCH --job-name=gm_trim
#SBATCH --account=b1042
#SBATCH --partition=genomics
#SBATCH --array=1-3
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=32G
#SBATCH --time=24:00:00
#SBATCH --output=/scratch/jmj7858/scnomehic/bulk_gm/pipeline/logs/02_trim_%A_%a.out
#SBATCH --error=/scratch/jmj7858/scnomehic/bulk_gm/pipeline/logs/02_trim_%A_%a.err

# Step 1: adapter-trim each bulk replicate with the SAME params as the pipeline's
# trim rule (clip_R1/R2=15, three_prime_clip_R1/R2=5). Demultiplexing is NOT run
# (it is single-cell only); we trim the bulk libraries directly.
set -euo pipefail
source /gpfs/projects/b1198/epifluidlab/yoshii/sc_nomehic_cellline/bulk_gm_from_scratch/00_paths.sh
activate_scnomehic
mkdir -p "${TRIMWHOLE}" "${WORK}/logs"

REP="rep${SLURM_ARRAY_TASK_ID}"
case "${SLURM_ARRAY_TASK_ID}" in
    1) BASE="${REP1_BASE}";;
    2) BASE="${REP2_BASE}";;
    3) BASE="${REP3_BASE}";;
    *) echo "bad array id"; exit 1;;
esac

R1="${DL}/${BASE}_1.fq.gz"
R2="${DL}/${BASE}_2.fq.gz"
OUT1="${TRIMWHOLE}/${REP}_val_1.fq.gz"
OUT2="${TRIMWHOLE}/${REP}_val_2.fq.gz"

echo "[$(date)] ${REP}: trimming ${R1} + ${R2}"

# Resume-aware
if [[ -s "${OUT1}" && -s "${OUT2}" ]]; then
    echo "[$(date)] ${OUT1}/${OUT2} already present. Skipping."
    exit 0
fi

# --basename gives deterministic names: ${REP}_val_1.fq.gz / ${REP}_val_2.fq.gz
trim_galore --paired \
    --clip_R1 15 --clip_R2 15 \
    --three_prime_clip_R1 5 --three_prime_clip_R2 5 \
    -j 4 --gzip \
    --basename "${REP}" \
    -o "${TRIMWHOLE}" \
    "${R1}" "${R2}"

echo "[$(date)] ${REP}: done -> ${OUT1} ($(du -h "${OUT1}" | cut -f1)), ${OUT2} ($(du -h "${OUT2}" | cut -f1))"
