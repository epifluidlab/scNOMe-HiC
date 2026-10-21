#!/bin/bash
#SBATCH --account=b1042
#SBATCH --partition=genomics
#SBATCH --job-name=insitu_step05_apa_pileup
#SBATCH --time=04:00:00
#SBATCH --mem=64G
#SBATCH --cpus-per-task=4
#SBATCH --output=/gpfs/projects/b1198/epifluidlab/yoshii/sc_nomehic_cellline/snakemake/APA/insitu/logs/%x_%j.out
#SBATCH --error=/gpfs/projects/b1198/epifluidlab/yoshii/sc_nomehic_cellline/snakemake/APA/insitu/logs/%x_%j.err
# STEP 05 (in-situ) -- Non-circular 2xN APA: loop sets from in-situ Hi-C (step 04),
# signal from the sc pseudobulk imputed Q matrices.
set -eo pipefail

PYTHON=/projects/b1198/epifluidlab/yoshii/software/conda/envs/hic_cooler/bin/python
SCRIPT="$(dirname "$(readlink -f "${BASH_SOURCE[0]:-$0}")")/05_apa_pileup_insitu.py"

echo "[$(date +%H:%M:%S)] host=$(hostname)"
"$PYTHON" "$SCRIPT"
echo "[$(date +%H:%M:%S)] done"
