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

python extract_trinuc.py --folder ${WORK_ROOT}/benchmark/scnome/04.alignment/ --suffix .rmdup.RG.trinuc_methy.chr21.txt --output ${WORK_ROOT}/benchmark/summary/trinuc/scnome.chr21.txt
python extract_trinuc.py --folder ${WORK_ROOT}/benchmark/smallwood/05.align_mm10/ --suffix .rmdup.RG.trinuc_methy.chr19.txt --output ${WORK_ROOT}/benchmark/summary/trinuc/smallwood.chr21.txt
python extract_trinuc.py --folder ${WORK_ROOT}/benchmark/snmCseq3/04.bhmem_bam/ --suffix .calmd.trinuc_methy.chr19.txt --output ${WORK_ROOT}/benchmark/summary/trinuc/snmCseq3.chr21.txt
python extract_trinuc.py --folder ${WORK_ROOT}/benchmark/snmCseq2/05.align/ --suffix .rmdup.RG.trinuc_methy.chr19.txt --output ${WORK_ROOT}/benchmark/summary/trinuc/snmCseq2.chr19.txt
python extract_trinuc.py --folder ${WORK_ROOT}/benchmark/snmCseq2/05.align/ --suffix .rmdup.RG.trinuc_methy.chr21.txt --output ${WORK_ROOT}/benchmark/summary/trinuc/snmCseq2.chr21.txt

