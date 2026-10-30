#!/usr/bin/env bash
# Per-peak GCH methylation coverage: total GpC read coverage (+ #sites) over each
# merged DNase peak, from the pseudobulk GCH 6plus2 bed (col8 = coverage).
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

set -euo pipefail
BASE=${WORK_ROOT}/analysis/s2_new/atac_dnase_gm12878
DATA="$BASE/data"
GCH6=${WORK_ROOT}/gm12878_cellline/pseudobulk_methylation/gm_pseudobulk_merged.GCH.6plus2.bed.gz
CHROM=${REFERENCE_ROOT}/hg38/autosomes.chrom.sizes
TMP="${TMPDIR:-/tmp}/gchcov_${SLURM_JOB_ID:-$$}"; mkdir -p "$TMP"
SORTMEM="${SORTMEM:-8G}"
cd "$DATA"

cut -f1 "$CHROM" | sort > "$TMP/autosomes.list"

echo "[1/3] extract autosomal GpC coverage (chr,start,end,cov) + sort (LC_ALL=C)"
zcat "$GCH6" \
  | awk 'NR==FNR{a[$1]=1;next} ($1 in a){print $1"\t"$2"\t"$3"\t"$8}' "$TMP/autosomes.list" - \
  | LC_ALL=C sort -S "$SORTMEM" -T "$TMP" -k1,1 -k2,2n > "$TMP/gch_cov.bed"
echo "    sites: $(wc -l < "$TMP/gch_cov.bed")"

echo "[2/3] sort peaks (LC_ALL=C, same order)"
LC_ALL=C sort -S "$SORTMEM" -T "$TMP" -k1,1 -k2,2n dnase_peaks.merged.bed > "$TMP/peaks.sorted.bed"

echo "[3/3] bedtools map: sum coverage + count sites per peak"
# output: chr start end cov_sum n_sites   (-null 0 for peaks with no GpC site)
bedtools map -a "$TMP/peaks.sorted.bed" -b "$TMP/gch_cov.bed" -c 4,4 -o sum,count -null 0 \
  > peak_gch_coverage.tab
echo "    wrote data/peak_gch_coverage.tab ($(wc -l < peak_gch_coverage.tab) peaks)"
head -3 peak_gch_coverage.tab
rm -rf "$TMP"
