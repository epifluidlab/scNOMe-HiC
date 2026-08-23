# Running the pipeline from scratch

This repository holds configs and driver scripts; the workflow itself is a separate
tool. This page covers what to install, what to edit, and the two entry points into
the per-cell pipeline.

**By default the pipeline starts from raw multiplexed FASTQ and performs
demultiplexing itself.** If you obtained the reads from GEO they are already
demultiplexed — use `start_from: "demultiplexed"`, described in
[Entry point B](#4-entry-point-b--reads-from-geo-already-demultiplexed).

---

## 1. Prerequisites

**The workflow**

```bash
git clone https://github.com/epifluidlab/sc_NOMeHiC_pipeline
cd sc_NOMeHiC_pipeline
# a0456b9 is the commit the paper's results were produced with.
# Use a later commit if you need Entry point B (start_from: "demultiplexed"),
# which was added in 0b94c56 and changes no processing step.
git checkout a0456b9
```

**Environments** — the pipeline ships conda definitions in its `envs/`. The main env
is `scnomehic`. This repository's `env/` holds the extra environments used by the
figure notebooks.

**External tools** referenced by the configs, installed separately:

| Tool | Used for |
|---|---|
| `bisulfiteHic` (Bhmem) | demultiplexing and bisulfite-aware alignment |
| Bis-tools / Bis-SNP | methylation calling |
| Picard | BAM processing |
| juicer_tools | `.hic` construction and dumps |
| trim_galore, FastQC, samtools, bedtools | standard preprocessing |
| metilene | de-novo DMR calling (Figure 2 only) |

**Reference files** (hg38 in this paper):

```
GCA_000001405.15_GRCh38_no_alt_analysis_set.{fa,fai,chrom.sizes}
GCA_000001405.15_GRCh38_no_alt_analysis_set.fa_DpnII.txt     # restriction sites
Homo_sapiens_assembly38.dbsnp138.vcf                          # for Bis-SNP
genome_bins_{5kb,250kb}.bed                                   # GCH normalization
```

---

## 2. Edit the config

Each dataset folder carries the config it ran with, under `00_config/`. **Every path
in it is absolute and machine-specific** — the config is a record of the original
run, so treat it as a template and change these keys:

| Key | Change to |
|---|---|
| `workdir` | where you want outputs written |
| `reference`, `variants`, `restriction_sites` | your reference files |
| `picard`, `bisulfitehic`, `bissnp_jar`, `bistools`, `scripts` | your tool installs |
| `hg38_5kb_no_dark_regions`, `hg38_250kb_no_dark_regions` | your genome-bin BEDs |
| `data`, `fileindex`, `trimmed_data` | your input locations (see below) |

The driver scripts in `01_pipeline/` additionally hardcode a SLURM account and
partition (`b1042`, `genomics`/`genomicslong`) and absolute log paths. Adjust those,
or the pipeline's `profiles/slurm`, for your cluster.

QC thresholds and adapter-clipping parameters are the scientific settings — leave
them alone to reproduce the paper.

---

## 3. Entry point A — raw data (default)

Set in the config:

```yaml
start_from: "raw"
data:      "00.raw_data/"        # holds {prefix}_R1_001.fastq.gz, {prefix}_R2_001.fastq.gz
fileindex: "00.raw_data/index.txt"   # one cell barcode per line
```

`start_from: "raw"` **requires** `fileindex` — the workflow raises an error without
it, because that file drives demultiplexing.

The pipeline then runs, per library: demultiplex → FastQC → trim_galore → align
(Bhmem) → BAM processing → QC → Bis-SNP → per-bin methylation.

```bash
bash data_processing/<dataset>/01_pipeline/01_run_pipeline.sh
```

---

## 4. Entry point B — reads from GEO (already demultiplexed)

GEO carries **per-cell** FASTQs, so demultiplexing has already been done — but they
have not been trimmed. Use `start_from: "demultiplexed"`, which skips demultiplexing
and picks the workflow up at trimming:

```yaml
start_from: "demultiplexed"
demul_data: "01.demul_fastq_snakemake"   # where your per-cell fastqs are
# fileindex is OPTIONAL here; set it only to restrict to specific barcodes
```

Name the files:

```
{prefix}.{index}.R1.fastq.gz
{prefix}.{index}.R2.fastq.gz
```

`{prefix}` is the library and `{index}` the cell barcode — e.g.
`scNH_GM_4plex_1_S1.ATCACG.R1.fastq.gz`. Rename the GEO filenames to this pattern if
they differ; the barcodes are auto-derived from the filenames, so no `fileindex` is
needed unless you want to process a subset.

Then run the same driver as in Entry point A. Trimming uses **the same
`trim_galore` parameters as raw mode** (`clip_R1`/`clip_R2` and the two
`three_prime_clip` values from the config), so everything from alignment onward is
identical to a run started from raw data.

Cells can also be selected explicitly with `fastq_prefixes` (inline list) or
`fastq_prefixes_file` (one per line), exactly as in `trimmed` mode.

> **This mode requires pipeline commit `0b94c56` or later.** The results in this
> paper were produced with `a0456b9`, which predates it; the mode only adds an entry
> point and does not change any processing step.

## 4b. A note on the snakemake flags in the drivers

The drivers pass `--rerun-incomplete` and, for the mixture, `--rerun-triggers mtime`.
**On a clean run from scratch both are no-ops** — nothing exists yet, so every job
runs either way. They matter only when resuming.

- **`--rerun-incomplete`** — redoes outputs left half-written by a killed or
  timed-out job. Required to resume at all; snakemake otherwise refuses to start.
  It never skips work, so there is no reason to remove it.
- **`--rerun-triggers mtime`** — narrows snakemake's default (which in v8 is all of
  `code, input, mtime, params, software-env`) down to file timestamps alone. It
  exists so that editing a rule does not invalidate and re-run hundreds of
  already-finished cells on a long HPC run.

  ⚠️ **If you change a parameter in the config and expect the affected steps to
  rerun, drop this flag** — with it, snakemake only notices newer input files, not
  changed parameters, and your outputs will silently stay stale. Use `--forcerun
  <rule>` or `--forceall` to force the work.

