#!/bin/bash
# 00_config.sh — shared paths/params for the saturation analysis.
# CODE_DIR resolves to this folder, so the scripts find each other wherever
# the folder is placed.
# Sourced by every script. All paths verified to exist 2026-06-28.

# ---- code + scratch layout ----
export CODE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export SCRATCH_DIR=/gpfs/projects/b1042/epifluidlab/yoshii/scnomehic_paper/s7
export WORK_DIR=${SCRATCH_DIR}/work        # per-task scratch BAMs (deleted after each task)
export RESULTS_DIR=${SCRATCH_DIR}/results  # one tiny .tsv per (cell,fraction)
export LOG_DIR=${SCRATCH_DIR}/logs         # slurm stdout/stderr

# ---- input data (gm_sc_new) ----
export GM=/gpfs/projects/b1198/epifluidlab/yoshii/sc_nomehic_cellline/gm_sc_new
export RAW_BAM_DIR=${GM}/04.alignment_snakemake                 # {cell}.bam = pre-markdup mapped reads
export METHYL_DIR=${GM}/07.bistools_snakemake/methylation       # existing full-depth 6plus2 beds (f=1.0)
export CELLS_FILE=${GM}/QC/cellline_passed.txt                  # 180 QC-passing cells

# ---- reference / tools (from sc_NOMeHiC_pipeline config.yaml) ----
export REFERENCE=/gpfs/projects/b1198/epifluidlab/yoshii/reference/hg38/GCA_000001405.15_GRCh38_no_alt_analysis_set
export VARIANTS=/gpfs/projects/b1198/epifluidlab/yoshii/reference/hg38/Homo_sapiens_assembly38.dbsnp138.vcf
export BISTOOLS=/gpfs/projects/b1198/epifluidlab/yoshii/software/Bis-tools
export BISSNP_JAR=${BISTOOLS}/Bis-SNP/Bis-SNP.latest.jar
export BISSNP_USAGE=${BISTOOLS}/Bis-SNP/bissnp_nomehic_usage.pl
export BISULFITEHIC=/gpfs/projects/b1198/epifluidlab/yoshii/software/bisulfiteHic
export MH_SUMMARY=${BISULFITEHIC}/src/python/mh_reads_summary.v2.py
export CONDA_BIN=/gpfs/projects/b1198/epifluidlab/yoshii/software/conda/envs/scnomehic/bin

# ---- saturation parameters ----
export SEED=42                                  # fixed -> samtools -s subsamples are NESTED across fractions
export FRACTIONS="0.05 0.1 0.2 0.4 0.6 0.8"     # f=1.0 taken from existing pipeline outputs (no job)
export JAVA8_MODULE=java/jdk1.8.0_191           # Bis-SNP needs Java 8
export BISSNP_MEM_GB=56                          # of the 64G requested

# put scnomehic env (samtools 1.21, bedtools, python) first on PATH
export PATH=${CONDA_BIN}:$PATH
