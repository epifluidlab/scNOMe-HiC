#!/bin/bash
#SBATCH -A b1042
#SBATCH -p genomics
#SBATCH -t 03:00:00
#SBATCH -N 1
#SBATCH --mem=32G
#SBATCH --cpus-per-task=2
#SBATCH --job-name=rc_scc9599
#SBATCH --output=/gpfs/projects/b1198/epifluidlab/yoshii/sc_nomehic/snakemake/replicate_comparison/logs/scc_9599.%j.out
#SBATCH --error=/gpfs/projects/b1198/epifluidlab/yoshii/sc_nomehic/snakemake/replicate_comparison/logs/scc_9599.%j.err
#
# Clip-percentile sweep at 95,96,97,98,99 for the rep1-vs-rep2 SCC (reuses cached dumps).
set -eo pipefail
source ~/.bashrc
conda activate scnomehic

RC=/gpfs/projects/b1198/epifluidlab/yoshii/sc_nomehic/snakemake/replicate_comparison
python "${RC}/04_scc_clip_sweep.py" \
  --dump_dir "${RC}/results/scc/dumps" \
  --out_dir "${RC}/results/scc_clip95to99" \
  --pcts 95,96,97,98,99 \
  --name1 rep1 --name2 rep2
echo "[$(date)] 95-99 clip sweep done."
