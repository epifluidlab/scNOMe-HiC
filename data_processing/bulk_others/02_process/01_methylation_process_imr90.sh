#!/usr/bin/env bash
# Convert IMR90 ENCODE bulk WGBS bigBed -> BED and bigWig, and subset to HCG.
# Mirror of fig1/codes/fig1j/methylation_process.sh (reuses its subset_hcg.py),
# applied to the single IMR90 accession ENCFF591PKF.
#
# Input bigBed is ENCODE bedMethyl (CpG context): col10 = read coverage,
# col11 = % methylation (0-100). Output bigWig signal is % methylation.
# HCG subset removes GCG (ambiguous with NOMe-HiC GpC accessibility signal);
# context is called from the reference genome by subset_hcg.py.
#
# Tools (bigBedToBed, bedGraphToBigWig, python+pysam) from `scnomehic` conda env.

# --- repo paths: edit paths.yaml at the repository root, not this file -------
_r="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]:-$0}")")" && pwd)"
while [ "$_r" != "/" ] && [ ! -f "$_r/paths.sh" ]; do _r="$(dirname "$_r")"; done
source "$_r/paths.sh"

source ${CONDA_SH}
conda activate scnomehic

# Enable strict mode after conda activation (its activate.d scripts use unset vars).
set -euo pipefail

FIG1CODE=${WORK_ROOT}/analysis/fig1/codes/fig1j
DIR=${WORK_ROOT}/analysis/fig2/data/bulk/IMR90/methylation
REF=${REFERENCE_ROOT}/hg38
CHROMSIZES=$REF/GCA_000001405.15_GRCh38_no_alt_analysis_set.chrom.sizes
GENOME=$REF/GCA_000001405.15_GRCh38_no_alt_analysis_set.fa
cd "$DIR"

# bedMethyl -> bigWig of % methylation (col 11); keep only chroms in chrom.sizes.
make_bw () {  # <input.bed> <output.bw>
  local bed="$1" out="$2" bg="${2%.bw}.bedGraph"
  awk 'BEGIN{OFS="\t"} NR==FNR{ok[$1]=1;next} ($1 in ok){print $1,$2,$3,$11}' \
      "$CHROMSIZES" "$bed" \
    | sort -k1,1 -k2,2n > "$bg"
  bedGraphToBigWig "$bg" "$CHROMSIZES" "$out"
  rm -f "$bg"
}

acc=ENCFF591PKF

if [[ -s "$acc.bed" ]]; then
  echo "[$acc] bed exists, skipping bigBed -> bed"
else
  echo "[$acc] bigBed -> bed"
  bigBedToBed "$acc.bigBed" "$acc.bed"
fi

echo "[$acc] subset to HCG (exclude GCG) via reference genome"
python "$FIG1CODE/subset_hcg.py" "$GENOME" "$acc.bed" "$acc.HCG.bed"

echo "[$acc] full CpG bigWig"
make_bw "$acc.bed" "$acc.bw"

echo "[$acc] HCG bigWig"
make_bw "$acc.HCG.bed" "$acc.HCG.bw"

echo "[$acc] done -> $acc.bed, $acc.HCG.bed, $acc.bw, $acc.HCG.bw"
