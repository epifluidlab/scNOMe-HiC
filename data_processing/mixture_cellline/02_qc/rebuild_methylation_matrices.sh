#!/bin/bash
#SBATCH -A b1042
#SBATCH -p genomics
#SBATCH -t 04:00:00
#SBATCH -N 1
#SBATCH --mem=64G
#SBATCH --cpus-per-task=4
#SBATCH --job-name=meth_matrix
#SBATCH --output=logs/rebuild_methylation_matrices.%j.out
#SBATCH --error=logs/rebuild_methylation_matrices.%j.err
# ─────────────────────────────────────────────────────────────────────────────
# Build the cells x bins methylation matrices that the Figure 2 UMAP notebook
# reads. For each context (HCG, GCH) and each bin size requested, writes:
#
#   QC/methylation_matrices/methylation_matrix_{context}_{bin}.tsv.gz
#   QC/methylation_matrices/bins_{bin}.tsv
#
# Inputs are the per-cell tables in 08.methylation_snakemake/, restricted to the
# QC-passing cells in QC/cellline_passed.txt — so run this AFTER
# 02_qc/qc_plots.ipynb.
#
# Consumed by main_figures/fig2/fig2_umap.ipynb, which reads the 250 kb pair
# (together with the Hi-C embedding from 01_pipeline/02_hicluster.sh).
#
# Submit from the dataset workdir (the SBATCH log paths are relative to it):
#   sbatch rebuild_methylation_matrices.sh            # 250kb  (what the UMAP needs)
#   sbatch rebuild_methylation_matrices.sh 250kb 100kb
#
# The original run also built 100 kb, for the companion subset_clustering/100kb
# analysis that is not part of this repository.
# ─────────────────────────────────────────────────────────────────────────────
set -eo pipefail
source /projects/b1198/epifluidlab/yoshii/software/conda/etc/profile.d/conda.sh
conda activate scnomehic
set -u

WORK=/gpfs/projects/b1198/epifluidlab/yoshii/sc_nomehic_cellline/snakemake
cd "$WORK"; mkdir -p logs

if [ "$#" -gt 0 ]; then BINS=("$@"); else BINS=(250kb); fi

echo "=== $(date) | host $(hostname) ==="
echo "    workdir : $WORK"
echo "    bins    : ${BINS[*]}"

python "$(dirname "$(readlink -f "$0")")/rebuild_methylation_matrices.py" "${BINS[@]}"

echo "=== done $(date) ==="
