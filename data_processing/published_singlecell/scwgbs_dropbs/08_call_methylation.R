#!/usr/bin/env Rscript
# ============================================================================
# 08_call_methylation.R — call per-cytosine methylation for one cell with
# methylKit::processBismarkAln, saving all three contexts (CpG/CHG/CHH) so that
# every cytosine is available (needed later for NOMe GpC / GCG handling).
# Usage: Rscript 08_call_methylation.R <dedup.bam> <sample.id> <assembly> <out.folder>
# ============================================================================
suppressMessages(library(methylKit))

args <- commandArgs(trailingOnly = TRUE)
bam      <- args[1]
sid      <- args[2]
assembly <- args[3]
outdir   <- args[4]
dir.create(outdir, showWarnings = FALSE, recursive = TRUE)

# save.context writes <sample.id>_<context>.txt with per-cytosine counts:
#   chrBase, chr, base, strand, coverage, freqC, freqT
processBismarkAln(
    location     = bam,
    sample.id    = sid,
    assembly     = assembly,
    read.context = "none",
    save.context = c("CpG", "CHG", "CHH"),
    save.folder  = outdir,
    treatment    = 0,
    mincov       = 1,
    minqual      = 20
)
cat(sprintf("[08] methylation calls written to %s for %s\n", outdir, sid))
