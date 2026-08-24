#!/bin/bash
# 02_run_one.sh CELL FRACTION
# Compute the 4 saturation metrics for one cell at one subsample fraction.
# Subsamples the PRE-dedup mapped BAM, re-runs markdup + contact-summary + Bis-SNP,
# writes a single result line, then deletes the scratch BAMs.
set -euo pipefail

CELL="$1"          # e.g. scNH_GM_4plex_10_S9.ATCACG
FRACTION="$2"      # e.g. 0.05
THREADS="${SLURM_CPUS_PER_TASK:-8}"

source "$(dirname "$0")/00_config.sh"

RAW=${RAW_BAM_DIR}/${CELL}.bam
OUT_TSV=${RESULTS_DIR}/${CELL}.f${FRACTION}.tsv
[[ -f "$RAW" ]] || { echo "ERROR: raw bam missing: $RAW" >&2; exit 1; }

# Idempotent: skip if already done (Pipeline Resume rule)
if [[ -s "$OUT_TSV" ]]; then echo "SKIP (done): $OUT_TSV"; exit 0; fi

WD=${WORK_DIR}/${CELL}.f${FRACTION}
rm -rf "$WD"; mkdir -p "$WD"; cd "$WD"
trap 'rm -rf "$WD"' EXIT   # always clean scratch BAMs

# samtools -s takes FLOAT seed.fraction. Build "42.05", "42.1", ... from FRACTION.
SARG="${SEED}${FRACTION#0}"

echo "[$(date +%T)] $CELL f=$FRACTION  -s $SARG  threads=$THREADS"

# ---- 1. subsample read pairs from the pre-dedup BAM ----
samtools view -@ "$THREADS" -b -s "$SARG" "$RAW" > sub.bam

# ---- 2. bamprocess: re-mark duplicates at this depth, calmd, name-sort ----
samtools sort   -@ "$THREADS" -T sub.tmp -n sub.bam | \
samtools fixmate -m -@ "$THREADS" - - | \
samtools sort   -@ "$THREADS" -T sub.cor - | \
samtools markdup -T sub.mdups -@ "$THREADS" - - | \
samtools calmd  -@ "$THREADS" -b - "${REFERENCE}.fa" 2>/dev/null > calmd.bam
samtools index -@ "$THREADS" calmd.bam
samtools sort  -@ "$THREADS" -n -o name_sorted.calmd.bam calmd.bam

# ---- 3. contact metrics (dedup-aware, from mh_reads_summary) ----
python "$MH_SUMMARY" --in_cram name_sorted.calmd.bam --out_summary summary.txt 2> mh.log
TOTAL=$(awk -F'\t' '$1=="TotalFragments:"{print $2}'                summary.txt)
MAPQ30=$(awk -F'\t' '$1=="UniqMappedMapQ30:"{print $2}'             summary.txt)
NODUP=$(awk -F'\t' '$1=="UniqMappedMapQ30NoPcr:"{print $2}'          summary.txt)
CIS=$(awk -F'\t' '$1=="UniqMappedMapQ30NoPcrCis:"{print $2}'         summary.txt)
CIS1KB=$(awk -F'\t' '$1=="UniqMappedMapQ30NoPcrCisMore1kb:"{print $2}' summary.txt)

# ---- 4. methylation loci (Bis-SNP), count detected GCH / HCG positions ----
module load "$JAVA8_MODULE" 2>/dev/null || true
export BISTOOLS
perl "$BISSNP_USAGE" --prefix "$CELL" --mem "$BISSNP_MEM_GB" \
     "$BISSNP_JAR" "${WD}/calmd.bam" "${REFERENCE}.fa" "$VARIANTS" > bissnp.log 2>&1

# 6plus2 beds carry one header line; subtract it.
GCH_BED=$(ls *GCH.6plus2.bed 2>/dev/null | grep -v strand | head -1 || true)
HCG_BED=$(ls *HCG.6plus2.bed 2>/dev/null | grep -v strand | head -1 || true)
count_loci () { [[ -s "$1" ]] && echo $(( $(wc -l < "$1") - 1 )) || echo NA; }
GCH=$(count_loci "$GCH_BED")
HCG=$(count_loci "$HCG_BED")

# ---- 5. write result line ----
mkdir -p "$RESULTS_DIR"
printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
  "$CELL" "$FRACTION" "$SEED" "$TOTAL" "$MAPQ30" "$NODUP" "$CIS" "$CIS1KB" "$GCH" "$HCG" \
  > "$OUT_TSV"

echo "[$(date +%T)] DONE $CELL f=$FRACTION  cis=$CIS cis1kb=$CIS1KB GCH=$GCH HCG=$HCG"
