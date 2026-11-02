#!/bin/bash
#SBATCH -A b1042
#SBATCH -p genomics
#SBATCH -t 12:00:00
#SBATCH -N 1
#SBATCH --mem=32G
#SBATCH --cpus-per-task=4
#SBATCH --array=1-51%8
#SBATCH --job-name=smw_trinuc
#SBATCH --output=logs/03b.trinuc/trinuc.%a.txt
#SBATCH --error=logs/03b.trinuc/trinuc.%a.err

# Trinucleotide methylation for scWGBS, calling bissnp_trinuc_sample.pl DIRECTLY
# instead of going through Bis-QC.pl.
#
# WHY NOT Bis-QC.pl
# 03.bisqc.sh runs the full Bis-QC, whose first step is the methylation-bias
# check. That step shells out to R with a path built from a variable Bis-QC.pl
# does not propagate, so it resolves to a bare `/Bis-QC/...`:
#     sh: /Bis-QC/after_reads_mapping/methyBiasDistPlot.R: No such file or directory
#     Unexpected stop at methylation bias check step
# Bis-QC then aborts BEFORE the trinucleotide step and no table is written. The
# GATK work itself succeeds -- the logs show reads being processed normally -- so
# the only blocker is that plotting call.
#
# This is the same invocation Bis-QC.pl would have made for the trinucleotide
# step, and the same one scnome/codes/04.qc_bissnp_trinuc.sh already uses
# successfully, so the computation is unchanged. It simply skips the bias plot,
# the conversion-distribution plot and the coverage estimate, none of which feed
# the conversion figure.
#
# Reads the mm10 BAMs produced by 02.alignment.sh after RG + index, writes
# <cell>.rmdup.RG.trinuc_methy.{chrM,chr19}.txt beside them.

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
cd ${WORK_ROOT}/benchmark/smallwood || { echo "ERROR: cd to working dir failed"; exit 1; }
conda activate scnomehic
# Bis-SNP is GATK 1.x: its walkers are found by reflection and are invisible to a
# modern JVM.
module load java/jdk1.8.0_191

BISTOOLS=${SOFTWARE_ROOT}/Bis-tools
TRINUC=${BISTOOLS}/Bis-QC/after_reads_mapping/bissnp_trinuc_sample.pl
JAR=${BISTOOLS}/Bis-SNP/Bis-SNP.latest.jar
GENOME=${REFERENCE_ROOT}/mm10/mm10.fa
DBSNP=${REFERENCE_ROOT}/mm10/mm10.dbsnp.vcf
OUT=05.align_mm10
mkdir -p logs/03b.trinuc

prefix=$(awk -v n=${SLURM_ARRAY_TASK_ID} 'NR==n' acc_list.txt)
[ -n "${prefix}" ] || { echo "ERROR: empty prefix for task ${SLURM_ARRAY_TASK_ID}"; exit 1; }
echo "[$(date)] cell=${prefix}"

src=${OUT}/${prefix}.SE.input_bismark_bt2.bam
rg=${OUT}/${prefix}.rmdup.RG.bam
samtools quickcheck "${src}" 2>/dev/null || { echo "ERROR: ${src} missing or truncated"; exit 1; }

# Bis-SNP needs a sorted, read-grouped, indexed BAM.
if ! samtools quickcheck "${rg}" 2>/dev/null \
   || [ "$(samtools view -c "${rg}" 2>/dev/null || echo 0)" -eq 0 ]; then
  echo "  [run ] sort + markdup + addreplacerg"
  samtools sort -@ 4 "${src}" \
    | samtools markdup -@ 4 - "${OUT}/${prefix}.rmdup.bam" \
    || { echo "ERROR: sort/markdup failed"; exit 1; }
  samtools addreplacerg \
    -r "@RG\tID:${prefix}\tSM:smallwood\tLB:lib1\tPL:ILLUMINA\tPU:unit1" \
    -o "${rg}" "${OUT}/${prefix}.rmdup.bam" || { echo "ERROR: addreplacerg failed"; exit 1; }
fi
[ -s "${rg}.bai" ] || samtools index "${rg}"

for chrom in chrM chr19; do
  out=${OUT}/${prefix}.rmdup.RG.trinuc_methy.${chrom}.txt
  # Resume only on a table that actually carries counts, not merely one that exists.
  if [ -s "${out}" ] && grep -q "^ACT:" "${out}" && ! grep -q "^ACT:[[:space:]]*0[[:space:]]" "${out}"; then
    echo "  [skip] ${out} already has data"; continue
  fi
  echo "  [run ] trinuc ${chrom}"
  perl "${TRINUC}" --bissnp "${JAR}" --genome "${GENOME}" --dbsnp "${DBSNP}" \
      --nt 4 --mem 22 --interval "${chrom}" "${out}" "${rg}" \
      || { echo "ERROR: trinuc failed ${prefix} ${chrom}"; exit 1; }
  rm -f "${OUT}/${prefix}.rmdup.RG.cytosine.raw.vcf.idx"
  [ -s "${out}" ] || { echo "ERROR: ${out} not written"; exit 1; }
  echo "  [ok  ] ${out}"
done
echo "[$(date)] DONE ${prefix}"
