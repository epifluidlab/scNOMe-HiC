#!/bin/bash
#SBATCH --account=b1042
#SBATCH --partition=genomics
#SBATCH --job-name=insitu_step01_subsample_gm
#SBATCH --time=10:00:00
#SBATCH --mem=48G
#SBATCH --cpus-per-task=8
#SBATCH --output=/gpfs/projects/b1198/epifluidlab/yoshii/sc_nomehic_cellline/snakemake/APA/insitu/logs/%x_%j.out
#SBATCH --error=/gpfs/projects/b1198/epifluidlab/yoshii/sc_nomehic_cellline/snakemake/APA/insitu/logs/%x_%j.err
# STEP 01 (in-situ) — Subsample GM12878 in-situ Hi-C to IMR90 in-situ depth.
#
# Why p = 0.307?  chr1 250kb sum: GM=309,835,537 vs IMR=95,000,825.
# IMR / GM = 0.3066 => keep this fraction of GM contacts to match IMR depth.
# (Both files are already deduplicated by ENCODE, so we skip juicer pre -d.)
#
# Method:
#   1. Pull sparse pixels from GM .hic at 5 kb via hicstraw
#   2. For each pixel (binX, binY, count): new_count = Binomial(count, p)
#   3. Output to short-format text (one row per subsampled contact)
#   4. juicer pre (no -d) to rebuild the subsampled .hic
# --- repo paths: edit paths.yaml at the repository root, not this file -------
_r="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]:-$0}")")" && pwd)"
while [ "$_r" != "/" ] && [ ! -f "$_r/paths.sh" ]; do _r="$(dirname "$_r")"; done
source "$_r/paths.sh"

set -euo pipefail
module load java/jdk-17.0.2+8

mkdir -p /gpfs/projects/b1198/epifluidlab/yoshii/sc_nomehic_cellline/snakemake/APA/insitu/logs

P=0.307
SEED=42
PY=${CONDA_ENVS}/scnomehic/bin/python
JUICER=${SOFTWARE_ROOT}/juicer_tools.jar
GM_IN=/gpfs/projects/b1198/epifluidlab/yoshii/scnomehic_paper/fig1/data/bulk/hic/ENCFF555ISR.hic

OUT_DIR=/scratch/jmj7858/scnomehic/insitu_hic/gm_subsampled
mkdir -p "$OUT_DIR"

SUBSAMPLED_TXT=$OUT_DIR/GM_insitu.subsampled_p${P}.short.txt.gz
OUT_HIC=$OUT_DIR/GM_insitu.subsampled_p${P}.hic

echo "[$(date +%H:%M:%S)] STEP 1a -- Binomial subsample at the pixel level"
if [ ! -s "$SUBSAMPLED_TXT" ] || ! gzip -t "$SUBSAMPLED_TXT" 2>/dev/null; then
  $PY /gpfs/projects/b1198/epifluidlab/yoshii/sc_nomehic_cellline/snakemake/APA/insitu/subsample_hic.py \
      --hic "$GM_IN" \
      --out-gz "$SUBSAMPLED_TXT" \
      --p $P --seed $SEED --resolution 5000 --chrom-prefix chr
  echo "[$(date +%H:%M:%S)] subsampled text: $(ls -la $SUBSAMPLED_TXT | awk '{print $5}') bytes"
  gzip -t "$SUBSAMPLED_TXT"
else
  echo "[$(date +%H:%M:%S)] subsampled text already exists and valid, skipping"
fi

echo "[$(date +%H:%M:%S)] STEP 1b -- juicer pre to build .hic (no -d, already deduplicated)"
java -Xmx44G -jar "$JUICER" pre \
    -r 5000,10000,25000,50000,100000,250000 \
    "$SUBSAMPLED_TXT" \
    "$OUT_HIC" \
    hg38

echo "[$(date +%H:%M:%S)] STEP 1c -- depth sanity check"
java -jar "$JUICER" dump observed NONE "$OUT_HIC" chr1 chr1 BP 250000 /tmp/gm_sub_chr1.txt 2>&1 | tail -3
n=$(wc -l < /tmp/gm_sub_chr1.txt)
s=$(awk '{s+=$3} END {print s}' /tmp/gm_sub_chr1.txt)
echo "  GM-subsampled chr1 250kb: $n bin-pairs, sum $s"
echo "  Target (IMR in-situ chr1 250kb): 404713 / 95000825"

echo "[$(date +%H:%M:%S)] done"
ls -la "$OUT_DIR"
