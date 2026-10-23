#!/usr/bin/env python
"""STEP 05 (in-situ) -- Non-circular 2xN APA.

Loop sets are defined ENTIRELY by the in-situ Hi-C HICCUPS calls (step 04 hiccupsdiff,
or the set-difference route).
Signal is read out from the sc pseudobulk imputed Q matrices.

Why this exists
---------------
The existing figure (`loop_insitu_apa.ipynb` cell 54 -> APA_2xN_insitu_diffloops.pdf)
selects differential loops from `loopq`/`loopt` -- statistics derived from the sc-imputed
Q/T matrices -- and then piles up O/E from those SAME Q matrices. Selection statistic and
display statistic share the underlying data, so the clean diagonal is partly guaranteed by
winner's curse (double-dipping). It cannot distinguish real biology from selection on noise.

Here the loop selection never touches the sc data. An independent selection can only
ATTENUATE a real effect, never manufacture one -- so a surviving diagonal is evidence.

Differences from cell 54 (deliberate)
-------------------------------------
1. loop_list comes from data/loops/diff_insitu_25kb/{GM12878,IMR90}_specific.bedpe.
2. Iterates ALL 22 autosomes. Cell 54 used `chrom_sizes.index[:-1]`, which silently
   drops chr22 (the sizes file is autosomes-only). Fixed here.
3. Distance filters made explicit. Cell 54 relied on the notebook's `distfilter`; these
   bedpes have had no such filter, and the O/E matrix E is upper-triangular only, so a
   loop with anchor separation <= flank_bins would have part of its window sitting in the
   unfilled lower triangle (zeros). Loops outside [flank_bins, dist) bins are dropped.

   This filter is load-bearing. E is written only at (i, i+k) for k >= 0, so a window
   pixel (a, b) lands in the unfilled lower triangle whenever a - b > the loop's span in
   bins -- strictly, safety needs span >= 2*flank_bins, not just > flank_bins. In practice
   the loops here span far enough that it does not bite: measured on the published panels,
   the lower-left half averages 0.99x the upper-right at flank 8 and 0.97x at flank 10,
   i.e. symmetric. Figure 3's pile-up had no distance filter at all, 65% of its loops
   clipped, and its lower-left came out at 0.40x -- it fills the lower triangle by
   mirroring instead (fig3_apa.ipynb). If you ever relax or remove the filter here, mirror
   E the same way rather than relying on the loop distribution.
4. Records per-loop centre O/E so the result can be tested, not just eyeballed.
5. Renders both the per-window min-max normalised image (matching the existing figure's
   style) and the raw mean O/E image (standard APA). Pile-up is the expensive part;
   rendering twice is free.

Loop-set source is selected with the APA_LOOPSET environment variable:

  APA_LOOPSET=setdiff      (default)  scripts/diff_loops.py presence/absence, 2,434 / 5,401
                                      -> APA_2xN_insituDEF_diffloops*, apa_insituDEF.*
  APA_LOOPSET=hiccupsdiff             juicer hiccupsdiff, FDR-tested,        516 /   968
                                      -> APA_2xN_insituHCD_diffloops*, apa_insituHCD.*

Only hiccupsdiff is BOTH a real statistical test and independent of the sc data. Set-difference
is independent but not a test (threshold-cliff); the notebook's sc ANOVA is a test but circular.

Outputs (into data/diff/GM12878_IMR90_insitu_loops/figures/), where <B> is the basename above:
  <B>.{png,pdf}       -- min-max normalised rendering
  <B>_raw.{png,pdf}   -- raw mean O/E rendering
  apa_insitu*.npz     -- vis_all, raw_all, cnt_all, per-loop centres
  apa_insitu*_stats.tsv -- APA scores + Mann-Whitney interaction test
"""
from __future__ import annotations

# --- repo paths: edit paths.yaml at the repository root, not this file -------
import os as _os, sys as _sys
_r = _os.path.dirname(_os.path.abspath(__file__))
while _r != "/" and not _os.path.exists(_os.path.join(_r, "paths.py")):
    _r = _os.path.dirname(_r)
_sys.path.insert(0, _r)
from paths import DATA, REFERENCE, SOFTWARE, WORK, TMP, CONDA_SH, CONDA_ENVS


import os
from concurrent.futures import ProcessPoolExecutor, as_completed

import numpy as np
import pandas as pd
import cooler
import matplotlib as mpl
import matplotlib.pyplot as plt
from scipy.stats import mannwhitneyu

