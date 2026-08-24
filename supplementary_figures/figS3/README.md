# Supplementary Figure S3 — GCH/HCG metaprofiles at CTCF sites and TSS

Accessibility (GCH) and CpG methylation (HCG) around two classes of regulatory
element, from the **GM12878 pseudobulk** NOMe tracks.

| Panel | File | Made by |
|---|---|---|
| CTCF sites (TSS-excluded), dual-axis overlay | `GCH_HCG.CTCFnoTSS.dualaxis.pdf` | `figS3_dualaxis_profiles.ipynb` |
| CGI TSS, dual-axis overlay | `GCH_HCG.TSS_CGI.dualaxis.pdf` | `figS3_dualaxis_profiles.ipynb` |
| CGI vs non-CGI TSS heatmap | `GCH_HCG.TSS_CGI_vs_nonCGI.heatmap.pdf` | `../../data_processing/gm12878_cellline/05_profiles/03_plot_cgi.sh` |

Note the third panel comes from the **processing step**, not a notebook —
`plotHeatmap` runs inside the deepTools job that builds the matrix.

| Notebook | Kernel | Reads |
|---|---|---|
| `figS3_dualaxis_profiles.ipynb` | Python (`python3`) | the `computeMatrix` `.gz` files from `05_profiles/` — no recompute |

## Why a notebook rather than deepTools for the overlays

GCH and HCG live on very different scales, and `plotProfile` can only put them on
one shared y-axis, which flattens whichever mark has the smaller range. The
notebook loads the matrix in Python, takes `np.nanmean` down the rows, and uses
`ax.twinx()` so **GCH gets the left axis (green) and HCG the right (black)**, each
auto-scaled. That is the only reason this step is not another deepTools call.

It splits the combined matrices using the header's `sample_boundaries` and
`group_boundaries` rather than reading separate files, so the values are exactly
those in the shipped matrix.

## Reading the CGI vs non-CGI panel

In the two-panel heatmap the shared scale makes non-CGI TSS look flat. It is not:
plotted alone it shows a real but subtle signal.

| | GCH (accessibility) | HCG (methylation) |
|---|---|---|
| **CGI TSS** | 66% → 82% | 58% → 18% |
| **non-CGI TSS** | 63% → 65.7% | 51% → 47% |

Do not read the combined panel as "no signal at non-CGI TSS" — read it as a much
smaller one on a scale set by CGI TSS.

## One deliberate deviation from the paper's earlier scripts

`plotHeatmap` is given `--missingDataColor white`. The per-site tracks cover only
about 6.3% of bases, so roughly 27% of 20 bp bins are NaN, and deepTools' default
black made the heatmap look solid black. `--missingDataAsZero` was **not** used —
that would deflate the methylation values by treating "not measured" as
"unmethylated".

## Parameters

`--referencePoint center` (CTCF) or `TSS` (CGI), ±2000 bp, 20 bp bins,
`--skipZeros`, `--averageTypeBins mean`. GCH green, HCG black throughout.
