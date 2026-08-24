# FILES — data_processing/barnyard_mixing

5 files. See `README.md` for the run order and what each step consumes and produces.

`$BY` = `/gpfs/projects/b1198/epifluidlab/yoshii/scnomehic_paper/s3/snakemake`

| File | What it is | Origin |
|---|---|---|
| `README.md` | Run order, why the run stops at QC, how species assignment works. | written for this repo |
| `FILES.md` | This file. | written for this repo |
| `00_config/config.yaml` | `start_from: trimmed`, combined `hg38_mm10` reference, `enzyme_list` → the locally built DpnII bedgraph, `hicluster_chromosomes` pinned to avoid a parse-time `chrom.sizes` read. | `$BY/config.yaml` |
| `01_pipeline/00_setup_workdir.sh` | One-time and idempotent: builds the combined DpnII span-region bedgraph and the `merged_trimmed/` symlinks for the 96 cells. | `$BY/setup_workdir.sh` |
| `01_pipeline/01_run_pipeline.sh` | Snakemake driver, `--until qc` — alignment and QC only. | `$BY/run_pipeline.sh` |
| `02_species_counts/01_extract_species_counts.sh` | Parallel driver over the 96 `calmd.bam`s → `species_read_counts.tsv`. | `$BY/code/extract_species_counts.sh` |
| `02_species_counts/_species_worker.sh` | Per-cell worker: HQ counts (`-f 2 -q 30 -F 3852`) split by contig prefix, plus `idxstats` totals. | `$BY/code/_species_worker.sh` |

## Edits made

Renumbered into run order. One comment fixed: `01_extract_species_counts.sh`
described the worker as `code/_species_worker.sh`, which is now a sibling. No
command, parameter or data path changed; `HERE` already resolved via
`readlink -f "$0"`, so the worker is found wherever the folder sits. All scripts
pass `bash -n`.

## Deliberately not included

- **`$BY/reference/hg38_mm10.DpnII.span_region.bedgraph`** — ~13.9 M intervals,
  built by `00_setup_workdir.sh` from the hg38 and mm10 bedgraphs. Generated, not
  source.
- **`$BY/merged_trimmed/`** — 192 symlinks, also built by step 0.
- **`$BY/code/build_barnyard_nb.py`** — generator for `species_barnyard.ipynb`.
  As with the other datasets, the notebook is the method and the generator is
  authoring tooling.
- **`$BY/species_read_counts.tsv` and `.classified.tsv`** — outputs of the
  counting step and the notebook.
- **`04.alignment_snakemake/`, `logs/`, `benchmarks/`** — run products.
