#!/usr/bin/env bash
# Build a pseudobulk snATAC coverage bigWig from the ENCODE aggregate BAM.
set -euo pipefail
BASE=/gpfs/projects/b1198/epifluidlab/yoshii/scnomehic_paper/s2_new/atac_dnase_gm12878
DATA="$BASE/data"
THREADS="${THREADS:-8}"
BAM="$DATA/ENCFF995ATT.bam"
cd "$DATA"

[[ -s "$BAM" ]] || { echo "ERROR: BAM missing: $BAM"; exit 2; }

if [[ ! -s "$BAM.bai" ]]; then
  echo "[snatac] indexing BAM..."
  samtools index -@ "$THREADS" "$BAM"
fi

echo "[snatac] bamCoverage (CPM, bs25, ignore dups, MAPQ>=30)..."
bamCoverage -b "$BAM" -o snatac.cpm.bw \
  --normalizeUsing CPM \
  --binSize 25 \
  --minMappingQuality 30 \
  --ignoreDuplicates \
  -p "$THREADS"
echo "[snatac] wrote snatac.cpm.bw"
bigWigInfo snatac.cpm.bw | sed -n '1,8p'
