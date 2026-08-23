#!/usr/bin/env python3
"""Build tumor / non-tumor cell lists for UXM deconvolution from the FINAL notebook's
HCG-based cell types (final_metadata.tsv, column `cell_type_hcg`).
  tumor      = cell_type_hcg in {tumor1, tumor2}
  non-tumor  = cell_type_hcg == monocyte
Lives in snakemake/code/; writes into the set's deconv/ folder. Run the final notebook
(subset_final_snakemake.ipynb) first so final_metadata.tsv exists."""
import os
import pandas as pd

SET  = "all_batches"          # cell set (subfolder under subset_clustering/250kb)
COL  = "cell_type_hcg"        # annotation column; switch to "cell_type_joint" if preferred
WORK = "/gpfs/projects/b1198/epifluidlab/yoshii/meningioma_scnomehic/snakemake"

SETDIR = os.path.join(WORK, "subset_clustering", "250kb", SET)
META   = os.path.join(SETDIR, "tables", "final_metadata.tsv")
OUTDIR = os.path.join(SETDIR, "deconv")
os.makedirs(OUTDIR, exist_ok=True)

df = pd.read_csv(META, sep="\t")
if COL not in df.columns:
    raise SystemExit(f"{COL} not in {META}; run the final notebook (§8b) first.")

tumor    = df.loc[df[COL].isin(["tumor1", "tumor2"]), "cell"]
nontumor = df.loc[df[COL] == "monocyte", "cell"]
tumor.to_csv(os.path.join(OUTDIR, "cell_tumor.txt"), index=False, header=False)
nontumor.to_csv(os.path.join(OUTDIR, "cell_nontumor.txt"), index=False, header=False)
print(f"set={SET}  annotation={COL}")
print(f"tumor (tumor1+tumor2): {len(tumor):4d} -> {OUTDIR}/cell_tumor.txt")
print(f"non-tumor (monocyte):  {len(nontumor):4d} -> {OUTDIR}/cell_nontumor.txt")
