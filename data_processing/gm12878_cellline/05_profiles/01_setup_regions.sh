#!/bin/bash
# =============================================================================
# STEP 1 — Stage region BED files (decompressed) used by computeMatrix
# -----------------------------------------------------------------------------
# CTCF figure (GM12878):
#   - GM12878 CTCF ChIP-seq peaks (noTSS4kb): the cell-line-matched CTCF set
#   - xie/cuddapeh+kim oriented CTCF motif (noKnownTss4kb): generic motif contrast
# CGI figure (cell-line agnostic gencode TSS):
#   - TSS in UCSC CGI
#   - TSS non-CGI (+/- shore 2kb), canonical
# Sources live in scnomehic_paper/s2 (already prepared for the paper).
# =============================================================================
set -eo pipefail

S2=/gpfs/projects/b1198/epifluidlab/yoshii/scnomehic_paper/s2
REG=/gpfs/projects/b1198/epifluidlab/yoshii/sc_nomehic_cellline/gm_sc_new/ctcf_cgi_profiles/regions
mkdir -p "${REG}"

# source .bed.gz -> staged .bed (decompressed)
FILES=(
  "CTCF_chipseq.GM12878.ENCFF960ZGP.optimalIDR.hg38.noTSS4kb.sort.bed.gz"
  "xie_cuddapeh_plus_kim.orientedOnly.noKnownTss4kb.hg38.sort.bed.gz"
  "gencode.v45.TSS.UCSC_CGI.hg38.primary_assembly.gene_ensemble_id.sort.bed.gz"
  "gencode.v45.TSS.no_UCSC_CGI_plus_shore_2kb.hg38.primary_assembly.gene_ensemble_id.canonical.bed.gz"
)

for gz in "${FILES[@]}"; do
  src="${S2}/${gz}"
  out="${REG}/${gz%.gz}"
  if [[ ! -s "${src}" ]]; then echo "ERROR: missing source ${src}" >&2; exit 1; fi
  if [[ -s "${out}" ]]; then echo "[skip] ${out} exists"; continue; fi
  echo "[stage] ${gz} -> $(basename "${out}")"
  zcat "${src}" > "${out}"
done

echo "[STEP 1 DONE] regions in ${REG}"
ls -lh "${REG}"
