#!/bin/bash
#SBATCH --account=b1042
#SBATCH --partition=genomics
#SBATCH --time=08:00:00
#SBATCH --mem=48G
#SBATCH --cpus-per-task=6
#SBATCH --output=${WORK_ROOT}/analysis/fig1/codes/hic_qc_loglog/logs/%x_%j.out
#SBATCH --error=${WORK_ROOT}/analysis/fig1/codes/hic_qc_loglog/logs/%x_%j.out
# ---------------------------------------------------------------------------
# HOMER contact-frequency-vs-distance (log-log) pipeline for ONE sample.
# Builds a HOMER HiCsummary from a read-pair-level file, runs makeTagDirectory,
# and copies the resulting petagDistDistribution.txt (the log-log plot data).
#
# Usage (env vars):
#   NAME  : sample label (used for output dir/file names)
#   SRC   : gzipped read-pair source file
#   FMT   : short8 | short16 | pairs
#           short8  = juicer short  : str1 chr1 pos1 frag1 str2 chr2 pos2 frag2
#           short16 = juicer medium : ...as short8 + mapq1(9) cigar1 seq1 mapq2(13) ...
#           pairs   = 4DN .pairs     : readID chr1 pos1 chr2 pos2 strand1 strand2
#   TARGET: max read pairs to keep (downsample cap; 0 = keep all)
# ---------------------------------------------------------------------------
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
[ -f /etc/profile.d/modules.sh ] && source /etc/profile.d/modules.sh 2>/dev/null || true
source ~/.bashrc 2>/dev/null || true
module load homer/5.1

: "${NAME:?}"; : "${SRC:?}"; : "${FMT:?}"; : "${TARGET:=100000000}"
OUTROOT=${TMP_ROOT}/hic_qc_loglog
RESULTS=${WORK_ROOT}/analysis/fig1/results/hic_qc_loglog
WORK=$OUTROOT/$NAME
mkdir -p "$WORK" "$RESULTS"
SUMMARY=$WORK/$NAME.hicsummary.txt
TAGDIR=$WORK/${NAME}_TagDir

echo "[$(date)] NAME=$NAME SRC=$SRC FMT=$FMT TARGET=$TARGET"

# --- awk filter+convert program: emit HiCsummary cols, main chroms only ---
# HiCsummary: name  chr1  pos1  strand1  chr2  pos2  strand2
read -r -d '' CONV_short8 <<'AWK' || true
BEGIN{OFS="\t"; split("chr1 chr2 chr3 chr4 chr5 chr6 chr7 chr8 chr9 chr10 chr11 chr12 chr13 chr14 chr15 chr16 chr17 chr18 chr19 chr20 chr21 chr22 chrX",a," "); for(i in a)m[a[i]]=1}
($2 in m)&&($6 in m){print "r", $2, $3, ($1==16?"-":"+"), $6, $7, ($5==16?"-":"+")}
AWK
read -r -d '' CONV_short16 <<'AWK' || true
BEGIN{OFS="\t"; split("chr1 chr2 chr3 chr4 chr5 chr6 chr7 chr8 chr9 chr10 chr11 chr12 chr13 chr14 chr15 chr16 chr17 chr18 chr19 chr20 chr21 chr22 chrX",a," "); for(i in a)m[a[i]]=1}
($2 in m)&&($6 in m)&&($9>=30)&&($13>=30){print "r", $2, $3, ($1==16?"-":"+"), $6, $7, ($5==16?"-":"+")}
AWK
read -r -d '' CONV_pairs <<'AWK' || true
BEGIN{OFS="\t"; split("chr1 chr2 chr3 chr4 chr5 chr6 chr7 chr8 chr9 chr10 chr11 chr12 chr13 chr14 chr15 chr16 chr17 chr18 chr19 chr20 chr21 chr22 chrX",a," "); for(i in a)m[a[i]]=1}
/^#/{next}
($2 in m)&&($4 in m){print $1, $2, $3, $6, $4, $5, $7}
AWK

case "$FMT" in
  short8)  CONV="$CONV_short8" ;;
  short16) CONV="$CONV_short16" ;;
  pairs)   CONV="$CONV_pairs" ;;
  *) echo "unknown FMT=$FMT"; exit 1 ;;
esac

# --- Pass 1: count qualifying pairs ---
echo "[$(date)] pass1 count..."
COUNT=$(pigz -dc -p4 "$SRC" | awk "$CONV" | wc -l)
echo "[$(date)] qualifying pairs = $COUNT"

# --- probability for downsample ---
if [ "$TARGET" -gt 0 ] && [ "$COUNT" -gt "$TARGET" ]; then
  P=$(awk -v t="$TARGET" -v c="$COUNT" 'BEGIN{printf "%.10f", t/c}')
else
  P=1.0
fi
echo "[$(date)] downsample p=$P"

# --- Pass 2: convert + Bernoulli subsample -> HiCsummary ---
echo "[$(date)] pass2 build HiCsummary..."
pigz -dc -p4 "$SRC" | awk "$CONV" | awk -v p="$P" 'BEGIN{srand(1)} p>=1||rand()<p' > "$SUMMARY"
KEPT=$(wc -l < "$SUMMARY")
echo "[$(date)] kept $KEPT pairs -> $SUMMARY"

# --- makeTagDirectory (auto-writes petagDistDistribution.txt) ---
echo "[$(date)] makeTagDirectory..."
rm -rf "$TAGDIR"
makeTagDirectory "$TAGDIR" -format HiCsummary "$SUMMARY" -tbp 1

# --- collect the log-log data ---
# HOMER 5.1 names the contact-freq-vs-distance file petag.FreqDistribution_1000.txt
# (older docs call it petagDistDistribution.txt). Header carries the interchromosomal fraction.
FREQ="$TAGDIR/petag.FreqDistribution_1000.txt"
[ -f "$FREQ" ] || FREQ="$TAGDIR/petagDistDistribution.txt"
cp "$FREQ" "$RESULTS/${NAME}.petag.FreqDistribution_1000.txt"
echo "$NAME	source=$SRC	fmt=$FMT	total_pairs=$COUNT	kept=$KEPT	p=$P" >> "$RESULTS/sample_depths.tsv"
echo "[$(date)] DONE $NAME -> $RESULTS/${NAME}.petag.FreqDistribution_1000.txt"
