# Barnyard — human/mouse species-mixing scNOMe-HiC

The **GM_F123** control: human GM12878 and mouse F123 cells sequenced together,
**96 cells**, aligned to a combined hg38 + mm10 reference. Human contigs are `chr*`
and mouse contigs `mm10_chr*`, so every read is assignable to a species.

Feeds Supplementary Figure S4 (`../../supplementary_figures/figS4/`).

Pipeline: <https://github.com/epifluidlab/sc_NOMeHiC_pipeline>. Running from
scratch: [../../RUNNING.md](../../RUNNING.md). This dataset ran from
`start_from: trimmed`, `--until qc`.

## Run order

| Step | What it is |
|---|---|
| `00_config/config.yaml` | Snakemake config: combined `hg38_mm10` reference, DpnII bedgraph, `hicluster_chromosomes` pinned. |
| `01_pipeline/00_setup_workdir.sh` | One-time. Builds `reference/hg38_mm10.DpnII.span_region.bedgraph` (hg38 spans plus mm10 spans with `mm10_` prefixed, ~13.9 M intervals) and the `merged_trimmed/` symlinks. |
| `01_pipeline/01_run_pipeline.sh` | Snakemake driver, `--until qc`. 288 jobs = 96 cells × (mapping, bamprocess, qc). |
| `02_species_counts/01_extract_species_counts.sh` | Runs the worker over all 96 `calmd.bam`s → `species_read_counts.tsv`. |
| `02_species_counts/_species_worker.sh` | One cell. High-quality counts are `-f 2 -q 30 -F 3852` (proper-pair, MAPQ ≥ 30, deduplicated primary) split by contig prefix; `all` counts come from `idxstats`. |

## Input

96 demultiplexed, trim_galore'd cells —
`demul_sc{49..72}.{ATCACG,CGATGT,GCCAAT,TGACCA}` — symlinked into `merged_trimmed/`
by step 0.

## Outputs

| Product | Path |
|---|---|
| Per-cell alignments | `04.alignment_snakemake/` |
| Per-cell species counts | `species_read_counts.tsv` |

## Notes

- The `bisqc`, `bistools` and `methylation` stages are not run: they need a dbSNP VCF
  and none exists for a mixed genome. The figure needs only per-cell human vs mouse
  read counts. This is why the folder has no QC-gate or methylation-matrix step.
- The shared reference had no DpnII file for the combined genome, so step 0 builds
  one. That file is generated, not shipped.
- Both HQ and `all` counts are kept: HQ is what the barnyard plot uses, `all` shows
  how much a cell loses to filtering.
- Human/Mouse/Mixed/LowDepth classification is made in the figure notebook, not here.
- Scripts keep the absolute paths they ran with. Original working directory:
  `scnomehic_paper/s3/snakemake`.
