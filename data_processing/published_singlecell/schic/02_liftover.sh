#!/bin/bash
# Step 02 — liftOver the unique 500 kb bin-midpoint anchors from hg19 to hg38.
set -euo pipefail
source "$(dirname "$0")/config.sh"
cd "$WORK"
echo "[liftOver] anchors_hg19.bed -> anchors_hg38.bed"
"$LIFTOVER" anchors_hg19.bed "$CHAIN" anchors_hg38.bed anchors_unmapped.bed
echo "  mapped   : $(wc -l < anchors_hg38.bed)"
echo "  unmapped : $(grep -vc '^#' anchors_unmapped.bed || true)"
