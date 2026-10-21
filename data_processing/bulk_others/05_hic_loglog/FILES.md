# FILES — bulk_others/05_hic_loglog

HOMER contact-frequency-vs-distance (log-log) data for three GM12878 samples:
bulk NOMe-HiC, pseudobulk NOMe-HiC, and ENCODE in-situ Hi-C. Produces the
`*.petag.FreqDistribution_1000.txt` tables that
`../../../supplementary_figures/figS1/figS1_contact_distance.ipynb` plots.

Method: HOMER `makeTagDirectory` reads a **HiCsummary** file (one read pair per
line) and writes `petagDistDistribution.txt` — the fraction of paired-end reads
at each separation, in 1 kb bins. Plotting that log-log is HOMER's
contact-vs-distance QC plot.
<http://homer.ucsd.edu/homer/interactions2/HiCtagDirectory.html>

| File | What it does | Origin |
|---|---|---|
| `01_download_insitu_pairs.sh` | Downloads the ENCODE in-situ read-pair file `ENCFF447ERX.pairs.gz` (GRCh38, ~115 GB). Resumable. The read-level source for the in-situ sample. | `scnomehic_paper/fig1/codes/hic_qc_loglog/download_insitu_pairs.sh` |
| `02_sample_pipeline.sh` | SLURM worker for ONE sample, parametrized by `NAME` / `SRC` / `FMT` / `TARGET`. Filters to main chromosomes, converts the read-pair file to HiCsummary, downsamples to `TARGET` pairs, runs `makeTagDirectory`, copies out `petagDistDistribution.txt`. `FMT`: `short8` (juicer short), `short16` (juicer medium, MAPQ ≥ 30 filter), `pairs` (4DN). | `…/sample_pipeline.sh` |
| `03_submit_insitu.sh` | Submits `02_` for the in-situ sample twice — the 100 M-capped subsample and full depth — after verifying the download is a complete gzip. Resolves `02_` relative to itself. | `…/submit_insitu.sh` |
| `04_aggregate_insitu_full.sh` | Fallback for the full-depth in-situ sample: aggregates its HiCsummary into the same `petag.FreqDistribution_1000.txt` format with awk, needing no HOMER and almost no memory. | `…/aggregate_insitu_full_from_hicsummary.sh` |

Only the cross-reference in `03_` was changed (it now resolves `02_` from its own
location instead of the author's source tree). Commands, parameters and data
paths are verbatim.

## Read-pair sources

| Sample | File | `FMT` |
|---|---|---|
| bulk NOMe-HiC | `bulk_GM12878_merged.hic.sorted.txt.gz` | `short16` |
| pseudobulk NOMe-HiC | `gm_pseudobulk.dedup.short.sorted.txt.gz` | `short8` |
| in-situ Hi-C | ENCODE `ENCFF447ERX.pairs.gz` | `pairs` |

## Deliberately not included

- **`plot_loglog.py`** — the batch equivalent of the figure notebook. It emits all
  12 combined/full/sub × raw/smoothed/zoom variants; the published panel comes
  from `figS1_contact_distance.ipynb`, which carries the same `make_fig()`.
- **`rerun_insitu_full_himem.sh`, `watch_and_submit_insitu.sh`,
  `watch_insitu_full.sh`** — operational helpers for resubmitting the full-depth
  job at higher memory and polling for the download to finish. Run management,
  not method.

## Note

The `#SBATCH --output/--error` paths in `02_` and `04_` are still absolute, as in
every other migrated SLURM script here. They are part of the path refactor, not
of this figure.
