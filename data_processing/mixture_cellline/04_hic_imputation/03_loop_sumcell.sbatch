#!/bin/bash
#SBATCH --account=b1042
#SBATCH --partition=genomics
#SBATCH --job-name=lm25_step03_loop_sumcell
#SBATCH --time=04:00:00
#SBATCH --mem=24G
#SBATCH --cpus-per-task=1
#SBATCH --output=/gpfs/projects/b1198/epifluidlab/yoshii/sc_nomehic_cellline/snakemake/loop_majortype_25kb/logs/%x_%A_%a.out
#SBATCH --error=/gpfs/projects/b1198/epifluidlab/yoshii/sc_nomehic_cellline/snakemake/loop_majortype_25kb/logs/%x_%A_%a.err
#SBATCH --array=0-43
# STEP 03 — Per (celltype, chr) SLURM array, calling hicluster loop-sumcell-chr.
#
# Array index = celltype_index * 22 + chr_index   (celltype_index 0=GM, 1=IMR; chr_index 0..21)
# 0..21  = GM12878 chr1..chr22
# 22..43 = IMR90   chr1..chr22
# NOTE: NOT using `set -u` because the system /etc/bashrc references BASHRCSOURCED
# unbound; -u would trip on `source ~/.bashrc`.
set -eo pipefail

source /home/jmj7858/.bashrc
conda activate hic_env

THIS_DIR=/gpfs/projects/b1198/epifluidlab/yoshii/sc_nomehic_cellline/snakemake/loop_majortype_25kb
CELL_TABLE=$THIS_DIR/cell_table.tsv
ROOT=/scratch/jmj7858/scnomehic/loop_majortype_25kb
IMP_DIR=$ROOT/hicluster_impute
PER_CT=$ROOT/per_celltype
RES=25000
MODE=pad2_std1_rp0.5_sqrtvc

CELLTYPES=(GM12878 IMR90)
IDX=$SLURM_ARRAY_TASK_ID
CT_IDX=$((IDX / 22))
CHR_IDX=$((IDX % 22))
CT=${CELLTYPES[$CT_IDX]}
CHR=$((CHR_IDX + 1))
CHROM="chr${CHR}"

CT_DIR="$PER_CT/${CT}/${CT}"
FILELIST_DIR="$ROOT/filelist"
mkdir -p "$CT_DIR" "$FILELIST_DIR"

LIST="$FILELIST_DIR/${CT}_${MODE}_${CHROM}_looplist.txt"

# Build the cell-prefix file list for this (celltype, chr)
awk -v CT="$CT" -v C="$CHR" -v M="$MODE" -v D="$IMP_DIR" '
    NR==1{next}
    $2==CT {
        printf("%s/chr%d/%s_chr%d_%s\n", D, C, $1, C, M)
    }
' "$CELL_TABLE" > "$LIST"

n_lines=$(wc -l < "$LIST")
echo "[$(date +%H:%M:%S)] $CT $CHROM : $n_lines cells in list"

hicluster loop-sumcell-chr \
    --cell_list "$LIST" \
    --outprefix "$CT_DIR/${CT}_${MODE}_dist_trim_${CHROM}" \
    --res $RES

echo "[$(date +%H:%M:%S)] done $CT $CHROM"
# `... | head -5` causes SIGPIPE on upstream commands and `set -eo pipefail`
# would mark the task FAILED even though loop-sumcell-chr succeeded.
# Use `| { head -5; cat >/dev/null; }` so head fully drains the pipe.
ls -la "$CT_DIR/" | grep "$CHROM" | { head -5; cat >/dev/null; }
