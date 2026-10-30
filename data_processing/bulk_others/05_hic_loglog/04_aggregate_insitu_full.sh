#!/bin/bash
#SBATCH --account=b1042
#SBATCH --partition=genomics
#SBATCH --time=08:00:00
#SBATCH --mem=8G
#SBATCH --cpus-per-task=2
#SBATCH --job-name=qc_insitu_full_awk
#SBATCH --output=${WORK_ROOT}/analysis/fig1/codes/hic_qc_loglog/logs/%x_%j.out
#SBATCH --error=${WORK_ROOT}/analysis/fig1/codes/hic_qc_loglog/logs/%x_%j.out
# FALLBACK (no HOMER, near-zero memory): aggregate the in-situ full HiCsummary into the same
# petag.FreqDistribution_1000.txt format HOMER produces — fraction of PE pairs per 1kb distance bin.
# HiCsummary cols: 1=name 2=chr1 3=pos1 4=str1 5=chr2 6=pos2 7=str2
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

set -eo pipefail
NAME=insitu_hic_full
WORK=${TMP_ROOT}/hic_qc_loglog/$NAME
SUMMARY=$WORK/$NAME.hicsummary.txt
RESULTS=${WORK_ROOT}/analysis/fig1/results/hic_qc_loglog
OUT=$RESULTS/${NAME}.petag.FreqDistribution_1000.txt
[ -s "$SUMMARY" ] || { echo "ERROR: missing $SUMMARY"; exit 1; }
echo "[$(date)] awk-aggregating $SUMMARY ..."
awk '
{
  if ($2==$5) { d=$6-$3; if(d<0)d=-d; b=int(d/1000)*1000; c[b]++; intra++ }
  else inter++
}
END{
  tot=intra+inter;
  printf "Distance between PE tags\tFraction of total PE tags(Interchromosomal:%e)\n", (tot?inter/tot:0);
  for (b in c) printf "%d\t%e\n", b, c[b]/tot;
}' "$SUMMARY" | { head -1; tail -n +2 | sort -k1,1n; } > "$OUT"
echo "[$(date)] wrote $OUT ($(wc -l < "$OUT") lines)"
