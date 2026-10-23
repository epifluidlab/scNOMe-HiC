#!/bin/bash
# Impute + loop-bkg the 434 annotated cells that have no 25 kb output yet, so
# that Q AND T exist for all 1,577 cells and the APA can use the full set.
#
# Writes into the EXISTING Jan-2026 impute dir, using the same mode and the same
# stripped cell naming, so the 1,143 cells already there are reused rather than
# recomputed (~43 G already on disk; these 434 add ~16 G).
#
# Per-cell work is independent of the annotation -- this is pure input->matrix
# computation, so it does not need redoing if the labels ever change again.
#
# Params are copied verbatim from apa_loop_pipeline/impute_one_cell.sh:
#   mode pad2_std1_rp0.5_sqrtvc, pad 2, output_dist 10050000,
#   window/step 30M/10M for chr1-12 (memory), plain for chr13-19.
#
#SBATCH --job-name=imp25k
#SBATCH -A b1042
#SBATCH -p genomics
#SBATCH --array=1-40
#SBATCH -N 1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=2
#SBATCH --mem=32G
#SBATCH -t 8:00:00
#SBATCH --output=/gpfs/projects/b1198/epifluidlab/yoshii/sc_nomehic/hic/loop_final/logs/impute_%A_%a.log

# /etc/bashrc reads unbound vars, so enable -u only after sourcing it
# --- repo paths: edit paths.yaml at the repository root, not this file -------
_r="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]:-$0}")")" && pwd)"
while [ "$_r" != "/" ] && [ ! -f "$_r/paths.sh" ]; do _r="$(dirname "$_r")"; done
source "$_r/paths.sh"

set -eo pipefail
# conda on PATH; override with SCNOMEHIC_CONDA_SH for a different install.
source "${SCNOMEHIC_CONDA_SH:-${CONDA_SH}}"
conda activate hic_env
set -u

HIC="/gpfs/projects/b1198/epifluidlab/yoshii/sc_nomehic/hic"
L="${HIC}/loop_final"
W="/gpfs/projects/b1198/epifluidlab/yoshii/sc_nomehic/snakemake/06.hiccluster_snakemake_run3_1577cells"
RAW="${HIC}/hicluster_25kb/hicluster_25kb_raw_dir"
IMP="${HIC}/hicluster_25kb/hicluster_25kb_impute_dir"
CHROM_FILE="${REFERENCE_ROOT}/mm10/mm10.noX.autosome.sizes"
MODE="pad2_std1_rp0.5_sqrtvc"
RES=25000
LIST="${L}/missing_cells_25kb.tsv"          # <stripped_name> TAB <full_name>
NTASK=40

mkdir -p "${RAW}" "${IMP}"
for c in $(seq 1 19); do mkdir -p "${RAW}/chr${c}" "${IMP}/chr${c}"; done

total=$(wc -l < "${LIST}")
echo "[task ${SLURM_ARRAY_TASK_ID}/${NTASK}] ${total} cells total"

# stride the list so each task takes every NTASK-th line
awk -v t="${SLURM_ARRAY_TASK_ID}" -v n="${NTASK}" 'NR % n == (t % n)' "${LIST}" |
while IFS=$'\t' read -r cell full; do
  [[ -n "${cell}" ]] || continue

  # resume-safe: skip when all 19 chroms already produced the loop-bkg output
  done_all=1
  for c in $(seq 1 19); do
    [[ -s "${IMP}/chr${c}/${cell}_chr${c}_${MODE}_dist_trim.E.npz" ]] || { done_all=0; break; }
  done
  if [[ "${done_all}" -eq 1 ]]; then echo "[skip] ${cell} already complete"; continue; fi

  # inputs are stored under the full batch-prefixed name; outputs keep the
  # stripped name so they sit alongside the existing 1,143 cells
  if   [[ -s "${W}/${full}.hic_matrix.txt.gz" ]]; then infile="${W}/${full}.hic_matrix.txt.gz"
  elif [[ -s "${W}/${full}.hic.txt.gz"        ]]; then infile="${W}/${full}.hic.txt.gz"
  else echo "[skip] no input for ${full}"; continue; fi

  echo "==== $(date '+%F %T') ${cell}  <- $(basename "${infile}")"
  tsv="${RAW}/${cell}.input.tsv"
  gzip -cd "${infile}" | awk -v OFS='\t' '{print $1,$2,$3,$4,$5,$6,$7}' > "${tsv}"

  hicluster generatematrix-cell \
    --infile "${tsv}" --outdir "${RAW}/" --chrom_file "${CHROM_FILE}" \
    --res "${RES}" --cell "${cell}" --chr1 1 --pos1 2 --chr2 5 --pos2 6

  for c in $(seq 1 19); do
    out="${IMP}/chr${c}/${cell}_chr${c}_${MODE}_dist_trim.E.npz"
    [[ -s "${out}" ]] && continue
    if [[ "${c}" -le 12 ]]; then
      hicluster impute-cell --indir "${RAW}/chr${c}/" --outdir "${IMP}/chr${c}/" \
        --cell "${cell}" --chrom "chr${c}" --res "${RES}" --chrom_file "${CHROM_FILE}" \
        --pad 2 --output_dist 10050000 --window_size 30000000 --step_size 10000000 --mode "${MODE}"
    else
      hicluster impute-cell --indir "${RAW}/chr${c}/" --outdir "${IMP}/chr${c}/" \
        --cell "${cell}" --chrom "chr${c}" --res "${RES}" --chrom_file "${CHROM_FILE}" \
        --pad 2 --output_dist 10050000 --mode "${MODE}"
    fi
    hicluster loop-bkg-cell --indir "${IMP}/" --cell "${cell}" --chrom "chr${c}" \
      --res "${RES}" --impute_mode "${MODE}"
  done

  rm -f "${tsv}"
  echo "[done] ${cell}"
done

echo "TASK ${SLURM_ARRAY_TASK_ID} FINISHED $(date '+%F %T')"
