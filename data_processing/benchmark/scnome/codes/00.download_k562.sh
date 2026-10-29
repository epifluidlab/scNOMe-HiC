#!/bin/bash
#SBATCH -A b1042
#SBATCH -p genomics
#SBATCH -t 08:00:00
#SBATCH -N 1
#SBATCH --mem=4G
#SBATCH --cpus-per-task=2
#SBATCH --array=1-22%10
#SBATCH --job-name=scn_dl_k562
#SBATCH --output=/gpfs/projects/b1042/epifluidlab/yoshii/scnomehic_paper/benchmark/scnome/logs/00.download_k562/dl.%a.txt
#SBATCH --error=/gpfs/projects/b1042/epifluidlab/yoshii/scnomehic_paper/benchmark/scnome/logs/00.download_k562/dl.%a.err

# Re-download the 22 SRA runs behind the 11 merged K562 scNOMe-seq cells.
#
# The 12 GM cells (SRR3729642-653) still have their trinuc tables in
# 04.alignment/, but the K562 runs (SRR372966x-68x) were lost when b1042 scratch
# was restored on 2026-10-26 -- 01.fastq/ is empty and no K562 BAM survives.
# acc_list_k562_cells.tsv maps K562_01..11 to its two runs each;
# codes/download_list_k562.tsv was rebuilt from the ENA filereport API.
#
# 01.trim.sh reads ${prefix}_{1,2}.fq.gz, so the ENA .fastq.gz are renamed.

source /home/jmj7858/.bashrc
set -eo pipefail

BASE="/gpfs/projects/b1042/epifluidlab/yoshii/scnomehic_paper/benchmark/scnome"
OUT="${BASE}/01.fastq"
LIST="${BASE}/codes/download_list_k562.tsv"
mkdir -p "${OUT}" "${BASE}/logs/00.download_k562"

# ENA refuses connections when many array tasks hit it at once, and wget does
# NOT retry a refused connection without --retry-connrefused. Stagger the start
# and retry patiently rather than failing the task.
sleep $(( (RANDOM % 90) + (SLURM_ARRAY_TASK_ID % 20) * 3 ))

line=$(sed -n "${SLURM_ARRAY_TASK_ID}p" "${LIST}")
acc=$(echo "${line}" | cut -f1)
urls=$(echo "${line}" | cut -f2)
md5s=$(echo "${line}" | cut -f3)
echo "[$(date)] Task ${SLURM_ARRAY_TASK_ID}: ${acc}"

i=1
while [ ${i} -le 2 ]; do
    url=$(echo "${urls}" | cut -d';' -f${i})
    want=$(echo "${md5s}" | cut -d';' -f${i})
    final="${OUT}/${acc}_${i}.fq.gz"

    if [ -s "${final}" ]; then
        echo "  [skip] ${acc}_${i}.fq.gz already present ($(stat -c%s "${final}") bytes)"
        i=$((i+1)); continue
    fi

    echo "  [get ] https://${url}"
    wget -c --tries=30 --waitretry=60 --random-wait --retry-connrefused --read-timeout=120 --timeout=60 -O "${final}" "https://${url}"

    got=$(md5sum "${final}" | cut -d' ' -f1)
    if [ "${got}" != "${want}" ]; then
        echo "  ERROR md5 mismatch for ${acc}_${i}: got ${got} want ${want}" >&2
        exit 1
    fi
    echo "  [md5 ] ok ${got}  -> ${final}"
    i=$((i+1))
done

echo "[$(date)] DONE ${acc}"
