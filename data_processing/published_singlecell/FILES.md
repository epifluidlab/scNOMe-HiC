# FILES — data_processing/published_singlecell

All scripts copied verbatim from `scnomehic_paper/s2_new/`. No renaming, no path
rewriting. Numbering gaps are the source numbering: the dropped steps are listed
under "Not included".

| Folder | Origin |
|---|---|
| `scwgbs_dropbs/` | `s2_new/code/` |
| `scimet/` | `s2_new/code/scmet/` |
| `snatac_dnase/` | `s2_new/atac_dnase_gm12878/scripts/` |
| `schic/` | `s2_new/schic_gm12878/code/` |

Files prefixed `_` are helpers called by a numbered step, not entry points:
`_split_percell.py` (called by 04), `_parse_bismark_qc.py` (by 06),
`_submit_postqc.sh` (submitted by `run_all.sh`).

`run_all.sh` and `_submit_postqc.sh` invoke the other steps as `code/NN_*.sh`,
which is where they sat in the source tree. Point `CODE` in `config.sh` at this
folder, or submit the numbered scripts directly in the order the README gives.

## Not included

| File | Why not |
|---|---|
| `code/11_bin_hcg_250kb.{py,sh}`, `12_pseudobulk_compare.py`, `14_bin_nomehic_250kb.py`, `14_bulk_wgbs_gm_tracks.sh` | The 250 kb binned comparison. The S2 panel is per-CpG-site, from `13_pseudobulk_persite` + `13b`. |
| `code/12_compare_nomehic.ipynb`, `14_bulkwgbs_compare_nomehic.ipynb` | Notebooks for that 250 kb comparison. Not S2 panels. |
| `code/_make_idemp_inputs.py`, `_test_*.sh`, `_verify_env.sh`, `setup_and_run.sh`, `Untitled` | Dev checks and a superseded idemp helper (idemp segfaulted at single-cell scale and was replaced by `_split_percell.py`). |
| `code/scmet/14_bin_250kb.py`, `15_compare_3way.ipynb`, `16_methylation_levels.ipynb` | The sci-MET 250 kb comparison; superseded by the per-site notebook in `figS2/`. |
| `code/scmet/_*.py`, `_*.sh`, `reextract*.sh`, `_trim*.sh` | Read-layout diagnostics, trimming experiments, and the `.sra` re-extraction that recovered reads the ENA deposit was missing. Recovery bookkeeping, not method. |
| `code/scmet/{sciMETv2,premethyst,unidex,supp_code}/` | Third-party repositories, cloned for reference. Not ours to redistribute; the demultiplexing route they support was abandoned (see `scimet/METHODS.md`). |
| `atac_dnase_gm12878/scripts/03_quartiles.sh`, `04_profiles.sh` | deepTools quartile profiles of GCH and snATAC over DNase peaks. A separate result, not an S2 panel. |
| `atac_dnase_gm12878/scripts/build_notebook.py`, `build_r_notebook.py`, `schic_gm12878/code/build_analysis_nb.py` | Generators that assemble the figure notebooks from cell sources. Authoring tooling, not method. |
