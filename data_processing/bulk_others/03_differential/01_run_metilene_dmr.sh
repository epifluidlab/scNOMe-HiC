#!/bin/bash
#SBATCH -A b1042
#SBATCH -p genomics
#SBATCH -t 08:00:00
#SBATCH -N 1
#SBATCH --mem=64G
#SBATCH --cpus-per-task=8
#SBATCH --job-name=metilene_dmr
#SBATCH --output=logs/metilene_dmr.%j.out
#SBATCH --error=logs/metilene_dmr.%j.err

# De-novo DMR calling on bulk WGBS (HCG context) GM12878 vs IMR90 with metilene.
# GM12878 = group A (2 WGBS reps), IMR90 = group B (1 rep). HCG = NOMe-HiC-comparable.
#
# Pipeline:
#   1) per-sample bedgraphs (chr,start,end,beta) from *.HCG.bed (beta = percent/100),
#      main chroms (chr1-22,X), sorted -k1,1 -k2,2n
#   2) metilene_input.pl -> merged sorted input matrix (bedtools unionbedg)
#   3) metilene de-novo (-f 1), FDR (-c 2), -X 1 -Y 1 for the 2-vs-1 design
#   4) metilene_output.pl -> q<0.05 filtered DMR bed + stats pdf
# Intermediates on /scratch (large, regenerable); final DMRs on gpfs analysis/.

# --- repo paths: edit paths.yaml at the repository root, not this file -------
_r="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]:-$0}")")" && pwd)"
while [ "$_r" != "/" ] && [ ! -f "$_r/paths.sh" ]; do _r="$(dirname "$_r")"; done
source "$_r/paths.sh"

set -eo pipefail
source ${CONDA_SH}
conda activate scnomehic   # bedtools, perl, R+ggplot2; metilene on PATH (yaping/software)
set -u

MET=${SOFTWARE_ROOT}/metilene
FIG2=${WORK_ROOT}/analysis/fig2
B=$FIG2/data/bulk
OUT=$FIG2/analysis/dmr_metilene_hcg
WORK=${TMP_ROOT}/metilene_work
cd "$FIG2"; mkdir -p "$OUT" logs "$WORK"
export TMPDIR="$WORK/tmp"; mkdir -p "$TMPDIR"

echo "=== $(date) | host $(hostname) | metilene $($MET/metilene 2>&1 | head -1) ==="

# 1) per-sample bedgraphs (resume: skip if present & non-empty)
mk_bg () {  # <in.HCG.bed> <out.bg>
  if [[ -s "$2" ]]; then echo "[bg] exists: $2"; return; fi
  echo "[bg] building $2"
  awk 'BEGIN{OFS="\t"} $1 ~ /^chr([1-9]|1[0-9]|2[0-2]|X)$/ {print $1,$2,$3,$11/100}' "$1" \
    | sort -k1,1 -k2,2n -S 6G --parallel=8 -T "$TMPDIR" > "$2"
}
mk_bg "$B/GM12878/methylation/ENCFF529CNU.HCG.bed" "$WORK/GM12878_rep1.bg"
mk_bg "$B/GM12878/methylation/ENCFF866WCV.HCG.bed" "$WORK/GM12878_rep2.bg"
mk_bg "$B/IMR90/methylation/ENCFF591PKF.HCG.bed"   "$WORK/IMR90_rep1.bg"

# 2) metilene input matrix (bedtools unionbedg via metilene_input.pl)
INPUT="$WORK/metilene_GM12878_IMR90.input"
if [[ -s "$INPUT" ]]; then
  echo "[input] exists: $INPUT"
else
  echo "[input] metilene_input.pl ..."
  perl "$MET/metilene_input.pl" \
    --in1 "$WORK/GM12878_rep1.bg,$WORK/GM12878_rep2.bg" \
    --in2 "$WORK/IMR90_rep1.bg" \
    --h1 GM12878 --h2 IMR90 \
    --out "$INPUT"
fi
echo "[input] header:"; head -1 "$INPUT"
echo "[input] rows: $(wc -l < "$INPUT")"

# 3) metilene de-novo DMRs (FDR), sorted
DMR="$OUT/metilene_GM12878_IMR90.dmr.txt"
echo "[metilene] de-novo, FDR, -M 300 -m 10 -d 0.1 -X 1 -Y 1 -t 8 ..."
"$MET/metilene" -a GM12878 -b IMR90 -f 1 -c 2 -M 300 -m 10 -d 0.1 -X 1 -Y 1 -t 8 \
  "$INPUT" | sort -V -k1,1 -k2,2n > "$DMR"
echo "[metilene] raw DMRs: $(wc -l < "$DMR")  -> $DMR"

# 4) filter (q<0.05, >=10 CpGs, >=0.1 diff) + stats pdf
perl "$MET/metilene_output.pl" -q "$DMR" \
  -o "$OUT/metilene_GM12878_IMR90_qval0.05" -p 0.05 -c 10 -d 0.1 \
  -a GM12878 -b IMR90
echo "[output] filtered:"; ls -la "$OUT"/metilene_GM12878_IMR90_qval0.05* 2>/dev/null

echo "=== done $(date) ==="
