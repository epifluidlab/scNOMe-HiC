#!/usr/bin/env bash
# Merge the 3 DNase bioreps (FDR0.01): union peaks + averaged signal bigWig.
set -euo pipefail
BASE=/gpfs/projects/b1198/epifluidlab/yoshii/scnomehic_paper/s2_new/atac_dnase_gm12878
DATA="$BASE/data"
CHROM=/gpfs/projects/b1198/epifluidlab/yoshii/reference/hg38/autosomes.chrom.sizes
THREADS="${THREADS:-8}"
cd "$DATA"

PEAKS=(ENCFF486VDW ENCFF647XPG ENCFF384OTX)     # br1 br2 br3, FDR0.01
BWS=(ENCFF126OKI ENCFF473TWJ ENCFF594DFV)       # br1 br2 br3 read-depth normalized signal

cut -f1 "$CHROM" | sort > autosomes.list

# ---- union peaks (autosomes only), header stripped ----
: > peaks.union.raw.bed
for p in "${PEAKS[@]}"; do
  zcat "$p.bed.gz" | grep -v '^#' | cut -f1-3 >> peaks.union.raw.bed
done
awk 'NR==FNR{a[$1]=1;next} ($1 in a)' autosomes.list peaks.union.raw.bed \
  | LC_ALL=C sort -k1,1 -k2,2n \
  | bedtools merge -i - > dnase_peaks.merged.bed
echo "[merge] union+merged consensus peaks: $(wc -l < dnase_peaks.merged.bed)"

# ---- averaged signal bigWig for ranking ----
bigwigAverage -b "${BWS[0]}.bigWig" "${BWS[1]}.bigWig" "${BWS[2]}.bigWig" \
  --binSize 25 -p "$THREADS" -o dnase.mean.bw
echo "[merge] wrote dnase.mean.bw"
bigWigInfo dnase.mean.bw | sed -n '1,8p'
