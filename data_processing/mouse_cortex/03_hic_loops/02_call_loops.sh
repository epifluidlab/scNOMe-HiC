#!/bin/bash
# Per-cell-type loop calling + Q/T/E coolers at 25 kb, under the FINAL 10-type
# annotation (subset_clustering/250kb_denovo, k20_r0.3).
#
# Mirrors hic/loop_call.sh (the Jan-2026 run) but:
#   - reads the final 10-type cell table (IT-L5_6 and Inhib replace the old
#     IT-L4-heavy split and the separate Pvalb/Vip)
#   - writes to loop_majortype_25kb_1577/ so the Jan outputs stay intact
#
# Q, T and the loop calls are all produced from the SAME 1,143 cells, which is
# required: the differential assignment compares fold-changes of Q against T,
# so mixing cell sets between them would invalidate the comparison.
#
# SLURM array: one task per cell type (10 tasks).
#SBATCH --job-name=loop1577
#SBATCH -A b1042
#SBATCH -p genomics
#SBATCH --array=1-10
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=64G
#SBATCH -t 8:00:00
#SBATCH --output=${WORK_ROOT}/mouse_cortex/hic/loop_final/logs/loop1577_%A_%a.log

# /etc/bashrc references unbound vars, so enable -u only AFTER sourcing it
# --- repo paths: edit paths.yaml at the repository root, not this file -------
_r="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]:-$0}")")" && pwd)"
while [ "$_r" != "/" ] && [ ! -f "$_r/paths.sh" ]; do _r="$(dirname "$_r")"; done
source "$_r/paths.sh"

set -eo pipefail
# conda on PATH; override with SCNOMEHIC_CONDA_SH for a different install.
source "${SCNOMEHIC_CONDA_SH:-${CONDA_SH}}"
conda activate hic_env
set -u

HIC="${WORK_ROOT}/mouse_cortex/hic"
L="${HIC}/loop_final"
CELL_TABLE="${L}/cell_table_all1577_25kb.tsv"
IMP_DIR="${HIC}/hicluster_25kb/hicluster_25kb_impute_dir"
OUT_ROOT="${HIC}/loop_majortype_25kb_1577"
chrom_file="${REFERENCE_ROOT}/mm10/mm10.noX.autosome.sizes"
mode="pad2_std1_rp0.5_sqrtvc"
res=25000

CTS=(ASC CT-L6 IT-L2_3 IT-L4 IT-L5_6 Inhib MGC ODC OPC PC_EC)
ct="${CTS[$((SLURM_ARRAY_TASK_ID - 1))]}"

echo "[task ${SLURM_ARRAY_TASK_ID}] ct=${ct} res=${res}"
mkdir -p "${OUT_ROOT}/filelist"
ct_dir="${OUT_ROOT}/${ct}/${ct}"
mkdir -p "${ct_dir}"

for chr in $(awk '{print $1}' "${chrom_file}"); do
  list="${OUT_ROOT}/filelist/${ct}_${mode}_${chr}_looplist.txt"
  # column 1 = cell (already in the impute dir's stripped naming), column 2 = type
  awk -v CT="${ct}" -v CHR="${chr}" -v M="${mode}" -v D="${IMP_DIR}" -F'\t' '
    NR==1{next} $2==CT{ printf("%s/%s/%s_%s_%s\n", D, CHR, $1, CHR, M) }
  ' "${CELL_TABLE}" > "${list}"
  if [ ! -s "${list}" ]; then
    echo "[warn] empty cell list ct=${ct} ${chr}" >&2; continue
  fi
  echo "[${ct}] ${chr}: $(wc -l < "${list}") cells"
  hicluster loop-sumcell-chr \
    --cell_list "${list}" \
    --outprefix "${ct_dir}/${ct}_${mode}_dist_trim_${chr}" \
    --res "${res}"
done

hicluster loop-mergechr \
  --inprefix  "${ct_dir}/${ct}_${mode}_dist_trim" \
  --outprefix "${ct_dir}/${ct}_${mode}_dist_trim" \
  --chrom_file "${chrom_file}" \
  --res "${res}"

if [ -f "${ct_dir}/${ct}_${mode}_dist_trim.loop.bedpe" ]; then
  ln -sf "${ct}_${mode}_dist_trim.loop.bedpe" "${ct_dir}/${ct}.loop.bedpe"
else
  echo "[warn] missing bedpe for ${ct}" >&2
fi

# Q/T/E coolers from the same cells, so the differential FCs are comparable
python "$(dirname "$(readlink -f "$0")")/make_celltype_cool.py" \
  --cell_table "${CELL_TABLE}" \
  --in_dir "${IMP_DIR}/" \
  --out_dir "${OUT_ROOT}/" \
  --chrom_sizes "${chrom_file}" \
  --mode "${mode}" \
  --res "${res}" \
  --chroms 1-19 \
  --cell_types "${ct}"

echo "DONE ct=${ct}"
