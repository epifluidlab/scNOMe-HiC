#!/bin/bash
# ─────────────────────────────────────────────────────────────────────────────
# Call NOMe methylation (GCH accessibility + HCG CpG methylation) on the merged
# PSEUDOBULK BAM (gm_sc_new/04.alignment_snakemake/merged.sorted.bam = pool of all
# 180 single cells), using the SAME BisSNP caller as the sc_NOMeHiC pipeline's
# `bistools` rule. Parallelized BY CHROMOSOME via the wrapper's --interval option
# (the BAM is ~180x a single cell, so a single genome-wide job would be too slow).
#
# BisSNP/GATK excludes flag-marked duplicates by default, so pooled PCR duplicates
# (~56% of reads, marked but present) are NOT double-counted.
#
# Output per chr: pseudobulk_methylation/<chr>/gm_pseudobulk_merged.<chr>.cyt.filtered.sort.{GCH,HCG}.6plus2.bed.gz
# Submit:  sbatch 02_call_methylation_array.sh
# ─────────────────────────────────────────────────────────────────────────────
#SBATCH --job-name=psb_methyl
#SBATCH --account=b1042
#SBATCH --partition=genomicslong
#SBATCH --array=1-23
#SBATCH --nodes=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=56G
#SBATCH --time=48:00:00
#SBATCH --output=/gpfs/projects/b1198/epifluidlab/yoshii/sc_nomehic_cellline/gm_sc_new/pseudobulk_methylation/logs/psb_methyl_%A_%a.out
#SBATCH --error=/gpfs/projects/b1198/epifluidlab/yoshii/sc_nomehic_cellline/gm_sc_new/pseudobulk_methylation/logs/psb_methyl_%A_%a.err

set -eo pipefail
source /projects/b1198/epifluidlab/yoshii/software/conda/etc/profile.d/conda.sh
conda activate scnomehic   # samtools/perl/bedtools/tabix on PATH; BisSNP jar runs on its own java8

# --- references / tools (from sc_NOMeHiC_pipeline configs/config.yaml) ---
BAM=/gpfs/projects/b1198/epifluidlab/yoshii/sc_nomehic_cellline/gm_sc_new/04.alignment_snakemake/merged.sorted.bam
REF=/gpfs/projects/b1198/epifluidlab/yoshii/reference/hg38/GCA_000001405.15_GRCh38_no_alt_analysis_set
VCF=/gpfs/projects/b1198/epifluidlab/yoshii/reference/hg38/Homo_sapiens_assembly38.dbsnp138.vcf
BIS=/gpfs/projects/b1198/epifluidlab/yoshii/software/Bis-tools
JAR=${BIS}/Bis-SNP/Bis-SNP.latest.jar
OUTROOT=/gpfs/projects/b1198/epifluidlab/yoshii/sc_nomehic_cellline/gm_sc_new/pseudobulk_methylation

# --- pick this task's chromosome ---
CHROMS=(chr1 chr2 chr3 chr4 chr5 chr6 chr7 chr8 chr9 chr10 chr11 chr12 chr13 \
        chr14 chr15 chr16 chr17 chr18 chr19 chr20 chr21 chr22 chrX)
CHR=${CHROMS[$((SLURM_ARRAY_TASK_ID - 1))]}
PREFIX=gm_pseudobulk_merged.${CHR}
OUTDIR=${OUTROOT}/${CHR}
mkdir -p "${OUTDIR}"

# --- resume: skip if both 6plus2 BEDs already exist ---
if [[ -s "${OUTDIR}/${PREFIX}.cyt.filtered.sort.GCH.6plus2.bed.gz" \
   && -s "${OUTDIR}/${PREFIX}.cyt.filtered.sort.HCG.6plus2.bed.gz" ]]; then
    echo "[$(date)] ${CHR}: outputs exist, skipping"; exit 0
fi

echo "[$(date)] ${CHR}: BisSNP methylation on merged pseudobulk BAM (host $(hostname))"
BAM_ABS=$(readlink -f "${BAM}")

# bissnp_nomehic_usage.pl writes outputs named from --prefix in the CURRENT dir.
cd "${OUTDIR}"
perl "${BIS}/Bis-SNP/bissnp_nomehic_usage.pl" \
    --interval "${CHR}" --prefix "${PREFIX}" --mem 40 \
    "${JAR}" "${BAM_ABS}" "${REF}.fa" "${VCF}"

# gzip the big text outputs (~5x smaller), as the pipeline's bistools rule does
gzip -f *.6plus2.bed *.strand.6plus2.bed *.GCH.txt *.HCG.txt *.cpgSummary.txt 2>/dev/null || true

echo "[$(date)] ${CHR}: done -> ${OUTDIR}"
ls -la "${OUTDIR}"/*.6plus2.bed.gz 2>/dev/null || true
