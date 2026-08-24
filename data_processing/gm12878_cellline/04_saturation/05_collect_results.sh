#!/bin/bash
# 05_collect_results.sh — concatenate all per-(cell,fraction) result lines into one
# table with a header. Reports how many of the expected rows are present.
set -euo pipefail
source "$(dirname "$0")/00_config.sh"

OUT=${CODE_DIR}/saturation_results.tsv
printf 'cell\tfraction\tseed\ttotal_frags\tmapq30\tnodup\tcis\tcis_1kb\tGCH_loci\tHCG_loci\n' > "$OUT"
cat ${RESULTS_DIR}/*.tsv 2>/dev/null | sort -k1,1 -k2,2g >> "$OUT" || true

NCELLS=$(wc -l < "$CELLS_FILE")
NFRAC=$(( $(echo $FRACTIONS | wc -w) + 1 ))   # +1 for f=1.0
EXPECT=$(( NCELLS * NFRAC ))
HAVE=$(( $(wc -l < "$OUT") - 1 ))
echo "collected $HAVE / $EXPECT rows -> $OUT"
