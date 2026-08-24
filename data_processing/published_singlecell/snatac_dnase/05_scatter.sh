#!/usr/bin/env bash
# Per-peak GCH vs snATAC signal over merged DNase peaks -> raw matrix, then scatter.
set -euo pipefail
BASE=/gpfs/projects/b1198/epifluidlab/yoshii/scnomehic_paper/s2_new/atac_dnase_gm12878
DATA="$BASE/data"; FIG="$BASE/figures"
THREADS="${THREADS:-8}"
GCH=/gpfs/projects/b1198/epifluidlab/yoshii/sc_nomehic_cellline/gm_sc_new/pseudobulk_methylation/gm_pseudobulk_merged.GCH.methlevel.bw
SNATAC="$DATA/snatac.cpm.bw"
PEAKS="$DATA/dnase_peaks.merged.bed"

echo "[scatter] multiBigwigSummary over peaks"
multiBigwigSummary BED-file -b "$GCH" "$SNATAC" \
  --labels GCH snATAC --BED "$PEAKS" -p "$THREADS" \
  -o "$DATA/peak_summary.npz" --outRawCounts "$DATA/peak_signal.tab"

python "$BASE/scripts/05_scatter.py" "$DATA/peak_signal.tab" "$FIG/gch_vs_snatac_scatter.pdf"
echo "[scatter] done"
