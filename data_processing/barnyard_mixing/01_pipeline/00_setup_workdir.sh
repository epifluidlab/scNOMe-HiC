#!/bin/bash
# ============================================================================
# One-time setup for the GM_F123 (human GM12878 + mouse F123 mixing) scNOMe-HiC
# alignment run against the combined hg38_mm10 reference.
#
# Builds:
#   1. reference/hg38_mm10.DpnII.span_region.bedgraph  (Bhmem -enzymeList)
#   2. merged_trimmed/  symlinks to the 96 demultiplexed+trimmed cells
# ============================================================================
set -euo pipefail

# ---- paths: edit ../../../paths.yaml, not this file -------------------------
HERE="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
source "${HERE}/../../paths.sh"

WORKDIR="${WORK_ROOT}/barnyard_mixing"
COMBREF="${REFERENCE_ROOT}/hg38_mm10/hg38_mm10"
HG38_BG="${REFERENCE_ROOT}/hg38/GCA_000001405.15_GRCh38_no_alt_analysis_set.DpnII.span_region.bedgraph"
MM10_BG="${REFERENCE_ROOT}/mm10/dpnII.span_region.bedgraph"
# The 96 demultiplexed, trimmed GM_F123 cells. From GEO these arrive untrimmed,
# so run them through the normal trimming step first and point this at the
# result; the names the loop expects are {prefix}.{index}.R{1,2}_val_{1,2}.fq.gz.
SRC_FASTQ="${SRC_FASTQ:-${DATA_ROOT}/barnyard_mixing/03.trimmed_fastq_snakemake}"

mkdir -p "$WORKDIR"

cd "$WORKDIR"
mkdir -p reference merged_trimmed logs code

# ── 1. Combined DpnII span-region bedgraph ─────────────────────────────────
# Combined genome names human contigs `chr*` (unprefixed) and mouse contigs
# `mm10_chr*`. So: take hg38 bedgraph as-is, prefix the mm10 bedgraph's chrom
# with `mm10_`. Filter both to contigs that actually exist in the combined
# .fai so Bhmem never sees an unknown contig.
FAI="${COMBREF}.fa.fai"
OUT="${REFERENCE_ROOT}/hg38_mm10/hg38_mm10.DpnII.span_region.bedgraph"
mkdir -p "$(dirname "$OUT")"

# Set of valid combined-genome contig names.
cut -f1 "$FAI" | sort -u > "${WORKDIR}/.combined_contigs.txt"

# Human side: keep hg38 lines whose chrom is in the combined genome.
awk 'NR==FNR{ok[$1]=1; next} ($1 in ok)' \
    "${WORKDIR}/.combined_contigs.txt" "$HG38_BG" > "$OUT"

# Mouse side: prefix chrom with mm10_, keep only those in the combined genome.
awk 'NR==FNR{ok[$1]=1; next}{c="mm10_"$1; if(c in ok) print c"\t"$2"\t"$3}' \
    "${WORKDIR}/.combined_contigs.txt" "$MM10_BG" >> "$OUT"

rm -f "${WORKDIR}/.combined_contigs.txt"
echo "Enzyme list built: $OUT"
echo "  total intervals: $(wc -l < "$OUT")"
echo "  human intervals: $(grep -cvE '^mm10_' "$OUT" || true)"
echo "  mouse intervals: $(grep -cE  '^mm10_' "$OUT" || true)"

# ── 2. merged_trimmed symlinks ─────────────────────────────────────────────
# The source files are already named {prefix}.{index}.R{1,2}_val_{1,2}.fq.gz,
# exactly what the pipeline's trimmed-mode auto-discovery expects. Symlink to
# the real targets (source dir entries are themselves symlinks) so the names
# are stable.
n=0
for f in "$SRC_FASTQ"/*.R1_val_1.fq.gz "$SRC_FASTQ"/*.R2_val_2.fq.gz; do
    b=$(basename "$f")
    ln -sf "$f" "merged_trimmed/$b"
    n=$((n+1))
done
echo "Linked $n trimmed fastqs into merged_trimmed/"
echo "  cells (prefix.index pairs): $(ls merged_trimmed/*.R1_val_1.fq.gz | wc -l)"
