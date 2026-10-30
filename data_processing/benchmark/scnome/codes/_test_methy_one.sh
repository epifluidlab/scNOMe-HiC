# --- repo paths: edit paths.yaml at the repository root, not this file -------
# SLURM copies a batch script to /var/spool/slurmd/<job>/slurm_script, so walking
# up from BASH_SOURCE cannot reach the repository. $SCNOMEHIC_REPO is tried first;
# submit with: sbatch --export=ALL,SCNOMEHIC_REPO=/path/to/repo
_r="${SCNOMEHIC_REPO:-}"
if [ -z "$_r" ] || [ ! -f "$_r/paths.sh" ]; then
    _r="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]:-$0}")")" && pwd)"
    while [ "$_r" != "/" ] && [ ! -f "$_r/paths.sh" ]; do _r="$(dirname "$_r")"; done
fi
[ -f "$_r/paths.sh" ] || { echo "ERROR: paths.sh not found. Set SCNOMEHIC_REPO to the repository root." >&2; exit 1; }
source "$_r/paths.sh"

set -uo pipefail
# conda on PATH; override with SCNOMEHIC_CONDA_SH for a different install.
source "${SCNOMEHIC_CONDA_SH:-${CONDA_SH}}"
conda activate scnomehic
cd ${WORK_ROOT}/benchmark/scnome
BIS=${REFERENCE_ROOT}/hg38_bismark/
METHY=05.methy
bam=04.alignment/SRR3729670_1.rmdup.bam
echo "[$(date)] step1 extractor start"
bismark_methylation_extractor -s --ignore 6 --comprehensive --multicore 4 \
    --bedGraph --CX --genome_folder "$BIS" -o "$METHY" "$bam"
echo "[$(date)] step1 done; cov:"
ls -la $METHY/SRR3729670_1.rmdup.bismark.cov.gz
echo "[$(date)] step2 coverage2cytosine --nome-seq start"
coverage2cytosine --nome-seq --CX --genome_folder "$BIS" --dir "$METHY" --gzip \
    -o SRR3729670_1 "$METHY/SRR3729670_1.rmdup.bismark.cov.gz"
echo "[$(date)] step2 done. NOMe outputs:"
ls -la $METHY/SRR3729670_1*NOMe* 2>/dev/null
echo "TESTDONE"
