# GM12878 — single-cell NOMe-HiC processing

GM12878 4-plex scNOMe-HiC: **188 cells** (47 libraries `scNH_GM_4plex_*_S*` × 4
barcodes ATCACG / CGATGT / GCCAAT / TGACCA), aligned to **hg38**.
**180 cells pass QC** and carry through to all downstream products.

Raw reads → per-cell methylation and accessibility → QC-filtered cell set. Figure
panels are built from these outputs under `../../main_figures/` and
`../../supplementary_figures/`.

> Downstream steps (pseudobulk methylation tracks, cell × bin matrix collapse) are
> still to be added.

## The pipeline itself is a separate repository

Step 01 is a thin caller for the shared Snakemake workflow, which is **not
duplicated here**:

| | |
|---|---|
| Repository | <https://github.com/epifluidlab/sc_NOMeHiC_pipeline> |
| Commit used | `a0456b972f07690ef0425cc852583660c036f277` |
| Provides | `Snakefile`, `rules/{GCHnorm,hiccluster,scnomehic_analysis}.smk`, `scripts/{calcmethylation.py,qc_analysis.py,count_fragment.py,methy_tab_to_pbetabinom.R,bed6plus2bw.pl}`, conda envs, SLURM profile |

Clone it, then run the script in `01_pipeline/` against it, parameterized by
`00_config/config.main_run.yaml`.

External tools referenced by the config: Bhmem (`bisulfiteHic`, built 2026-05-11),
Bis-SNP (`Bis-SNP.latest.jar` = BisSNP-1.2.bisqc_walkers, 2026-05-13), Picard,
Bis-tools. References: `GCA_000001405.15_GRCh38_no_alt_analysis_set`,
`Homo_sapiens_assembly38.dbsnp138.vcf`, DpnII restriction sites.

## Run order

### 00_config — dataset parameters

**`config.main_run.yaml`** is the single config for this dataset, and the
authoritative record of the run: `workdir`, references and tool paths,
`start_from: raw`, adapter clipping (15/15 5′, 5/5 3′), methylation bin sizes
(1/50/100/250 kb), and the QC thresholds.

In the original layout this file lived *inside* the pipeline repo, where it is
overwritten for each new dataset — hence keeping it here.

QC thresholds: `fragnum > 80000`, `noncpg < 5`, `GCH > 1e6`, `HCG > 150000`,
`transrate > 0.7`, `cis1kbnum > 2000`.

### 01_pipeline — run the Snakemake workflow

**`run_pipeline_gm_sc_new.sh`** — `sbatch` driver for the full per-cell chain.
A lightweight long-walltime allocation (genomicslong, 7 d) runs Snakemake with the
SLURM profile, which submits each rule as its own child job (`-j 1000`).

- *in*: `00.raw_data/` paired FASTQs + `index.txt` barcode list
- *out*: `01.demul_fastq_snakemake/` → `02.fastqc_out_snakemake/` →
  `03.trimmed_fastq_snakemake/` → `04.alignment_snakemake/` (Bhmem; `{prefix}.calmd.bam`,
  `{prefix}.summary.txt.gz`) → `07.bistools_snakemake/` (Bis-SNP; per-cell
  `{GCH,HCG}.6plus2.bed.gz`, trinucleotide QC) → `08.methylation_snakemake/`
  (per-cell `{GCH,HCG}.{1kb,50kb,100kb,250kb}_methylation.txt.gz`)

### 02_qc — cell filtering

**`qc_plots.ipynb`** — run top to bottom in Jupyter. Builds the per-cell aggregate
tables, applies the thresholds from `00_config/`, and plots the QC summary.

- *in*: `04.alignment_snakemake/{prefix}.summary.txt.gz`,
  `07.bistools_snakemake/qc/{prefix}/*.calmd.trinuc_methy.{chrM,chr21}.txt.gz`,
  `07.bistools_snakemake/methylation/{prefix}/*.{GCH,HCG}.6plus2.bed.gz`,
  `08.methylation_snakemake/*`
- *out*: `QC/cellline_passed.txt` (**180 cells** — the gate for everything downstream),
  `QC/cellline_prefixes_used.txt`, `QC/cellline_qc_summary.txt`,
  `QC/cellline.{gch_hcg_count,chrM,chr21}.txt`, `QC/methylation_matrices/`,
  and the `figures/cellline_*` PDFs

Bisulfite conversion is assessed as **non-CpG methylation %** (the ACT trinucleotide
rate from the `trinuc_methy` tables); low = good conversion.

## Outputs

| Product | Path |
|---|---|
| QC-passing cell list (180 of 188) | `QC/cellline_passed.txt` |
| Per-cell QC metrics | `QC/cellline_qc_summary.txt` |
| Per-cell methylation / accessibility | `08.methylation_snakemake/*.{GCH,HCG}.{1kb,50kb,100kb,250kb}_methylation.txt.gz` |
| Per-cell per-site methylation | `07.bistools_snakemake/methylation/*/*.{GCH,HCG}.6plus2.bed.gz` |
| Aligned per-cell reads (input to Hi-C) | `04.alignment_snakemake/*.calmd.bam` |

## A note on Hi-C contacts

There is no per-cell contact-matrix step here, and none is needed. The GM12878
pseudobulk and bulk `.hic` files are built **directly from the per-cell
`calmd.bam`** — `samtools view -q30 -f1 -F1804` → `sam2juicer_new.py` →
`juicer pre -f DpnII` — in the Hi-C comparison code, which lives with the figure
that uses it. Nothing in the analysis or figure code reads the pipeline's
`06.hiccluster_snakemake/*.hic_matrix.txt.gz`; that rule set (schicluster
imputation and embedding) is used for the mouse cortex dataset, not for this
homogeneous cell line.

## Notes on paths

Every script keeps the absolute paths it ran with (`/gpfs/projects/b1198/...`,
SLURM `--account=b1042`). They document the original run and will need editing for
another system. Original working directory:
`/gpfs/projects/b1198/epifluidlab/yoshii/sc_nomehic_cellline/gm_sc_new`.
