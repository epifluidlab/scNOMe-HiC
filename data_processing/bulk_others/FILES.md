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
| `04_hic_loops/04_hiccupsdiff.sbatch` | juicer HiCCUPSDiff (GPU) on the two in-situ `.hic` files. For every loop in either HICCUPS list it tests whether contact frequency differs between the cell types, with FDR, and writes A-specific / B-specific / common bedpes. Reads the GPFS copies in `data/loops/`; copies the differential bedpes back to GPFS so a scratch purge cannot destroy them again. |
| `04_hic_loops/apa_pileup_insitu.py` | The non-circular APA pile-up: loop sets come entirely from the in-situ Hi-C (step 04), signal is read from the single-cell pseudobulk `.Q.cool`. Iterates all 22 autosomes, records per-loop centre O/E, renders min-max and raw O/E, and runs a Mann-Whitney interaction test. `APA_LOOPSET` selects `hiccupsdiff` (the published panel) or `setdiff`. **`main_figures/fig2/fig2_apa.ipynb` imports this module** directly, so the notebook can rebuild the cache without any renaming; the file is called `apa_pileup_insitu.py` rather than `05_...` because a module name cannot begin with a digit. Its runner keeps the step number: `05_apa_pileup_insitu.sbatch`. |
| `04_hic_loops/05_apa_pileup_insitu.sbatch` | SLURM wrapper for the above (`hic_cooler` env). |

Only `03_build_bulk_methylation_bins.py` was edited (bin size parameterized); the rest are verbatim.

## Not included

| File | Why not |
|---|---|
| `dmr_methylkit_250kb.R/.sh` | Differential 250 kb tiles via methylKit. The published figure uses the metilene DMRs. |
| `fix_gm_bed_links.sh` | Per-CpG BED symlinks needed only by methylKit. |
| `diffbind_atac.R/.sh`, `download_atac_bams.sh` | Differential ATAC peaks via DiffBind/DESeq2. The published panel ranks bins by bulk ATAC signal, not by DiffBind peaks. |
| `copy_imr90_hic.sh` | One-off copy of the IMR90 in-situ Hi-C (`ENCFF188SSH`, 17.5 GB) off purgeable scratch. Data movement, not method. |
| `step04_diff_loops.sh`, `step07_diff_loops_gpfs.sh` | The **set-difference** route to differential loops (presence/absence across the two HICCUPS call sets, 25 kb tolerance; 2,434 / 5,401 loops). Independent of the single-cell data but not a statistical test — a threshold cliff. `apa_pileup_insitu.py` still supports it via `APA_LOOPSET=setdiff`; the published panel uses `hiccupsdiff`. |
| `step05_apa_pileup.sh`, `step05_juicer_apa.sbatch`, `step06_juicer_apa_specific.sbatch`, `step06_make_2x2_figure.py` | Superseded by `apa_pileup_insitu.py`; `step06_make_2x2_figure.py` was never executed. |
| `step04_hiccupsdiff.sbatch` | The first hiccupsdiff wrapper, reading from `/scratch`. Superseded by `04_hiccupsdiff.sbatch`, which reads the GPFS copies that survived the 2026-08-24 purge. |