# NB: the Agg backend is selected inside main(), not at import time, so that
# importing this module from a notebook does not clobber the inline backend.
# ../../../main_figures/fig2/fig2_apa.ipynb imports it, under the filename it
# carries in the working directory (step08_apa_insitu_defined), via
# sys.path.insert(0, BASE) -- this numbered copy is the record, not the import
# target, because a module name cannot begin with a digit.

# ----------------------------------------------------------------------------
# Config -- mirrors notebook cell 12
# ----------------------------------------------------------------------------
BASE = WORK + "/mixture_cellline/APA/insitu"

celltypes = ["GM12878", "IMR90"]
leg = pd.Index(celltypes)
legname = list(celltypes)

res = 25000
dist = 505                      # bins; decay/E are only defined out to this separation
# Window half-width. 200 kb (8 bins, 17x17) is our default; the scHiCluster reference uses
# 250 kb (10 bins, 21x21). Override with APA_FLANK_KB=250.
apa_flank_bp = int(os.environ.get("APA_FLANK_KB", "200")) * 1000
apa_flank_bins = apa_flank_bp // res
apa_window_size = 2 * apa_flank_bins + 1
cpu = 2                         # one worker per cell type

if apa_flank_bp % res != 0:
    raise ValueError("apa_flank_bp must be divisible by res")

indir = f"{BASE}/data/per_celltype"
outdir = f"{BASE}/data/diff/GM12878_IMR90_insitu_loops"
fig_outdir = os.path.join(outdir, "figures")

# Which in-situ differential loop definition to use. Both are independent of the sc data;
# they differ in how "differential" is decided.
#   setdiff      -- scripts/diff_loops.py: presence/absence in the two HICCUPS call sets
#                   (L_inf match, 25 kb). Not a statistical test; a loop just under FDR in one
#                   sample and just over in the other is called specific. 2,434 / 5,401.
#   hiccupsdiff  -- juicer hiccupsdiff: tests contact frequency at each loop directly, with
#                   FDR. A real test AND independent of the sc data. 516 / 968.
# Select with APA_LOOPSET=hiccupsdiff; default stays setdiff so earlier results reproduce.
LOOPSET = os.environ.get("APA_LOOPSET", "setdiff")

if LOOPSET == "hiccupsdiff":
    DIFF_DIR = f"{BASE}/data/loops/hiccupsdiff_25kb"
    LOOPSET_FILES = [
        ("GM12878 specific loops", f"{DIFF_DIR}/GM12878_specific_hiccupsdiff.bedpe"),
        ("IMR90 specific loops",   f"{DIFF_DIR}/IMR90_specific_hiccupsdiff.bedpe"),
    ]
    FIG_BASE = "APA_2xN_insituHCD_diffloops"
    NPZ_NAME = "apa_insituHCD.npz"
    STATS_NAME = "apa_insituHCD_stats.tsv"
elif LOOPSET == "setdiff":
    DIFF_DIR = f"{BASE}/data/loops/diff_insitu_25kb"
    LOOPSET_FILES = [
        ("GM12878 specific loops", f"{DIFF_DIR}/GM12878_specific.bedpe"),
        ("IMR90 specific loops",   f"{DIFF_DIR}/IMR90_specific.bedpe"),
    ]
    FIG_BASE = "APA_2xN_insituDEF_diffloops"
    NPZ_NAME = "apa_insituDEF.npz"
    STATS_NAME = "apa_insituDEF_stats.tsv"
else:
    raise ValueError(f"APA_LOOPSET must be 'setdiff' or 'hiccupsdiff', got {LOOPSET!r}")

# keep non-default flanks in their own files
if apa_flank_bp != 200_000:
    _sfx = f"_{apa_flank_bp // 1000}kb"
    FIG_BASE += _sfx
    NPZ_NAME = NPZ_NAME.replace(".npz", f"{_sfx}.npz")
    STATS_NAME = STATS_NAME.replace(".tsv", f"{_sfx}.tsv")

chrom_size_path = REFERENCE + "/hg38/autosomes.chrom.sizes"


