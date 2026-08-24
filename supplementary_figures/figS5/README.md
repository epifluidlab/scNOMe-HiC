# Supplementary Figure S5 — sequencing saturation (GM12878)

How much of each library's complexity the sequencing actually captured, for the
GM12878 4-plex single-cell NOMe-HiC dataset. **180 QC-passing cells.**

| Panel | File | Made by |
|---|---|---|
| Saturation curves with Michaelis–Menten fit | `s5_saturation.pdf` | §3 of the notebook |

The notebook also draws two supporting views that are not the panel:
`s5_library_complexity` (unique molecules against raw fragments, §4) and
`s5_saturation_byfraction` (the same curves with subsample fraction on the
x-axis, §5). Both are kept — they are how the fit was sanity-checked.

| Notebook | Kernel | Inputs |
|---|---|---|
| `figS5_saturation.ipynb` | Python (`python3`) | the per-(cell, fraction) result files from `../../data_processing/gm12878_cellline/04_saturation/` |

## What is measured

Reads are subsampled to a series of depths and four metrics re-measured at each:

| metric | meaning |
|---|---|
| `HCG_loci` | CpG methylation positions detected |
| `GCH_loci` | GpC accessibility positions detected |
| `cis` | intra-chromosomal contacts, MAPQ 30, deduplicated |
| `cis_1kb` | cis contacts spanning more than 1 kb |

Fractions are 0.05, 0.1, 0.2, 0.4, 0.6, 0.8, plus 1.0 taken from the existing
full-depth pipeline outputs rather than recomputed.

## Two design choices that make the curve meaningful

**Subsample *before* de-duplication.** Saturation is a statement about PCR
duplicates: as depth rises you increasingly re-sequence molecules you already
have. So the chain subsamples the **pre-dedup** mapped BAM and re-runs
de-duplication at every depth. Subsampling a deduplicated BAM would just thin an
already-unique set and produce a straight line with no saturation to measure.

**A fixed subsampling seed.** `samtools view -s` with one seed makes the depths
**nested** — the 0.2 subset is contained in the 0.4 subset, and so on — so each
cell's curve is monotonic by construction rather than by luck. Without it, curves
could wander non-monotonically from sampling noise alone and the fit would be
meaningless.

## Reading the fit

§3 fits `y = Ymax·N/(N+K)` per curve and reports `Ymax`, `K`, and the percentage
of saturation reached at full depth, with the per-cell distribution. `Ymax` is the
asymptotic ceiling — what infinite sequencing would recover — so "% saturation at
full depth" is the number that says whether sequencing deeper would have paid.

## Run order

The measurement chain is `../../data_processing/gm12878_cellline/04_saturation/`
(steps 00–05: config → task list → per-task subsample and re-measure as a SLURM
array → the f = 1.0 point → collect). This notebook is the last step: it reads
every `results/*.tsv`, checks completeness (180 cells × 7 fractions), fits, and
plots.
