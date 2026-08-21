#!/usr/bin/env Rscript
## Build per-cell HCG methylated_reads (mc) and total_reads (cov) matrices
## at three region resolutions: gene_tss, gene_body, gene (TSS+body).
## These support read-weighted pseudobulk: sum(mc)/sum(cov) per cell type.
##
## Run with the scnomehic R:
##   /Users/jmj7858/miniconda3/envs/scnomehic/lib/R/bin/R --slave -f build_hcg_counts.R
suppressPackageStartupMessages({ library(data.table); library(parallel) })
setDTthreads(1)                      # 1 thread per fread; parallelism is across cells

WORKDIR <- "/Users/jmj7858/Yoshii/sc_nomehic/snakemake"
MDIR    <- file.path(WORKDIR, "08.methylation_snakemake")
OUT     <- file.path(WORKDIR, "QC", "methylation_matrices")
NCORES  <- 10
REGIONS <- c("gene_tss", "gene_body", "gene")

passed <- readLines(file.path(WORKDIR, "QC", "cortex_passed.txt"))
cat(sprintf("Cells (QC-passed): %d   cores: %d\n", length(passed), NCORES))

fpath <- function(cell, region)
  file.path(MDIR, sprintf("%s.HCG.%s_methylation.txt.gz", cell, region))

## gene order (verified identical across cells by md5) taken from first file
genes <- fread(cmd = sprintf("gzip -dc '%s'", fpath(passed[1], "gene_tss")),
               select = 1L, header = TRUE)$bin_id
NG <- length(genes)
cat(sprintf("Genes per cell: %d\n", NG))

read_counts <- function(cell, region) {
  f <- fpath(cell, region)
  if (!file.exists(f)) return(NULL)
  dt <- tryCatch(
    fread(cmd = sprintf("gzip -dc '%s'", f),
          select = c(1L, 5L, 6L), header = TRUE),   # bin_id, methylated_reads, total_reads
    error = function(e) NULL)
  if (is.null(dt) || nrow(dt) != NG) {
    ## fall back to bin_id alignment if a file is out of order / short
    if (is.null(dt)) return(NULL)
    idx <- match(genes, dt$bin_id)
    return(cbind(mc  = dt$methylated_reads[idx],
                 cov = dt$total_reads[idx]))
  }
  cbind(mc = dt$methylated_reads, cov = dt$total_reads)
}

for (region in REGIONS) {
  t0 <- proc.time()["elapsed"]
  mats <- mclapply(passed, read_counts, region = region, mc.cores = NCORES)
  ok   <- !vapply(mats, is.null, logical(1))
  if (any(!ok)) cat(sprintf("  [%s] WARNING: %d cells missing/failed\n",
                            region, sum(!ok)))
  cells_ok <- passed[ok]
  mc  <- vapply(mats[ok], function(m) as.integer(m[, "mc"]),  integer(NG))
  cov <- vapply(mats[ok], function(m) as.integer(m[, "cov"]), integer(NG))
  dimnames(mc)  <- list(genes, cells_ok)
  dimnames(cov) <- list(genes, cells_ok)
  out <- file.path(OUT, sprintf("HCG_%s_counts.rds", region))
  saveRDS(list(mc = mc, cov = cov, genes = genes, cells = cells_ok),
          out, compress = "xz")
  dt <- proc.time()["elapsed"] - t0
  cat(sprintf("  [%s] %d cells x %d genes  ->  %s  (%.1fs)\n",
              region, length(cells_ok), NG, basename(out), dt))
}
cat("DONE\n")
