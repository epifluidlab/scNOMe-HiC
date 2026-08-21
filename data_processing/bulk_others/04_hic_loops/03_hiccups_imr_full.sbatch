#!/bin/bash
#SBATCH --account=b1042
#SBATCH --partition=genomics-gpu
#SBATCH --gres=gpu:a100:1
#SBATCH --job-name=insitu_step03_hiccups_imr
#SBATCH --time=06:00:00
#SBATCH --mem=128G
#SBATCH --cpus-per-task=8
#SBATCH --output=/gpfs/projects/b1198/epifluidlab/yoshii/sc_nomehic_cellline/snakemake/APA/insitu/logs/%x_%j.out
#SBATCH --error=/gpfs/projects/b1198/epifluidlab/yoshii/sc_nomehic_cellline/snakemake/APA/insitu/logs/%x_%j.err
# STEP 03 (in-situ) -- GPU HICCUPS on the IMR90 in-situ .hic (full depth).
# Same params as step02.
set -eo pipefail

source ~/.bashrc
module load java/jdk-17.0.2+8
module load cuda/11.3.1-gcc-10.4.0
module load gcc/10.4.0-gcc-4.8.5

JUICER=/gpfs/projects/b1198/epifluidlab/weimin/code/analysis/3D_genome_prediction/KS_test/juicer_tools.2.20.00.jar  # 2.20 needed for v9 hic
HIC=/scratch/jmj7858/scnomehic/insitu_hic/ENCFF188SSH_IMR90_insitu.hic
OUT=/scratch/jmj7858/scnomehic/insitu_hic/imr_insitu_hiccups_25kb_loops

echo "[$(date +%H:%M:%S)] HICCUPS IMR in-situ 25kb"
echo "  hic: $HIC"
echo "  out: $OUT"
nvidia-smi 2>&1 | head -10 || true

rm -rf "$OUT" && mkdir -p "$OUT"

java -Xmx112G -jar "$JUICER" hiccups \
    -c 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,X \
    -r 25000 \
    -k SCALE \
    -m 128 \
    -f .1 -p 1 -i 3 -t 0.02,1.5,1.75,2 -d 50000 \
    "$HIC" \
    "$OUT"

echo "[$(date +%H:%M:%S)] done"
ls -la "$OUT"
echo "loops: $(grep -vc '^#' $OUT/merged_loops.bedpe 2>/dev/null)"
