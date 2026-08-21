#!/bin/bash
#SBATCH -A b1042
#SBATCH -p genomics
#SBATCH -t 06:00:00
#SBATCH -N 1
#SBATCH --mem=32G
#SBATCH --cpus-per-task=2
#SBATCH --job-name=rc_scc
#SBATCH --output=/gpfs/projects/b1198/epifluidlab/yoshii/sc_nomehic/snakemake/replicate_comparison/logs/scc.%j.out
#SBATCH --error=/gpfs/projects/b1198/epifluidlab/yoshii/sc_nomehic/snakemake/replicate_comparison/logs/scc.%j.err
#
# Step 3: hicrep SCC between rep1.hic and rep2.hic at 1Mb/500kb/250kb (H=3, per chrom).
# Submit with a dependency on the two Step-2 .hic jobs:
#   sbatch --dependency=afterok:<rep1_jobid>:<rep2_jobid> 03_submit_scc.slurm
set -eo pipefail

source ~/.bashrc
conda activate scnomehic
module load java/jdk-17.0.2+8

RC=/gpfs/projects/b1198/epifluidlab/yoshii/sc_nomehic/snakemake/replicate_comparison
JUICER=/home/jmj7858/epifluidlab/software/juicer/juicer_tools.jar

python "${RC}/code/03_scc_hicrep.py" \
  --hic1 "${RC}/hic/rep1.mapQ30.hic" \
  --hic2 "${RC}/hic/rep2.mapQ30.hic" \
  --juicer "${JUICER}" \
  --out_dir "${RC}/results/scc" \
  --name1 rep1 --name2 rep2

echo "[$(date)] SCC done."
