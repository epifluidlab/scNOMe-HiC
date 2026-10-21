# FILES — benchmark/snm3cseq

The snm3C-seq arm of Figure 1 and S1. 100 cells from **PRJNA658701 / GSE156683**
(CEMBA, mouse hippocampus; Liu et al., *Nature* 598:120–128, 2021), processed with
**YAP `m3c`** — the assay's own pipeline, matching the published methods. Pairs with
scNOMe-HiC processed by bisulfiteHic/Bhmem, so each dataset runs under its original
aligner.

| File | What it is | Origin |
|---|---|---|
| `cells100.tsv` | The 100 cells: accession, read count, ENA fastq URLs. Randomly sampled with seed 20260827; sample median 1,176,237 reads against a project median of 1,167,515, so the sample is representative. | `benchmark/snm3c_100/codes/cells100.tsv` |
| `codes/01.setup_and_download.sh` | Downloads and `gzip -t` verifies all 100 cells, then runs a single `yap start-from-cell-fastq`, which emits one Group (and one `snakemake -j 10` command) per cell into `alignment/`. | `benchmark/snm3c_100/codes/stage1_setup.sh` |
| `codes/02.run_cells.sh` | SLURM array, one task per YAP Group, each running that Group's `snakemake -j 10`. Runs the cells concurrently instead of a ~50 h sequential loop. | `benchmark/snm3c_100/codes/stage2_run.sh` |
| `codes/mapping_config.ini` | YAP config. Byte-identical to YAP's shipped `mapping_config_m3c.ini` except the filled-in mm10 references and `min_gap = 1000` (default 2500), to match the ">1 kb" definition used in Figure 1. | `benchmark/snm3c_100/codes/mapping_config.ini` |

Only job names and the `Stage N` → `STEP NN` headers were changed. Commands,
parameters and data paths are verbatim.

## Notes

- `m3c` mode uses bismark/bowtie2; the `hisat3n_*` keys in the config are inert.
- `mapq_threshold` in the config is **never read** — YAP's `m3c` Snakefile hardcodes
  `samtools view -q 10`. The MAPQ30 figures are recomputed downstream, not by YAP.
- `total_read_pairs_max` does not apply because `start-from-cell-fastq` skips
  demultiplexing.
- Outputs consumed downstream: `alignment/` (per-Group `*.3C.contact.tsv.gz` and
  `stats/MappingSummary.csv.gz`), read by
  `../summary/` → `qc_tables/{align,hic}.csv` and the Figure 1 panels.

## Deliberately not included

- **`benchmark/snm3c_100/codes/snm3c100.sh`** — a self-contained variant that
  downloads, sets up and maps in 5 array batches of 20 cells, writing to
  `batchN/alignment/`. The published arm is the two-stage route above, whose output
  is the `alignment/` directory the summary tables read. Kept out to avoid shipping
  two routes to the same product.
- **`ncmds.txt`** — a one-line count (64) written by step 01 and read back by it;
  generated, not method.
