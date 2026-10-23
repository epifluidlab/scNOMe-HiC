# --- repo paths: edit paths.yaml at the repository root, not this file -------
_r="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]:-$0}")")" && pwd)"
while [ "$_r" != "/" ] && [ ! -f "$_r/paths.sh" ]; do _r="$(dirname "$_r")"; done
source "$_r/paths.sh"

python extract_GCH_HCG_counts.py --folder /ocean/projects/mcb190124p/dnaase/projects/hexa_seq/scNOMe_DNA_IMR90_GM_all/bam/methy  --middle .hg38.calmd.cytosine.filtered.sort. --output imr90_gm_all.gch_hcg_count.txt
python extract_GCH_HCG_counts.py --folder /ocean/projects/mcb190124p/dnaase/projects/hexa_seq/scNOMe_mouse_cortex_20230417/bam/methylation --middle .mm10.calmd.cytosine.filtered.sort. --output mouse_cortex_20230417.gch_hcg_count.txt
python extract_GCH_HCG_counts.py --folder /ocean/projects/mcb190124p/dnaase/projects/hexa_seq/scNOMe_mouse_cortex_20240507/methy --middle .mm10.calmd.cytosine.filtered.sort. --output mouse_cortex_20240507.gch_hcg_count.txt
python extract_GCH_HCG_counts.py --folder ${WORK_ROOT}/meningioma/data_batch_2/07.bistools_snakemake/methylation_2 --middle .calmd.cytosine.filtered.sort. --output summary_files/eningioma_batch2.gch_hcg_count.txt
python extract_GCH_HCG_counts.py --folder ${WORK_ROOT}/meningioma/data_batch_3/07.bistools_snakemake/methylation --middle .calmd.cytosine.filtered.sort. --output summary_files/eningioma_batch3.gch_hcg_count.txt

python extract_GCH_HCG_counts.py --folder ${WORK_ROOT}/gm12878_cellline/07.bistools_snakemake/methylation  --middle .calmd.cytosine.filtered.sort. --output gm_sc.gch_hcg_count.txt
