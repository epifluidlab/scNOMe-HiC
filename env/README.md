# env

Environment definitions needed to rerun the code in this repository.

| File | What it builds |
|---|---|
| `create_diff_env.sh` | Conda env **`scnomehic_diff`** — methylKit, DiffBind, DESeq2, csaw, edgeR. The kernel for `main_figures/fig2/fig2_{accessibility,methylation}.ipynb`. |

Still to capture:

- **`scnomehic`** — the main conda env used by nearly every processing script and by
  `fig2_umap.ipynb`. Not yet exported.
- **`nomehic_r`** — the R 4.4.2 kernel behind `main_figures/fig1/fig1_methylation_accessibility.ipynb`.
- **`scnomehic_python`** — kernel for the QC notebooks.
- **`hic_cooler`** — kernel for the APA notebook.
- Versions of external tools invoked by the shell scripts (Bhmem/bisulfiteHic,
  Bis-SNP, Picard, juicer_tools, metilene, deepTools, seqkit, trim_galore).

The Snakemake pipeline ships its own environment files — see
<https://github.com/epifluidlab/sc_NOMeHiC_pipeline> (`envs/`).
