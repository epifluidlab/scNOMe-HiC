# GM12878 — single-cell NOMe-HiC processing

GM12878 4-plex scNOMe-HiC: **188 cells** (47 libraries `scNH_GM_4plex_*_S*` × 4
barcodes ATCACG / CGATGT / GCCAAT / TGACCA), aligned to **hg38**.
**180 cells pass QC** and carry through to all downstream products.

Raw reads → per-cell methylation, accessibility and contact matrices → pseudobulk
tracks. Figure panels are built from these outputs under `../../main_figures/` and
`../../supplementary_figures/`.

## The pipeline itself is a separate repository

Steps 01–02 are thin callers for the shared Snakemake workflow, which is **not
duplicated here**:

| | |
|---|---|
| Repository | <https://github.com/epifluidlab/sc_NOMeHiC_pipeline> |
| Commit used | `a0456b972f07690ef0425cc852583660c036f277` |
| Provides | `Snakefile`, `rules/{GCHnorm,hiccluster,scnomehic_analysis}.smk`, `scripts/{calcmethylation.py,qc_analysis.py,count_fragment.py,methy_tab_to_pbetabinom.R,bed6plus2bw.pl}`, conda envs, SLURM profile |

Clone it, then run the scripts in `01_pipeline/` against it. `00_config/` holds the
two config files that parameterize it for this dataset.

External tools referenced by the config: Bhmem (`bisulfiteHic`, built 2026-05-11),
Bis-SNP (`Bis-SNP.latest.jar` = BisSNP-1.2.bisqc_walkers, 2026-05-13), Picard,
Bis-tools. References: `GCA_000001405.15_GRCh38_no_alt_analysis_set`,
`Homo_sapiens_assembly38.dbsnp138.vcf`, DpnII restriction sites.

## Run order

### 00_config — dataset parameters

Two configs, because two different entry points were used:

- **`config.main_run.yaml`** — the config that drove the main pipeline run
  (`--configfile` of `run_pipeline_gm_sc_new.sh`). Sets `workdir`, `start_from: raw`,
  adapter clipping (15/15 5′, 5/5 3′), methylation bin sizes (1/50/100/250 kb), and
  the QC thresholds. **This is the authoritative record of the run** — in the original
  layout it lived inside the pipeline repo, where it is overwritten per dataset.
- **`config.hicmatrix.yaml`** — the smaller config used only by
  `gm_hicmatrix_driver.sh`. It predates the main run and omits `bissnp_jar` (the
  driver injects it on the command line).

QC thresholds (both configs): `fragnum > 80000`, `noncpg < 5`, `GCH > 1e6`,
`HCG > 150000`, `transrate > 0.7`, `cis1kbnum > 2000`.

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

**`gm_hicmatrix_driver.sh`** — per-cell Hi-C contact matrices (rules `scbam2hic` +
`hicprocess` only; no imputation or embedding).

- *in*: `04.alignment_snakemake/{prefix}.calmd.bam`, cell list `QC/cellline_prefixes_used.txt`
- *out*: `06.hiccluster_snakemake/{prefix}.hic_matrix.txt.gz` (188 cells)
- `bash gm_hicmatrix_driver.sh -n` for a dry run.

### 02_qc — cell filtering

**`make_qc_notebook.py`** generates **`qc_plots.ipynb`**; edit the generator and
re-run it rather than hand-editing the notebook. Then run the notebook top to bottom.

- *in*: `04.alignment_snakemake/{prefix}.summary.txt.gz`,
  `07.bistools_snakemake/qc/{prefix}/*.calmd.trinuc_methy.{chrM,chr21}.txt.gz`,
  `07.bistools_snakemake/methylation/{prefix}/*.{GCH,HCG}.6plus2.bed.gz`,
  `08.methylation_snakemake/*`, plus thresholds from `00_config/`
- *out*: `QC/cellline_passed.txt` (**180 cells** — the gate for everything below),
  `QC/cellline_prefixes_used.txt`, `QC/cellline_qc_summary.txt`,
  `QC/cellline.{gch_hcg_count,chrM,chr21}.txt`, `QC/methylation_matrices/`,
  and the `figures/cellline_*` PDFs

**`make_qc_excel.py`** builds the reader-facing QC table.

- *in*: the alignment summaries + `QC/cellline.*` aggregates
- *out*: `QC/cellline_qc_table.xlsx` (sheets: Per-cell QC 188 / QC passed 180 /
  Summary stats) and `QC/cellline_qc_table.tsv` (snake_case columns for downstream use)
- Bisulfite conversion is reported as **non-CpG methylation %** (the ACT
  trinucleotide rate); low = good conversion.
- Needs pandas + openpyxl: run with the `scwgbs` env python.

