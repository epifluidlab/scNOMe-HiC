# FILES — fig5_fig6/

`$M` = the `reproduce/` folder of [epifluidlab/meth_concord](https://github.com/epifluidlab/meth_concord) at commit `dade069`

Copied from `$M` and adapted to this repository's layout: paths come from
`paths.yaml`, the sample sheets point at the pipeline's own BAM files, and
meth_concord itself is a checkout under `software/`, not copied here. The
analysis code (the `nome_hic_concordance` package and the `scripts/` the
notebooks run) stays in meth_concord.

| File | What it is | Origin |
|---|---|---|
| `README.md` | Install, data, run order, what each step makes, the checks, notes. | `$M/README.md`, adapted |
| `FILES.md` | This file. | written for this repo |
| `fig5_cortex.ipynb` | Python, 10 code cells, kernel `meth_concord`. Figure 5 and Supplementary Figs. 9–12 from the 1,577 cortex BAM files; ends with 19 checks against the manuscript. Unexecuted. | `$M/figure5_cortex.ipynb`; the configuration cells adapted |
| `fig6_xci.ipynb` | Python, 11 code cells, kernel `meth_concord`. Figure 6 from the 629 GM12878 and IMR-90 BAM files; ends with 16 checks. Unexecuted. | `$M/figure6_xci.ipynb`; the configuration cells adapted |
| `repro.py` | The notebooks' helpers: run a command or skip it when its outputs exist, show a PDF inline, compare with the manuscript. | `$M/repro.py`, unchanged |
| `download_public_data.sh` | Downloads and prepares the public data (Supplementary Table 7) into `<work_root>/concordance/annotations`. | `$M/download_public_data.sh`; finds meth_concord through `paths.sh` |
| `samples/mouse_cortex.samples.tsv` | The 1,577 cortex cells: BAM path, cell type, experiment and library batch, colour. | `$M/samples/`; BAM paths re-pointed |
| `samples/gm12878_imr90.samples.tsv` | The 629 human cells: BAM path, cell line, batch. The 188 GM12878 cells of batch `batch_gm` are `gm12878_cellline`; batches 1–5 (281 GM12878, 160 IMR-90) are `mixture_cellline`. | `$M/samples/`; BAM paths re-pointed |

## What was adapted

- **The configuration cells.** Each notebook opens with this repository's
  environment check, finds `paths.py` above its folder, and takes `BAMS`
  (`<work_root>`), `DATA` (`<work_root>/concordance`) and `METH_CONCORD`
  (`<software_root>/meth_concord`) from it. In meth_concord they read one
  `$SCNOMEHIC_DATA` folder and the repository they sit in. Nothing after the
  configuration cells changed: the commands are the same.
- **The sample sheets' `bam_path`.** meth_concord's sheets name a folder of
  linked BAM files (`bams/<dataset>/<cell>.bam`); here they name the pipeline's
  `<dataset>/04.alignment_snakemake/<cell>.calmd.bam`, so nothing has to be
  linked. The cells, cell types, batches and colours are unchanged.
- **The notebooks' names**, `figure5_cortex` → `fig5_cortex` and `figure6_xci`
  → `fig6_xci`, after this repository's `figN_*` pattern.

## Checked

Run from this folder against the published runs' outputs (each command then
skipped, only the figures and checks redone): 19 of 19 checks match in
`fig5_cortex.ipynb` and 16 of 16 in `fig6_xci.ipynb`, and the redrawn Figure 5, Figure 6 and Supplementary Figs. 11 and 12
are pixel-identical to the manuscript's. With `DRY_RUN = True` and no data,
both notebooks print every command (13 each) with this repository's paths.
