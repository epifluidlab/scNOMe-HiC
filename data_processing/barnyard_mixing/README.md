# Barnyard — human/mouse species-mixing scNOMe-HiC

The **GM_F123** species-mixing control: human GM12878 and mouse F123 cells
sequenced together, **96 cells**, aligned to a **combined hg38 + mm10** reference.
Because human contigs are named `chr*` and mouse contigs `mm10_chr*`, every read
can be assigned to a species — which is what makes the collision rate and per-cell
purity measurable.

Feeds **Supplementary Figure S4** (`../../supplementary_figures/figS4/`).

## Scope — alignment and QC only

The pipeline is run with `--until qc`, so the per-cell chain is
`mapping → bamprocess → qc` (288 jobs = 96 × 3). The `bisqc`, `bistools` and
`methylation` stages are deliberately **not** run: they need a dbSNP VCF and no
combined dbSNP exists for a mixed genome. They are also unnecessary here — the
figure needs per-cell human versus mouse read counts, nothing downstream of
alignment.

This is why the folder has no QC-gate or methylation-matrix step, unlike the
other datasets.

## Run order

### 00_config

`config.yaml`: `start_from: trimmed`, the combined `hg38_mm10` reference, and
`enzyme_list` pointing at the locally built DpnII bedgraph. `hicluster_chromosomes`
is pinned so the workflow does not read `{reference}.chrom.sizes` at parse time.

### 01_pipeline

| Step | What it does |
|---|---|
| `00_setup_workdir.sh` | One-time, idempotent. Builds `reference/hg38_mm10.DpnII.span_region.bedgraph` — hg38's DpnII spans as-is plus mm10's with `mm10_` prefixed, filtered to contigs present in the combined `.fai` (~13.9 M intervals, 7.20 M human + 6.68 M mouse) — and the `merged_trimmed/` symlinks. |
| `01_run_pipeline.sh` | Snakemake driver, `--until qc`. |

The shared reference had no DpnII enzyme file for the combined genome, which is
why step 0 builds one. That file is generated, not shipped.

### 02_species_counts

| Step | What it does |
|---|---|
| `01_extract_species_counts.sh` | Runs the worker over all 96 `calmd.bam`s in parallel → `species_read_counts.tsv`. |
| `_species_worker.sh` | One cell: high-quality counts are proper-pair, MAPQ ≥ 30, deduplicated primary reads (`-f 2 -q 30 -F 3852`) split by contig prefix (`mm10_*` = mouse); `all` counts come from `idxstats`. |

Both counts are kept because they answer different questions — the HQ counts are
what the barnyard plot uses, while `all` shows how much a cell loses to filtering.

## Input

96 already demultiplexed and trim_galore'd cells,
`demul_sc{49..72}.{ATCACG,CGATGT,GCCAAT,TGACCA}`, symlinked into
`merged_trimmed/` by step 0.

## Outputs

| Product | Path |
|---|---|
| Per-cell alignments | `04.alignment_snakemake/` |
| Per-cell species counts | `species_read_counts.tsv` |

The classification into Human / Mouse / Mixed / LowDepth is made in the figure
notebook, not here.

## Notes on paths

Scripts keep the absolute paths they ran with. Original working directory:
`/gpfs/projects/b1198/epifluidlab/yoshii/scnomehic_paper/s3/snakemake`.
