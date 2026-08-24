# GM12878 — single-cell NOMe-HiC processing

GM12878 4-plex scNOMe-HiC: **188 cells** (47 libraries `scNH_GM_4plex_*_S*` × 4
barcodes ATCACG / CGATGT / GCCAAT / TGACCA), aligned to **hg38**.
**180 cells pass QC** and carry through to all downstream products.

This folder covers everything up to **data generation**. The figure panels are
built from these outputs by the notebooks in `../../main_figures/fig1/`.

Raw reads → per-cell methylation, accessibility and contacts → QC gate →
**pseudobulk** in three modalities: the single-cell arm of the Figure 1 comparison
against bulk NOMe-HiC, which is processed in `../bulk_scNOMeHiC/`.

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

To run this from scratch on your own machine, see **[../../RUNNING.md](../../RUNNING.md)**.

External tools referenced by the config: Bhmem (`bisulfiteHic`, built 2026-05-11),
Bis-SNP (`Bis-SNP.latest.jar` = BisSNP-1.2.bisqc_walkers, 2026-05-13), Picard,
Bis-tools, juicer_tools. References:
`GCA_000001405.15_GRCh38_no_alt_analysis_set`,
`Homo_sapiens_assembly38.dbsnp138.vcf`, DpnII restriction sites.

## Run order

### 00_config — dataset parameters

**`config.main_run.yaml`** is the single config for this dataset, and the
authoritative record of the run: `workdir`, references and tool paths,
`start_from: raw`, adapter clipping (15/15 5′, 5/5 3′), methylation bin sizes
(1/50/100/250 kb), and the QC thresholds.

In the original layout this file lived *inside* the pipeline repo, where it is
overwritten for each new dataset — hence keeping it here.

QC thresholds: `fragnum > 100000`, `noncpg < 5`, `GCH > 1e6`, `HCG > 150000`,
`transrate > 0.7`, `cis1kbnum > 2000`.

`fragnum_threshold` was **80,000 when this dataset was run** and has been raised to
100,000 here so all four datasets share one value. The change is inert: the lowest
`fragnum` among the 180 passing cells is 1,565,866 — about 15× either cutoff — and
no cell falls between 80,000 and 100,000, so the passing set is identical either
way. This is the only place the published config departs from the config as run.

### 01_pipeline — run the Snakemake workflow

**`01_run_pipeline.sh`** — `sbatch` driver for the full per-cell chain. A
lightweight long-walltime allocation (genomicslong, 7 d) runs Snakemake with the
SLURM profile, which submits each rule as its own child job (`-j 1000`).

This driver is **identical across datasets** apart from its job name and which
config it points at — see `../mixture_cellline/01_pipeline/01_run_pipeline.sh`.
`sbatch 01_run_pipeline.sh` to run, `bash 01_run_pipeline.sh -n` to dry-run.

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
- *out*: `QC/cellline_passed.txt` (**180 cells** — the gate for everything below),
  `QC/cellline_prefixes_used.txt`, `QC/cellline_qc_summary.txt`,
  `QC/cellline.{gch_hcg_count,chrM,chr21}.txt`, `QC/methylation_matrices/`,
  and the `figures/cellline_*` PDFs

Bisulfite conversion is assessed as **non-CpG methylation %** (the ACT trinucleotide
rate from the `trinuc_methy` tables); low = good conversion.

### 03_pseudobulk — pool the 180 cells into a bulk-equivalent, in 3 modalities

Gated on `QC/cellline_passed.txt`.

This is the single-cell arm of the Figure 1 comparison. Pooling and re-calling at
full depth (rather than summing per-cell calls) re-genotypes SNPs at pooled
coverage, which per-cell summing cannot do.

Steps 01–03 deliberately mirror `../bulk_scNOMeHiC/` steps 07–09 — merge, scatter
Bis-SNP by chromosome, concatenate and bin — so the two arms of the comparison are
processed identically. Step 04 uses the same good-reads filter as the bulk `.hic`.

