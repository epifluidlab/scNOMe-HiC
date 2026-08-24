# benchmark — the published single-cell methods compared in Figure 1 and S1

Download, alignment and per-cell QC for the six published single-cell methods that
appear in the panels, run the same way so their per-cell yield can be compared with
scNOMe-HiC. The violins are drawn in
`../../main_figures/fig1/fig1_benchmark_violins.ipynb`.

| Folder | Method | Publication |
|---|---|---|
| `scnomehic/` | scNOMe-HiC | this paper |
| `droplethic/` | Droplet Hi-C | Chang et al. 2025 |
| `scnome/` | scNOMe-seq | Pott et al. 2017 |
| `smallwood/` | scWGBS | Smallwood et al. 2014 |
| `snmCseq2/` | snmC-seq2 | Luo et al. 2018 |
| `snmCseq3/` | snm3C-seq | Liu et al. 2023 |
| `snmCAT/` | snmCAT-seq | Luo et al. 2022 |

## Layout

Each dataset folder holds its `codes/` (the pipeline it was run with), its
accession list, and any per-dataset QC collector. `00_shared/` holds the tools
called across datasets, `summary/` the cross-method aggregation.

| Folder | What it is |
|---|---|
| `00_shared/bam_summary_universal.py` | BAM → alignment and Hi-C summary. Called by the per-dataset pipelines. |
| `00_shared/build_trinuc_summary.py`, `parse_bissnp_trinuc.py` | Trinucleotide methylation summary from Bis-SNP output. |
| `00_shared/analysis_pipeline.md` | The processing recipe each dataset follows. |
| `summary/` | Builds the cross-method tables the notebook reads — see below. |

## Run order, per dataset

Each `codes/` folder is numbered in run order and follows the same shape:

```
00.rename_fastq_header  →  01.trim  →  02.alignment  →  03.bamprocess / summary
```

with per-method variations (`yap` for the snmC family, Snakemake for Droplet Hi-C).
`mapping_config*.ini` carries the aligner settings.

## summary — the cross-method tables

Run after every dataset's pipeline. These produce exactly what the notebook reads:

| Script | Writes |
|---|---|
| `build_qc_tables.py` | `qc_tables/{align,hic}.csv` — the read-count, mapping-rate and Hi-C metrics |
| `collect_conversion.py` | `conversion_percell.csv` — bisulfite non-conversion |
| `extract_trinuc*.py`, `run_extract_trinuc.sh` | `trinuc/<dataset>.chr{19,21}.txt` |
| `frag_counts.py`, `frag_droplethic.py` | the Hi-C fragment counts behind `hic_cache/` |
| `count_gch_hcg.py`, `hcg_lib.py`, `count_hcg_destranded.py`, `assemble_hcg_all.py` | `gch_hcg_counts/all_methods.*` — the detected-loci counts behind the Figure 1 panels |

`<dataset>/codes/compute_hcg.py` does the per-method HCG calculation that
`count_hcg_destranded.py` drives.

## Notes

- **HCG means covered CpG with GCG removed**, one definition for every method, but
  how GCG is removed depends on how the caller was run — hence a `compute_hcg.py`
  per dataset. The four non-scNOMe-HiC methylation datasets use Bismark or allcools
  rather than Bis-SNP, because Bis-SNP's `-mmq 30` cut drops ~95% of low-MAPQ PBAT
  reads very unevenly (3–21× fewer loci). scNOMe-HiC is the exception and keeps its
  native Bis-SNP NOMe pipeline, so it still carries the MAPQ ≥ 30 cut.
- The scNOMe-HiC arm of the comparison is generated in
  `../gm12878_cellline/06_benchmark_qc/`, not here.
- **The notebook still loads Nagano** (scHi-C) in its Hi-C cells, but plots it
  nowhere: `dataset_order` is reassigned before every panel is drawn, so even the
  panels *not* named `_no_nagano` exclude it. Its processing is therefore not
  carried here. Methyl-HiC never enters the notebook at all.
- Every intermediate lives on scratch — see `../../README.md`. This folder is code
  only, so paths in these scripts are a record of the original run.
- Upstream repository: <https://github.com/yoshihiko1218/snomehic_benchmark>,
  commit `236719d`.
