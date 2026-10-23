#!/bin/bash
#SBATCH -A b1042
#SBATCH -p genomics
#SBATCH -t 8:00:00
#SBATCH -N 1
#SBATCH --mem=32G
#SBATCH --cpus-per-task=4
#SBATCH --array=1-32
#SBATCH --job-name=smwhcg
#SBATCH --output=logs/05.hcg_nome/smwhcg.%a.txt
#SBATCH --error=logs/05.hcg_nome/smwhcg.%a.err

# Smallwood scBS-seq -> HCG track for cross-method benchmark vs scNOMe.
#
# WHY: scNOMe counts "detected HCG sites" as rows of the Bismark
#   coverage2cytosine --nome-seq  NOMe.CpG.cov.gz  (see scnome/codes/
#   03.methy_extract.sh + nome_qc_sites_trinuc.py). To compare apples-to-apples,
#   we run the IDENTICAL tool/version (Bismark 0.24.2) on the Smallwood cov, so
#   the HCG definition (CpG context minus ambiguous GCG) is identical by
#   construction -- no need to resolve H=A/C/T vs W=A/T ourselves.
#
# INPUT: 06.methy/<cell>.dedup.bismark.cov.gz  (CpG-context-only; produced by
#        04.methy_extract.sh without --CX). HCG is a subset of CpG and context
#        is read from the genome, so a CpG-only cov yields the correct HCG set;
#        the GpC output will be ~empty (no GpC positions in a CpG-only cov) and
#        is irrelevant for scBS-seq (no GpC methyltransferase).
# OUTPUT: 06.methy/hcg/<cell>.NOMe.CpG.cov.gz  <- HCG track (count rows = sites)
#
# Scoped to the 32 ESC benchmark cells (acc_list_esc.txt: 12 x 2i + 20 x Ser).
# Leaves the paper-faithful all-CpG cov in 06.methy/ untouched.
#
# NOTE (M-bias): Smallwood reads were 5'-clipped 9 bp at trim (Trim Galore
#   --clip_r1/r2 9); scNOMe used clip 6 + extractor --ignore 6. Minor stage
#   difference in end-bias handling; both remove the priming-biased region.

# conda on PATH; override with SCNOMEHIC_CONDA_SH for a different install.
# --- repo paths: edit paths.yaml at the repository root, not this file -------
_r="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]:-$0}")")" && pwd)"
while [ "$_r" != "/" ] && [ ! -f "$_r/paths.sh" ]; do _r="$(dirname "$_r")"; done
source "$_r/paths.sh"

source "${SCNOMEHIC_CONDA_SH:-${CONDA_SH}}"
conda activate scnomehic
set -o pipefail

cd ${WORK_ROOT}/benchmark/smallwood
mkdir -p logs/05.hcg_nome

BIS=${REFERENCE_ROOT}/mm10_bismark/
METHY=06.methy
HCG=06.methy/hcg
mkdir -p ${HCG}

prefix=$(awk -v n=${SLURM_ARRAY_TASK_ID} 'NR==n' acc_list_esc.txt)
echo "[$(date)] prefix=${prefix}"

cov=${METHY}/${prefix}.dedup.bismark.cov.gz
hcg_cov=${HCG}/${prefix}.NOMe.CpG.cov.gz

if [ ! -s "${cov}" ]; then
    echo "  WARN: missing input cov ${cov}"; exit 0
fi
if [ -s "${hcg_cov}" ]; then
    echo "  [skip] HCG cov already present: ${hcg_cov}"
    echo "[$(date)] DONE prefix=${prefix}"; exit 0
fi

echo "  [run ] coverage2cytosine --nome-seq ${cov}"
coverage2cytosine \
    --nome-seq \
    --genome_folder "${BIS}" \
    --dir "${HCG}" \
    --gzip \
    -o "${prefix}" \
    "${cov}"

if [ -s "${hcg_cov}" ]; then
    echo "  [ok  ] HCG cov written: ${hcg_cov} ($(zcat ${hcg_cov} | wc -l) sites)"
else
    echo "  WARN: HCG cov not produced for ${prefix}"
fi
echo "[$(date)] DONE prefix=${prefix}"