1. **`01_merge_calmd_passed.sh`** (sbatch)
   - *in*: `QC/cellline_passed.txt`, `04.alignment_snakemake/{prefix}.calmd.bam`
   - *out*: `04.alignment_snakemake/merged.sorted.bam` + `.bai`
2. **`02_call_methylation_array.sh`** (sbatch, `--array=1-23`, one chromosome per task)
   - *in*: `merged.sorted.bam`
   - *out*: `pseudobulk_methylation/<chr>/gm_pseudobulk_merged.<chr>.cyt.filtered.sort.{GCH,HCG}.6plus2.bed.gz`
   - Same `Bis-SNP/bissnp_nomehic_usage.pl` caller as the pipeline's `bistools`
     rule, split by `--interval`. Duplicates are flag-marked but present; BisSNP
     skips them, so pooled PCR duplicates are not double-counted. Re-running skips
     chromosomes already complete.
3. **`03_merge_methylation.sh`** (sbatch, after the array completes)
   - *in*: the 23 per-chromosome BEDs
   - *out*: **`gm_pseudobulk_merged.{GCH,HCG}.6plus2.bed.gz`** ← *accessibility +
     methylation, 2 of the 3 modalities*, plus binned
     `{1kb,50kb,100kb,250kb}_methylation.txt.gz` (binned with the pipeline's
     `calcmethylation.py`, same as the per-cell rule)
4. **`04_build_pseudobulk_hic.sh`** (sbatch)
   - *in*: per-cell `04.alignment_snakemake/*_sorted_by_name.calmd.bam` (all 188)
   - *out*: **`hic_comparison/gm_pseudobulk.dedup.mapQ30.hic`** ← *3rd modality*
   - Per-cell `samtools view -q30 -f1 -F1804` → `sam2juicer_new.py` → 8-column
     short → sort → `juicer_tools pre -f DpnII`. The good-reads filter is applied
     **before** sam2juicer, byte-for-byte matching the bulk, so both arms exclude
     PCR duplicates. An earlier build that omitted this included ~56 % duplicate
     reads and is not used.
   - Per-cell processing runs in parallel, which keeps sam2juicer's orphan buffer small.
5. **`05_make_bedgraph_bigwig.sh`** (sbatch) — genome-browser / deepTools tracks
   - *in*: `gm_pseudobulk_merged.{GCH,HCG}.6plus2.bed.gz`
   - *out*: `gm_pseudobulk_merged.{GCH,HCG}.methlevel.{bedgraph,bw}`
   - Value is column 7 (methylation %, 0–100), no coverage filter; exact-duplicate
     coordinates are collapsed by averaging so `bedGraphToBigWig` accepts the input.

### 04_saturation — sequencing saturation (Supplementary Fig. S5)

Measures how much of each library's complexity the sequencing captured, by
subsampling reads and re-measuring four metrics at each depth.

| Step | What it does |
|---|---|
| `00_config.sh` | All paths and parameters; sourced by every other step. `CODE_DIR` resolves to this folder. |
| `01_make_tasklist.sh` | Writes `tasks.tsv` — one `CELL⇥FRACTION` line per array task (180 cells × 6 fractions). |
| `02_run_one.sh` | One task: subsample → markdup → contact summary → Bis-SNP → `results/{cell}.f{frac}.tsv`. Idempotent; deletes its scratch BAMs. |
| `03_submit_array.sbatch` | SLURM array wrapper around step 2. |
| `04_extract_full_depth.sh` | The f = 1.0 point, read from the existing full-depth pipeline outputs rather than recomputed. |
| `05_collect_results.sh` | Concatenates every result line into `saturation_results.tsv`. |

Two choices make the curve meaningful. **Subsampling happens before
de-duplication** — saturation is a statement about PCR duplicates, so each depth
is deduplicated afresh; thinning an already-deduplicated BAM would give a
straight line. And a **fixed `samtools view -s` seed** makes the depths nested,
so each cell's curve is monotonic by construction rather than by luck.

