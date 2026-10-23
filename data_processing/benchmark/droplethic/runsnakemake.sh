#!/bin/bash
#SBATCH -A b1042
#SBATCH -p genomics
#SBATCH -t 48:00:00
#SBATCH -N 1
#SBATCH --mem=128G
#SBATCH --cpus-per-task=16
#SBATCH --job-name=runsnakemake
#SBATCH --output=logs/runsnakemake/runsnakemake.txt
#SBATCH --error=logs/runsnakemake/runsnakemake.err

# conda on PATH; override with SCNOMEHIC_CONDA_SH for a different install.
# --- repo paths: edit paths.yaml at the repository root, not this file -------
_r="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]:-$0}")")" && pwd)"
while [ "$_r" != "/" ] && [ ! -f "$_r/paths.sh" ]; do _r="$(dirname "$_r")"; done
source "$_r/paths.sh"
# rupture reads a plain YAML, so render the template with your paths first.
CONFIG="$(bash "$_r/data_processing/render_config.sh" "$_r/data_processing/benchmark/droplethic/config.template.yaml" "${WORK_ROOT}/benchmark/droplethic")"

source "${SCNOMEHIC_CONDA_SH:-${CONDA_SH}}"
cd /gpfs/projects/b1042/epifluidlab/yoshii/scnomehic_paper/benchmark/droplethic/my_project

conda activate rupture

rupture run --configfile config.yaml --cores 16 --snakemake-args --rerun-incomplete --keep-going

