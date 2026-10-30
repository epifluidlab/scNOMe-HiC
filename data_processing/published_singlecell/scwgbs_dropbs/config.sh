#!/bin/bash
# ============================================================================
# config.sh — shared configuration for the scWGBS pipeline (sourced by all steps)
# ============================================================================
# Pipeline: barcode extraction -> demux -> trim -> per-cell align (Bismark) ->
#           QC -> merge/dedup -> methylation calling -> allc construction.
# Scope: stops at per-cell allc files (feature matrix / clustering are separate,
#        done later together with the scNOMeHiC comparison + GCG removal).
# ----------------------------------------------------------------------------

# ---- project layout --------------------------------------------------------
# --- repo paths: edit paths.yaml at the repository root, not this file -------
# SLURM copies a batch script to /var/spool/slurmd/<job>/slurm_script, so walking
# up from BASH_SOURCE cannot reach the repository. $SCNOMEHIC_REPO is tried first;
# submit with: sbatch --export=ALL,SCNOMEHIC_REPO=/path/to/repo
_r="${SCNOMEHIC_REPO:-}"
if [ -z "$_r" ] || [ ! -f "$_r/paths.sh" ]; then
    _r="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]:-$0}")")" && pwd)"
    while [ "$_r" != "/" ] && [ ! -f "$_r/paths.sh" ]; do _r="$(dirname "$_r")"; done
fi
[ -f "$_r/paths.sh" ] || { echo "ERROR: paths.sh not found. Set SCNOMEHIC_REPO to the repository root." >&2; exit 1; }
source "$_r/paths.sh"

export PROJ=${WORK_ROOT}/analysis/s2_new
export CODE=$PROJ/code
export DATA=$PROJ/data/scWGBS
export WORK=$PROJ/work            # all intermediate outputs live here
export LOGS=$CODE/logs

# ---- input FASTQ (from code/download.sh) -----------------------------------
export SAMPLE=GM12878
export R1=$DATA/${SAMPLE}_R1.fastq.gz     # genomic read 1 (PBAT strand)
export R2=$DATA/${SAMPLE}_R2.fastq.gz     # read 2: [24 bp constant][15 bp barcode][genomic]

# ---- reference genome (Bismark bowtie2-prepared dir = folder w/ Bisulfite_Genome)
# GM12878 is a human cell line -> hg38.
export GENOME_DIR=${REFERENCE_ROOT}/hg38_bismark
export GENOME_FA=$GENOME_DIR/GCA_000001405.15_GRCh38_no_alt_analysis_set.fa

# ---- barcode design (from the methods) -------------------------------------
# R2, 5'->3': bases 1-24 = constant, bases 25-39 = 15 bp cell barcode, no UMI.
export BC_CONST=TAAGTAGAAGATGGTATATGAGAT
export BC_PATTERN='(?P<discard_1>TAAGTAGAAGATGGTATATGAGAT){s<=4}(?P<cell_1>.{15})(?P<umi_1>.{0})'
export N_CELLS=5000               # umi_tools whitelist --set-cell-number

# ---- trimming (Trim Galore) ------------------------------------------------
export CLIP_R1=15
export CLIP_R2=40

# ---- per-cell QC thresholds (tunable; methods only say "lower ..." ) --------
export MIN_MAP_EFF=10             # min Bismark mapping efficiency, percent
export MIN_READS=10000            # min raw reads per cell

# ---- conda environment -----------------------------------------------------
export CONDA=${SOFTWARE_ROOT}/conda
export ENV=scwgbs                 # python tools (created by 00_setup_env.sh)
export ENV_R=scwgbs_r             # R/methylKit only (step 08)
export IDEMP=$CONDA/envs/$ENV/bin/idemp

# ---- SLURM defaults --------------------------------------------------------
export SLURM_ACCOUNT=b1042
export SLURM_PARTITION=genomics
export THREADS=8

# ---- per-step work dirs ----------------------------------------------------
export D01=$WORK/01_whitelist
export D02=$WORK/02_extract
export D03=$WORK/03_trim
export D04=$WORK/04_demux
export D05=$WORK/05_align
export D06=$WORK/06_qc
export D07=$WORK/07_merge_dedup
export D08=$WORK/08_methylation
export D09=$WORK/09_allc
export D10=$WORK/10_allc_noGCG         # allc with GCG cytosines removed (NOMe match)
export D11=$WORK/11_bins_hcg250kb      # per-cell 250kb HCG bin sums
export D12=$WORK/12_compare_nomehic    # WGBS pseudobulk 250kb + NOMe-HiC comparison
export CELL_LIST=$WORK/cell_list.txt   # one cell barcode per line (built after step 04)

# NOMe-HiC pseudobulk reference (GM12878 sc NOMe-HiC, hg38).
# Use the variant-aware merged-BAM pseudobulk in pseudobulk_methylation/ (BisSNP,
# same caller as the sc pipeline) — per-site HCG 6plus2; we bin it ourselves.
export NOMEHIC_DIR=${WORK_ROOT}/gm12878_cellline
export NOMEHIC_HCG_6PLUS2=$NOMEHIC_DIR/pseudobulk_methylation/gm_pseudobulk_merged.HCG.6plus2.bed.gz
export NOMEHIC_HCG_250KB=$D12/nomehic_pseudobulk_HCG_250kb.bed   # binned from 6plus2 by 14_bin_nomehic_250kb.py
export BIN=250000

# activate a pipeline env (default = $ENV python tools; pass $ENV_R for methylKit)
# conda's binutils activation scripts reference unbound vars (e.g. ADDR2LINE),
# which crash under `set -u`; disable nounset across activation, then restore it.
activate_env () {
    local e=${1:-$ENV}
    local had_u=""; case $- in *u*) had_u=1;; esac
    set +u
    source "$CONDA/etc/profile.d/conda.sh"
    conda activate "$e" || echo "WARN: conda env '$e' not found (run 00_setup_env.sh)" >&2
    [ -n "$had_u" ] && set -u
    return 0
}
