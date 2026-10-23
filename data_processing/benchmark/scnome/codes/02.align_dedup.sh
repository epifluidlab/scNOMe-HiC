#!/bin/bash
#SBATCH -A b1042
#SBATCH -p genomics
#SBATCH -t 36:00:00
#SBATCH -N 1
#SBATCH --mem=128G
#SBATCH --cpus-per-task=16
#SBATCH --array=1-12
#SBATCH --job-name=bisqc
#SBATCH --output=logs/02.bisqc/bisqc.%a.txt
#SBATCH --error=logs/02.bisqc/bisqc.%a.err

# conda on PATH; override with SCNOMEHIC_CONDA_SH for a different install.
# --- repo paths: edit paths.yaml at the repository root, not this file -------
_r="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]:-$0}")")" && pwd)"
while [ "$_r" != "/" ] && [ ! -f "$_r/paths.sh" ]; do _r="$(dirname "$_r")"; done
source "$_r/paths.sh"

source "${SCNOMEHIC_CONDA_SH:-${CONDA_SH}}"
cd /gpfs/projects/b1042/epifluidlab/yoshii/scnomehic_paper/benchmark/scnome

conda activate scnomehic

prefix=`cat acc_list.txt | awk -v num=${SLURM_ARRAY_TASK_ID} 'NR == num'`
echo ${prefix}

# Exclude control / spike-in samples (SRR3729654-SRR3729660) from analysis.
# GM12878: SRR3729642-SRR3729653 ; K562: SRR3729661-SRR3729682
srr_num=${prefix#SRR}
if [ "${srr_num}" -ge 3729654 ] && [ "${srr_num}" -le 3729660 ]; then
  echo "${prefix} is a control sample (excluded from analysis). Skipping."
  exit 0
fi

input=03.trimmed_fastq
outdir=04.alignment
methydir=05.methy
vcf=${REFERENCE_ROOT}/hg38/Homo_sapiens_assembly38.dbsnp138.vcf
reference=${REFERENCE_ROOT}/hg38/GCA_000001405.15_GRCh38_no_alt_analysis_set

bismark_genome=${REFERENCE_ROOT}/hg38_bismark/

# ---- Align each mate independently with Bismark (non-directional, hg38) ----
bismark --fastq --prefix ${prefix} --output_dir ${outdir} --non_directional --phred33-quals --score_min L,0,-0.2 --bowtie2 --genome ${bismark_genome} ${input}/${prefix}_1_trimmed.fq.gz
bismark --fastq --prefix ${prefix} --output_dir ${outdir} --non_directional --phred33-quals --score_min L,0,-0.2 --bowtie2 --genome ${bismark_genome} ${input}/${prefix}_2_trimmed.fq.gz

# ---- Coordinate-sort + remove duplicates (markdup; identical handling to all
#      other cell types -- only the upstream trimming differs for GM12878) ----
samtools sort -@ 16 \
  ${outdir}/${prefix}.${prefix}_1_trimmed_bismark_bt2.bam \
| samtools markdup -@ 16 - \
  ${outdir}/${prefix}_1.rmdup.bam

samtools sort -@ 16 \
  ${outdir}/${prefix}.${prefix}_2_trimmed_bismark_bt2.bam \
| samtools markdup -@ 16 - \
  ${outdir}/${prefix}_2.rmdup.bam

# ---- Add read groups + index (needed for bam_summary and downstream tools) ----
RGSM="scNOMe"
RGPL="ILLUMINA"
RGLB="lib1"
RGPU="unit1"

samtools addreplacerg \
  -r "@RG\tID:${prefix}_1\tSM:${RGSM}\tLB:${RGLB}\tPL:${RGPL}\tPU:${RGPU}" \
  -o "${outdir}/${prefix}_1.rmdup.RG.bam" \
  "${outdir}/${prefix}_1.rmdup.bam"
samtools index "${outdir}/${prefix}_1.rmdup.RG.bam"

samtools addreplacerg \
  -r "@RG\tID:${prefix}_2\tSM:${RGSM}\tLB:${RGLB}\tPL:${RGPL}\tPU:${RGPU}" \
  -o "${outdir}/${prefix}_2.rmdup.RG.bam" \
  "${outdir}/${prefix}_2.rmdup.bam"
samtools index "${outdir}/${prefix}_2.rmdup.RG.bam"

# Methylation extraction is handled separately in codes/03.methy_extract.sh
# (reads ${prefix}_${mate}.rmdup.bam). Bis-QC / Bis-SNP steps are intentionally
# left out of the core rerun.

# ---- Per-mate BAM mapping summary ----
python /gpfs/projects/b1042/epifluidlab/yoshii/scnomehic_paper/benchmark/bam_summary_universal.py --in_bam ${outdir}/${prefix}_1.rmdup.RG.bam  --out_summary  ${outdir}/${prefix}_1.summary.txt
python /gpfs/projects/b1042/epifluidlab/yoshii/scnomehic_paper/benchmark/bam_summary_universal.py --in_bam ${outdir}/${prefix}_2.rmdup.RG.bam  --out_summary  ${outdir}/${prefix}_2.summary.txt