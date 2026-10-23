#!/bin/bash
# Download ENCODE in-situ Hi-C GM12878 read-pair (.pairs) file for HOMER HiCsummary.
# ENCFF447ERX: pairs, GRCh38, ~115 GB, from the mapping-quality-thresholded GM12878 in-situ Hi-C dataset.
# Used as the read-level source (analog of the NOMe-HiC *.short.sorted.txt.gz files).
# --- repo paths: edit paths.yaml at the repository root, not this file -------
_r="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]:-$0}")")" && pwd)"
while [ "$_r" != "/" ] && [ ! -f "$_r/paths.sh" ]; do _r="$(dirname "$_r")"; done
source "$_r/paths.sh"

set -euo pipefail
OUTDIR=${TMP_ROOT}/insitu_hic/pairs
mkdir -p "$OUTDIR"
cd "$OUTDIR"
URL="https://www.encodeproject.org/files/ENCFF447ERX/@@download/ENCFF447ERX.pairs.gz"
echo "[start] $(date) downloading $URL"
# -c resume; ENCODE @@download issues a fresh signed S3 redirect each attempt.
wget -c --tries=20 --waitretry=30 --read-timeout=120 -O ENCFF447ERX.pairs.gz "$URL"
echo "[done] $(date)"
ls -la ENCFF447ERX.pairs.gz
