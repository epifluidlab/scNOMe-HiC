#!/bin/bash
# STEP 04 — Merge per-chr outputs to a per-celltype loop.bedpe.
# Runs `hicluster loop-mergechr` per celltype. < 5 min total.
# NOTE: drop -u because /etc/bashrc trips on BASHRCSOURCED with -u.
set -eo pipefail

# conda on PATH; override with SCNOMEHIC_CONDA_SH for a different install.
source "${SCNOMEHIC_CONDA_SH:-/projects/b1198/epifluidlab/yoshii/software/conda/etc/profile.d/conda.sh}"
conda activate hic_env

ROOT=/scratch/jmj7858/scnomehic/loop_majortype_25kb
PER_CT=$ROOT/per_celltype
CHROM_FILE=/gpfs/projects/b1198/epifluidlab/yoshii/reference/hg38/autosomes.chrom.sizes
RES=25000
MODE=pad2_std1_rp0.5_sqrtvc

for CT in GM12878 IMR90; do
    CT_DIR="$PER_CT/${CT}/${CT}"
    echo "=== merge $CT ==="

    hicluster loop-mergechr \
        --inprefix  "$CT_DIR/${CT}_${MODE}_dist_trim" \
        --outprefix "$CT_DIR/${CT}_${MODE}_dist_trim" \
        --chrom_file "$CHROM_FILE" \
        --res $RES

    # Convenience symlink so the notebook can use {CT}.loop.bedpe
    if [ -f "$CT_DIR/${CT}_${MODE}_dist_trim.loop.bedpe" ]; then
        ln -sf "${CT}_${MODE}_dist_trim.loop.bedpe" "$CT_DIR/${CT}.loop.bedpe"
        echo "  loops: $(wc -l < $CT_DIR/${CT}_${MODE}_dist_trim.loop.bedpe)"
    fi
done

echo "done"
ls -la "$PER_CT"/GM12878/GM12878/ | head
ls -la "$PER_CT"/IMR90/IMR90/ | head
