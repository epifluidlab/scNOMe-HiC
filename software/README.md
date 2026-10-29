# software/

External tools you install yourself. **Empty in the repository** — only this
README is tracked.

Set `software_root` in `../paths.yaml` if you keep these elsewhere. The default
is this folder. Install each at the path given in the first column.

| Expected at | Tool | Used for |
|---|---|---|
| `sc_NOMeHiC_pipeline/` | [epifluidlab/sc_NOMeHiC_pipeline](https://github.com/epifluidlab/sc_NOMeHiC_pipeline) @ `a0456b9` | the per-cell workflow itself |
| `meth_concord/` | [epifluidlab/meth_concord](https://github.com/epifluidlab/meth_concord) @ `dade069` | Figures 5 and 6: the end posteriors and the concordance analyses. Installed with `pip install -e` into its own `meth_concord` environment; see `../main_figures/fig5_fig6/README.md` |
| `bisulfiteHic/` | bisulfiteHic v0.38 (`bhmem`, `demultiplex_ecker_scWGBS.pl`, `sam2juicer_new.py`) | demultiplexing and bisulfite- + Hi-C-aware alignment |
| `Bis-tools/` | Bis-tools, including `Bis-SNP/` | methylation calling and VCF post-processing |
| `Bis-tools/Bis-SNP/Bis-SNP.latest.jar` | the Bis-SNP jar | `BisulfiteGenotyper`; the paper used the build reporting version 1.0.1 |
| `picard/picard.jar` | Picard | BAM processing |
| `juicer_tools.jar` | juicer_tools 2.20.00 | `.hic` construction, dumps, HICCUPS (2.20 is required for v9 `.hic`) |
| `metilene/` | metilene | de-novo DMR calling (Figure 2 only) |
| `wgbs_tools/wgbstools` | wgbs_tools | BAM to fragment-level PAT (Figure 4 deconvolution) |
| `UXM_deconv/uxm` | UXM | methylation deconvolution (Figure 4) |

## The two built from source

`sc_NOMeHiC_pipeline` and `bisulfiteHic` are cloned and built rather than
downloaded; [the Setup section of `../README.md`](../README.md#setup) gives the
commands. Two things specific to this folder:

- **Keep `bisulfiteHic`'s whole source tree.** `paths.yaml`'s `bisulfitehic` key
  points at the directory, not the jar, because the workflow calls
  `src/python/sam2juicer_new.py` and `src/perl/demultiplex_ecker_scWGBS.pl` from
  inside it. A jar on its own is not enough.
- **`epifluidlab/bisulfiteHic` is private.** Cloning it anonymously returns 404.

## On the Bis-SNP version

`paths.yaml` expects `Bis-tools/Bis-SNP/Bis-SNP.latest.jar`. Upstream is
<https://github.com/dnaase/Bis-tools>.

The build used here is named `BisSNP-1.2.bisqc_walkers.jar` but reports version
**1.0.1** when asked. That matters: it calls roughly 2.3x more cytosines than the
older BisSNP-0.90, and the per-cell HCG and GCH counts in Supplementary Table 2
are from this build. Calling with 0.90 will not reproduce them.

Also needed, but expected on `PATH` rather than here — these come from the conda
environments in `../env/` and from the pipeline's own `envs/`:

`trim_galore` (0.6.7) and `cutadapt` (5.2) · `bismark` (0.24.2) · `bwa` (0.7.18) ·
`samtools` (1.21) · `bedtools` · `tabix` · `metilene` (Figure 2 only) ·
`deepTools` (Figure S3) · `wgbstools` and `uxm` (Figure 4 deconvolution) ·
`hicluster` / scHiCluster · `cooler` · `hicrep` · `seqkit` and `faToTwoBit`
(Figures 5 and 6, from the `meth_concord` environment)

Set `conda_sh` in `../paths.yaml` to your conda's `etc/profile.d/conda.sh` so the
driver scripts can activate those environments.
