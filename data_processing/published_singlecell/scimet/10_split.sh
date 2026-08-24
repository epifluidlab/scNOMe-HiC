#!/bin/bash
# ============================================================================
# 10_split.sh — split the sci-MET genomic read (_2) into chunks for a bismark
# array. Pseudobulk (no demux): the tn5/i5 barcodes are not recoverable from
# the SRA deposit, so we align the genomic read directly and pool. _2 is the
# bisulfite genomic mate (low C, ~9% SE directional mapping).
# ============================================================================
#SBATCH --job-name=sciMET_10_split
#SBATCH --account=b1042
#SBATCH --partition=genomics
#SBATCH --time=8:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=8G
#SBATCH --output=code/scmet/logs/10_split_%j.out
#SBATCH --error=code/scmet/logs/10_split_%j.err
set -eu
cd "${SLURM_SUBMIT_DIR:-$(dirname "$0")/../..}"
source code/config.sh
activate_env

R2=data/scMET/raw/SRR6398696_2.fastq.gz     # genomic read
CHUNKDIR=work/scmet/chunks
mkdir -p "$CHUNKDIR"
# 12.6M reads/chunk (50,400,000 lines) -> ~60 chunks over 757M reads
echo "[$(date '+%F %T')] splitting $R2 into chunks"
zcat "$R2" | split -a3 -d -l 50400000 --filter='pigz -p2 -1 > ${FILE}.fq.gz' - "$CHUNKDIR/chunk"
n=$(ls "$CHUNKDIR"/chunk*.fq.gz | wc -l)
echo "[$(date '+%F %T')] $n chunks -> $CHUNKDIR"
ls "$CHUNKDIR"/chunk*.fq.gz | sed 's#.*/##' | sed 's/\.fq\.gz$//' > "$CHUNKDIR/chunk_list.txt"
