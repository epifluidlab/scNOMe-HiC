#!/bin/bash
# ============================================================================
# 04_demux_idemp.sh — split the trimmed reads into per-cell FASTQ files by the
# cell barcode in each read header (written by umi_tools). Reads carrying the
# same barcode go to the same file.
#
# NOTE: idemp (the tool named in the methods) segfaults at single-cell scale
# (~5000 barcodes), so we use a custom streaming splitter (_split_percell.py).
# umi_tools already error-corrected + whitelist-filtered the barcodes, making
# idemp's error-correction redundant — a plain split is equivalent and robust.
# ============================================================================
#SBATCH --job-name=scwgbs_04_demux
#SBATCH --account=b1042
#SBATCH --partition=genomics
#SBATCH --time=12:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=64G
#SBATCH --output=code/logs/04_demux_%j.out
#SBATCH --error=code/logs/04_demux_%j.err
set -euo pipefail
cd "${SLURM_SUBMIT_DIR:-$(dirname "$0")/..}"
source code/config.sh
activate_env
mkdir -p "$D04/percell"

# raise the open-file limit so all per-cell handles can stay open (best effort)
ulimit -n 20000 2>/dev/null || true

VAL1=$(ls "$D03"/*_val_1.fq.gz)   # trimmed R1
VAL2=$(ls "$D03"/*_val_2.fq.gz)   # trimmed R2

echo "[$(date '+%F %T')] splitting into per-cell FASTQs (fd limit: $(ulimit -n))"
python code/_split_percell.py \
    --r1 "$VAL1" \
    --r2 "$VAL2" \
    --whitelist "$D01/whitelist.txt" \
    --outdir "$D04/percell" \
    --cap 12000

# canonical cell list (barcode per line) for the per-cell array steps
cut -f1 "$D01/whitelist.txt" > "$CELL_LIST"
echo "[$(date '+%F %T')] per-cell FASTQs: $(ls "$D04"/percell/*_R1.fastq.gz 2>/dev/null | wc -l) cells ; list: $CELL_LIST"