def load_loopsets():
    """Read the in-situ differential bedpes, apply the distance filters, report drops."""
    labels, loops = [], []
    for label, path in LOOPSET_FILES:
        df = pd.read_csv(path, sep="\t", header=None, comment="#", low_memory=False)
        df = df.iloc[:, :6]
        for col in (0, 3):
            df[col] = df[col].astype(str)
            df[col] = df[col].where(df[col].str.startswith("chr"), "chr" + df[col])
        n0 = len(df)

        sep_bins = (df[4].astype(int) // res) - (df[1].astype(int) // res)
        keep = (sep_bins > apa_flank_bins) & (sep_bins < dist)
        df = df[keep].reset_index(drop=True)

        n_close = int((sep_bins <= apa_flank_bins).sum())
        n_far = int((sep_bins >= dist).sum())
        print(f"  {label:<26s} {n0:>6d} loops -> {len(df):>6d} kept "
              f"(dropped {n_close} too close, {n_far} too far)")
        labels.append(label)
        loops.append(df)
    return labels, loops


def apa(ct, indir, chrom_index, loop_list, res, dist, flank_bins):
    """Pile up O/E from the sc-imputed Q matrix of one cell type at each loop set.

    Returns (result_vis, result_raw, counts, centres, windows). centres[j] is a
    per-loop array of the centre-pixel O/E and windows[j] the full per-loop window,
    both aligned to loop_list[j]'s row order (NaN where extraction failed).
    """
    n_sets = len(loop_list)
    window_size = 2 * flank_bins + 1

    result_vis = np.zeros((n_sets, window_size, window_size), dtype=float)
    result_raw = np.zeros((n_sets, window_size, window_size), dtype=float)
    counts = np.zeros(n_sets, dtype=np.int64)
    centres = [np.full(len(lp), np.nan, dtype=float) for lp in loop_list]
    # full per-loop raw O/E window, so main() can build a median-of-log-ratios difference
    # map. Dividing the MEAN panels instead lets a few very strong loops (present in both
    # cell types) dominate and wash the ratio toward zero -- ratio-of-means is not the same
    # as median-of-ratios, and here they differ by ~8x on the GM-specific set.
    windows = [np.full((len(lp), window_size, window_size), np.nan, dtype=float)
               for lp in loop_list]

    cool = cooler.Cooler(f"{indir}/{ct}/{ct}/{ct}.Q.cool")

    for c in chrom_index:
        Q = cool.matrix(balance=False, sparse=True).fetch(c).toarray().astype(float)

        decay = np.empty(dist, dtype=float)
        for k in range(dist):
            d = np.diag(Q, k)
            decay[k] = np.nanmean(d) if d.size else np.nan

        E = np.zeros(Q.shape, dtype=float)
        row, col = np.diag_indices(E.shape[0])
        E[row, col] = 1.0
        for k in range(1, dist):
            dk = decay[k]
            if (not np.isfinite(dk)) or (dk <= 0):
                continue
            E[row[:-k], col[k:]] = Q[row[:-k], col[k:]] / dk

        for j, loop in enumerate(loop_list):
            pos = np.where((loop[0] == c).to_numpy())[0]
            if pos.size == 0:
                continue
            coords = loop.iloc[pos][[1, 4]].to_numpy() // res

            for p, (xx, yy) in zip(pos, coords):
                tmp = E[(xx - flank_bins):(xx + flank_bins + 1),
                        (yy - flank_bins):(yy + flank_bins + 1)]
                if tmp.shape != (window_size, window_size):
                    continue

                tmp = tmp.astype(float, copy=True)
                tmp[~np.isfinite(tmp)] = np.nan
                if np.all(np.isnan(tmp)):
                    continue

                centres[j][p] = tmp[flank_bins, flank_bins]
                windows[j][p] = tmp

                result_raw[j] += np.nan_to_num(tmp, nan=0.0, posinf=0.0, neginf=0.0)

                tmin, tmax = np.nanmin(tmp), np.nanmax(tmp)
                if (not np.isfinite(tmin)) or (not np.isfinite(tmax)) or (tmax <= tmin):
                    continue
                tmp_vis = (tmp - tmin) / (tmax - tmin)
                result_vis[j] += np.nan_to_num(tmp_vis, nan=0.0, posinf=0.0, neginf=0.0)

                counts[j] += 1

    for j in range(n_sets):
        if counts[j] > 0:
            result_vis[j] /= counts[j]
            result_raw[j] /= counts[j]
        else:
            result_vis[j][:] = np.nan
            result_raw[j][:] = np.nan

    return result_vis, result_raw, counts, centres, windows


def apa_score(raw_panel, flank_bins):
    """Standard APA: centre pixel over the lower-left corner background."""
    bg_width = max(1, min(5, flank_bins))
    ctr = raw_panel[flank_bins, flank_bins]
    bg = np.mean(raw_panel[-bg_width:, :bg_width])
    if np.isfinite(ctr) and np.isfinite(bg) and bg > 0:
        return ctr / bg
    return np.nan


def draw(panels, scores, loop_labels, counts, out_base, cbar_label, vmin, vmax):
    mpl.rcParams["font.family"] = "sans-serif"
    mpl.rcParams["font.sans-serif"] = ["Arial", "Liberation Sans", "DejaVu Sans"]
    mpl.rcParams["pdf.fonttype"] = 42
    mpl.rcParams["ps.fonttype"] = 42

    n_rows, n_cols = len(leg), len(loop_labels)
    fig, axes = plt.subplots(n_rows, n_cols,
                             figsize=(n_cols * 2.3, n_rows * 1.9),
                             sharex=True, sharey=True, dpi=300)
    fig.subplots_adjust(wspace=0.55, hspace=0.35)

    for i in range(n_rows):
        for j in range(n_cols):
            ax = axes[i, j]
            im = ax.imshow(panels[i, j], cmap="hot_r", vmin=vmin, vmax=vmax)
            s = scores[i, j]
            ax.set_title("APA = n/a" if not np.isfinite(s) else f"APA = {s:.2f}",
                         fontsize=8)

    for i, ct_label in enumerate(legname):
        axes[i, 0].set_ylabel(ct_label)

    for j, loop_label in enumerate(loop_labels):
        axes[-1, j].set_xlabel(f"{loop_label}\n(n = {counts[0, j]})", fontsize=8)

    edge_tick = apa_window_size - 1
    edge_label = f"{apa_flank_bp // 1000}k"
    axes[-1, 0].set_xticks([0, edge_tick])
    axes[-1, 0].set_xticklabels([f"-{edge_label}", f"+{edge_label}"])
    axes[-1, 0].set_yticks([0, edge_tick])
    axes[-1, 0].set_yticklabels([f"-{edge_label}", f"+{edge_label}"])

    cbar = fig.colorbar(im, ax=axes.ravel().tolist(), fraction=0.046, pad=0.04)
    cbar.set_label(cbar_label, fontsize=7)
    cbar.ax.tick_params(labelsize=6)

    os.makedirs(fig_outdir, exist_ok=True)
    for ext in ("png", "pdf"):
        p = os.path.join(fig_outdir, f"{out_base}.{ext}")
        fig.savefig(p, dpi=300, bbox_inches="tight", transparent=(ext == "pdf"))
        print(f"  saved: {p}")
    plt.close(fig)


def main():
    mpl.use("Agg")
    print("=" * 70)
    print(f"STEP 05 -- non-circular APA  [loopset={LOOPSET}]")
    print("=" * 70)

    chrom_sizes = cooler.read_chromsizes(chrom_size_path, all_names=True)
    if not any(str(c).startswith("chr") for c in chrom_sizes.index):
        chrom_sizes.index = ["chr" + str(c) for c in chrom_sizes.index]
    chrom_index = list(chrom_sizes.index)      # all 22 autosomes (cell 54 dropped chr22)
    print(f"chromosomes: {len(chrom_index)} ({chrom_index[0]}..{chrom_index[-1]})\n")

    print("loop sets:")
    loop_labels, loop_list = load_loopsets()
    print()

    n_rows, n_cols = len(leg), len(loop_list)
    vis_all = np.full((n_rows, n_cols, apa_window_size, apa_window_size), np.nan)
    raw_all = np.full((n_rows, n_cols, apa_window_size, apa_window_size), np.nan)
    cnt_all = np.zeros((n_rows, n_cols), dtype=np.int64)
    centres_all = {}
    windows_all = {}

    with ProcessPoolExecutor(max_workers=cpu) as ex:
        futs = {ex.submit(apa, ct, indir, chrom_index, loop_list, res, dist,
                          apa_flank_bins): i
                for i, ct in enumerate(leg)}
        for fut in as_completed(futs):
            i = futs[fut]
            v, r, cnt, centres, wins = fut.result()
            vis_all[i], raw_all[i], cnt_all[i] = v, r, cnt
            centres_all[leg[i]] = centres
            windows_all[leg[i]] = wins
            print(f"  {leg[i]} finished ({cnt.tolist()} windows)")
    print()

    # median-of-log-ratios difference map: per loop, log2(GM window / IMR window), then
    # the median across loops. Immune to loop-set strength, length and the GM-subsample
    # enrichment, because every value compares a loop against itself across the two
    # pseudobulks. This is the visual form of the paired Mann-Whitney below.
    wg, wi = windows_all["GM12878"], windows_all["IMR90"]
    diffmap = np.full((n_cols, apa_window_size, apa_window_size), np.nan)
    for j in range(n_cols):
        a, b = wg[j], wi[j]
        with np.errstate(divide="ignore", invalid="ignore"):
            lr = np.log2(a / b)
        lr[~np.isfinite(lr)] = np.nan
        if np.any(np.isfinite(lr)):
            diffmap[j] = np.nanmedian(lr, axis=0)

    print("difference map (median per-loop log2 GM/IMR) centre values:")
    for j, lb in enumerate(loop_labels):
        c = diffmap[j][apa_flank_bins, apa_flank_bins]
        print(f"  {lb:<26s} {c:+.4f}  ({2 ** c:.2f}x)")
    print()

    scores = np.array([[apa_score(raw_all[i, j], apa_flank_bins)
                        for j in range(n_cols)] for i in range(n_rows)])

    print("APA scores (centre / lower-left background, from raw O/E):")
    print(f"  {'':<14s}" + "".join(f"{lb:>28s}" for lb in loop_labels))
    for i, ct in enumerate(legname):
        print(f"  {ct:<14s}" + "".join(f"{scores[i, j]:>28.3f}" for j in range(n_cols)))
    print()

    # ---- figures ----
    print("figures:")
    draw(vis_all, scores, loop_labels, cnt_all, FIG_BASE,
         "min-max normalized O/E", 0.2, 0.8)
    rmin = float(np.nanpercentile(raw_all, 5))
    rmax = float(np.nanpercentile(raw_all, 99))
    draw(raw_all, scores, loop_labels, cnt_all, f"{FIG_BASE}_raw",
         "mean O/E", rmin, rmax)
    print()

    # ---- statistical test ----
    # Per loop, log2( centre O/E in GM  /  centre O/E in IMR ).  Comparing this
    # log-ratio between the two loop sets is the interaction test: it controls for
    # loop-intrinsic properties (distance, anchor strength) that affect both cell types.
    gm_c, imr_c = centres_all["GM12878"], centres_all["IMR90"]
    rows = []
    ratios = []
    for j, label in enumerate(loop_labels):
        a, b = gm_c[j], imr_c[j]
        ok = np.isfinite(a) & np.isfinite(b) & (a > 0) & (b > 0)
        lr = np.log2(a[ok] / b[ok])
        ratios.append(lr)
        rows.append({"loop_set": label, "n_paired": int(ok.sum()),
                     "median_log2_GM_over_IMR": float(np.median(lr)),
                     "mean_log2_GM_over_IMR": float(np.mean(lr))})
        print(f"  {label:<26s} n={ok.sum():>5d}  "
              f"median log2(GM/IMR) centre O/E = {np.median(lr):+.4f}")

    u, p = mannwhitneyu(ratios[0], ratios[1], alternative="greater")
    print(f"\n  Mann-Whitney (GM-specific log-ratio > IMR-specific log-ratio):")
    print(f"    U = {u:.4g}   p = {p:.4g}")
    print("    Interpretation: p small => GM-specific loops are relatively stronger in the")
    print("    GM pseudobulk than IMR-specific loops are, i.e. the sc data recapitulates the")
    print("    in-situ-defined cell-type specificity. Loop selection never saw the sc data.")

    stats = pd.DataFrame(rows)
    stats["mannwhitney_U"] = u
    stats["mannwhitney_p_greater"] = p
    for i, ct in enumerate(legname):
        for j, label in enumerate(loop_labels):
            stats.loc[stats.loop_set == label, f"apa_score_on_{ct}"] = scores[i, j]
    stats_path = os.path.join(fig_outdir, STATS_NAME)
    stats.to_csv(stats_path, sep="\t", index=False)
    print(f"\n  saved: {stats_path}")

    npz_path = os.path.join(fig_outdir, NPZ_NAME)
    np.savez_compressed(
        npz_path, vis_all=vis_all, raw_all=raw_all, cnt_all=cnt_all, diffmap=diffmap,
        scores=scores, loop_labels=np.array(loop_labels),
        **{f"centres_{ct}_{j}": centres_all[ct][j]
           for ct in leg for j in range(n_cols)},
    )
    print(f"  saved: {npz_path}")
    print("\ndone.")


if __name__ == "__main__":
    main()
