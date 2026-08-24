#!/bin/bash
# Dump the scNOMe-HiC .hic at all $RESLIST resolutions (step 04) for the
# by-resolution SCC. Step 03 (sci-Hi-C multires dumps) is fast Python — run it
# on the login node first: `source code/config.sh; $PY code/03_rebin_hg38.py`.
#   sbatch code/run_multires.sbatch
#SBATCH --account=b1042
#SBATCH --partition=genomics
#SBATCH --time=01:00:00
#SBATCH --nodes=1
#SBATCH --cpus-per-task=2
#SBATCH --mem=24G
#SBATCH --job-name=schic_multi
#SBATCH --output=/gpfs/projects/b1198/epifluidlab/yoshii/scnomehic_paper/s2_new/schic_gm12878/logs/multi.%j.out
#SBATCH --error=/gpfs/projects/b1198/epifluidlab/yoshii/scnomehic_paper/s2_new/schic_gm12878/logs/multi.%j.err
set -euo pipefail
ROOT=/gpfs/projects/b1198/epifluidlab/yoshii/scnomehic_paper/s2_new/schic_gm12878
cd "$ROOT"; source "$ROOT/code/config.sh"; activate_env
"$PY" code/03_rebin_hg38.py       # idempotent; ensures sci-Hi-C multires dumps exist
bash code/04_dump_nomehic.sh      # scNOMe-HiC dumps at 500kb/1Mb/2.5Mb
echo "=== DONE $(date) ==="
