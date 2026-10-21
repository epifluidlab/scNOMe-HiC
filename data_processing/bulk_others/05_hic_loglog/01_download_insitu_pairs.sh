#!/bin/bash
# Download ENCODE in-situ Hi-C GM12878 read-pair (.pairs) file for HOMER HiCsummary.
# ENCFF447ERX: pairs, GRCh38, ~115 GB, from the mapping-quality-thresholded GM12878 in-situ Hi-C dataset.
# Used as the read-level source (analog of the NOMe-HiC *.short.sorted.txt.gz files).
set -euo pipefail
OUTDIR=/scratch/jmj7858/scnomehic/insitu_hic/pairs
mkdir -p "$OUTDIR"
cd "$OUTDIR"
URL="https://www.encodeproject.org/files/ENCFF447ERX/@@download/ENCFF447ERX.pairs.gz"
echo "[start] $(date) downloading $URL"
# -c resume; ENCODE @@download issues a fresh signed S3 redirect each attempt.
wget -c --tries=20 --waitretry=30 --read-timeout=120 -O ENCFF447ERX.pairs.gz "$URL"
echo "[done] $(date)"
ls -la ENCFF447ERX.pairs.gz
