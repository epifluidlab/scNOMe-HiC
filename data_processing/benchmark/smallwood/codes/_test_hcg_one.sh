#!/bin/bash
# Quick test: run coverage2cytosine --nome-seq on ONE Smallwood cell's CpG-only
# cov to confirm it produces NOMe.CpG.cov.gz (HCG) correctly from a non-CX cov.
# conda on PATH; override with SCNOMEHIC_CONDA_SH for a different install.
# --- repo paths: edit paths.yaml at the repository root, not this file -------
_r="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]:-$0}")")" && pwd)"
while [ "$_r" != "/" ] && [ ! -f "$_r/paths.sh" ]; do _r="$(dirname "$_r")"; done
source "$_r/paths.sh"

source "${SCNOMEHIC_CONDA_SH:-${CONDA_SH}}"
conda activate scnomehic
set -o pipefail

cd /gpfs/projects/b1042/epifluidlab/yoshii/scnomehic_paper/benchmark/smallwood
BIS=${REFERENCE_ROOT}/mm10_bismark/
cell=SRR1248457
cov=06.methy/${cell}.dedup.bismark.cov.gz
out=06.methy/_hcg_test
mkdir -p "${out}"

echo "[`date`] input cov rows (all-CpG): $(zcat ${cov} | wc -l)"
echo "[`date`] running coverage2cytosine --nome-seq ..."
coverage2cytosine \
    --nome-seq \
    --genome_folder "${BIS}" \
    --dir "${out}" \
    --gzip \
    -o "${cell}" \
    "${cov}"

echo "[`date`] output files:"
ls -la "${out}"
echo "=== HCG (NOMe.CpG) cov rows ==="
zcat "${out}/${cell}.NOMe.CpG.cov.gz" 2>/dev/null | wc -l
echo "=== head of HCG cov ==="
zcat "${out}/${cell}.NOMe.CpG.cov.gz" 2>/dev/null | head -3
echo "=== GpC cov rows (expected ~0 from CpG-only input) ==="
zcat "${out}/${cell}.NOMe.GpC.cov.gz" 2>/dev/null | wc -l
echo "[`date`] DONE"