The two published drivers take opposite approaches, which is worth knowing if you
run both: `gm12878_cellline` uses `--forceall` (regenerate everything), while
`mixture_cellline` uses `--rerun-triggers mtime` (regenerate as little as possible).
For a reproduction run, `--forceall` is the safer choice.

## 5. Per-dataset entry points as published

| Dataset | `start_from` as run | Note |
|---|---|---|
| `gm12878_cellline` | `raw` | Full chain including demultiplexing — the default path. |
| `mixture_cellline` | `trimmed` | Its raw→trimmed step predates this record and the trimmed FASTQs lived on scratch. To run it from scratch, switch to `raw` and supply `data` + `fileindex`, or use `demultiplexed` if you have per-cell reads. |
| `bulk_scNOMeHiC` | `trimmed` | Bulk libraries are trimmed and split into chunks by that folder's own steps 02–03 before the workflow is invoked. |
| `mouse_cortex` | `trimmed` | Switch to `demultiplexed` for per-cell reads from GEO. |
| `meningioma` | `trimmed` | Three sequencing batches were processed as one set from a single input directory (`trimmed_data: merged_trimmed`). That directory was assembled locally by symlinking three separately-trimmed batch folders — batch 1 had been trimmed by an older, non-snakemake pipeline — which is why the assembly script is not shipped. Starting from GEO, point `demultiplexed_data` at the download and set `start_from: "demultiplexed"`; the workflow trims for itself and the three-way split disappears. |

---

## 6. After the pipeline

Each dataset's `README.md` gives the run order for the steps that follow — QC,
pseudobulk construction, and the products the figure notebooks consume.
