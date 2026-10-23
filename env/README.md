# env/

Conda environments for everything in this repository. Each is exported from the
environment the published results were produced in.

## Recreate

```bash
conda env create -f env/scnomehic.yml        # then: conda activate scnomehic
```

| File | What |
|---|---|
| `<name>.yml` | Full conda spec, builds stripped so it resolves on other platforms. This is the one to use. |
| `<name>.requirements.txt` | `pip freeze` of the same environment, for the pip-installed packages. Reference, not a substitute for the YAML. |
| `<name>.R-packages.tsv` | Installed R packages and versions, for the environments with R. Reference — the YAML installs them. |
| `create_diff_env.sh` | How `scnomehic_diff` was originally built (methylKit, DiffBind, DESeq2, csaw, edgeR). |

## The five environments

| Environment | Language | What it is for |
|---|---|---|
| `scnomehic` | Python **and** R | The main environment. Nearly every processing script, and most notebooks. Carries both a Python kernel and an R kernel (`ir`). |
| `scnome` | R | The R kernel used by the UMAP and per-site methylation notebooks. Registered as the `nomehic_r` kernel. |
| `scnomehic_diff` | R | Differential analysis — methylKit, DiffBind, DESeq2, csaw, edgeR. Figure 2's methylation and accessibility panels. |
| `hic_cooler` | Python | cooler / scHiCluster 1.3.2, for the APA notebooks. |
| `hic_env` | Python | scHiCluster 1.3.5.dev17 for the 25 kb loop chain. Shell scripts only — no notebook uses it. |

## Which notebook needs which

Every notebook opens with an environment check that prints a warning if it is
running somewhere else. It warns rather than fails, so an equivalent environment
under a different name still works.

| Environment | Language | Kernel name | Notebook |
|---|---|---|---|
| `hic_cooler` | Python | `hic_cooler` | `main_figures/fig2/fig2_apa.ipynb` |
| `hic_cooler` | Python | `hic_cooler` | `main_figures/fig3/fig3_apa.ipynb` |
| `scnome` | R | `nomehic_r` | `main_figures/fig1/fig1_methylation_accessibility.ipynb` |
| `scnome` | R | `nomehic_r` | `main_figures/fig3/fig3_umap.ipynb` |
| `scnome` | R | `nomehic_r` | `main_figures/fig4/fig4_umap.ipynb` |
| `scnome` | R | `nomehic_r` | `supplementary_figures/figS2/figS2_methylation_persite.ipynb` |
| `scnome` | R | `nomehic_r` | `supplementary_figures/figS7/figS7_qc_panels.ipynb` |
| `scnomehic` | Python | `scnomehic` | `main_figures/fig4/fig4_deconv_barplot.ipynb` |
| `scnomehic` | Python | `scnomehic` | `supplementary_figures/figS2/figS2_schic_scc.ipynb` |
| `scnomehic` | Python | `scnomehic_python` | `data_processing/benchmark/scnome/codes/qc.ipynb` |
| `scnomehic` | Python | `scnomehic_python` | `data_processing/gm12878_cellline/02_qc/qc_plots.ipynb` |
| `scnomehic` | Python | `scnomehic_python` | `data_processing/meningioma/02_qc/qc_plots.ipynb` |
| `scnomehic` | Python | `scnomehic_python` | `data_processing/mixture_cellline/02_qc/qc_plots.ipynb` |
| `scnomehic` | Python | `scnomehic_python` | `data_processing/mouse_cortex/02_qc/qc_plots.ipynb` |
| `scnomehic` | Python | `scnomehic_python` | `main_figures/fig1/fig1_benchmark_violins.ipynb` |
| `scnomehic` | Python | `scnomehic_python` | `main_figures/fig1/fig1_hic_comparison.ipynb` |
| `scnomehic` | Python | `scnomehic_python` | `main_figures/fig4/fig4_cna.ipynb` |
| `scnomehic` | Python | `scnomehic_python` | `supplementary_figures/figS1/figS1_contact_distance.ipynb` |
| `scnomehic` | Python | `scnomehic_python` | `supplementary_figures/figS3/figS3_dualaxis_profiles.ipynb` |
| `scnomehic` | Python | `scnomehic_python` | `supplementary_figures/figS4/figS4_barnyard.ipynb` |
| `scnomehic` | Python | `scnomehic_python` | `supplementary_figures/figS4/figS4_distributions.ipynb` |
| `scnomehic` | Python | `scnomehic_python` | `supplementary_figures/figS5/figS5_saturation.ipynb` |
| `scnomehic` | Python | `scnomehic_python` | `supplementary_figures/figS6/figS6_replicate_reproducibility.ipynb` |
| `scnomehic` | R | `ir` | `main_figures/fig2/fig2_umap.ipynb` |
| `scnomehic` | R | `ir` | `supplementary_figures/figS2/figS2_accessibility.ipynb` |
| `scnomehic_diff` | R | `scnomehic_diff` | `main_figures/fig2/fig2_accessibility.ipynb` |
| `scnomehic_diff` | R | `scnomehic_diff` | `main_figures/fig2/fig2_methylation.ipynb` |

## Notes

- **`scnomehic` and `scnomehic_python` are the same environment.** Two kernel
  names were registered against one env; both resolve to `envs/scnomehic`.
- **The `nomehic_r` kernel lives in the `scnome` environment**, not in one called
  `nomehic_r`. Register it after creating the env:
  `R -e 'IRkernel::installspec(name = "nomehic_r", displayname = "R (scnome)")'`
- **Three notebooks previously declared the `python3` kernel**, which resolved to
  the conda *base* install — not something anyone else could reproduce. They have
  been retargeted to `scnomehic`, which has everything they import.
- **`hic_env` pins nothing.** Its scHiCluster comes from
  `git+https://github.com/zhoujt1994/scHiCluster.git` with no revision, so the
  version depends on when the environment is built; this one reports
  `1.3.5.dev17+gda98594`. Pin it if you need an exact reproduction.
- The YAMLs record the environments as they were on a Linux x86-64 cluster. Some
  pins may not resolve on macOS or ARM; relax the offending ones rather than the
  whole file.
