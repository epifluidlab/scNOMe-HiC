#!/bin/bash
# ============================================================================
# 02_extract.sh — extract whitelisted reads, write the barcode into the read
# header. Note the read roles are swapped for umi_tools: R2 carries the barcode
# so it is --stdin, and R1 rides along as --read2-in.
# ============================================================================
#SBATCH --job-name=scwgbs_02_extract
#SBATCH --account=b1042
#SBATCH --partition=genomics
#SBATCH --time=08:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G
#SBATCH --output=code/logs/02_extract_%j.out
#SBATCH --error=code/logs/02_extract_%j.err
set -euo pipefail
cd "${SLURM_SUBMIT_DIR:-$(dirname "$0")/..}"
source code/config.sh
activate_env
mkdir -p "$D02"

# --error-correct-cell corrects barcodes to the whitelist within edit distance 1.
echo "[$(date '+%F %T')] umi_tools extract (barcode -> header, filter to whitelist)"
umi_tools extract \
    --stdin "$R2" \
    --extract-method=regex \
    --bc-pattern="$BC_PATTERN" \
    --error-correct-cell \
    --whitelist="$D01/whitelist.txt" \
    --filter-cell-barcode \
    --read2-in "$R1" \
    --stdout "$D02/${SAMPLE}_R2.extracted.fastq.gz" \
    --read2-out "$D02/${SAMPLE}_R1.extracted.fastq.gz" \
    --log2stderr

echo "[$(date '+%F %T')] extracted R1: $D02/${SAMPLE}_R1.extracted.fastq.gz"
echo "[$(date '+%F %T')] extracted R2: $D02/${SAMPLE}_R2.extracted.fastq.gz"
