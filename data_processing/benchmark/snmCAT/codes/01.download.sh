#!/bin/bash
#SBATCH -A b1042
#SBATCH -p genomics
#SBATCH -t 04:00:00
#SBATCH -N 1
#SBATCH --mem=4G
#SBATCH --cpus-per-task=2
#SBATCH --array=1-100%10
#SBATCH --job-name=dl_brain
#SBATCH --output=/gpfs/projects/b1042/epifluidlab/yoshii/scnomehic_paper/benchmark/snmCAT/codes/logs/01.download/dl.%a.txt
#SBATCH --error=/gpfs/projects/b1042/epifluidlab/yoshii/scnomehic_paper/benchmark/snmCAT/codes/logs/01.download/dl.%a.err

# Download 100 cells from 190321_mCTseq_hs_29yr (UMB5580) = snmC2T-seq (NOMe) batch.
source /home/jmj7858/.bashrc
BASE="/gpfs/projects/b1042/epifluidlab/yoshii/scnomehic_paper/benchmark/snmCAT"
outfolder="${BASE}/fastq_brain"
listfile="${BASE}/codes/download_list_brain.txt"
mkdir -p "${outfolder}" "${BASE}/codes/logs/01.download"

# ENA refuses connections when many array tasks hit it at once, and wget does
# NOT retry a refused connection without --retry-connrefused. Stagger the start
# and retry patiently rather than failing the task.
sleep $(( (RANDOM % 90) + (SLURM_ARRAY_TASK_ID % 20) * 3 ))

line=$(sed -n "${SLURM_ARRAY_TASK_ID}p" "${listfile}")
echo "Task ${SLURM_ARRAY_TASK_ID}: ${line}"
# Verify every file with `gzip -t` and refetch once if it is corrupt. Two cells
# (SRR10471420, SRR10471456) downloaded at full size but with a CRC error and
# only surfaced hours later, when yap's trim_r1/cutadapt step failed on them.
# A truncated or corrupt .gz must fail here, not in the middle of mapping.
echo "${line}" | tr ';' '\n' | while read url; do
    [ -z "${url}" ] && continue
    f="${outfolder}/$(basename "${url}")"
    echo "Downloading https://${url}"
    wget -c --tries=30 --waitretry=60 --random-wait --retry-connrefused --read-timeout=120 --timeout=60 -O "${f}" "https://${url}"
    if ! gzip -t "${f}" 2>/dev/null; then
        echo "  WARN ${f} failed gzip -t; refetching from scratch"
        wget --tries=30 --waitretry=60 --random-wait --retry-connrefused --read-timeout=120 --timeout=60 -O "${f}" "https://${url}"
        gzip -t "${f}" || { echo "  ERROR ${f} still corrupt after refetch" >&2; exit 1; }
    fi
    echo "  [gzip ok] ${f} ($(stat -c%s "${f}") bytes)"
done
echo "Download Done for task ${SLURM_ARRAY_TASK_ID}"
