#!/bin/bash
# ============================================================================
# scNOMe-HiC vs sci-Hi-C GM12878 SCC pipeline (steps 01-05).
# References (chain, hg19 sizes, sci-Hi-C tar) must already be in data/
# (see code/00_download_refs.sh — run on the login node first).
#   sbatch code/run_pipeline.sbatch
# ============================================================================
#SBATCH --account=b1042
#SBATCH --partition=genomics
#SBATCH --time=02:00:00
#SBATCH --nodes=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=32G
#SBATCH --job-name=schic_scc
#SBATCH --output=/gpfs/projects/b1198/epifluidlab/yoshii/scnomehic_paper/s2_new/schic_gm12878/logs/scc.%j.out
#SBATCH --error=/gpfs/projects/b1198/epifluidlab/yoshii/scnomehic_paper/s2_new/schic_gm12878/logs/scc.%j.err

set -euo pipefail
ROOT=/gpfs/projects/b1198/epifluidlab/yoshii/scnomehic_paper/s2_new/schic_gm12878
cd "$ROOT"
source "$ROOT/code/config.sh"
activate_env
module load java/jdk-17.0.2+8 2>/dev/null || module load java 2>/dev/null || true

echo "=== 01 pool GM cells (hg19) ==="        ; "$PY" code/01_pool_gm.py
echo "=== 02 liftOver hg19 -> hg38 ==="        ; bash code/02_liftover.sh
echo "=== 03 re-bin to hg38 2.5 Mb ==="        ; "$PY" code/03_rebin_hg38.py
echo "=== 04 dump scNOMe-HiC hg38 2.5 Mb ===" ; bash code/04_dump_nomehic.sh
echo "=== 05 HiCRep SCC ==="                   ; "$PY" code/05_scc.py
echo "=== DONE $(date) ==="
