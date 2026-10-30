#!/bin/bash
# Compute Bismark-native trinuc QC on a few Smallwood ESC cells and compare to
# the existing BisSNP-derived values. Uses the SAME shared script as scNOMe
# (scnome/codes/nome_qc_sites_trinuc.py) with --mates "" (single no-mate cell).
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
conda activate scnomehic
set -o pipefail

cd ${WORK_ROOT}/benchmark/smallwood
QC=${WORK_ROOT}/benchmark/scnome/codes/nome_qc_sites_trinuc.py
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
