#!/bin/bash
#SBATCH -A b1042
#SBATCH -p genomics
#SBATCH -t 36:00:00
#SBATCH -N 1
#SBATCH --mem=128G
#SBATCH --cpus-per-task=8
#SBATCH --array=1-51
#SBATCH --job-name=bisqc
#SBATCH --output=logs/03.bisqc/bisqc.%a.txt
#SBATCH --error=logs/03.bisqc/bisqc.%a.err

# conda on PATH; override with SCNOMEHIC_CONDA_SH for a different install.
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

source "${SCNOMEHIC_CONDA_SH:-${CONDA_SH}}"
cd ${WORK_ROOT}/benchmark/smallwood/ || { echo "ERROR: cd to working dir failed"; exit 1; }

conda activate scnomehic
# Bis-SNP is a GATK 1.x tool: its walkers are discovered by reflection and are
# invisible to a modern JVM. Without this the run dies at the first Bis-QC step
# with "Could not find walker with name: QuickMethylationLevel", before writing
# any trinucleotide table. scnome/codes/04.qc_bissnp_trinuc.sh loads the same JDK.
module load java/jdk1.8.0_191

outdir=05.align_mm10
vcf=${REFERENCE_ROOT}/mm10/mm10.dbsnp.vcf
reference=${REFERENCE_ROOT}/mm10/mm10

prefix=`cat acc_list.txt | awk -v num=${SLURM_ARRAY_TASK_ID} 'NR == num'`
echo ${prefix}

samtools sort -@ 8 \
  ${outdir}/${prefix}.SE.input_bismark_bt2.bam \
| samtools markdup -@ 8 - \
  ${outdir}/${prefix}.rmdup.bam

RGSM="smallwood"
RGPL="ILLUMINA"
RGLB="lib1"
RGPU="unit1"

samtools addreplacerg \
  -r "@RG\tID:${prefix}\tSM:${RGSM}\tLB:${RGLB}\tPL:${RGPL}\tPU:${RGPU}" \
  -o "${outdir}/${prefix}.rmdup.RG.bam" \
  "${outdir}/${prefix}.rmdup.bam"

samtools index "${outdir}/${prefix}.rmdup.RG.bam"

perl ${SOFTWARE_ROOT}/Bis-tools/Bis-QC/Bis-QC.pl --QC_mode 1 --disable_enzyme_eff_check --disable_coverage_check --pattern WCH --nt 8 --mem 64 --genome ${reference}.fa --dbsnp ${vcf} --bistools_path ${SOFTWARE_ROOT}/Bis-tools ${outdir}/${prefix}.rmdup.RG.bam

perl ${SOFTWARE_ROOT}/Bis-tools/Bis-SNP/bissnp_easy_usage.pl -use_bad_mates --bistools_path ${SOFTWARE_ROOT}/Bis-tools --lowCov --mmq 30 --nt 10 --mem 120 ${SOFTWARE_ROOT}/Bis-tools/Bis-SNP/BisSNP-0.90.jar ${outdir}/${prefix}.rmdup.RG.bam ${reference}.fa ${vcf}
