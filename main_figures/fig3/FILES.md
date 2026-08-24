# FILES — main_figures/fig3

2 notebooks, copied whole. See `README.md` for the annotation, inputs, and caveats.

| File | What it is | Origin |
|---|---|---|
| `fig3_umap.ipynb` | R, 28 code cells, kernel `nomehic_r`. De novo Leiden clustering of the HCG Harmony embedding, CEMBA atlas assignment, then the Fig-4b style UMAPs (§8e) and the marker-gene heatmaps for methylation (§8.5) and accessibility (§8.5b, §8.5c). Writes `annotation/`. All 28 cells carry outputs except §4a/§6b — 12 figures, no errors. | `sc_nomehic/snakemake/subset_clustering/250kb_denovo/subset_final_snakemake_denovo.ipynb` |
| `fig3_apa.ipynb` | Python, 7 code cells, kernel `hic_cooler`. Union loops → Q/T per anchor → differential assignment → APA pile-up → the 10 × 10 panel grid. Caches intermediates, so only §6 needs re-running to retune the colour scale. Executed: all 7 cells carry outputs, including the panel grid. | `sc_nomehic/hic/loop_final/celltype_diffloop_apa.ipynb` |

Renamed, and eight empty trailing code cells dropped (23 → 15 cells, 15 → 7 code).

**Updated 2026-08-22** to the finalised plotting. Four changes from the previous
version: `FC_THRESH` 1.2 → **2**; cell-type order changed to put **ASC before ODC
and OPC**; the colour scale moved from `gamma=3` with 1st/99.9th-percentile limits
to **`gamma=2` with fixed `vmin=0.2, vmax=0.75`**; and per-panel APA scores were
taken off the grid (reported in §7 instead). §5 gained a **cache-permutation
guard** — `apa_25kb.npz` now stores the `LEG` order it was built under, and both
axes are permuted if `LEG` has changed since. That guard fired on this run, so the
shipped figure is drawn from a cache built under the old order and correctly
re-indexed.
No path rewriting; `OUTDIR` still resolves to `hic/loop_final/apa_1577`.

The figure cell's output was regenerated headlessly: the working-copy save at
15:38:18 on 2026-08-21 caught the cell mid-run, so the notebook was saved without
it while the PDF landed at 15:38:22. The re-execution reused the cached
`apa_25kb.npz`, and the §7 diagonal-score table it produced is byte-identical to
the one in the working copy — same `result`, same 23.68 / 22.71 / 23.39 … values.
The stored PNG differs from `apa_1577/*.png` by a few pixels of `bbox_inches="tight"`
margin only, an artefact of headless vs interactive text metrics.

## Environment

Two kernels: `nomehic_r` (R) and `hic_cooler` (Python). Neither is captured in `../../env/` yet.

## Not included

| File | Why not |
|---|---|
| `scripts/regen_marker_heatmaps.R` | Standalone reproduction of §8e + §8.5 + §8.5b + §8.5c, written to refresh the PDFs without a kernel re-run. The notebook is the source of truth. |
| `marker_gene_heatmap_*_gene_tss.*`, `*_gene_body.*` | Stale leftovers from an earlier three-region version; no longer produced. |
| `resolution_exploration.ipynb`, `archive_superseded/`, `.bak` notebooks | Development history. |
| `annotation_k20_r0.3/`, `annotation_consensus12_backup/` | Non-canonical annotations — a superseded scanpy intermediate (differs on 23 cells) and a retired 12-type consensus. |

## Two bugs fixed upstream, worth knowing

The APA pipeline corrected two faults in the earlier `hic/save.py`:

1. **chr9 was silently dropped.** `save.py` iterated `chrom_sizes.index[:-1]`, and the
   chrom file is lexically sorted (`chr1, chr10…chr19, chr2…chr9`), so that expression
   removed chr9 — a real autosome. The old figure used 18 autosomes; this one uses 19.
2. **Axis labels were wrong by 2.5×.** They read ±100 kb, but at `res = 25000` with a
   ±10-bin window the panels span **±250 kb**.
