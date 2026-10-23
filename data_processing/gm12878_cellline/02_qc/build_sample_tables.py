#!/usr/bin/env python
# --- repo paths: edit paths.yaml at the repository root, not this file -------
import os as _os, sys as _sys
_r = _os.path.dirname(_os.path.abspath(__file__))
while _r != "/" and not _os.path.exists(_os.path.join(_r, "paths.py")):
    _r = _os.path.dirname(_r)
_sys.path.insert(0, _r)
from paths import DATA, REFERENCE, SOFTWARE, WORK, TMP, CONDA_SH, CONDA_ENVS

"""Write the per-cell sample tables that figS4_distributions.ipynb reads:
   <cell>\t<path to that cell's per-site .6plus2.bed.gz>

The originals (sample_table_{gch,hcg}.tsv.gz, 2026-05-17) point at the
BisSNP-0.90 `.calmd.cytosine.filtered.sort.` files and are still consumed by
collapse.sh / methylation_collapse.py, so they are left alone. This writes the
BisSNP-1.0.1 (`.cyt.filtered.sort.`) equivalents under a `_bissnp101` suffix.

Usage:  python build_sample_tables.py [GM_DIR]
"""
import gzip, os, sys

GM = sys.argv[1] if len(sys.argv) > 1 else \
    WORK + "/gm12878_cellline"
METH = os.path.join(GM, "07.bistools_snakemake", "methylation")

for ctx in ("GCH", "HCG"):
    rows, missing = [], []
    for cell in sorted(os.listdir(METH)):
        d = os.path.join(METH, cell)
        if not os.path.isdir(d):
            continue
        p = os.path.join(d, f"{cell}.cyt.filtered.sort.{ctx}.6plus2.bed.gz")
        (rows if os.path.exists(p) else missing).append((cell, p))
    out = os.path.join(GM, f"sample_table_{ctx.lower()}_bissnp101.tsv.gz")
    with gzip.open(out, "wt") as fh:
        for cell, p in rows:
            fh.write(f"{cell}\t{p}\n")
    print(f"{ctx}: {len(rows)} cells -> {out}" +
          (f"   MISSING {len(missing)}: {[c for c, _ in missing][:5]}" if missing else ""))
