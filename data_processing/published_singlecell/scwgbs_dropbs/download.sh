#!/bin/bash
#SBATCH --job-name=dl_scWGBS
#SBATCH --account=b1042
#SBATCH --partition=genomics
#SBATCH --time=4:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=2
#SBATCH --mem=4G
#SBATCH --output=code/logs/dl_scWGBS_%j.out
#SBATCH --error=code/logs/dl_scWGBS_%j.err

# Download GM12878 scWGBS FASTQ (SRR19391270) from the ENA free mirror.
#
# Source: the SRA record lists original-submitted files on
#   s3://sra-pub-src-14/SRR19391270/GM12878_R{1,2}.fastq.gz.1
# but that bucket is Requester-Pays (needs a paid AWS account). ENA mirrors the
# same run's FASTQ over free HTTPS, so we pull it from there instead.
#
# The two files are renamed to GM12878_R1/R2 to match the original sample name.
#
# Run standalone:  bash code/download.sh
# Or on SLURM:     sbatch code/download.sh   (run from the s2_new project root)

set -euo pipefail

DEST="data/scWGBS"
mkdir -p "$DEST" code/logs

# ENA HTTPS endpoints for run SRR19391270
URL_R1="https://ftp.sra.ebi.ac.uk/vol1/fastq/SRR193/070/SRR19391270/SRR19391270_1.fastq.gz"
URL_R2="https://ftp.sra.ebi.ac.uk/vol1/fastq/SRR193/070/SRR19391270/SRR19391270_2.fastq.gz"

# Expected MD5s from the ENA filereport API
MD5_R1="196300e59859410e2b1b8def916ec5fb"
MD5_R2="9d25cacd299c0b52b19efce0e4283ef2"

OUT_R1="$DEST/GM12878_R1.fastq.gz"
OUT_R2="$DEST/GM12878_R2.fastq.gz"

download () {
    local url="$1" out="$2" attempt
    # ENA occasionally returns a transient 403 that wget treats as fatal, so
    # wrap the whole download in a retry loop. -c resumes any partial file.
    for attempt in 1 2 3 4 5 6; do
        echo "[$(date '+%F %T')] Downloading $url -> $out (attempt $attempt)"
        if wget -c --tries=10 --timeout=60 -O "$out" "$url"; then
            return 0
        fi
        echo "[$(date '+%F %T')] attempt $attempt failed; retrying in 60s"
        sleep 60
    done
    echo "ERROR: failed to download $url after retries" >&2
    return 1
}

verify () {
    local out="$1" want="$2"
    echo "[$(date '+%F %T')] Verifying MD5 of $out"
    local got
    got=$(md5sum "$out" | awk '{print $1}')
    if [[ "$got" != "$want" ]]; then
        echo "MD5 MISMATCH for $out: got $got, expected $want" >&2
        exit 1
    fi
    echo "[$(date '+%F %T')] OK  $out  $got"
}

download "$URL_R1" "$OUT_R1"
download "$URL_R2" "$OUT_R2"

verify "$OUT_R1" "$MD5_R1"
verify "$OUT_R2" "$MD5_R2"

echo "[$(date '+%F %T')] All downloads complete and verified."
ls -lh "$DEST"