Fractions are 0.05, 0.1, 0.2, 0.4, 0.6, 0.8, plus 1.0 from step 4.

Intermediates and per-task results live on b1042 scratch
(`SCRATCH_DIR` in `00_config.sh`), not here.

The fit and figures are in `../../supplementary_figures/figS5/`.

### 05_profiles — CTCF and TSS metaprofiles (Supplementary Fig. S3)

deepTools profiles of the pseudobulk GCH and HCG bigwigs from step 3 around CTCF
sites and transcription start sites.

| Step | What it does |
|---|---|
| `01_setup_regions.sh` | Stages the region BEDs: GM12878 CTCF ChIP-seq peaks (TSS-excluded), an oriented CTCF motif set, and gencode v45 TSS split into CGI and non-CGI (+2 kb shore). |
| `02_plot_ctcf.sh` | `computeMatrix` with **GCH and HCG in one matrix** so they overlay in one figure, then `plotProfile`/`plotHeatmap`. |
| `03_plot_cgi.sh` | The same at TSS, with **both region sets in one matrix** so `--perGroup` gives one panel per set. Its `plotHeatmap` output is an S3 panel. |

Both plotting jobs pass `--missingDataColor white`: the per-site tracks cover ~6.3%
of bases, so ~27% of bins are NaN and deepTools' default black renders the heatmap
almost solid. `--missingDataAsZero` is not used — it would treat "not measured" as
"unmethylated".

The dual-axis overlays are in `../../supplementary_figures/figS3/`.

## Outputs

What the figure code reads:

| Product | Path |
|---|---|
| QC-passing cell list (180 of 188) | `QC/cellline_passed.txt` |
| Per-cell QC metrics | `QC/cellline_qc_summary.txt` |
| Per-cell methylation / accessibility | `08.methylation_snakemake/*.{GCH,HCG}.{1kb,50kb,100kb,250kb}_methylation.txt.gz` |
| Per-cell per-site methylation | `07.bistools_snakemake/methylation/*/*.{GCH,HCG}.6plus2.bed.gz` |
| **Pseudobulk accessibility** | `pseudobulk_methylation/gm_pseudobulk_merged.GCH.6plus2.bed.gz` (1.5 G) |
| **Pseudobulk methylation** | `pseudobulk_methylation/gm_pseudobulk_merged.HCG.6plus2.bed.gz` (194 M) |
| **Pseudobulk contacts** | `hic_comparison/gm_pseudobulk.dedup.mapQ30.hic` (1.5 G) |
| Pseudobulk tracks | `pseudobulk_methylation/gm_pseudobulk_merged.{GCH,HCG}.methlevel.bw` |

The three bold rows are the single-cell arm of the Figure 1 comparison; their bulk
counterparts come from `../bulk_scNOMeHiC/`. The Figure 1 R notebook reads those
`.6plus2.bed.gz` files directly and does its own binning, so the per-bin
`*_methylation.txt.gz` tables are produced but not required by the figure.

## A note on per-cell Hi-C contact matrices

There is no per-cell contact-matrix step here, and none is needed. The pseudobulk
`.hic` is built in `03_pseudobulk/04_` directly from the per-cell `calmd.bam`.
Nothing in the analysis or figure code reads the pipeline's
`06.hiccluster_snakemake/*.hic_matrix.txt.gz`; that rule set (schicluster
imputation and embedding) is used for the mouse cortex dataset, not for this
homogeneous cell line.

## Notes on paths

Every script keeps the absolute paths it ran with (`/gpfs/projects/b1198/...`,
SLURM `--account=b1042`). They document the original run and will need editing for
another system. Original working directory:
`/gpfs/projects/b1198/epifluidlab/yoshii/sc_nomehic_cellline/gm_sc_new`.
