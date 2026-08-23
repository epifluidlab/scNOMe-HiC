#!/bin/bash
#SBATCH -A b1042
#SBATCH -p genomics
#SBATCH -t 8:00:00
#SBATCH -N 1
#SBATCH --mem=32G
#SBATCH --cpus-per-task=16
#SBATCH --job-name=deconv_allb
#SBATCH --output=/gpfs/projects/b1198/epifluidlab/yoshii/meningioma_scnomehic/snakemake/subset_clustering/250kb/all_batches/deconv/deconv_allb.out
#SBATCH --error=/gpfs/projects/b1198/epifluidlab/yoshii/meningioma_scnomehic/snakemake/subset_clustering/250kb/all_batches/deconv/deconv_allb.err
# UXM tumor-vs-non-tumor deconvolution for the all_batches (3-batch) set.
# Split is copy-number driven: non-tumour = cna_group 1 (chr22q intact).
# Mirrors Combined_sample2/09.deconv.sh. Scripts live in snakemake/code/; outputs go to
# subset_clustering/250kb/<SET>/deconv/. Run the FINAL notebook first (final_metadata.tsv).
# Submit: sbatch 03_run_deconv.sh
# NOTE: source .bashrc BEFORE enabling strict mode — /etc/bashrc references an unbound
# variable (BASHRCSOURCED), which would abort the job under `set -u`.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source /home/jmj7858/.bashrc
module load gcc/11.2.0 || true
module load htslib || true
conda activate scnomehic
set -eo pipefail          # strict error checking (no -u; bashrc trips it)

SET=all_batches
WORK=/gpfs/projects/b1198/epifluidlab/yoshii/meningioma_scnomehic/snakemake
OUTDIR=$WORK/subset_clustering/250kb/$SET/deconv
mkdir -p "$OUTDIR"; cd "$OUTDIR"          # all outputs land here

WGBS=/gpfs/projects/b1198/epifluidlab/yoshii/software/wgbs_tools/wgbstools
UXM=/gpfs/projects/b1198/epifluidlab/yoshii/software/UXM_deconv/uxm
# Newoligo brain atlas (has Microglia) — the one used for the original barplot.
ATLAS=/projects/b1198/epifluidlab/jocelyn/project/ms/atlas/Atlas.U25.l4.hg38.monofixed_newoligo_micro40.tsv

# 1) tumor / non-tumor cell lists from the CNA groups (cna_group; 1 = diploid) -> $OUTDIR
python "${HERE}/01_make_cell_lists.py"

# 2) merge per-cell BAMs into one BAM per group (run from $OUTDIR; lists + outputs are here)
bash "${HERE}/02_combine_bam.sh" tumor    cell_tumor.txt
bash "${HERE}/02_combine_bam.sh" nontumor cell_nontumor.txt

# 3) BAM -> pat (paired-end, include_flags 3). Needs wgbstools hg38 genome initialised.
$WGBS bam2pat --include_flags 3 -f combined_sorted_tumor.bam
$WGBS bam2pat --include_flags 3 -f combined_sorted_nontumor.bam

# 4) UXM deconvolution + its own stacked-bar plot
$UXM deconv -o output.csv --atlas "$ATLAS" \
    combined_sorted_tumor.pat.gz combined_sorted_nontumor.pat.gz
$UXM plot output.csv -o deconv.pdf

# 5) the tumor-vs-non-tumor difference barplot is drawn from output.csv by
#    main_figures/fig4/fig4_deconv_barplot.ipynb, not here -- that notebook is
#    the published version of the panel.
echo "DONE — output.csv and deconv.pdf are in $OUTDIR;"
echo "       draw the figure with main_figures/fig4/fig4_deconv_barplot.ipynb"
