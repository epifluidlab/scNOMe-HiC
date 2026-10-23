# Repository path settings, read from paths.yaml.
#
#   source("<repo root>/paths.R")
#   file.path(WORK, "gm12878_cellline", "...")
#
# Defines: REPO DATA REFERENCE SOFTWARE WORK TMP CONDA_SH
#
# Resolution order for the settings file: SCNOMEHIC_PATHS, then paths.local.yaml,
# then paths.yaml. Relative values resolve against the repository root.

.scnomehic_repo <- function() {
  # the directory holding this file, however it was sourced
  for (i in rev(seq_len(sys.nframe()))) {
    f <- sys.frame(i)$ofile
    if (!is.null(f)) return(normalizePath(dirname(f)))
  }
  normalizePath(getwd())
}

REPO <- .scnomehic_repo()

.scnomehic_file <- function() {
  env <- Sys.getenv("SCNOMEHIC_PATHS")
  if (nzchar(env)) return(env)
  for (n in c("paths.local.yaml", "paths.yaml")) {
    p <- file.path(REPO, n)
    if (file.exists(p)) return(p)
  }
  stop("no paths.yaml in ", REPO)
}

.scnomehic_settings <- local({
  lines <- readLines(.scnomehic_file(), warn = FALSE)
  lines <- sub("#.*$", "", lines)
  lines <- trimws(lines)
  lines <- lines[grepl(":", lines, fixed = TRUE) & nzchar(lines)]
  k <- trimws(sub(":.*$", "", lines))
  v <- trimws(sub("^[^:]*:", "", lines))
  v <- gsub('^"|"$', "", v); v <- gsub("^'|'$", "", v)
  stats::setNames(as.list(v), k)
})

.scnomehic_abs <- function(key, default) {
  v <- .scnomehic_settings[[key]]
  if (is.null(v) || !nzchar(v)) v <- default
  if (!nzchar(v)) return("")
  if (substr(v, 1, 1) == "/") return(v)
  if (substr(v, 1, 1) == "~") return(path.expand(v))
  file.path(REPO, v)
}

DATA      <- .scnomehic_abs("data_root",      "data")
REFERENCE <- .scnomehic_abs("reference_root", "reference")
SOFTWARE  <- .scnomehic_abs("software_root",  "software")
WORK      <- .scnomehic_abs("work_root",      "work")
TMP       <- .scnomehic_abs("tmp_root",       "work/tmp")
CONDA_SH  <- .scnomehic_abs("conda_sh",       "")
