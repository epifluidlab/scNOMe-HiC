#!/bin/bash
#SBATCH -A b1042
#SBATCH -p genomics
#SBATCH -t 24:00:00
#SBATCH -N 1
#SBATCH --mem=96G
#SBATCH --cpus-per-task=8
#SBATCH --array=1-100%10
#SBATCH --job-name=snm3c_bisqc
#SBATCH --output=/gpfs/projects/b1042/epifluidlab/yoshii/scnomehic_paper/benchmark/snm3c_100/logs/03.bisqc/bisqc.%a.txt
#SBATCH --error=/gpfs/projects/b1042/epifluidlab/yoshii/scnomehic_paper/benchmark/snm3c_100/logs/03.bisqc/bisqc.%a.err

# Read-level trinucleotide QC for the snm3C-seq arm: chrM and chr19 methylation
# by trinucleotide context, the input to summary/trinuc/snmCseq3.{chrM,chr21}.txt.
#
# STATUS: NOT THE PRODUCTION PATH FOR THIS ARM -- see below before using it.
#
# snm3C-seq was processed with YAP, so its per-cell methylation comes from the
# YAP allc files and the committed extractor for this arm is
# summary/extract_trinuc_snmCseq3_allc.py, which reads them. The
# `[bhmem]` annotation on the snmCseq3 line of summary/collect_conversion.py is
# wrong -- snm3c_100's BAMs are Bismark v0.20.0 via YAP (--pbat, mm10), and the
# only bhmem BAMs in the tree belong to a different accession set (SRR215493xx).
# That annotation should be corrected rather than relied on.
#
# This script is kept as a read-level cross-check of the allc numbers, using the
# same Bis-QC invocation as the other arms. It is NOT what produced the published
# table and should not be substituted for the allc path without saying so.
#
# Same tool and flags as every other arm (`Bis-QC.pl --QC_mode 1 --pattern WCH`),
# so the resulting contexts are comparable across arms. Bis-QC picks the autosome
# from the genome .fai: mm10 has no chr21, so it selects chr19 automatically.
#
# Set NONCPG_CONTEXT when extracting afterwards; this step emits all 16 contexts
# regardless, so ACT and TCT both come out of one run.

source /home/jmj7858/.bashrc
cd /gpfs/projects/b1042/epifluidlab/yoshii/scnomehic_paper/benchmark/snm3c_100 || exit 1
conda activate scnomehic

BISTOOLS=/projects/b1198/epifluidlab/yoshii/software/Bis-tools
reference=/projects/b1198/epifluidlab/yoshii/reference/mm10/mm10
vcf=/gpfs/projects/b1198/epifluidlab/shared/data/dbsnp/mm10.dbsnp.vcf
LIST=codes/bam_list.txt
mkdir -p logs/03.bisqc

bam=$(sed -n "${SLURM_ARRAY_TASK_ID}p" "${LIST}")
if [ -z "${bam}" ]; then echo "ERROR: no BAM for task ${SLURM_ARRAY_TASK_ID}"; exit 1; fi
cell=$(basename "${bam}" .3C.sorted.bam)
dir=$(dirname "${bam}")
rg="${dir}/${cell}.RG.bam"
echo "[$(date)] task ${SLURM_ARRAY_TASK_ID}: ${cell}"

# Resume: both trinuc outputs present and non-empty means this cell is done.
if [ -s "${dir}/${cell}.RG.trinuc_methy.chrM.txt" ] && \
   [ -s "${dir}/${cell}.RG.trinuc_methy.chr19.txt" ]; then
  echo "  [skip] trinuc already present for ${cell}"
  exit 0
fi

# Bis-SNP requires a read group; the YAP BAMs carry none.
if [ ! -s "${rg}" ]; then
  samtools addreplacerg \
    -r "@RG\tID:${cell}\tSM:snm3c\tLB:lib1\tPL:ILLUMINA\tPU:unit1" \
    -o "${rg}" "${bam}" || { echo "ERROR: addreplacerg failed"; exit 1; }
fi
[ -s "${rg}.bai" ] || samtools index "${rg}"

perl ${BISTOOLS}/Bis-QC/Bis-QC.pl --QC_mode 1 \
  --disable_enzyme_eff_check --disable_coverage_check \
  --pattern WCH --nt 8 --mem 64 \
  --genome ${reference}.fa --dbsnp ${vcf} \
  --bistools_path ${BISTOOLS} "${rg}" || { echo "ERROR: Bis-QC failed"; exit 1; }

for c in chrM chr19; do
  f="${dir}/${cell}.RG.trinuc_methy.${c}.txt"
  [ -s "${f}" ] || { echo "ERROR: expected ${f} missing"; exit 1; }
  echo "  [ok] ${f} ($(wc -l < "${f}") lines)"
done
echo "[$(date)] DONE ${cell}"
