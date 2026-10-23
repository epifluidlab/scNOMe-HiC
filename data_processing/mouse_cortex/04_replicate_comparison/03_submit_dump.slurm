#!/bin/bash
#SBATCH -A b1042
#SBATCH -p genomics
#SBATCH -t 06:00:00
#SBATCH -N 1
#SBATCH --mem=32G
#SBATCH --cpus-per-task=2
#SBATCH --job-name=rc_dump
#SBATCH --output=/gpfs/projects/b1198/epifluidlab/yoshii/sc_nomehic/snakemake/replicate_comparison/logs/dump.%j.out
#SBATCH --error=/gpfs/projects/b1198/epifluidlab/yoshii/sc_nomehic/snakemake/replicate_comparison/logs/dump.%j.err
#
# Step 3: dump per-chromosome contact matrices from rep1.hic and rep2.hic at
# 1Mb/500kb/250kb. The SCC itself is computed in the Figure S6 notebook from
# these dumps.
# Submit with a dependency on the two Step-2 .hic jobs:
#   sbatch --dependency=afterok:<rep1_jobid>:<rep2_jobid> 03_submit_dump.slurm
# --- repo paths: edit paths.yaml at the repository root, not this file -------
_r="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]:-$0}")")" && pwd)"
while [ "$_r" != "/" ] && [ ! -f "$_r/paths.sh" ]; do _r="$(dirname "$_r")"; done
source "$_r/paths.sh"

set -eo pipefail

source ~/.bashrc
conda activate scnomehic
module load java/jdk-17.0.2+8

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RC=/gpfs/projects/b1198/epifluidlab/yoshii/sc_nomehic/snakemake/replicate_comparison
JUICER=${SOFTWARE_ROOT}/juicer/juicer_tools.jar

python "${HERE}/03_dump_hic.py" \
  --hic1 "${RC}/hic/rep1.mapQ30.hic" \
  --hic2 "${RC}/hic/rep2.mapQ30.hic" \
  --juicer "${JUICER}" \
  --dump_dir "${RC}/results/scc/dumps" \
  --name1 rep1 --name2 rep2

echo "[$(date)] dumps done."
