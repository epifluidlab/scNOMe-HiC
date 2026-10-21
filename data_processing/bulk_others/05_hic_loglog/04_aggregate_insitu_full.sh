#!/bin/bash
#SBATCH --account=b1042
#SBATCH --partition=genomics
#SBATCH --time=08:00:00
#SBATCH --mem=8G
#SBATCH --cpus-per-task=2
#SBATCH --job-name=qc_insitu_full_awk
#SBATCH --output=/gpfs/projects/b1198/epifluidlab/yoshii/scnomehic_paper/fig1/codes/hic_qc_loglog/logs/%x_%j.out
#SBATCH --error=/gpfs/projects/b1198/epifluidlab/yoshii/scnomehic_paper/fig1/codes/hic_qc_loglog/logs/%x_%j.out
# FALLBACK (no HOMER, near-zero memory): aggregate the in-situ full HiCsummary into the same
# petag.FreqDistribution_1000.txt format HOMER produces — fraction of PE pairs per 1kb distance bin.
# HiCsummary cols: 1=name 2=chr1 3=pos1 4=str1 5=chr2 6=pos2 7=str2
set -eo pipefail
NAME=insitu_hic_full
WORK=/scratch/jmj7858/scnomehic/hic_qc_loglog/$NAME
SUMMARY=$WORK/$NAME.hicsummary.txt
RESULTS=/gpfs/projects/b1198/epifluidlab/yoshii/scnomehic_paper/fig1/results/hic_qc_loglog
OUT=$RESULTS/${NAME}.petag.FreqDistribution_1000.txt
[ -s "$SUMMARY" ] || { echo "ERROR: missing $SUMMARY"; exit 1; }
echo "[$(date)] awk-aggregating $SUMMARY ..."
awk '
{
  if ($2==$5) { d=$6-$3; if(d<0)d=-d; b=int(d/1000)*1000; c[b]++; intra++ }
  else inter++
}
END{
  tot=intra+inter;
  printf "Distance between PE tags\tFraction of total PE tags(Interchromosomal:%e)\n", (tot?inter/tot:0);
  for (b in c) printf "%d\t%e\n", b, c[b]/tot;
}' "$SUMMARY" | { head -1; tail -n +2 | sort -k1,1n; } > "$OUT"
echo "[$(date)] wrote $OUT ($(wc -l < "$OUT") lines)"