### 03 and 04 — two parallel branches, both gated on `QC/cellline_passed.txt`

### 03_pseudobulk_methylation — pool cells, re-call at pooled depth

Calling on the pooled BAM re-genotypes SNPs at full depth, which per-cell summing
cannot do. Run in order:

1. **`merge_calmd_passed.sh`** (sbatch)
   - *in*: `QC/cellline_passed.txt`, `04.alignment_snakemake/{prefix}.calmd.bam`
   - *out*: `04.alignment_snakemake/merged.sorted.bam` + `.bai`, plus
     `merge_input_list.txt` / `merge_missing.txt`
2. **`call_methylation_array.sh`** (sbatch, `--array=1-23`, one chromosome per task)
   - *in*: `merged.sorted.bam`
   - *out*: `pseudobulk_methylation/<chr>/gm_pseudobulk_merged.<chr>.cyt.filtered.sort.{GCH,HCG}.6plus2.bed.gz`
   - Uses the same `Bis-SNP/bissnp_nomehic_usage.pl` caller as the pipeline's
     `bistools` rule, split by `--interval`. Duplicates are flag-marked but present;
     BisSNP/GATK skips them, so pooled PCR duplicates are not double-counted.
     Re-running skips chromosomes whose outputs already exist.
3. **`merge_methylation.sh`** (sbatch, after the array completes)
   - *in*: the 23 per-chromosome BEDs
   - *out*: genome-wide `gm_pseudobulk_merged.{GCH,HCG}.6plus2.bed.gz` and binned
     `gm_pseudobulk_merged.{GCH,HCG}.{1kb,50kb,100kb,250kb}_methylation.txt.gz`
     (binned with the pipeline's `calcmethylation.py`, same as the per-cell rule)
4. **`make_bedgraph_bigwig.sh`** (sbatch) — genome-browser / deepTools tracks
   - *in*: `gm_pseudobulk_merged.{GCH,HCG}.6plus2.bed.gz`
   - *out*: `gm_pseudobulk_merged.{GCH,HCG}.methlevel.{bedgraph,bw}`
   - Value is column 7 (methylation %, 0–100), no coverage filter; exact-duplicate
     coordinates are collapsed by averaging so `bedGraphToBigWig` accepts the input.

### 04_single_cell_matrices — cell × bin matrices

1. **`make_table.sh`**
   - *in*: `07.bistools_snakemake/methylation/*/*.HCG.6plus2.bed`
   - *out*: `sample_table_hcg.tsv` (two columns: cell, path)
   - As written it emits the HCG table; change `*.HCG.` / `OUT` to produce
     `sample_table_gch.tsv`, which `collapse.sh` also requires.
2. **`collapse.sh`** → **`methylation_collapse.py`**
   - *in*: `sample_table_{gch,hcg}.tsv`, hg38 chrom sizes, gencode v36 GTF, and the
     bin BEDs `genome_bins_{250kb,gene,1kb.no_blacklist}.bed`
   - *out*: `GCH_250kb.txt`, `GCH_gene.txt`, `GCH_1kb.txt`, `HCG_250kb.txt`,
     `HCG_gene.txt` — the cell × bin matrices the figure code consumes
3. **`collapse.ipynb`** — interactive inspection of the collapsed matrices.

## Final outputs

What the rest of the paper reads:

| Product | Path |
|---|---|
| QC-passing cell list (180) | `QC/cellline_passed.txt` |
| Per-cell QC table | `QC/cellline_qc_table.{xlsx,tsv}` |
| Per-cell methylation/accessibility | `08.methylation_snakemake/*.{GCH,HCG}.{1kb,50kb,100kb,250kb}_methylation.txt.gz` |
| Per-cell contact matrices | `06.hiccluster_snakemake/*.hic_matrix.txt.gz` |
| Cell × bin matrices | `{GCH,HCG}_{250kb,gene}.txt.gz`, `GCH_1kb.txt.gz` |
| Pseudobulk per-site methylation | `pseudobulk_methylation/gm_pseudobulk_merged.{GCH,HCG}.6plus2.bed.gz` |
| Pseudobulk tracks | `pseudobulk_methylation/gm_pseudobulk_merged.{GCH,HCG}.methlevel.bw` |

Per-cell `{GCH,HCG}.strand.6plus2` BEDs and `hic_matrix.txt.gz` are the files
deposited as GEO processed data.

## Notes on paths

Every script keeps the absolute paths it ran with (`/gpfs/projects/b1198/...`,
SLURM `--account=b1042`). They document the original run and will need editing for
another system. Original working directory:
`/gpfs/projects/b1198/epifluidlab/yoshii/sc_nomehic_cellline/gm_sc_new`.
