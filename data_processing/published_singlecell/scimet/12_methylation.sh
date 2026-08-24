#!/bin/bash
# ============================================================================
# 12_methylation.sh — merge chunk bams, extract methylation, and collapse CpG
# to one strand with coverage2cytosine --merge_CpG (as the paper does).
# Output: per-CpG coverage (chr,pos,pos,%meth,countM,countU).
# ============================================================================
#SBATCH --job-name=sciMET_12_meth
#SBATCH --account=b1042
#SBATCH --partition=genomics
#SBATCH --time=24:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=48G
#SBATCH --output=code/scmet/logs/12_meth_%j.out
#SBATCH --error=code/scmet/logs/12_meth_%j.err
set -eu
cd "${SLURM_SUBMIT_DIR:-$(dirname "$0")/../..}"
source code/config.sh
activate_env

ALIGN=work/scmet/align
METH=work/scmet/methylation
mkdir -p "$METH"

echo "[$(date '+%F %T')] merging chunk bams"
find "$ALIGN" -name "chunk*.bam" | sort > "$METH/bam_list.txt"
echo "  $(wc -l < "$METH/bam_list.txt") bams"
samtools cat -b "$METH/bam_list.txt" -o "$METH/sciMET_merged.bam"

echo "[$(date '+%F %T')] bismark_methylation_extractor (SE, genome-wide CX coverage)"
bismark_methylation_extractor -s --comprehensive --bedGraph --CX \
    --genome_folder "$GENOME_DIR" --multicore 4 -o "$METH" "$METH/sciMET_merged.bam"

COV=$(ls "$METH"/sciMET_merged.bismark.cov.gz | head -1)
echo "[$(date '+%F %T')] coverage2cytosine --merge_CpG"
coverage2cytosine --merge_CpG --genome_folder "$GENOME_DIR" \
    --dir "$METH" -o sciMET_CpG "$COV"

echo "[$(date '+%F %T')] outputs:"; ls -lh "$METH"/sciMET_CpG* 2>/dev/null
