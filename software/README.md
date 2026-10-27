# software/

External tools you install yourself. **Empty in the repository** — only this
README is tracked.

Set `software_root` in `../paths.yaml` if you keep these elsewhere. The default
is this folder. Install each at the path given in the first column.

| Expected at | Tool | Used for |
|---|---|---|
| `sc_NOMeHiC_pipeline/` | [epifluidlab/sc_NOMeHiC_pipeline](https://github.com/epifluidlab/sc_NOMeHiC_pipeline) @ `a0456b9` | the per-cell workflow itself |
| `meth_concord/` | [epifluidlab/meth_concord](https://github.com/epifluidlab/meth_concord) @ `9c6284f` | Figures 5 and 6: the end posteriors and the concordance analyses. Installed with `pip install -e` into its own `meth_concord` environment; see `../main_figures/fig5_fig6/README.md` |
| `bisulfiteHic/` | bisulfiteHic v0.38 (`bhmem`, `demultiplex_ecker_scWGBS.pl`, `sam2juicer_new.py`) | demultiplexing and bisulfite- + Hi-C-aware alignment |
| `Bis-tools/` | Bis-tools, including `Bis-SNP/` | methylation calling and VCF post-processing |
| `Bis-tools/Bis-SNP/Bis-SNP.latest.jar` | the Bis-SNP jar | `BisulfiteGenotyper`; the paper used the build reporting version 1.0.1 |
| `picard/picard.jar` | Picard | BAM processing |
| `juicer_tools.jar` | juicer_tools 2.20.00 | `.hic` construction, dumps, HICCUPS (2.20 is required for v9 `.hic`) |
| `metilene/` | metilene | de-novo DMR calling (Figure 2 only) |
| `wgbs_tools/wgbstools` | wgbs_tools | BAM to fragment-level PAT (Figure 4 deconvolution) |
| `UXM_deconv/uxm` | UXM | methylation deconvolution (Figure 4) |

Also needed, but expected on `PATH` rather than here — these come from the conda
environments in `../env/` and from the pipeline's own `envs/`:

`trim_galore` (0.6.7) and `cutadapt` (5.2) · `bismark` (0.24.2) · `bwa` (0.7.18) ·
`samtools` (1.21) · `bedtools` · `tabix` · `metilene` (Figure 2 only) ·
`deepTools` (Figure S3) · `wgbstools` and `uxm` (Figure 4 deconvolution) ·
`hicluster` / scHiCluster · `cooler` · `hicrep` · `seqkit` and `faToTwoBit`
(Figures 5 and 6, from the `meth_concord` environment)

Set `conda_sh` in `../paths.yaml` to your conda's `etc/profile.d/conda.sh` so the
driver scripts can activate those environments.
