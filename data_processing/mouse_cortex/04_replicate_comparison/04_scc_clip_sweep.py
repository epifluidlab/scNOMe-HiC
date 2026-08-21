#!/usr/bin/env python3
"""
Step 4: sweep the per-chromosome clip percentile (95 -> 100) for the rep1-vs-rep2
Hi-C SCC, to find where the 3b-style clip stops saturating on the deep cortex data.

For each percentile p, each resolution, each chromosome:
  thresh = np.percentile(m, p);  m_clipped = np.minimum(m, thresh);  hicrepSCC(...)
p = 100 is equivalent to raw (no clip). Reuses cached juicer dumps from Step 3.

Outputs (results/scc_clipsweep/):
  - scc_clip_sweep.csv          : chrom, resolution, percentile, scc
  - scc_clip_sweep_summary.csv  : median/mean SCC per (resolution, percentile)
  - scc_clip_sweep.png/pdf      : median SCC vs percentile, one line per resolution
"""
import argparse
import os
import numpy as np
import pandas as pd
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import cooler
from hicrep import hicrepSCC

RES_LIST = [1_000_000, 500_000, 250_000]
RES_LABEL = {1_000_000: "1Mb", 500_000: "500kb", 250_000: "250kb"}
H_SMOOTH = 3
CHROMS = [f"chr{i}" for i in range(1, 20)] + ["chrX"]
PCTS = [95, 99, 99.5, 99.9, 99.99, 100]


def load_matrix(path, res):
    if not os.path.exists(path) or os.path.getsize(path) == 0:
        return np.zeros((0, 0))
    df = pd.read_csv(path, sep="\t", header=None, names=["s1", "s2", "count"])
    if df.empty:
        return np.zeros((0, 0))
    b1 = (df["s1"] // res).astype(int).to_numpy()
    b2 = (df["s2"] // res).astype(int).to_numpy()
    n = int(max(b1.max(), b2.max()) + 1)
    m = np.zeros((n, n))
    m[b1, b2] = df["count"].to_numpy(float)
    m[b2, b1] = df["count"].to_numpy(float)
    return m


def to_cool(mat, chrom, res, out_path):
    n = mat.shape[0]
    bins = pd.DataFrame({"chrom": [chrom] * n,
                         "start": np.arange(0, n * res, res, dtype=np.int64),
                         "end": np.arange(res, (n + 1) * res, res, dtype=np.int64)})
    iu, ju = np.triu_indices(n)
    c = mat[iu, ju].astype(np.float64)
    keep = c > 0
    px = pd.DataFrame({"bin1_id": iu[keep].astype(np.int64),
                       "bin2_id": ju[keep].astype(np.int64), "count": c[keep]})
    if os.path.exists(out_path):
        os.remove(out_path)
    cooler.create_cooler(out_path, bins=bins, pixels=px,
                         dtypes={"count": "float64"}, ordered=True, symmetric_upper=True)


def scc(a, b, chrom, res, cool_dir, tag):
    ca = os.path.join(cool_dir, f"a_{tag}.cool")
    cb = os.path.join(cool_dir, f"b_{tag}.cool")
    to_cool(a, chrom, res, ca)
    to_cool(b, chrom, res, cb)
    try:
        return float(np.asarray(hicrepSCC(cooler.Cooler(ca), cooler.Cooler(cb),
                                          H_SMOOTH, res, False, np.array([chrom]))).ravel()[0])
    except Exception as e:
        print(f"[warn] {tag}: {e}", flush=True)
        return np.nan


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--dump_dir", required=True)
    ap.add_argument("--out_dir", required=True)
    ap.add_argument("--name1", default="rep1")
    ap.add_argument("--name2", default="rep2")
    ap.add_argument("--pcts", default=None, help="comma-separated clip percentiles (default: 95,99,99.5,99.9,99.99,100)")
    args = ap.parse_args()
    pcts = [float(x) for x in args.pcts.split(",")] if args.pcts else PCTS
    os.makedirs(args.out_dir, exist_ok=True)
    cool_dir = os.path.join(args.out_dir, "cool_tmp")
    os.makedirs(cool_dir, exist_ok=True)

    rows = []
    for res in RES_LIST:
        lab = RES_LABEL[res]
        for chrom in CHROMS:
            d1 = os.path.join(args.dump_dir, f"{args.name1}_{lab}_{chrom}.txt")
            d2 = os.path.join(args.dump_dir, f"{args.name2}_{lab}_{chrom}.txt")
            m1 = load_matrix(d1, res)
            m2 = load_matrix(d2, res)
            if m1.size == 0 or m2.size == 0:
                continue
            n = min(m1.shape[0], m2.shape[0])
            m1, m2 = m1[:n, :n], m2[:n, :n]
            for p in pcts:
                t1 = np.percentile(m1, p)
                t2 = np.percentile(m2, p)
                s = scc(np.minimum(m1, t1), np.minimum(m2, t2), chrom, res, cool_dir,
                        f"{lab}_{chrom}_{p}")
                rows.append({"chrom": chrom, "resolution": lab, "percentile": p, "scc": s})
            print(f"{lab} {chrom}: " +
                  " ".join(f"p{p}={[r['scc'] for r in rows if r['chrom']==chrom and r['resolution']==lab and r['percentile']==p][0]:.3f}"
                           for p in pcts), flush=True)

    df = pd.DataFrame(rows)
    df.to_csv(os.path.join(args.out_dir, "scc_clip_sweep.csv"), index=False)

    summ = (df.groupby(["resolution", "percentile"], observed=True).scc
              .agg(["median", "mean", "std"]).round(4).reset_index())
    summ.to_csv(os.path.join(args.out_dir, "scc_clip_sweep_summary.csv"), index=False)
    print("\n=== median SCC by resolution x clip percentile ===")
    piv = summ.pivot(index="percentile", columns="resolution", values="median")[["1Mb", "500kb", "250kb"]]
    print(piv)

    fig, ax = plt.subplots(figsize=(6.2, 4.4))
    for lab, col in zip(["1Mb", "500kb", "250kb"], ["#1f77b4", "#2ca02c", "#d62728"]):
        sub = summ[summ.resolution == lab].sort_values("percentile")
        ax.plot(sub["percentile"], sub["median"], "o-", color=col, label=lab)
    ax.set_xlabel("clip percentile"); ax.set_ylabel("median SCC (per chrom)")
    ax.set_title(f"Hi-C SCC vs clip percentile: {args.name1} vs {args.name2}")
    ax.set_ylim(0, 1.03); ax.legend(title="resolution")
    ax.axhline(1.0, ls=":", color="0.6", lw=1)
    fig.tight_layout()
    fig.savefig(os.path.join(args.out_dir, "scc_clip_sweep.png"), dpi=150)
    fig.savefig(os.path.join(args.out_dir, "scc_clip_sweep.pdf"))
    print("\nwrote sweep CSV + summary + plot to", args.out_dir)


if __name__ == "__main__":
    main()
