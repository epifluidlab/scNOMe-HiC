#!/usr/bin/env bash
# Set up fig2/data/bulk: per-cell-line reference data.
# GM12878 -> softlinks to fig1 bulk data (already downloaded/processed).
# IMR90   -> empty folders, awaiting download links.
set -euo pipefail

FIG2_DATA="/gpfs/projects/b1198/epifluidlab/yoshii/scnomehic_paper/fig2/data/bulk"
FIG1_BULK="/gpfs/projects/b1198/epifluidlab/yoshii/scnomehic_paper/fig1/data/bulk"

# Create folder structure
for cell in GM12878 IMR90; do
  for mod in hic atac methylation; do
    mkdir -p "${FIG2_DATA}/${cell}/${mod}"
  done
done

# --- GM12878 softlinks (relative, so they survive path moves within the tree) ---
link() {
  # link <target_abs> <linkdir_abs>
  local target="$1" linkdir="$2"
  local name
  name="$(basename "$target")"
  ln -sfn "$(realpath --relative-to="$linkdir" "$target")" "${linkdir}/${name}"
}

# Hi-C (in-situ Hi-C contact matrix)
link "${FIG1_BULK}/hic/ENCFF555ISR.hic"            "${FIG2_DATA}/GM12878/hic"

# ATAC-seq signal track
link "${FIG1_BULK}/atac/ENCFF667MDI.bigWig"        "${FIG2_DATA}/GM12878/atac"

# WGBS methylation (raw bigBed + processed bigWigs, both replicates)
for acc in ENCFF529CNU ENCFF866WCV; do
  link "${FIG1_BULK}/methylation/${acc}.bigBed"    "${FIG2_DATA}/GM12878/methylation"
  link "${FIG1_BULK}/methylation/${acc}.bw"        "${FIG2_DATA}/GM12878/methylation"
  link "${FIG1_BULK}/methylation/${acc}.HCG.bw"    "${FIG2_DATA}/GM12878/methylation"
done

echo "Done. Structure:"
find "${FIG2_DATA}" -maxdepth 3 \( -type l -o -type d \) | sort
