# Supplementary Figure S3 — GCH/HCG metaprofiles at CTCF sites and TSS

GM12878 pseudobulk NOMe tracks. GCH = accessibility (green), HCG = methylation (black).

## Panels

| File | Made by |
|---|---|
| `GCH_HCG.CTCFnoTSS.dualaxis.pdf` | `figS3_dualaxis_profiles.ipynb` |
| `GCH_HCG.TSS_CGI.dualaxis.pdf` | `figS3_dualaxis_profiles.ipynb` |
| `GCH_HCG.TSS_CGI_vs_nonCGI.heatmap.pdf` | `../../data_processing/gm12878_cellline/05_profiles/03_plot_cgi.sh` |

## Files

| File | What it is |
|---|---|
| `figS3_dualaxis_profiles.ipynb` | Python (`python3`). Reads the `computeMatrix` outputs from `05_profiles/` and draws the dual-y-axis GCH/HCG overlays. 6 cells, 3 figures. |

## Inputs

From `../../data_processing/gm12878_cellline/05_profiles/`:

- `analysis/ctcf/matrices/GCH_HCG.CTCFnoTSS.matrix.gz`
- `analysis/tss_cgi/matrices/GCH_HCG.TSS_CGI_vs_nonCGI.matrix.gz`

The notebook splits the combined matrix in Python via the header's
`group_boundaries` / `sample_boundaries`. Nothing is recomputed.

## Notes

- The overlays use `twinx()` so GCH and HCG each get their own y-axis. deepTools
  `plotProfile` allows only one shared axis, which flattens the smaller-range mark.
- In the CGI vs non-CGI heatmap the shared scale makes non-CGI TSS look flat. It is
  not: GCH 63 → 65.7%, HCG 51 → 47%, against CGI TSS at GCH 66 → 82%, HCG 58 → 18%.
- Parameters: ±2000 bp, 20 bp bins, `--skipZeros`, `--averageTypeBins mean`.
