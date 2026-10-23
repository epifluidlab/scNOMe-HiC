#!/usr/bin/env bash
# Download DNase signal bigWigs (3 bioreps) + snATAC aggregate BAM from ENCODE
# via the direct public-S3 HTTPS endpoints (much faster than the @@download redirect).
# Size-aware: skips files already fully present; resumes partial ones.
# --- repo paths: edit paths.yaml at the repository root, not this file -------
_r="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]:-$0}")")" && pwd)"
while [ "$_r" != "/" ] && [ ! -f "$_r/paths.sh" ]; do _r="$(dirname "$_r")"; done
source "$_r/paths.sh"

set -euo pipefail
DATA=${WORK_ROOT}/analysis/s2_new/atac_dnase_gm12878/data
cd "$DATA"

declare -A URL=(
  [ENCFF126OKI.bigWig]="https://encode-public.s3.amazonaws.com/2025/10/01/8bf447b6-c0e3-4f9f-961b-1bbc1a6869cc/ENCFF126OKI.bigWig"
  [ENCFF473TWJ.bigWig]="https://encode-public.s3.amazonaws.com/2025/10/01/475cefb4-e165-4613-9d6a-f0209f5e19c2/ENCFF473TWJ.bigWig"
  [ENCFF594DFV.bigWig]="https://encode-public.s3.amazonaws.com/2025/10/01/c94b2a89-0ed9-455f-b332-70215833f457/ENCFF594DFV.bigWig"
  [ENCFF995ATT.bam]="https://encode-public.s3.amazonaws.com/2021/12/16/75e424b1-a568-4868-917f-eb2d949fb144/ENCFF995ATT.bam"
)

for f in ENCFF126OKI.bigWig ENCFF473TWJ.bigWig ENCFF594DFV.bigWig ENCFF995ATT.bam; do
  url="${URL[$f]}"
  remote=$(curl -sI "$url" | awk 'BEGIN{IGNORECASE=1}/^content-length:/{gsub(/\r/,"");print $2}' | tail -1)
  local=0; [[ -f "$f" ]] && local=$(stat -c %s "$f")
  if [[ -n "$remote" && "$local" == "$remote" ]]; then
    echo "[$(date +%T)] skip $f (complete: $local bytes)"; continue
  fi
  echo "[$(date +%T)] downloading $f (local=$local remote=${remote:-?})"
  curl -sS --retry 8 --retry-delay 5 --retry-all-errors -C - -o "$f" "$url"
  echo "[$(date +%T)] done $f ($(du -h "$f" | cut -f1))"
done

echo "[$(date +%T)] ALL DOWNLOADS COMPLETE"
ls -la "$DATA"/*.bigWig "$DATA"/*.bam
