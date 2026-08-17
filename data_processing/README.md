# data_processing

Code that turns raw scNOMe-HiC sequencing into analysis-ready matrices, organized
by dataset. Nothing here is figure code — panels are built in `../main_figures/`
and `../supplementary_figures/` from the tables these pipelines emit.

| Folder | Dataset | Source working dir |
|---|---|---|
| `mouse_cortex/` | mouse cortex scNOMe-HiC | `../../sc_nomehic/` |
| `gm12878_cellline/` | GM12878 cell line | `../../sc_nomehic_cellline/` |
| `mixture_cellline/` | GM12878 / IMR90 mixture | `../../sc_nomehic_cellline/` |
| `meningioma/` | primary meningioma | `../../meningioma_scnomehic/` |
| `bulk_scNOMeHiC/` | bulk scNOMe-HiC libraries | <!-- FILL --> |
| `bulk_others/` | published bulk datasets for comparison | <!-- FILL --> |

Each dataset folder documents, in its own `README.md`, the order the steps run in
and what each step consumes and produces.
