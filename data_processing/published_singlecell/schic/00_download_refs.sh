#!/bin/bash
# Download reference files needed for the hg19->hg38 liftOver of the Kim2020 sci-Hi-C
# matrices (which are hg19). Run on the LOGIN node (needs internet).
#   bash code/00_download_refs.sh
# --- repo paths: edit paths.yaml at the repository root, not this file -------
_r="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]:-$0}")")" && pwd)"
while [ "$_r" != "/" ] && [ ! -f "$_r/paths.sh" ]; do _r="$(dirname "$_r")"; done
source "$_r/paths.sh"

set -euo pipefail
ROOT=${WORK_ROOT}/analysis/s2_new/schic_gm12878
DATA=$ROOT/data
cd "$DATA"

# UCSC hg19->hg38 liftOver chain
if [ ! -s hg19ToHg38.over.chain.gz ]; then
  echo "[dl] hg19ToHg38.over.chain.gz"
  curl -sSL "https://hgdownload.soe.ucsc.edu/goldenPath/hg19/liftOver/hg19ToHg38.over.chain.gz" \
    -o hg19ToHg38.over.chain.gz
fi

# hg19 chrom sizes (to build the 500 kb global-bin layout)
if [ ! -s hg19.chrom.sizes ]; then
  echo "[dl] hg19.chrom.sizes"
  curl -sSL "https://hgdownload.soe.ucsc.edu/goldenPath/hg19/bigZips/hg19.chrom.sizes" \
    -o hg19.chrom.sizes
fi

echo "=== data/ ==="
ls -l "$DATA"
echo "chain lines:"; zcat hg19ToHg38.over.chain.gz | head -1
echo "hg19 main chroms:"; grep -E "^chr([0-9]+|X|Y)\s" hg19.chrom.sizes | sort -V | head -30
