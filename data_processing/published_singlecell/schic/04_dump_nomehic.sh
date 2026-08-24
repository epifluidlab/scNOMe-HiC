#!/bin/bash
# Step 04 — dump the scNOMe-HiC pseudobulk .hic (hg38) at EACH resolution in
# $RESLIST, per chromosome (juicer "observed NONE"), same recipe as
# gm_sc_new/hic_comparison/dump_2.5Mb.sh. .hic stores a standard resolution set
# from `juicer pre` (…2.5Mb,1Mb,500kb,250kb,100kb…), so 500kb/1Mb/2.5Mb are present.
set -euo pipefail
source "$(dirname "$0")/config.sh"
module load java/jdk-17.0.2+8 2>/dev/null || module load java 2>/dev/null || true

reslabel () { # bp -> label (matches 03_rebin_hg38.py: 500kb / 1Mb / 2.5Mb)
  local r=$1
  if   [ "$r" -lt 1000000 ];        then echo "$((r/1000))kb"
  elif [ $((r % 1000000)) -eq 0 ];  then echo "$((r/1000000))Mb"
  else awk -v r="$r" 'BEGIN{printf "%gMb", r/1000000}'
  fi
}

MOUT="$WORK/dump_multires"; mkdir -p "$MOUT"
COMPAT="$WORK/dump_2.5Mb";  mkdir -p "$COMPAT"

for RES in $RESLIST; do
  LAB=$(reslabel "$RES")
  echo "=== dump scNOMe-HiC @ $LAB ($RES bp) ==="
  for chr in {1..22} X; do
      CHR="chr${chr}"
      OUT="${MOUT}/nomehic_${LAB}_${CHR}.txt"
      java -jar "$JUICER" dump observed NONE "$NOMEHIC_HIC" $CHR $CHR BP $RES "$OUT"
      # backward-compat name for the 2.5 Mb step-05 script
      if [ "$RES" = "2500000" ]; then cp "$OUT" "${COMPAT}/nomehic_2.5Mb_${CHR}.txt"; fi
  done
  echo "  $LAB: chr1 -> $(wc -l < ${MOUT}/nomehic_${LAB}_chr1.txt) lines"
done
