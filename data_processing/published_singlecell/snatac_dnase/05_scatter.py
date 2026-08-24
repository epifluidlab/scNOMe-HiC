#!/usr/bin/env python
"""Per-peak GCH vs snATAC scatter + Spearman/Pearson.
Input: multiBigwigSummary --outRawCounts tab (cols: chr start end GCH snATAC)."""
import sys
import numpy as np
import pandas as pd
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from scipy.stats import spearmanr, pearsonr

tab, outpdf = sys.argv[1], sys.argv[2]

df = pd.read_csv(tab, sep="\t")
df.columns = [c.strip().strip("#'\" ") for c in df.columns]
# expected: chr start end GCH snATAC
gcol = [c for c in df.columns if c.lower() == "gch"][0]
acol = [c for c in df.columns if c.lower() == "snatac"][0]
g = pd.to_numeric(df[gcol], errors="coerce")
a = pd.to_numeric(df[acol], errors="coerce")
m = np.isfinite(g) & np.isfinite(a)
g, a = g[m].values, a[m].values
n = len(g)
print(f"[scatter] {n:,} peaks with finite GCH & snATAC")

rho, prho = spearmanr(g, a)
# Pearson on log1p(snATAC) vs GCH% (snATAC is heavy-tailed)
al = np.log1p(a)
r, pr = pearsonr(g, al)
print(f"[scatter] Spearman rho = {rho:.4f} (p={prho:.2e})")
print(f"[scatter] Pearson r (GCH vs log1p(snATAC)) = {r:.4f} (p={pr:.2e})")

slope, intercept = np.polyfit(g, al, 1)
print(f"[scatter] OLS fit: log1p(snATAC) = {slope:.4g} * GCH + {intercept:.4g}")

fig, ax = plt.subplots(figsize=(6, 5.5))
hb = ax.hexbin(g, al, gridsize=60, bins="log", cmap="viridis", mincnt=1)
cb = fig.colorbar(hb, ax=ax); cb.set_label("log10(peak count)")
xs = np.linspace(g.min(), g.max(), 100)
ax.plot(xs, slope * xs + intercept, color="red", lw=2, ls="--",
        label=f"OLS fit: y = {slope:.3g}x + {intercept:.3g}")
ax.legend(loc="lower right", frameon=True, fontsize=9)
ax.set_xlabel("scNOMe-HiC GCH methylation (%)")
ax.set_ylabel("snATAC signal  log1p(CPM)")
ax.set_title("GM12878 DNase peaks: GCH accessibility vs snATAC")
ax.text(0.03, 0.97,
        f"n = {n:,}\nSpearman rho = {rho:.3f}\nPearson r = {r:.3f}\nslope = {slope:.3g}",
        transform=ax.transAxes, va="top", ha="left",
        bbox=dict(boxstyle="round", fc="white", alpha=0.8))
fig.tight_layout()
fig.savefig(outpdf)
fig.savefig(outpdf.replace(".pdf", ".png"), dpi=200)
print(f"[scatter] wrote {outpdf}")
