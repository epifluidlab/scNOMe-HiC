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

python extract_trinuc_chrM.py --folder /ocean/projects/mcb190124p/dnaase/projects/hexa_seq/scNOMe_mouse_cortex_20230417/bam/QC --suffix .mm10.calmd.trinuc_methy.chrM.txt --output mouse_cortex_20230417.chrM.txt
python extract_trinuc_chrM.py --folder /ocean/projects/mcb190124p/dnaase/projects/hexa_seq/scNOMe_DNA_IMR90_GM_all/bam/QC/ --suffix .hg38.calmd.trinuc_methy.chrM.txt --output imr90_gm_all.chrM.txt
python extract_trinuc_chrM.py --folder ${WORK_ROOT}/meningioma/data_batch_2/07.bistools_snakemake/qc/ --suffix .calmd.trinuc_methy.chrM.txt --output summary_files/meningioma_batch2.chrM.txt
python extract_trinuc_chrM.py --folder ${WORK_ROOT}/meningioma/data_batch_3/07.bistools_snakemake/qc/ --suffix .calmd.trinuc_methy.chrM.txt --output summary_files/meningioma_batch3.chrM.txt
python extract_trinuc_chrM.py --folder ${WORK_ROOT}/analysis/s1/QC/mouse_summary --suffix .mm10.calmd.trinuc_methy.chrM.txt --output chrM_gch_hcg/mouse_cortex_20240507.chrM.txt
python extract_trinuc_chrM.py --folder ${DATA_ROOT}/external/scNOMe_celllines_20240314/bam/IMR90/QC/ --suffix .hg38.calmd.trinuc_methy.chrM.txt --output chrM_gch_hcg/imr90.chrM.txt
