#!/usr/bin/env bash
# Create conda env `scnomehic_diff` for fig2 differential analyses:
#   methylKit (250kb DMR), DiffBind+DESeq2 (diff accessibility), csaw/edgeR.
#
# The blocker is bioconda's bioconductor-genomeinfodbdata post-link script: it
# curls a data tarball, trying 3 URLs until an md5 matches. From this cluster the
# 1st URL (bioconductor.org) HANGS ~5 min, but the 3rd (depot.galaxyproject.org)
# WORKS (md5 8798e58b89d84d9fa6a85f2191704668). Neither conda nor mamba avoids the
# post-link, so the real fix is to give curl a short connect-timeout via a scoped
# CURL_HOME/.curlrc: the hanging URL fails fast and curl falls through to the
# working mirror. We also relax conda safety/clobber checks (a benign cached
# r-base size record mismatch + mysql libmysqlclient.so shared-path clobber).
set -euo pipefail

# --- repo paths: edit paths.yaml at the repository root, not this file -------
_r="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]:-$0}")")" && pwd)"
while [ "$_r" != "/" ] && [ ! -f "$_r/paths.sh" ]; do _r="$(dirname "$_r")"; done
source "$_r/paths.sh"

source "${CONDA_SH}"
conda activate base

ENVS="${CONDA_ENVS}"
ENV=scnomehic_diff

# --- scoped curl config so post-link curl fails fast on the dead mirror ---
export CURL_HOME="${TMP_ROOT}/.curl_home"
mkdir -p "${CURL_HOME}"
mkdir -p "$CURL_HOME"
cat > "$CURL_HOME/.curlrc" <<'RC'
connect-timeout = 25
max-time = 300
retry = 1
RC

# --- relax checks that aborted prior transactions (non-fatal issues) ---
export CONDA_SAFETY_CHECKS=disabled
export CONDA_PATH_CONFLICT=clobber

# 1) remove prior broken env
conda env remove -y -n "$ENV" 2>/dev/null || true
rm -rf "${ENVS:?}/$ENV"

# 2) clone the working scnomehic (R 4.4.2 / Bioc 3.20, GenomeInfoDbData already ok)
echo "cloning scnomehic -> $ENV ..."
conda create -y -n "$ENV" --clone scnomehic

# 3) add analysis packages (mamba). If genomeinfodbdata relinks, its post-link
#    curl now falls through to the working mirror thanks to CURL_HOME/.curlrc.
echo "mamba install analysis packages ..."
mamba install -y -n "$ENV" -c conda-forge -c bioconda \
  bioconductor-methylkit \
  bioconductor-diffbind \
  bioconductor-deseq2 \
  bioconductor-csaw \
  bioconductor-edger

echo "=== verify ==="
conda run -n "$ENV" Rscript -e 'for(p in c("methylKit","DiffBind","DESeq2","csaw","edgeR")) cat(p, ":", requireNamespace(p, quietly=TRUE), "\n")'
echo "Done."
