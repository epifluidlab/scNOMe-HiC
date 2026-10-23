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
# --- repo paths: edit paths.yaml at the repository root, not this file -------
_r="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]:-$0}")")" && pwd)"
while [ "$_r" != "/" ] && [ ! -f "$_r/paths.sh" ]; do _r="$(dirname "$_r")"; done
source "$_r/paths.sh"

set -eo pipefail

PYTHON=${CONDA_ENVS}/hic_cooler/bin/python
SCRIPT="$(dirname "$(readlink -f "${BASH_SOURCE[0]:-$0}")")/05_apa_pileup_insitu.py"

echo "[$(date +%H:%M:%S)] host=$(hostname)"
"$PYTHON" "$SCRIPT"
echo "[$(date +%H:%M:%S)] done"
