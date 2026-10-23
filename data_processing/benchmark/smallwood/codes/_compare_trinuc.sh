#!/bin/bash
# Compute Bismark-native trinuc QC on a few Smallwood ESC cells and compare to
# the existing BisSNP-derived values. Uses the SAME shared script as scNOMe
# (scnome/codes/nome_qc_sites_trinuc.py) with --mates "" (single no-mate cell).
# conda on PATH; override with SCNOMEHIC_CONDA_SH for a different install.
# --- repo paths: edit paths.yaml at the repository root, not this file -------
_r="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]:-$0}")")" && pwd)"
while [ "$_r" != "/" ] && [ ! -f "$_r/paths.sh" ]; do _r="$(dirname "$_r")"; done
source "$_r/paths.sh"

source "${SCNOMEHIC_CONDA_SH:-${CONDA_SH}}"
conda activate scnomehic
set -o pipefail

cd /gpfs/projects/b1042/epifluidlab/yoshii/scnomehic_paper/benchmark/smallwood
QC=/gpfs/projects/b1042/epifluidlab/yoshii/scnomehic_paper/benchmark/scnome/codes/nome_qc_sites_trinuc.py
REF=${REFERENCE_ROOT}/mm10/mm10.fa
OUT=qc_stats/trinuc_bismark
mkdir -p ${OUT}

for cell in SRR1248457 SRR1248458 SRR1248481 SRR1248490 SRR1248496; do
    echo "[`date`] === ${cell} ==="
    python3 ${QC} \
        --cell ${cell} \
        --methy_dir 06.methy/hcg \
        --align_dir 05.align_mm10 \
        --ref ${REF} \
        --chroms chrM,chr19 \
        --bam_suffix .rmdup.RG.bam \
        --mates "" \
        --out ${OUT}/${cell}.trinuc_bismark.csv
done
echo "[`date`] ALL DONE"
