#!/bin/bash
# ============================================================================
# config.sh — scNOMe-HiC (Hi-C part) vs sci-Hi-C GM12878 SCC comparison
# ============================================================================
# Compare the Hi-C part of the GM12878 scNOMe-HiC pseudobulk to an external
# GM12878 single-cell Hi-C (sci-Hi-C) pseudobulk via HiCRep SCC @ 2.5 Mb,
# mirroring sc_nomehic_cellline/gm_sc_new/hic_comparison (bulk comparison).
#
# scHiC source: Kim et al. 2020 (PLoS Comp Biol) sci-Hi-C, GM12878+IMR90 library
#   "GM12878-IMR90.R1", processed per-cell 500 kb matrices + cell-type labels from
#   https://noble.gs.washington.edu/proj/schic-topic-model/ (open download, hg19).
#   We keep ONLY the 489 GM12878-labeled cells, pool raw counts, liftOver hg19->hg38,
#   re-bin at 2.5 Mb, and SCC against the scNOMe-HiC pseudobulk (hg38).
# ----------------------------------------------------------------------------
# --- repo paths: edit paths.yaml at the repository root, not this file -------
_r="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]:-$0}")")" && pwd)"
while [ "$_r" != "/" ] && [ ! -f "$_r/paths.sh" ]; do _r="$(dirname "$_r")"; done
source "$_r/paths.sh"

export ROOT=${WORK_ROOT}/analysis/s2_new/schic_gm12878
export CODE=$ROOT/code
export DATA=$ROOT/data
export WORK=$ROOT/work
export FIG=$ROOT/figures
export LOGS=$ROOT/logs

# ---- sci-Hi-C processed inputs (Kim 2020, hg19) ----------------------------
export LIB=GM12878-IMR90.R1
export SCHIC_TAR=$DATA/${LIB}.tar.gz
export SCHIC_LABELS=$DATA/${LIB}.labeled
export SCHIC_CELLTYPE=GM12878          # label to keep
export SCHIC_RES=500000                # native bin size of the matrices (hg19)

# ---- liftOver hg19 -> hg38 -------------------------------------------------
export CHAIN=$DATA/hg19ToHg38.over.chain.gz
export HG19_SIZES=$DATA/hg19.chrom.sizes

# ---- scNOMe-HiC pseudobulk reference (hg38) --------------------------------
export NOMEHIC_HIC=${WORK_ROOT}/gm12878_cellline/hic_comparison/gm_pseudobulk.dedup.mapQ30.hic

# ---- SCC settings (match the existing bulk comparison) ---------------------
export BIN=2500000                     # default/primary SCC resolution (hg38)
# Multi-resolution series (matches gm_sc_new/hic_comparison gm_scc_*_by_resolution).
# Only aggregations of the 500 kb sci-Hi-C source are possible: 500kb, 1Mb, 2.5Mb.
# (250 kb is NOT achievable from the 500 kb processed matrices — needs read-level data.)
export RESLIST="500000 1000000 2500000"
export HICREP_H=3
export IS_LOG=False
export PCTS="95 99 100"                # percentile clip caps (boxplot x-axis)

# ---- tools -----------------------------------------------------------------
export JUICER=${SOFTWARE_ROOT}/juicer/juicer_tools.jar
export CONDA=${SOFTWARE_ROOT}/conda
export ENV=scnomehic                   # hicrep + cooler 0.10.3 + liftOver + java
export PY=$CONDA/envs/$ENV/bin/python
export LIFTOVER=$CONDA/envs/$ENV/bin/liftOver

# ---- SLURM -----------------------------------------------------------------
export SLURM_ACCOUNT=b1042
export SLURM_PARTITION=genomics

activate_env () {
    local had_u=""; case $- in *u*) had_u=1;; esac
    set +u
    source "$CONDA/etc/profile.d/conda.sh"
    conda activate "$ENV" || echo "WARN: env $ENV not found" >&2
    [ -n "$had_u" ] && set -u
    return 0
}
