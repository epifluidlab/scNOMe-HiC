#!/bin/bash
#SBATCH --account=b1042
#SBATCH --partition=genomics-gpu
#SBATCH --gres=gpu:a100:1
#SBATCH --job-name=insitu_step04_hiccupsdiff
#SBATCH --time=12:00:00
#SBATCH --mem=128G
#SBATCH --cpus-per-task=8
#SBATCH --output=${WORK_ROOT}/mixture_cellline/APA/insitu/logs/%x_%j.out
#SBATCH --error=${WORK_ROOT}/mixture_cellline/APA/insitu/logs/%x_%j.err
# STEP 04 (in-situ) -- juicer hiccupsdiff, rerun after the 2026-08-24 scratch purge.
#
# This supersedes an earlier hiccupsdiff wrapper, with two fixes:
#   1. The loop lists now come from the GPFS copies in data/loops/ (the /scratch originals
#      were purged). These are the 02/03 HICCUPS outputs and are unchanged.
#   2. The differential bedpes are copied to GPFS at the end, so the next purge cannot
#      destroy the result again. Only the small bedpes are copied -- the .hic files stay
#      on /scratch because GPFS is at 98%.
#
# Unlike set-difference on caller output (scripts/diff_loops.py), hiccupsdiff works on the
# two .hic files directly and, for each loop in either list, tests whether contact frequency
# actually differs -- with FDR. It is both a real statistical test AND independent of the
# sc data, which set-difference and the sc ANOVA respectively are not.
#
# Previous run (job 4630253, 2026-06-15, ~6 h) produced 516 / 968 differential loops.
# --- repo paths: edit paths.yaml at the repository root, not this file -------
_r="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]:-$0}")")" && pwd)"
while [ "$_r" != "/" ] && [ ! -f "$_r/paths.sh" ]; do _r="$(dirname "$_r")"; done
source "$_r/paths.sh"

set -eo pipefail

source ~/.bashrc
module load java/jdk-17.0.2+8
module load cuda/11.3.1-gcc-10.4.0
module load gcc/10.4.0-gcc-4.8.5

BASE=${WORK_ROOT}/mixture_cellline/APA/insitu
JUICER=${SOFTWARE_ROOT}/juicer_tools.jar  # 2.20 needed for v9 hic

HIC_GM=${TMP_ROOT}/insitu_hic/gm_subsampled/GM_insitu.subsampled_p0.307.hic
HIC_IMR=${TMP_ROOT}/insitu_hic/ENCFF188SSH_IMR90_insitu.hic

# Loop lists: GPFS copies, not the purged /scratch originals
LOOPS_GM=$BASE/data/loops/gm_insitu_sub_hiccups_25kb_loops/merged_loops.bedpe
LOOPS_IMR=$BASE/data/loops/imr_insitu_hiccups_25kb_loops/merged_loops.bedpe

# FDR for the internal HICCUPS scans. Default 0.1 reproduces the original run.
# Set HICCUPSDIFF_FDR=0.01 for the stricter version; outputs go to their own dirs so
# the two never clobber each other.
FDR=${HICCUPSDIFF_FDR:-0.1}
SFX=""
if [ "$FDR" != "0.1" ]; then SFX="_fdr${FDR}"; fi

OUT=${TMP_ROOT}/insitu_hic/hiccupsdiff_25kb${SFX}
GPFS_OUT=$BASE/data/loops/hiccupsdiff_25kb${SFX}

for f in "$HIC_GM" "$HIC_IMR" "$LOOPS_GM" "$LOOPS_IMR"; do
    if [ ! -s "$f" ]; then
        echo "ERROR: required input missing or empty: $f"
        exit 1
    fi
done

mkdir -p "$OUT"
echo "[$(date +%H:%M:%S)] hiccupsdiff GM-sub vs IMR (both in-situ) @25kb"
echo "  GM  hic  : $HIC_GM"
echo "  IMR hic  : $HIC_IMR"
echo "  GM loops : $(grep -vc '^#' $LOOPS_GM) ($LOOPS_GM)"
echo "  IMR loops: $(grep -vc '^#' $LOOPS_IMR) ($LOOPS_IMR)"
echo "  out      : $OUT"
echo "  FDR      : $FDR"
nvidia-smi 2>&1 | head -10 || true

# -k SCALE: KR is not precomputed at 25 kb for these in-situ files.
# Same params as HICCUPS in steps 02/03 so the comparison stays consistent.
java -Xmx112G -jar "$JUICER" hiccupsdiff \
    -c 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,X \
    -k SCALE \
    -m 128 \
    -f $FDR -p 1 -i 3 -t 0.02,1.5,1.75,2 -d 50000 \
    "$HIC_GM" "$HIC_IMR" \
    "$LOOPS_GM" "$LOOPS_IMR" \
    "$OUT"

echo
echo "[$(date +%H:%M:%S)] hiccupsdiff finished"
ls -la "$OUT"
echo
echo "loops per bedpe:"
for f in "$OUT"/*.bedpe; do
    [ -e "$f" ] && printf "  %-40s %s\n" "$(basename $f)" "$(grep -vc '^#' $f)"
done

# --- persist the result to GPFS ---
# differential_loops1 = GM12878-specific, differential_loops2 = IMR90-specific
echo
echo "[$(date +%H:%M:%S)] copying differential bedpes to GPFS"
mkdir -p "$GPFS_OUT"
cp -v "$OUT"/differential_loops1.bedpe "$GPFS_OUT"/GM12878_specific_hiccupsdiff.bedpe
cp -v "$OUT"/differential_loops2.bedpe "$GPFS_OUT"/IMR90_specific_hiccupsdiff.bedpe
cmp "$OUT"/differential_loops1.bedpe "$GPFS_OUT"/GM12878_specific_hiccupsdiff.bedpe
cmp "$OUT"/differential_loops2.bedpe "$GPFS_OUT"/IMR90_specific_hiccupsdiff.bedpe
# the per-file HICCUPS detail is what makes a true differential magnitude recoverable
mkdir -p "$GPFS_OUT"/file1 "$GPFS_OUT"/file2
cp -v "$OUT"/file1/requested_list_25000.bedpe "$GPFS_OUT"/file1/
cp -v "$OUT"/file2/requested_list_25000.bedpe "$GPFS_OUT"/file2/
cp -v "$OUT"/file1/merged_loops.bedpe "$GPFS_OUT"/file1/
cp -v "$OUT"/file2/merged_loops.bedpe "$GPFS_OUT"/file2/
echo "  verified byte-for-byte"
ls -la "$GPFS_OUT"

echo "[$(date +%H:%M:%S)] done"
