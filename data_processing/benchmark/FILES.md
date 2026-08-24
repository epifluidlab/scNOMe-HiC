# FILES — data_processing/benchmark

Copied from <https://github.com/yoshihiko1218/snomehic_benchmark> @ `236719d`.
169 files, 633K — code, configs and accession lists only.

Each dataset folder keeps its upstream `codes/` directory verbatim, plus its
root-level QC collectors, `acc_list*.txt`, and its own `FILES.md` / `JOBS.md`
where the upstream repo had one. Those per-folder docs are the upstream author's
and describe the working tree there, so they mention output directories that are
not part of this repository.

| Folder | Files |
|---|---|
| `00_shared/` | 4 |
| `scnomehic/` | 13 |
| `nagano/` | 9 |
| `droplethic/` | 7 |
| `scnome/` | 26 |
| `smallwood/` | 17 |
| `snmCAT/` | 15 |
| `snmCseq2/` | 20 |
| `snmCseq3/` | 12 |
| `methylhic/` | 9 |
| `methylhic_new/` | 9 |
| `summary/` | 26 |

`droplethic/` is the exception to the `codes/` shape: upstream it runs out of
`my_project/`, so its `config.yaml`, `runsnakemake.sh`, `run_qc.sh` and the two QC
scripts were lifted to the folder root.

## One source change

`methylhic_new/codes/01.excute_snakemake.sh` line 40 read `fiche` instead of `fi`,
leaving an `if` unterminated — the script fails `bash -n` with "unexpected end of
file" at line 62. Corrected to `fi` here. The typo is still present upstream; its
sibling `methylhic/codes/01.excute_snakemake.sh` is unaffected. Every other file is
byte-identical to the upstream copy, and all 78 shell scripts now parse.

## Not included

| What | Why not |
|---|---|
| `alignment/`, `04.*`, `05.*`, `06.*`, `yap_mapping_*`, `qc_stats/`, `my_project/0*` | Pipeline outputs and per-group generated Snakemake configs, not method. Everything heavy lives on scratch. |
| `figures/` | The published PDFs. The notebook that draws them is `main_figures/fig1/fig1_benchmark_violins.ipynb`. |
| `summary/` cached tables — `qc_tables/`, `trinuc/`, `hic_cache/`, `gch_hcg_counts/`, `*.csv`, `*.pdf`, `benchmark_data_summary.xlsx` | Derived data. The scripts that build them are here. |
| `summary/_archive/`, `_backups/` | One-off notebook-patching scripts and `.ipynb` snapshots. |
| `summary/compare_qc*.py`, `build_data_summary_xlsx.py`, `make_dataset_summaries.py`, `dist_check.py`, `verify_scnome_merge.py` | Kept — they are in `summary/`. Listed here only to note they are side analyses, not on the panel path. |
| `snmCseq3/codes/comparison/` | 51 files of BHMEM/NM alignment debugging (mismatch recomputation, MAPQ comparison, PBAT-correction checks). Investigation, not the processing path. |
| `snmCAT/meta.tsv` | 3.3 MB ENA run manifest, 8,495 rows. The cell list actually used is `snmCAT/codes/cells_brain.tsv` with `download_list_brain.txt`. |
| `notes/`, `PROJECT_CONTEXT.md`, `REORG_PLAN.md`, `cleanup/`, `tools/`, `SESSION_NOTE_*.md` | Session logs, project-management notes and git wrapper scripts. |
| `scratch_keepalive/` | Operational — keeps the scratch tree from being purged. Lives on b1198 at `scnomehic_paper/benchmark/scratch_keepalive/`. |
| `snmCseq2/`'s vendored YAP outputs (6,736 files upstream) | Output tree. Only `codes/` is carried. |
