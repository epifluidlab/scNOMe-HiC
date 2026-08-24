#!/bin/bash
# ============================================================================
# download.sh — download the pure-GM12878 sci-MET run SRR6398696 from ENA.
#   Paper: Mulqueen et al. 2018 sci-MET (Nat Biotechnol, nbt.4112)
#   SRX3491863 "sci-MET LAND GM12878"; GSE112554 / SRP127273 / PRJNA397747.
#   No processed pure-GM12878 methylation was deposited (only the mixed
#   HumanCellLineSplit bed), so we process the raw FASTQ ourselves.
# PAIRED, 378.7M read pairs, ~38 GB (R1 14.3 GB + R2 23.6 GB).
# Run:  sbatch code/scmet/download.sh   (from the s2_new project root)
# ============================================================================
#SBATCH --job-name=dl_sciMET
#SBATCH --account=b1042
#SBATCH --partition=genomics
#SBATCH --time=8:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=2
#SBATCH --mem=4G
#SBATCH --output=code/scmet/logs/dl_sciMET_%j.out
#SBATCH --error=code/scmet/logs/dl_sciMET_%j.err
set -euo pipefail
cd "${SLURM_SUBMIT_DIR:-$(dirname "$0")/../..}"

DEST="data/scMET"
mkdir -p "$DEST" code/scmet/logs

URL_R1="https://ftp.sra.ebi.ac.uk/vol1/fastq/SRR639/006/SRR6398696/SRR6398696_1.fastq.gz"
URL_R2="https://ftp.sra.ebi.ac.uk/vol1/fastq/SRR639/006/SRR6398696/SRR6398696_2.fastq.gz"
MD5_R1="02c4406c140f67507c4970b3d7cc89cf"
MD5_R2="f9bf7c49bba4f97e95011fbd3f016ab2"
OUT_R1="$DEST/GM12878_sciMET_R1.fastq.gz"
OUT_R2="$DEST/GM12878_sciMET_R2.fastq.gz"

download () {
    local url="$1" out="$2" attempt
    for attempt in 1 2 3 4 5 6; do
        echo "[$(date '+%F %T')] Downloading $url -> $out (attempt $attempt)"
        if wget -c --tries=10 --timeout=60 -O "$out" "$url"; then return 0; fi
        echo "[$(date '+%F %T')] attempt $attempt failed; retry in 60s"; sleep 60
    done
    echo "ERROR: failed to download $url" >&2; return 1
}
verify () {
    local out="$1" want="$2" got
    got=$(md5sum "$out" | awk '{print $1}')
    [[ "$got" == "$want" ]] && echo "[$(date '+%F %T')] OK  $out  $got" \
        || { echo "MD5 MISMATCH $out: got $got want $want" >&2; exit 1; }
}

download "$URL_R1" "$OUT_R1"
download "$URL_R2" "$OUT_R2"
verify "$OUT_R1" "$MD5_R1"
verify "$OUT_R2" "$MD5_R2"
echo "[$(date '+%F %T')] sci-MET GM12878 download complete + verified"
ls -lh "$DEST"
