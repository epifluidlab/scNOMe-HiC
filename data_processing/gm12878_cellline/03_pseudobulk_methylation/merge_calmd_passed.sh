#!/bin/bash
#SBATCH --job-name=merge_calmd
#SBATCH --account=b1042
#SBATCH --partition=genomics
#SBATCH --cpus-per-task=16
#SBATCH --mem=64G
#SBATCH --time=12:00:00
#SBATCH --output=/gpfs/projects/b1198/epifluidlab/yoshii/sc_nomehic_cellline/gm_sc_new/logs/merge_calmd_%j.out
#SBATCH --error=/gpfs/projects/b1198/epifluidlab/yoshii/sc_nomehic_cellline/gm_sc_new/logs/merge_calmd_%j.err
#
# Merge all per-cell .calmd.bam files for QC-passing cells into a single
# pseudobulk BAM. Reads cell prefixes from QC/cellline_passed.txt, pulls each
# {prefix}.calmd.bam from 04.alignment_snakemake/, samtools-merges them, then
# sorts by coordinate and indexes.
#
# Edit PROJECT to point at a different cohort (e.g. snakemake/) if needed.

set -uo pipefail

PROJECT=/gpfs/projects/b1198/epifluidlab/yoshii/sc_nomehic_cellline/gm_sc_new
PASSED=${PROJECT}/QC/cellline_passed.txt
ALIGN_DIR=${PROJECT}/04.alignment_snakemake
OUT_BAM=${ALIGN_DIR}/merged.bam
OUT_SORTED=${ALIGN_DIR}/merged.sorted.bam
LIST=${ALIGN_DIR}/merge_input_list.txt
SAMTOOLS=/gpfs/projects/b1198/epifluidlab/yoshii/software/conda/envs/scnomehic/bin/samtools

mkdir -p ${PROJECT}/logs ${ALIGN_DIR}

# ---- Sanity ----
if [[ ! -f ${PASSED} ]]; then
    echo "ERROR: ${PASSED} not found. Run qc_plots.ipynb first." >&2
    exit 1
fi
if [[ ! -x ${SAMTOOLS} ]]; then
    echo "ERROR: samtools not executable at ${SAMTOOLS}" >&2
    exit 1
fi

# ---- Build BAM file list ----
> ${LIST}
N_FOUND=0
N_MISSING=0
MISSING_LOG=${ALIGN_DIR}/merge_missing.txt
> ${MISSING_LOG}
while IFS= read -r prefix; do
    [[ -z "${prefix}" ]] && continue
    bam=${ALIGN_DIR}/${prefix}.calmd.bam
    if [[ -f ${bam} ]]; then
        echo ${bam} >> ${LIST}
        N_FOUND=$((N_FOUND + 1))
    else
        echo ${prefix} >> ${MISSING_LOG}
        N_MISSING=$((N_MISSING + 1))
    fi
done < ${PASSED}

echo "[INFO] passed cells:   $(wc -l < ${PASSED})"
echo "[INFO] BAMs found:     ${N_FOUND}"
echo "[INFO] BAMs missing:   ${N_MISSING}  (see ${MISSING_LOG})"

if [[ ${N_FOUND} -eq 0 ]]; then
    echo "ERROR: no input BAMs to merge." >&2
    exit 1
fi

# ---- Merge ----
echo "[INFO] samtools merge ${N_FOUND} BAMs -> ${OUT_BAM}"
date
${SAMTOOLS} merge -@ ${SLURM_CPUS_PER_TASK:-16} -f -b ${LIST} ${OUT_BAM}
date
echo "[INFO] merge done. Size:"
ls -la ${OUT_BAM}

# ---- Sort + index ----
echo "[INFO] samtools sort (by coordinate) -> ${OUT_SORTED}"
date
${SAMTOOLS} sort -@ ${SLURM_CPUS_PER_TASK:-16} -m 3G -o ${OUT_SORTED} ${OUT_BAM}
${SAMTOOLS} index -@ ${SLURM_CPUS_PER_TASK:-16} ${OUT_SORTED}
date
echo "[INFO] sort + index done. Final files:"
ls -la ${OUT_BAM} ${OUT_SORTED} ${OUT_SORTED}.bai

echo "[DONE] merged ${N_FOUND} per-cell calmd.bams -> ${OUT_SORTED}"
