#!/bin/bash
# ============================================================================
# 00_setup_env.sh — create the `scwgbs` conda env with every pipeline tool,
#                   and build idemp from source (not on bioconda).
# Run on a login node (needs internet):  bash code/00_setup_env.sh
# ============================================================================
set -euo pipefail
cd "$(dirname "$0")/.."
source code/config.sh

# Two separate envs, built with conda's libmamba solver. The classic `mamba`
# (libsolv) solver thrashed for 30+ min and then failed unsatisfiable; libmamba
# resolves the same specs in seconds. Env creation is idempotent so this script
# can be safely re-run. methylKit is only needed by step 08 ($ENV_R).
have_env () { "$CONDA/bin/conda" env list | awk '{print $1}' | grep -qx "$1"; }

# Python tools: strict channel priority (bioconda-first) resolves cleanly.
if have_env "$ENV"; then
    echo "[$(date '+%F %T')] env '$ENV' already exists — skipping"
else
    echo "[$(date '+%F %T')] Creating python tools env '$ENV' (libmamba) ..."
    "$CONDA/bin/conda" create -y -n "$ENV" --solver=libmamba --strict-channel-priority \
        -c bioconda -c conda-forge \
        python \
        umi_tools \
        trim-galore \
        bismark bowtie2 \
        samtools bamtools \
        picard \
        cutadapt pigz \
        pysam numpy pandas
fi

# R/methylKit: Bioconductor needs r-base from conda-forge, so conda-forge is
# prioritized and strict-channel-priority is NOT used (it would force an
# incompatible bioconda r-base and make the solve unsatisfiable).
if have_env "$ENV_R"; then
    echo "[$(date '+%F %T')] env '$ENV_R' already exists — skipping"
else
    echo "[$(date '+%F %T')] Creating R/methylKit env '$ENV_R' (libmamba) ..."
    "$CONDA/bin/conda" create -y -n "$ENV_R" --solver=libmamba \
        -c conda-forge -c bioconda \
        bioconductor-methylkit r-base
fi

echo "[$(date '+%F %T')] Building idemp from source ..."
IDEMP_SRC=code/tools/idemp
if [[ ! -d "$IDEMP_SRC" ]]; then
    git clone https://github.com/yhwu/idemp.git "$IDEMP_SRC"
fi
( cd "$IDEMP_SRC" && make )
cp "$IDEMP_SRC/idemp" "$CONDA/envs/$ENV/bin/idemp"

echo "[$(date '+%F %T')] Verifying tools:"
source "$CONDA/etc/profile.d/conda.sh"
conda activate "$ENV"
for t in umi_tools trim_galore bismark bowtie2 samtools bamtools picard idemp; do
    printf '  %-12s ' "$t"; command -v "$t" || echo "MISSING"
done
conda activate "$ENV_R"
Rscript -e 'if(!requireNamespace("methylKit",quietly=TRUE)) stop("methylKit missing"); cat("  methylKit OK\n")'
echo "[$(date '+%F %T')] Environments '$ENV' + '$ENV_R' ready."
