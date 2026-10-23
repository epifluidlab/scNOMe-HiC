#!/bin/bash
# STEP 01 — Build cell_table.tsv with dot IDs and verify all 441 source
# .hic_matrix.txt.gz files exist in the snakemake output.
# No symlinks — step02 derives the underscore-format source path directly.
# --- repo paths: edit paths.yaml at the repository root, not this file -------
_r="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]:-$0}")")" && pwd)"
while [ "$_r" != "/" ] && [ ! -f "$_r/paths.sh" ]; do _r="$(dirname "$_r")"; done
source "$_r/paths.sh"

set -euo pipefail

THIS_DIR=$(dirname "$(readlink -f "$0")")
SRC_TABLE=${WORK_ROOT}/mixture_cellline/subset_clustering/250kb/annotation/cell_type_table.tsv
SRC_HIC_DIR=${WORK_ROOT}/mixture_cellline/06.hiccluster_snakemake
OUT_TABLE=$THIS_DIR/cell_table.tsv

echo "=== build cell_table.tsv with dot IDs ==="
# Replace just the FIRST underscore with a dot in column 1
# Also rename header column "cell" -> "cell_id" (required by make_celltype_cool.py)
awk 'BEGIN{OFS="\t"} NR==1 { $1="cell_id"; print; next } { sub(/_/, ".", $1); print }' "$SRC_TABLE" > "$OUT_TABLE"

n_cells=$(tail -n+2 "$OUT_TABLE" | wc -l)
echo "Cells: $n_cells"
echo "Per type:"
tail -n+2 "$OUT_TABLE" | cut -f2 | sort | uniq -c

echo
echo "=== verify all per-cell .hic_matrix.txt.gz exist at source ==="
# We use the SLIM tab-delim 7-col .hic_matrix.txt.gz (schicluster-compatible),
# NOT the wide space-delim 16-col .hic.txt.gz (for the read-level analyses).
missing=0
while IFS=$'\t' read -r dot_id celltype; do
    # convert dot ID back to underscore for snakemake naming
    underscore_id="${dot_id/./_}"
    src="$SRC_HIC_DIR/${underscore_id}.hic_matrix.txt.gz"
    if [ ! -e "$src" ]; then
        echo "  MISSING: $dot_id -> $src" >&2
        missing=$((missing+1))
    fi
done < <(tail -n+2 "$OUT_TABLE")

if [ $missing -eq 0 ]; then
    echo "All $n_cells cells have source files. Ready for step02."
else
    echo
    echo "WARNING: $missing cells are missing source files. step02 will skip them."
fi
