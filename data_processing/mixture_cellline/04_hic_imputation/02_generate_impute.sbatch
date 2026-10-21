#!/bin/bash
#SBATCH --account=b1042
#SBATCH --partition=genomics
#SBATCH --job-name=lm25_step02_gen_impute
#SBATCH --time=02:00:00
#SBATCH --mem=12G
#SBATCH --cpus-per-task=1
#SBATCH --output=/gpfs/projects/b1198/epifluidlab/yoshii/sc_nomehic_cellline/snakemake/loop_majortype_25kb/logs/%x_%A_%a.out
#SBATCH --error=/gpfs/projects/b1198/epifluidlab/yoshii/sc_nomehic_cellline/snakemake/loop_majortype_25kb/logs/%x_%A_%a.err
#SBATCH --array=1-441
# STEP 02 — Per-cell SLURM array.  For one cell at index $SLURM_ARRAY_TASK_ID:
#   1. hicluster generatematrix-cell (all chrs at once, outputs to chr{N}/ subdirs)
#   2. for each chr 1..22, hicluster impute-cell (writes chr{N}/{cell}_..._pad2_std1_rp0.5_sqrtvc.hdf5)
#
# array index 1 -> first non-header line of cell_table.tsv, ..., 441 -> 441st cell
# NOTE: NOT using `set -u` because the system /etc/bashrc references the
# BASHRCSOURCED variable expecting it to possibly be unset; -u would trigger
# an "unbound variable" error when `source ~/.bashrc` runs below.
set -eo pipefail

# conda on PATH; override with SCNOMEHIC_CONDA_SH for a different install.
source "${SCNOMEHIC_CONDA_SH:-/projects/b1198/epifluidlab/yoshii/software/conda/etc/profile.d/conda.sh}"
conda activate hic_env

THIS_DIR=/gpfs/projects/b1198/epifluidlab/yoshii/sc_nomehic_cellline/snakemake/loop_majortype_25kb
CELL_TABLE=$THIS_DIR/cell_table.tsv
SRC_HIC_DIR=/gpfs/projects/b1198/epifluidlab/yoshii/sc_nomehic_cellline/snakemake/06.hiccluster_snakemake
ROOT=/scratch/jmj7858/scnomehic/loop_majortype_25kb
RAW_OUT=$ROOT/hicluster_raw
IMP_OUT=$ROOT/hicluster_impute
CHROM_FILE=/gpfs/projects/b1198/epifluidlab/yoshii/reference/hg38/autosomes.chrom.sizes
RES=25000
MODE=pad2_std1_rp0.5_sqrtvc

mkdir -p "$RAW_OUT" "$IMP_OUT"

# Look up this task's cell ID (first non-header line is index 1)
IDX=$SLURM_ARRAY_TASK_ID
CELL=$(awk -v i="$IDX" 'NR>1 && (NR-1)==i {print $1; exit}' "$CELL_TABLE")
CELLTYPE=$(awk -v i="$IDX" 'NR>1 && (NR-1)==i {print $2; exit}' "$CELL_TABLE")

if [ -z "$CELL" ]; then
    echo "ERROR: no cell at index $IDX" >&2
    exit 1
fi

# Convert dot ID back to underscore for the snakemake naming convention
UNDERSCORE_ID="${CELL/./_}"
# Use .hic_matrix.txt.gz (tab-delim, 7 col) NOT .hic.txt.gz (space-delim, 16 col).
# The snakemake pipeline splits the two: hic.txt.gz keeps full reads for the
# 09_coordination methylation analyses, hic_matrix.txt.gz is the slim
# tab-delim pairs file that schicluster expects.
INFILE="$SRC_HIC_DIR/${UNDERSCORE_ID}.hic_matrix.txt.gz"
if [ ! -e "$INFILE" ]; then
    echo "SKIP: $INFILE missing" >&2
    exit 0
fi

cd "$ROOT"

echo "[$(date +%H:%M:%S)] cell $IDX/441 : $CELL ($CELLTYPE)"
echo "  infile: $INFILE"

# --- 1. generatematrix-cell: builds per-chr {cell}_chr{N}.npz under raw/chr{N}/ ---
echo "[$(date +%H:%M:%S)] generatematrix-cell ..."
hicluster generatematrix-cell \
    --infile "$INFILE" \
    --outdir "$RAW_OUT/" \
    --cell "$CELL" \
    --res $RES \
    --chrom_file "$CHROM_FILE" \
    --chr1 1 --pos1 2 --chr2 5 --pos2 6 --dist 2500

# --- 2. impute-cell + loop-bkg-cell, per chr ---
#
# Two phases per chr:
#   (a) impute-cell  -> {cell}_chr{N}_{mode}.hdf5     (Q matrix; slow)
#   (b) loop-bkg-cell -> {cell}_chr{N}_{mode}_dist_trim.{E,T,O}.npz  (background; fast)
#
# Both are needed by step03 (loop-sumcell-chr). Skips impute if the .hdf5
# already exists (so resubmits don't redo the slow impute step).
for c in $(seq 1 22); do
    chrom="chr${c}"
    indir="$RAW_OUT/${chrom}/"
    outdir="$IMP_OUT/${chrom}/"
    mkdir -p "$outdir"
    impute_out="$outdir/${CELL}_${chrom}_${MODE}.hdf5"

    if [ -e "$impute_out" ]; then
        echo "[$(date +%H:%M:%S)] impute-cell $chrom : skip (already exists)"
    else
        echo "[$(date +%H:%M:%S)] impute-cell $chrom ..."
        # NB: don't pass --logscale (hicluster's argparse rejects "--logscale False"
        # because the flag is store_true; default is False which is what we want).
        hicluster impute-cell \
            --indir "$indir" \
            --outdir "$outdir" \
            --cell "$CELL" \
            --chrom "$chrom" \
            --res $RES \
            --chrom_file "$CHROM_FILE" \
            --pad 2 --std 1 --rp 0.5 --tol 0.01 \
            --window_size 30000000 --step_size 10000000 --output_dist 10050000 \
            --output_format hdf5 --mode "$MODE"
    fi

    echo "[$(date +%H:%M:%S)] loop-bkg-cell $chrom ..."
    hicluster loop-bkg-cell \
        --indir "$IMP_OUT/" \
        --cell "$CELL" \
        --chrom "$chrom" \
        --res $RES \
        --impute_mode "$MODE"
done

echo "[$(date +%H:%M:%S)] done $CELL"
