#!/bin/bash
# 00_paths.sh — shared paths/vars for the bulk NOMe-HiC processing scripts.
# Source this from the numbered scripts: `source 00_paths.sh`
#
# Strategy: run the single-cell sc_NOMeHiC Snakemake pipeline on a BULK sample
# by splitting each replicate's trimmed FASTQ into chunks treated as pipeline
# "cells" (prefix=repN, index=chunkNNN). Alignment + methylation calling fan out
# in parallel across SLURM; the final .hic is built from the 3-rep merged,
# per-library deduped BAM (step 10). Demultiplexing is SKIPPED (start_from: trimmed).

# ---- repo (scripts/tracking live here) ----
# --- repo paths: edit paths.yaml at the repository root, not this file -------
# SLURM copies a batch script to /var/spool/slurmd/<job>/slurm_script, so walking
# up from BASH_SOURCE cannot reach the repository. $SCNOMEHIC_REPO is tried first;
# submit with: sbatch --export=ALL,SCNOMEHIC_REPO=/path/to/repo
_r="${SCNOMEHIC_REPO:-}"
if [ -z "$_r" ] || [ ! -f "$_r/paths.sh" ]; then
    _r="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]:-$0}")")" && pwd)"
    while [ "$_r" != "/" ] && [ ! -f "$_r/paths.sh" ]; do _r="$(dirname "$_r")"; done
fi
[ -f "$_r/paths.sh" ] || { echo "ERROR: paths.sh not found. Set SCNOMEHIC_REPO to the repository root." >&2; exit 1; }
source "$_r/paths.sh"

export REPO="${WORK_ROOT}/analysis/bulk_scNOMeHiC"

# ---- scratch (all heavy outputs live here, NOT in the repo) ----
export DL="${TMP_ROOT}/bulk_gm"                 # raw downloaded fq.gz
export TRIMWHOLE="${DL}/trimmed_whole"                         # per-rep trimmed (pre-chunk)
export WORK="${DL}/pipeline"                                   # snakemake workdir
export CHUNK="${WORK}/03.trimmed_fastq_snakemake"              # chunked, pipeline-named cells
export HICDIR="${WORK}/hic_merged"                             # PBAT flow only -- unused by this chain
export METHMERGE="${WORK}/methylation_merged"                  # PBAT flow only -- unused by this chain

# ---- pipeline + tools ----
export PIPELINE="${SOFTWARE_ROOT}/sc_NOMeHiC_pipeline"
export SCNOMEHIC_ENV="${CONDA_ENVS}/scnomehic"
export TRIMGALORE_DIR="${SOFTWARE_ROOT}/TrimGalore-0.6.7"
export BISHIC="${SOFTWARE_ROOT}/bisulfiteHic"
export JUICER_JAR="${SOFTWARE_ROOT}/juicer/juicer_tools.jar"

# ---- reference ----
export REF="${REFERENCE_ROOT}/hg38/GCA_000001405.15_GRCh38_no_alt_analysis_set"
export DPNII="${REF}.fa_DpnII.txt"

# ---- replicate -> raw fastq basename map ----
# index 1..3 used by the SLURM arrays
export REP1_BASE="GM12878_bT_WGBS_rep1"
export REP2_BASE="GM12878_bT_WGBS_rep2"
export REP3_BASE="GM12878_bT_WGBS_rep3"

# ---- chunking ----
export CHUNK_READS=20000000   # read-pairs per chunk (seqkit split2 -s)

# ---- non-PBAT bulk flow (scripts 04-10) ----
# Different protocol: align chunks WITHOUT -pbat, merge per replicate, bamprocess
# per replicate (dedup per library), then merge all 3 reps and call methylation.
# Kept in separate dirs so the existing -pbat snakemake outputs are untouched.
export ALN_NOPBAT="${WORK}/04b.alignment_nopbat"     # per-chunk BAMs, aligned w/o -pbat
export BAMPROC_REP="${WORK}/05b.bamprocess_perrep"   # per-rep merged + bamprocessed calmd BAMs
export METHCALL="${WORK}/06b.methylation_merged"     # 3-rep merged BAM + bissnp methylation
export CHUNK_LIST="${ALN_NOPBAT}/chunk_list.txt"     # manifest: one "repN.chunkNNN" per line

# ---- SLURM ----
export SLURM_ACCT="b1042"
export SLURM_PART="genomics"

# helper: put scnomehic env + trim_galore on PATH (scnomehic env is the core env)
activate_scnomehic() {
    export PATH="${SCNOMEHIC_ENV}/bin:${TRIMGALORE_DIR}:${PATH}"
}
