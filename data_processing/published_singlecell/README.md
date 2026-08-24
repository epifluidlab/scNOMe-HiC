# Published single-cell datasets — the Figure S2 comparison

Four external GM12878 single-cell datasets, reprocessed to hg38 pseudobulk so each
scNOMe-HiC modality can be compared against an independent single-cell assay of the
same thing. Panels are built in `../../supplementary_figures/figS2/`.

| Folder | Dataset | Compared against |
|---|---|---|
| `scwgbs_dropbs/` | Drop-BS scWGBS, GM12878, SRA `SRR19391270` | HCG methylation |
| `scimet/` | sci-MET, Mulqueen et al. 2018, SRA `SRR6398696` (GSE112554) | HCG methylation |
| `snatac_dnase/` | ENCODE snATAC `ENCSR680NPV` + DNase `ENCSR581CCT` | GCH accessibility |
| `schic/` | sci-Hi-C, Kim et al. 2020, `GM12878-IMR90.R1` | Hi-C contacts |

Each chain is self-contained; they can be run in any order. The scNOMe-HiC side of
every comparison is the GM12878 pseudobulk from `../gm12878_cellline/03_pseudobulk/`.

## scwgbs_dropbs — Drop-BS scWGBS

`config.sh` holds every shared path and threshold and is sourced by all steps.
`run_all.sh` submits them to SLURM in dependency-chained phases
(`bulk` → `align` → `postqc`).

| Step | What it is |
|---|---|
| `download.sh` | GM12878 FASTQ from the ENA mirror of `SRR19391270`. |
| `00_setup_env.sh` | Creates the `scwgbs` and `scwgbs_r` conda envs. |
| `01_whitelist.sh` | `umi_tools whitelist` → cell-barcode whitelist from R2. |
| `02_extract.sh` | `umi_tools extract` → filter to whitelist, barcode into the header. |
| `03_trim.sh` | Trim Galore `--paired --clip_R1 15 --clip_R2 40`. |
| `04_demux_idemp.sh` → `_split_percell.py` | Per-cell FASTQ split by header barcode. Writes `cell_list.txt`. |
| `05_align_bismark.sh` | Array. Bismark bowtie2 — R2 default, R1 `--pbat`. |
| `06_qc_filter.sh` → `_parse_bismark_qc.py` | Filter cells on mapping efficiency (≥ 10%) and reads (≥ 10,000) → `passing_cells.txt`. **2,628 / 4,998 cells pass.** |
| `_submit_postqc.sh` | Launcher job: sizes the 07/08/09 arrays to the passing-cell count. |
| `07_merge_dedup.sh` | Array. Sort, `bamtools merge` R1+R2, picard dedup. |
| `08_call_methylation.{sh,R}` | Array. methylKit per-cytosine calls, all contexts. |
| `09_build_allc.{sh,py}` | Array. methylpy-format allc per cell, with trinucleotide context. |
| `10_remove_gcg.{sh,py}` | Drops GCG-context cytosines, so the CpG track is comparable to NOMe HCG. |
| `13_pseudobulk_persite.{sh,py}` | Pools every GCG-free allc into one per-CpG-site pseudobulk. |
| `13b_merge_cpg_strands.py` | Collapses to one entry per CpG (both strands summed), matching the NOMe-HiC 6plus2 convention. |

- *out*: `work/13_persite/wgbs_pseudobulk_HCG.cpgmerged.tsv.gz`

## scimet — sci-MET

| Step | What it is |
|---|---|
| `download.sh` | `SRR6398696` from ENA. |
| `10_split.sh` | Splits the run into 61 chunks for the alignment array. |
| `11_align.sh` | Array. Bismark hg38 SE directional on the genomic read (`_2`). |
| `12_methylation.sh` | `coverage2cytosine --merge_CpG` over the pooled alignments. |
| `13_to_hcg.py` | GCG removal → per-CpG HCG track. |
| `METHODS.md` | The barcode investigation and why the run is processed as pseudobulk. |

- *out*: `work/scmet/sciMET_pseudobulk_HCG.cpgmerged.tsv.gz`

## snatac_dnase — snATAC and DNase

| Step | What it is |
|---|---|
| `00_download.sh` | ENCODE: 3 DNase peak beds + 3 signal bigWigs (`ENCSR581CCT`), snATAC BAM `ENCFF995ATT` (`ENCSR680NPV`). |
| `01_merge_dnase.sh` | Merges peaks across the 3 replicates (autosomes) → `dnase_peaks.merged.bed`; averages the signal bigWigs → `dnase.mean.bw`. |
| `02_snatac_bamcoverage.sh` | `bamCoverage --normalizeUsing CPM --binSize 25 --ignoreDuplicates` → `snatac.cpm.bw`. |
| `05_scatter.{sh,py}` | `multiBigwigSummary BED-file` over the merged peaks → `peak_signal.tab`. |
| `06_gch_coverage.sh` | Per-peak GpC read coverage and site count from the pseudobulk GCH 6plus2 → `peak_gch_coverage.tab`. |

- *out*: `data/peak_signal.tab`, `data/peak_gch_coverage.tab`

## schic — sci-Hi-C

`config.sh` holds the paths and the resolution list; `run_pipeline.sbatch` runs
01→05 at 2.5 Mb and `run_multires.sbatch` adds the 500 kb and 1 Mb dumps.

| Step | What it is |
|---|---|
| `00_download_refs.sh` | UCSC `hg19ToHg38.over.chain.gz` and `hg19.chrom.sizes`. |
| `01_pool_gm.py` | Extracts the 489 GM12878-labelled cells and pools their raw cis counts at 500 kb (hg19). |
| `02_liftover.sh` | `liftOver` of the 500 kb bin midpoints, hg19 → hg38. |
| `03_rebin_hg38.py` | Maps contacts through the lifted anchors (both ends must stay cis on the same chromosome) and re-bins at 500 kb / 1 Mb / 2.5 Mb. |
| `04_dump_nomehic.sh` | `juicer dump observed NONE` of the scNOMe-HiC dedup `.hic` at the same resolutions. |
| `05_scc.py` | Per-chromosome `.cool` → `hicrepSCC(H=3)` → the SCC table and boxplots. |

- *out*: `work/dump_multires/{nomehic,schic_gm}_{500kb,1Mb,2.5Mb}_{chr}.txt`

## Notes

- **sci-MET is pseudobulk, not per-cell.** Only the i7 index survives in the SRA
  deposit — the tn5/i5 barcodes are unrecoverable — so cells cannot be demultiplexed.
  The run is pure GM12878, so pooling is valid. See `scimet/METHODS.md`.
- **sci-Hi-C uses the authors' pre-labelled matrices, not the 4DN FASTQ.** The 4DN
  deposit (`4DNEXE63LNM5`) is a 50/50 GM12878 + IMR-90 mixture sharing files and
  barcodes across both experiments, and is login-gated. The Kim 2020 project page
  openly hosts per-cell 500 kb matrices with the authors' cell-type labels, giving a
  clean GM12878-only pseudobulk (489 of 590 cells in `GM12878-IMR90.R1`).
- **Only 500 kb / 1 Mb / 2.5 Mb are reachable for the sci-Hi-C SCC.** The source
  matrices are processed at 500 kb, so they can only be aggregated coarser; 250 kb
  would require reprocessing the raw FASTQ.
- Scripts keep the absolute paths they ran with; `config.sh` in each chain is where
  to point them elsewhere. Original working directory: `scnomehic_paper/s2_new/`.
