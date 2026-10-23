#!/bin/bash
#SBATCH -A b1042
#SBATCH -p genomics
#SBATCH -t 8:00:00
#SBATCH -N 1 -n 1 --cpus-per-task=8 --mem=32G
#SBATCH --job-name=snm3c_01_setup
#SBATCH --output=${WORK_ROOT}/benchmark/snm3c_100/logs/setup_%j.out
#SBATCH --error=${WORK_ROOT}/benchmark/snm3c_100/logs/setup_%j.out
#
# STEP 01 -- download+verify 100 cells, then ONE `yap start-from-cell-fastq`,
# which emits one Group (and one `snakemake -j 10` command) per cell.
# Step 02 runs those commands as a parallel array -- YAP's intended model.
# --- repo paths: edit paths.yaml at the repository root, not this file -------
_r="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]:-$0}")")" && pwd)"
while [ "$_r" != "/" ] && [ ! -f "$_r/paths.sh" ]; do _r="$(dirname "$_r")"; done
source "$_r/paths.sh"

set +u
source ${CONDA_SH}
conda activate mapping
export PATH="$CONDA_PREFIX/bin:$PATH"
W=${WORK_ROOT}/benchmark/snm3c_100
mkdir -p "$W/fastq" "$W/cell_fastq"; cd "$W" || exit 1

get_one () {
  acc="$1"; urls="$3"; W="$4"
  u1=${urls%%;*}; u2=${urls##*;}
  for a in 1 2 3; do
    [ -s "$W/fastq/${acc}_1.fastq.gz" ] || curl -s -L --max-time 1800 -o "$W/fastq/${acc}_1.fastq.gz" "https://$u1"
    [ -s "$W/fastq/${acc}_2.fastq.gz" ] || curl -s -L --max-time 1800 -o "$W/fastq/${acc}_2.fastq.gz" "https://$u2"
    gzip -t "$W/fastq/${acc}_1.fastq.gz" 2>/dev/null && gzip -t "$W/fastq/${acc}_2.fastq.gz" 2>/dev/null && return 0
    rm -f "$W/fastq/${acc}"_[12].fastq.gz
  done
  echo "  FAILED: $acc"; return 1
}
export -f get_one
echo "[$(date)] downloading 100 cells (8-way)"
awk -F'\t' '{print $1"\t"$2"\t"$3}' "$W/codes/cells100.tsv" \
  | xargs -P 8 -I{} bash -c 'IFS=$'"'"'\t'"'"' read -r a b c <<< "{}"; get_one "$a" "$b" "$c" "'"$W"'"'

echo "[$(date)] verifying + linking"
n=0
while IFS=$'\t' read -r acc rc urls; do
  [ -z "$acc" ] && continue
  if gzip -t "$W/fastq/${acc}_1.fastq.gz" 2>/dev/null && gzip -t "$W/fastq/${acc}_2.fastq.gz" 2>/dev/null; then
    ln -sf "$W/fastq/${acc}_1.fastq.gz" "$W/cell_fastq/${acc}-R1.fq.gz"
    ln -sf "$W/fastq/${acc}_2.fastq.gz" "$W/cell_fastq/${acc}-R2.fq.gz"
    n=$((n+1))
  else echo "  BAD: $acc"; fi
done < "$W/codes/cells100.tsv"
echo "[$(date)] gzip-verified cells: $n / 100"
[ "$n" -ge 90 ] || { echo "ERROR: only $n cells usable, aborting"; exit 1; }

yap start-from-cell-fastq --output_dir "$W/alignment" \
    --config_path "$W/codes/mapping_config.ini" \
    --fastq_pattern "$W/cell_fastq/*-R[12].fq.gz" || { echo "yap setup failed"; exit 1; }
CMD=$W/alignment/snakemake/snakemake_cmd.txt
N=$(grep -cve '^[[:space:]]*$' "$CMD")
echo "[$(date)] YAP groups (= parallel tasks): $N"
grep -cve '^[[:space:]]*$' "$CMD" > "$W/codes/ncmds.txt"
echo "[$(date)] SETUP DONE"
