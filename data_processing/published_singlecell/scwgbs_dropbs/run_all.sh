#!/bin/bash
# ============================================================================
# run_all.sh — submit the scWGBS pipeline to SLURM in dependency-chained phases.
#
# The per-cell array steps need a cell count that only exists after an earlier
# job runs, so submission is split into phases. Run them in order; each waits
# (via afterok dependencies) for the previous.
#
#   bash code/run_all.sh bulk      # steps 01->02->03->04 (whole-sample)
#   bash code/run_all.sh align     # step  05 (array) -> 06 QC        (after 04 done)
#   bash code/run_all.sh postqc    # steps 07->08->09 (arrays)         (after 06 done)
#   bash code/run_all.sh demux2allc# 04 -> 05 -> 06 -> [launcher] -> 07->08->09, one dependency chain
#
# %50 throttles arrays to 50 concurrent tasks; adjust to taste.
# ============================================================================
set -euo pipefail
cd "$(dirname "$0")/.."
source code/config.sh
mkdir -p "$LOGS"

THROTTLE=50
phase=${1:-}

# number of cells for the step-05 array (CELL_LIST if present, else whitelist)
ncells () {
    if [[ -s "$CELL_LIST" ]]; then wc -l < "$CELL_LIST"; else wc -l < "$D01/whitelist.txt"; fi
}

case "$phase" in

  # 04 (re-demux) through allc as a single SLURM dependency chain. The postqc
  # arrays are submitted by a launcher job (their size needs QC output first).
  demux2allc)
    n=$(ncells)
    j4=$(sbatch --parsable code/04_demux_idemp.sh)
    j5=$(sbatch --parsable --dependency=afterok:$j4 --array=1-${n}%${THROTTLE} code/05_align_bismark.sh)
    # afterany: run QC once all align tasks finish, even if some cells failed
    j6=$(sbatch --parsable --dependency=afterany:$j5 code/06_qc_filter.sh)
    jL=$(sbatch --parsable --dependency=afterok:$j6 code/_submit_postqc.sh)
    echo "submitted demux2allc: demux=$j4 align(1-$n)=$j5 qc=$j6 launch_postqc=$jL"
    echo "final allc -> $D09/<cell>/allc_<cell>.tsv.gz"
    ;;

  # 05 through allc (demux already done): align array -> QC -> launcher -> 07/08/09
  align2allc)
    n=$(ncells)
    j5=$(sbatch --parsable --array=1-${n}%${THROTTLE} code/05_align_bismark.sh)
    j6=$(sbatch --parsable --dependency=afterany:$j5 code/06_qc_filter.sh)
    jL=$(sbatch --parsable --dependency=afterok:$j6 code/_submit_postqc.sh)
    echo "submitted align2allc: align(1-$n)=$j5 qc=$j6 launch_postqc=$jL"
    echo "final allc -> $D09/<cell>/allc_<cell>.tsv.gz"
    ;;
  bulk)
    j1=$(sbatch --parsable code/01_whitelist.sh)
    j2=$(sbatch --parsable --dependency=afterok:$j1 code/02_extract.sh)
    j3=$(sbatch --parsable --dependency=afterok:$j2 code/03_trim.sh)
    j4=$(sbatch --parsable --dependency=afterok:$j3 code/04_demux_idemp.sh)
    echo "submitted bulk: whitelist=$j1 extract=$j2 trim=$j3 demux=$j4"
    echo "when $j4 finishes, run: bash code/run_all.sh align"
    ;;

  align)
    [[ -s "$CELL_LIST" ]] || { echo "ERROR: $CELL_LIST missing (run 'bulk' first)"; exit 1; }
    n=$(wc -l < "$CELL_LIST")
    j5=$(sbatch --parsable --array=1-${n}%${THROTTLE} code/05_align_bismark.sh)
    j6=$(sbatch --parsable --dependency=afterok:$j5 code/06_qc_filter.sh)
    echo "submitted align: bismark(array 1-$n)=$j5 qc=$j6"
    echo "when $j6 finishes, run: bash code/run_all.sh postqc"
    ;;

  postqc)
    PASS="$D06/passing_cells.txt"
    [[ -s "$PASS" ]] || { echo "ERROR: $PASS missing (run 'align' first)"; exit 1; }
    n=$(wc -l < "$PASS")
    j7=$(sbatch --parsable --array=1-${n}%${THROTTLE} code/07_merge_dedup.sh)
    j8=$(sbatch --parsable --dependency=aftercorr:$j7 --array=1-${n}%${THROTTLE} code/08_call_methylation.sh)
    j9=$(sbatch --parsable --dependency=aftercorr:$j8 --array=1-${n}%${THROTTLE} code/09_build_allc.sh)
    echo "submitted postqc: dedup=$j7 methyl=$j8 allc=$j9 (each array 1-$n)"
    echo "final allc files land in $D09/<cell>/allc_<cell>.tsv.gz"
    ;;

  *)
    echo "usage: bash code/run_all.sh {bulk|align|postqc}"; exit 1 ;;
esac
