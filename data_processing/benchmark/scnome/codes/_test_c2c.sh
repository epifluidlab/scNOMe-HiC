# conda on PATH; override with SCNOMEHIC_CONDA_SH for a different install.
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

source "${SCNOMEHIC_CONDA_SH:-${CONDA_SH}}"
conda activate scnomehic
set -o pipefail
cd ${WORK_ROOT}/benchmark/scnome
BIS=${REFERENCE_ROOT}/hg38_bismark/
METHY=05.methy
echo "[$(date)] c2c --nome-seq (no --CX) start"
coverage2cytosine --nome-seq --genome_folder "$BIS" --dir "$METHY" --gzip \
    -o SRR3729642_1 "$METHY/SRR3729642_1.rmdup.bismark.cov.gz"
echo "[$(date)] exit=$?"
echo "=== outputs ==="
ls -la $METHY/SRR3729642_1* | grep -iE "nome|gpc|cpg"
echo "TESTDONE"
