#!/usr/bin/env bash
# Merge the 3 DNase bioreps (FDR0.01): union peaks + averaged signal bigWig.
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
CHROM=${REFERENCE_ROOT}/hg38/autosomes.chrom.sizes
THREADS="${THREADS:-8}"
cd "$DATA"

PEAKS=(ENCFF486VDW ENCFF647XPG ENCFF384OTX)     # br1 br2 br3, FDR0.01
BWS=(ENCFF126OKI ENCFF473TWJ ENCFF594DFV)       # br1 br2 br3 read-depth normalized signal

cut -f1 "$CHROM" | sort > autosomes.list

# ---- union peaks (autosomes only), header stripped ----
: > peaks.union.raw.bed
for p in "${PEAKS[@]}"; do
  zcat "$p.bed.gz" | grep -v '^#' | cut -f1-3 >> peaks.union.raw.bed
done
awk 'NR==FNR{a[$1]=1;next} ($1 in a)' autosomes.list peaks.union.raw.bed \
  | LC_ALL=C sort -k1,1 -k2,2n \
  | bedtools merge -i - > dnase_peaks.merged.bed
echo "[merge] union+merged consensus peaks: $(wc -l < dnase_peaks.merged.bed)"

# ---- averaged signal bigWig for ranking ----
bigwigAverage -b "${BWS[0]}.bigWig" "${BWS[1]}.bigWig" "${BWS[2]}.bigWig" \
  --binSize 25 -p "$THREADS" -o dnase.mean.bw
echo "[merge] wrote dnase.mean.bw"
bigWigInfo dnase.mean.bw | sed -n '1,8p'
