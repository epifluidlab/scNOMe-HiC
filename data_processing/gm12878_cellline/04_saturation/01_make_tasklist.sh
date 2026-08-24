#!/bin/bash
# 01_make_tasklist.sh — write tasks.tsv: one "CELL<TAB>FRACTION" line per array task.
set -euo pipefail
source "$(dirname "$0")/00_config.sh"

OUT=${CODE_DIR}/tasks.tsv
: > "$OUT"
while read -r CELL; do
  [[ -z "$CELL" ]] && continue
  for F in $FRACTIONS; do
    printf '%s\t%s\n' "$CELL" "$F" >> "$OUT"
  done
done < "$CELLS_FILE"

N=$(wc -l < "$OUT")
echo "wrote $OUT with $N tasks ($(wc -l < "$CELLS_FILE") cells x $(echo $FRACTIONS | wc -w) fractions)"
