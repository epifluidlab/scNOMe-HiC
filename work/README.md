# work/

Everything the pipeline and the analysis steps **generate**. **Empty in the
repository** — only this folder structure and the READMEs are tracked.

You do not create anything here by hand. Each step writes its outputs into its
own subtree and the next step reads them back from the same place, so running
the steps in the order each dataset's `README.md` gives is enough.

Point `work_root` in `../paths.yaml` somewhere with room: a full reproduction
writes several TB. The default is this folder.

| Folder | Written by | Read by |
|---|---|---|
| `gm12878_cellline/` | `../data_processing/gm12878_cellline/` | Figure 1, S1, S2, S3, S4, S5 |
| `mixture_cellline/` | `../data_processing/mixture_cellline/` | Figure 2 |
| `mouse_cortex/` | `../data_processing/mouse_cortex/` | Figure 3, S6, S7 |
| `meningioma/` | `../data_processing/meningioma/` | Figure 4, S8 |
| `barnyard_mixing/` | `../data_processing/barnyard_mixing/` | Figure S4 (species mixing) |
| `benchmark/` | `../data_processing/benchmark/` | Figure 1, S1 |
| `analysis/` | `../data_processing/bulk_others/`, `../data_processing/published_singlecell/`, `../data_processing/bulk_scNOMeHiC/` | Figure 1, 2, 3, S1, S2 |
| `tmp/` | large, short-lived intermediates | — |

## Inside `analysis/`

The cross-dataset steps keep the short names they ran under. What each holds:

| Folder | What | Feeds |
|---|---|---|
| `s1/` | per-cell QC tables for the GM12878 benchmark arm | Figure 1, S1 |
| `s2_new/` | the published single-cell comparisons — Drop-BS, sci-MET, snATAC, sci-Hi-C | Figure S2 |
| `s3/` | CTCF and CpG-island profile matrices | Figure S3 |
| `s7/` | the sequencing-saturation subsampling results | Figure S5 |
| `fig1/` | contact-frequency-vs-distance (HOMER log-log) tables | Figure S1 |
| `fig2/` | metilene DMRs and the bulk ATAC bins | Figure 2 |
| `bulk_scNOMeHiC/` | the bulk NOMe-HiC GM12878 chain | Figure 1 |

`tmp/` is separately configurable as `tmp_root`. On a cluster, point it at fast
scratch; the steps that use it do not expect its contents to survive.

## The Hi-C embedding

`<dataset>/06.hiccluster_snakemake/hicluster_250kb_embed_dir/``all_merged.pad1_std1_rp0.5_sqrtvc.svd20.hdf5` is what the Figure 2, 3 and 4
UMAP notebooks read for the Hi-C modality. It is written by each dataset's
`01_pipeline/02_hicluster.sh`, which must run after that dataset's `02_qc/`
step has produced the passing-cell list. See
`../data_processing/README.md` for the full chain.
