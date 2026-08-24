#!/bin/bash
# 04_extract_full_depth.sh — f=1.0 point from EXISTING pipeline outputs (no recompute).
# Reads {cell}.summary.txt.gz for contacts and the existing GCH/HCG 6plus2 beds
# for loci, writing results/{cell}.f1.0.tsv in the same schema as 02_run_one.sh.
# Light enough to run on a login node, or `sbatch` it (see header in README).
set -euo pipefail
source "$(dirname "$0")/00_config.sh"
mkdir -p "$RESULTS_DIR"

while read -r CELL; do
  [[ -z "$CELL" ]] && continue
  OUT=${RESULTS_DIR}/${CELL}.f1.0.tsv
  [[ -s "$OUT" ]] && { echo "SKIP $CELL"; continue; }

  SUM=${RAW_BAM_DIR}/${CELL}.summary.txt.gz
  # MUST use the '.cyt.filtered.sort.' beds (current pipeline = same method as the
  # fractional recompute). The dir also holds OLDER '.calmd.cytosine.filtered.sort.'
  # beds (more heavily filtered, ~2x fewer loci) which a bare *.GCH glob would pick
  # first alphabetically — that caused the f=1.0 methylation discontinuity.
  GCHB=$(ls ${METHYL_DIR}/${CELL}/*.cyt.filtered.sort.GCH.6plus2.bed.gz 2>/dev/null | grep -v strand | head -1 || true)
  HCGB=$(ls ${METHYL_DIR}/${CELL}/*.cyt.filtered.sort.HCG.6plus2.bed.gz 2>/dev/null | grep -v strand | head -1 || true)
  if [[ ! -s "$SUM" || -z "$GCHB" || -z "$HCGB" ]]; then
    echo "WARN missing inputs for $CELL (sum=$SUM gch=$GCHB hcg=$HCGB)" >&2; continue
  fi

  TOTAL=$(zcat "$SUM" | awk -F'\t' '$1=="TotalFragments:"{print $2}')
  MAPQ30=$(zcat "$SUM" | awk -F'\t' '$1=="UniqMappedMapQ30:"{print $2}')
  NODUP=$(zcat "$SUM" | awk -F'\t' '$1=="UniqMappedMapQ30NoPcr:"{print $2}')
  CIS=$(zcat "$SUM" | awk -F'\t' '$1=="UniqMappedMapQ30NoPcrCis:"{print $2}')
  CIS1KB=$(zcat "$SUM" | awk -F'\t' '$1=="UniqMappedMapQ30NoPcrCisMore1kb:"{print $2}')
  GCH=$(( $(zcat "$GCHB" | wc -l) - 1 ))
  HCG=$(( $(zcat "$HCGB" | wc -l) - 1 ))

  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
    "$CELL" "1.0" "$SEED" "$TOTAL" "$MAPQ30" "$NODUP" "$CIS" "$CIS1KB" "$GCH" "$HCG" > "$OUT"
  echo "DONE $CELL  cis=$CIS cis1kb=$CIS1KB GCH=$GCH HCG=$HCG"
done < "$CELLS_FILE"
