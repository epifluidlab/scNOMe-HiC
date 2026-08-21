# FILES — main_figures/fig3

2 notebooks, copied whole. See `README.md` for the annotation, inputs, and caveats.

| File | What it is | Origin |
|---|---|---|
| `fig3_umap.ipynb` | R, 28 code cells, kernel `nomehic_r`. De novo Leiden clustering of the HCG Harmony embedding, CEMBA atlas assignment, then the Fig-4b style UMAPs (§8e) and the marker-gene heatmaps for methylation (§8.5) and accessibility (§8.5b, §8.5c). Writes `annotation/`. Outputs partly stale — see README. | `sc_nomehic/snakemake/subset_clustering/250kb_denovo/subset_final_snakemake_denovo.ipynb` |
| `fig3_apa.ipynb` | Python, 15 code cells, kernel `hic_cooler`. Union loops → Q/T per anchor → differential assignment → APA pile-up → the 10 × 10 panel grid. Caches intermediates, so only §6 needs re-running to retune the colour scale. | `sc_nomehic/hic/loop_final/celltype_diffloop_apa.ipynb` |

Renamed only — no cell edits, no path rewriting.

## Environment

Two kernels: `nomehic_r` (R) and `hic_cooler` (Python). Neither is captured in `../../env/` yet.

## Not included

See `README.md`: `regen_marker_heatmaps.R`, the stale `*_gene_tss` / `*_gene_body`
heatmap variants, `resolution_exploration.ipynb`, `archive_superseded/`, and the
non-canonical annotation directories.

## Two bugs fixed upstream, worth knowing

The APA pipeline corrected two faults in the earlier `hic/save.py`:

1. **chr9 was silently dropped.** `save.py` iterated `chrom_sizes.index[:-1]`, and the
   chrom file is lexically sorted (`chr1, chr10…chr19, chr2…chr9`), so that expression
   removed chr9 — a real autosome. The old figure used 18 autosomes; this one uses 19.
2. **Axis labels were wrong by 2.5×.** They read ±100 kb, but at `res = 25000` with a
   ±10-bin window the panels span **±250 kb**.
