#!/bin/bash
# 00_config.sh — shared paths/params for the saturation analysis.
# CODE_DIR resolves to this folder, so the scripts find each other wherever
# the folder is placed.
# Sourced by every script. All paths verified to exist 2026-06-28.

# ---- code + scratch layout ----
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

export CODE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export SCRATCH_DIR=${WORK_ROOT}/analysis/s7
export WORK_DIR=${SCRATCH_DIR}/work        # per-task scratch BAMs (deleted after each task)
export RESULTS_DIR=${SCRATCH_DIR}/results  # one tiny .tsv per (cell,fraction)
export LOG_DIR=${SCRATCH_DIR}/logs         # slurm stdout/stderr

# ---- input data (gm_sc_new) ----
export GM=${WORK_ROOT}/gm12878_cellline
export RAW_BAM_DIR=${GM}/04.alignment_snakemake                 # {cell}.bam = pre-markdup mapped reads
export METHYL_DIR=${GM}/07.bistools_snakemake/methylation       # existing full-depth 6plus2 beds (f=1.0)
export CELLS_FILE=${GM}/QC/cellline_passed.txt                  # 180 QC-passing cells

# ---- reference / tools (from sc_NOMeHiC_pipeline config.yaml) ----
export REFERENCE=${REFERENCE_ROOT}/hg38/GCA_000001405.15_GRCh38_no_alt_analysis_set
export VARIANTS=${REFERENCE_ROOT}/hg38/Homo_sapiens_assembly38.dbsnp138.vcf
export BISTOOLS=${SOFTWARE_ROOT}/Bis-tools
export BISSNP_JAR=${BISTOOLS}/Bis-SNP/Bis-SNP.latest.jar
export BISSNP_USAGE=${BISTOOLS}/Bis-SNP/bissnp_nomehic_usage.pl
export BISULFITEHIC=${SOFTWARE_ROOT}/bisulfiteHic
export MH_SUMMARY=${BISULFITEHIC}/src/python/mh_reads_summary.v2.py
export CONDA_BIN=${CONDA_ENVS}/scnomehic/bin

# ---- saturation parameters ----
export SEED=42                                  # fixed -> samtools -s subsamples are NESTED across fractions
export FRACTIONS="0.05 0.1 0.2 0.4 0.6 0.8"     # f=1.0 taken from existing pipeline outputs (no job)
export JAVA8_MODULE=java/jdk1.8.0_191           # Bis-SNP needs Java 8
export BISSNP_MEM_GB=56                          # of the 64G requested

# put scnomehic env (samtools 1.21, bedtools, python) first on PATH
export PATH=${CONDA_BIN}:$PATH
