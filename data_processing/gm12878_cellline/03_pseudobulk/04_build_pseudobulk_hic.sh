#!/bin/bash
# ─────────────────────────────────────────────────────────────────────────────
# Rebuild the GM12878 PSEUDOBULK .hic with the SAME good-reads extraction as the
# from-scratch bulk (../../bulk_scNOMeHiC/10_hic_from_merged.sh) and the single-cell
# `scbam2hic` rule:  samtools view -q30 -f1 -F1804  (removes PCR duplicates,
# secondary, supplementary, unmapped, unpaired)  BEFORE sam2juicer.
#
# An earlier pseudobulk build (superseded, not included here) ran sam2juicer
# DIRECTLY on the per-cell *_sorted_by_name.calmd.bam, which still contain MARKED
# (not removed) duplicates (~56% of reads), so the original gm_pseudobulk.mapQ30.hic
# INCLUDES PCR duplicates while the new bulk excludes them. This script fixes that
# inconsistency. Output is a NEW file; the original is left untouched.
#
# Per-cell processing (parallel) keeps sam2juicer's orphan buffer small.
#
# Submit:  sbatch 04_build_pseudobulk_hic.sh
# ─────────────────────────────────────────────────────────────────────────────
#SBATCH --account=b1042
#SBATCH --partition=genomics
#SBATCH --time=24:00:00
#SBATCH --nodes=1
#SBATCH --cpus-per-task=16
#SBATCH --mem=150G
#SBATCH --job-name=gm_psb_dedup
#SBATCH --output=/gpfs/projects/b1198/epifluidlab/yoshii/sc_nomehic_cellline/gm_sc_new/hic_comparison/logs/build_pseudobulk_dedup.%j.out
#SBATCH --error=/gpfs/projects/b1198/epifluidlab/yoshii/sc_nomehic_cellline/gm_sc_new/hic_comparison/logs/build_pseudobulk_dedup.%j.err

# --- repo paths: edit paths.yaml at the repository root, not this file -------
_r="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]:-$0}")")" && pwd)"
while [ "$_r" != "/" ] && [ ! -f "$_r/paths.sh" ]; do _r="$(dirname "$_r")"; done
source "$_r/paths.sh"

set -eo pipefail

source ${CONDA_SH}
conda activate scnomehic
module load java/jdk-17.0.2+8 2>/dev/null || module load java 2>/dev/null || true

D=/gpfs/projects/b1198/epifluidlab/yoshii/sc_nomehic_cellline/gm_sc_new
ALN="${D}/04.alignment_snakemake"
OUT="${D}/hic_comparison"
SAM2JUICER=${SOFTWARE_ROOT}/bisulfiteHic/src/python/sam2juicer_new.py
FRAG=${REFERENCE_ROOT}/hg38/GCA_000001405.15_GRCh38_no_alt_analysis_set.fa_DpnII.txt
JUICER=${SOFTWARE_ROOT}/juicer/juicer_tools.jar

SHORT_GZ="${OUT}/gm_pseudobulk.dedup.short.sorted.txt.gz"
HICOUT="${OUT}/gm_pseudobulk.dedup.mapQ30.hic"

TMP="/scratch/jmj7858/scnomehic/gm_psb_dedup.${SLURM_JOB_ID}"
SHORT="${TMP}/short"
mkdir -p "${SHORT}" "${OUT}/logs"

echo "=== Pseudobulk dedup .hic build start: $(date) on $(hostname) ==="

# --- Step 1: per-cell  view -q30 -f1 -F1804 | sam2juicer | 8-col short --------
# -q 30  : mapQ >= 30 (both mates, since a low-mapQ mate is dropped and orphans
#          are never emitted by sam2juicer)
# -f 1   : read paired
# -F 1804: exclude unmapped(4)+mate-unmapped(8)+secondary(256)+QCfail(512)+dup(1024)
# This is byte-for-byte the bulk's good-reads filter. mapQ already enforced here,
# so the awk only projects to the 8-col juicer SHORT format.
echo "[1] per-cell good-reads -> sam2juicer -> short (parallel)  $(date)"
run_one() {
  bam="$1"; frag="$2"; sj="$3"; outdir="$4"
  base=$(basename "$bam" .bam)
  samtools view -h -q 30 -f 1 -F 1804 "$bam" \
    | python "$sj" -s - -f "$frag" 2>> "${outdir}/sam2juicer.err" \
    | awk '{print $1,$2,$3,$4,$5,$6,$7,$8}' > "${outdir}/${base}.short"
}
export -f run_one
ls "${ALN}"/*_sorted_by_name.calmd.bam \
  | xargs -P 12 -I{} bash -c 'run_one "$@"' _ {} "$FRAG" "$SAM2JUICER" "$SHORT"

n_done=$(ls "${SHORT}"/*.short 2>/dev/null | wc -l)
echo "    produced ${n_done} per-cell short files (expect 188)"
[ "${n_done}" -eq 188 ] || { echo "ERROR: expected 188 short files, got ${n_done}"; exit 1; }

# --- Step 2: concat + LC_ALL=C byte sort (chr1=f2, chr2=f6) + gzip ------------
echo "[2] concat + LC_ALL=C sort + gzip  $(date)"
cat "${SHORT}"/*.short \
  | LC_ALL=C sort --parallel=16 -S 120G -T "${TMP}" -k2,2d -k6,6d \
  | gzip -c > "${SHORT_GZ}"
echo "    sorted contact lines: $(zcat "${SHORT_GZ}" | wc -l)  $(date)"

# --- Step 3: juicer pre -f DpnII -> .hic (mapQ already filtered upstream) -----
echo "[3] juicer_tools pre  $(date)"
java -Xmx120G -jar "${JUICER}" pre -f "${FRAG}" "${SHORT_GZ}" "${HICOUT}" hg38

echo "[OK] wrote ${HICOUT}  ($(du -h "${HICOUT}" | cut -f1))"
rm -rf "${TMP}"
echo "=== Pseudobulk dedup .hic build done: $(date) ==="
