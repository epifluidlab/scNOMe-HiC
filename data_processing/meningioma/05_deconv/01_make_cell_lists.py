#!/usr/bin/env python3
"""Build tumor / non-tumor cell lists for UXM deconvolution.

The split is **copy-number driven**: tumour status is defined by the CNA groups
called in the copy-number notebook (Approach 3, chr1p + chr22q), not by a
methylation clustering. chr22q carries NF2, the truncal meningioma event, so
"has the driver lesion" is the definition that matches what the deconvolution is
asking — which methylomes are tumour and which are the normal compartment.

    cna_group 1  chr22q intact                  -> NON-TUMOUR
    cna_group 2  chr22q loss                    -> tumour
    cna_group 3  chr22q loss + chr1p loss       -> tumour

Set SPLIT to a cell-type column instead ("cell_type_joint" / "cell_type_hcg") to
split on an annotation; then tumour = {tumor1, tumor2} and non-tumour = macrophage.

Reads `tables/final_metadata.tsv`, so run the final notebook
(`subset_final_snakemake.ipynb`) and the CNA notebook first.
"""
import os
import pandas as pd

SET   = "all_batches"      # cell set (subfolder under subset_clustering/250kb)
SPLIT = "cna_group"        # "cna_group", or "cell_type_joint" / "cell_type_hcg"
NORMAL_GROUP = "1"         # cna_group value that is the diploid / non-tumour group
WORK  = "/gpfs/projects/b1198/epifluidlab/yoshii/meningioma_scnomehic/snakemake"

SETDIR = os.path.join(WORK, "subset_clustering", "250kb", SET)
META   = os.path.join(SETDIR, "tables", "final_metadata.tsv")
OUTDIR = os.path.join(SETDIR, "deconv")
os.makedirs(OUTDIR, exist_ok=True)

df = pd.read_csv(META, sep="\t")
if SPLIT not in df.columns:
    raise SystemExit(f"{SPLIT} not in {META}; run the final notebook (§8b/§9) first.")

if SPLIT == "cna_group":
    is_normal = df[SPLIT].astype(str) == str(NORMAL_GROUP)
    tumor     = df.loc[~is_normal, "cell"]
    nontumor  = df.loc[is_normal,  "cell"]
    how = f"cna_group (non-tumour = group {NORMAL_GROUP}, tumour = all others)"
else:
    tumor    = df.loc[df[SPLIT].isin(["tumor1", "tumor2"]), "cell"]
    nontumor = df.loc[df[SPLIT] == "macrophage", "cell"]
    how = f"{SPLIT} (tumour = tumor1 + tumor2, non-tumour = macrophage)"

tumor.to_csv(os.path.join(OUTDIR, "cell_tumor.txt"), index=False, header=False)
nontumor.to_csv(os.path.join(OUTDIR, "cell_nontumor.txt"), index=False, header=False)
print(f"set={SET}  split by {how}")
print(f"tumor:     {len(tumor):4d} -> {OUTDIR}/cell_tumor.txt")
print(f"non-tumor: {len(nontumor):4d} -> {OUTDIR}/cell_nontumor.txt")

# How the split lands against the methylation annotations, for the record.
for col in ("cell_type_hcg", "cell_type_joint"):
    if col in df.columns:
        lab = pd.Series("non-tumour", index=df.index)
        lab[df["cell"].isin(set(tumor))] = "tumour"
        print(f"\n{col} x split:")
        print(pd.crosstab(df[col], lab).to_string())
