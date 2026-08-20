# FILES — data_processing/bulk_others

6 files. See `README.md` for the run order and rationale.

Sources: `$F` = `/gpfs/.../scnomehic_paper/fig2/codes`, `$C` = `/gpfs/.../sc_nomehic_cellline`

| File | What it is |
|---|---|
| `01_download/01_setup_bulk_links.sh` | Creates the `data/bulk/{GM12878,IMR90}/{hic,atac,methylation}` tree and symlinks GM12878 bulk data from the Figure 1 folder. |
| `01_download/02_download_imr90.sh` | Downloads IMR90 WGBS (`ENCFF591PKF.bigBed`) and ATAC (`ENCFF770EAV.bigWig`) from ENCODE. Resumable. |
| `02_process/01_methylation_process_imr90.sh` | IMR90 WGBS bigBed → BED → HCG subset → bigWig, mirroring the Figure 1 bulk methylation processing. Needs the `scnomehic` env and the hg38 reference. |
| `02_process/02_bin_bulk_atac_250kb.py` | Bins bulk ATAC bigWigs (GM `ENCFF667MDI`, IMR `ENCFF770EAV`) to 250 kb mean signal via pyBigWig → `bulk_atac_250kb.tsv`. |
| `02_process/03_build_bulk_methylation_bins.py` | Bins bulk WGBS methylation onto the single-cell bin grid → the GM12878/IMR90 references the Fig. 2 UMAP uses for cell-type calling. Generalized from `bulk_methylation_100kb.py`: bin label is now an argument (default 250 kb) rather than hardcoded, and the missing-bins case fails with a message naming the step that produces it. The binning function itself is verbatim. Requires `bins_{label}.tsv` from `mixture_cellline/02_qc/`. | `$C/bulk_methylation_100kb.py` |
| `03_differential/01_run_metilene_dmr.sh` | SLURM job calling metilene for de-novo DMRs, GM12878 vs IMR90, on bulk HCG WGBS. 213,578 raw / 76,126 significant. |

Only `03_build_bulk_methylation_bins.py` was edited (bin size parameterized); the rest are verbatim.

## Not included

See the "Not included" section of `README.md`: the methylKit tile-based DMR branch,
the DiffBind differential-ATAC branch, `fix_gm_bed_links.sh` (methylKit support), and
`copy_imr90_hic.sh` (belongs with the APA analysis, not yet migrated).
