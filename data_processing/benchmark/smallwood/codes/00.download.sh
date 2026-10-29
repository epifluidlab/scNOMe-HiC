#!/bin/bash
#SBATCH -A b1042
#SBATCH -p genomics
#SBATCH -t 08:00:00
#SBATCH -N 1
#SBATCH --mem=4G
#SBATCH --cpus-per-task=2
#SBATCH --array=1-51%10
#SBATCH --job-name=smw_dl
#SBATCH --output=/gpfs/projects/b1042/epifluidlab/yoshii/scnomehic_paper/benchmark/smallwood/logs/00.download/dl.%a.txt
#SBATCH --error=/gpfs/projects/b1042/epifluidlab/yoshii/scnomehic_paper/benchmark/smallwood/logs/00.download/dl.%a.err

# Re-download the 51 Smallwood 2014 scBS-seq cells from ENA.
#
# The original fastq were lost when b1042 scratch was restored on 2026-10-26 --
# 01.fastq/ and fastq/ are empty and only the Bismark reports in 04.align_hg38/
# survive. codes/download_list.tsv was rebuilt from the ENA filereport API
# (accession, fastq_ftp, fastq_md5) against acc_list.txt.
#
# 01.qc_trim.sh reads PLAIN .fastq, not .gz, so each file is gunzipped after its
# md5 is checked against ENA's.

source /home/jmj7858/.bashrc
set -eo pipefail

BASE="/gpfs/projects/b1042/epifluidlab/yoshii/scnomehic_paper/benchmark/smallwood"
OUT="${BASE}/01.fastq"
LIST="${BASE}/codes/download_list.tsv"
mkdir -p "${OUT}" "${BASE}/logs/00.download"

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
    gz="${OUT}/${acc}_${i}.fastq.gz"
    plain="${OUT}/${acc}_${i}.fastq"

    # resume: a non-empty plain fastq means this mate is already done
    if [ -s "${plain}" ]; then
        echo "  [skip] ${acc}_${i}.fastq already present ($(stat -c%s "${plain}") bytes)"
        i=$((i+1)); continue
    fi

    echo "  [get ] https://${url}"
    wget -c --tries=30 --waitretry=60 --random-wait --retry-connrefused --read-timeout=120 --timeout=60 -O "${gz}" "https://${url}"

    got=$(md5sum "${gz}" | cut -d' ' -f1)
    if [ "${got}" != "${want}" ]; then
        echo "  ERROR md5 mismatch for ${acc}_${i}: got ${got} want ${want}" >&2
        exit 1
    fi
    echo "  [md5 ] ok ${got}"

    gunzip -f "${gz}"
    echo "  [gunzip] ${plain} ($(stat -c%s "${plain}") bytes)"
    i=$((i+1))
done

echo "[$(date)] DONE ${acc}"
