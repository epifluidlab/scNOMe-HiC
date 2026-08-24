#!/bin/bash
# Extract per-cell human vs mouse read counts for all 96 GM_F123 cells, from the
# combined hg38_mm10 alignments. Runs _species_worker.sh (sibling) over every
# {cell}.calmd.bam in parallel and writes species_read_counts.tsv.
set -euo pipefail

WORKDIR=/gpfs/projects/b1198/epifluidlab/yoshii/scnomehic_paper/s3/snakemake
cd "$WORKDIR"
ALN=04.alignment_snakemake
OUT=species_read_counts.tsv
HERE="$(dirname "$(readlink -f "$0")")"
export HERE

tmpd="$(mktemp -d)"
export TMPD="$tmpd"

# Only the primary coordinate-sorted calmd.bam (exclude _sorted_by_name.calmd.bam).
ls "$ALN"/*.calmd.bam | grep -vE '_sorted_by_name' \
  | xargs -P 12 -I{} bash -c 'b="$1"; bash "$HERE/_species_worker.sh" "$b" > "$TMPD/$(basename "$b")"' _ {}

printf "cell\thuman_hq_reads\tmouse_hq_reads\thuman_all_reads\tmouse_all_reads\n" > "$OUT"
cat "$tmpd"/* | sort >> "$OUT"
rm -rf "$tmpd"

echo "Wrote $OUT ($(($(wc -l < "$OUT") - 1)) cells)"
column -t "$OUT" | head -6
