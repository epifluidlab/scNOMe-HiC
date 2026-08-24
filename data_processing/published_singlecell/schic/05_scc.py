#!/usr/bin/env python3
"""
Step 05 — HiCRep SCC between the scNOMe-HiC pseudobulk and the sci-Hi-C GM12878
pseudobulk at 2.5 Mb per chromosome. Adapted verbatim from
gm_sc_new/hic_comparison/scripts/scc_analysis.py (same load/clip/cool/hicrep path),
only the two inputs differ:
    reference = scNOMe-HiC   dump work/dump_2.5Mb/nomehic_2.5Mb_<chr>.txt
    target    = sci-Hi-C GM  dump work/dump_2.5Mb/schic_gm_2.5Mb_<chr>.txt
Both are juicer-style triplets (start1 start2 count), hg38 2.5 Mb.
Outputs: figures/schic_scc_by_chrom_and_percentile.csv + boxplot (png/pdf).
"""
import os, re, numpy as np, pandas as pd
import matplotlib; matplotlib.use("Agg"); import matplotlib.pyplot as plt
import cooler
from hicrep import hicrepSCC
from hicrep.utils import readMcool

BIN_SIZE = int(os.environ.get("BIN", 2_500_000))
H        = int(os.environ.get("HICREP_H", 3))
IS_LOG   = os.environ.get("IS_LOG", "False") == "True"
CHROMS   = [f"chr{i}" for i in range(1, 23)] + ["chrX"]
PCTS     = [int(x) for x in os.environ.get("PCTS", "95 99 100").split()]

WORK = os.environ["WORK"]; FIG = os.environ["FIG"]
DUMP = os.path.join(WORK, "dump_2.5Mb")
COOL = os.path.join(WORK, "cool_files"); os.makedirs(COOL, exist_ok=True)
os.makedirs(FIG, exist_ok=True)
OUT_CSV = os.path.join(FIG, "schic_scc_by_chrom_and_percentile.csv")
OUT_PNG = os.path.join(FIG, "schic_scc_boxplots_by_percentile.png")
OUT_PDF = os.path.join(FIG, "schic_scc_boxplots_by_percentile.pdf")

path_nome  = lambda c: os.path.join(DUMP, f"nomehic_2.5Mb_{c}.txt")
path_schic = lambda c: os.path.join(DUMP, f"schic_gm_2.5Mb_{c}.txt")


def load_matrix(path, bin_size=BIN_SIZE):
    if not os.path.exists(path) or os.path.getsize(path) == 0:
        return np.zeros((0, 0))
    df = pd.read_csv(path, sep="\t", header=None, names=["start1", "start2", "count"])
    if df.empty:
        return np.zeros((0, 0))
    df["bin1"] = (df["start1"] // bin_size).astype(int)
    df["bin2"] = (df["start2"] // bin_size).astype(int)
    n = int(max(df["bin1"].max(), df["bin2"].max()) + 1)
    m = np.zeros((n, n))
    for i, j, v in zip(df["bin1"], df["bin2"], df["count"]):
        m[i, j] = v; m[j, i] = v
    return m


def clip_vmax(m, pct):
    return 1.0 if m.size == 0 else float(np.percentile(m.ravel(), pct))


def save_cool(m, chrom, out):
    n = m.shape[0]
    if n == 0:
        return False
    bins = pd.DataFrame({"chrom": [chrom]*n,
                         "start": np.arange(0, n*BIN_SIZE, BIN_SIZE, dtype=np.int64),
                         "end":   np.arange(BIN_SIZE, (n+1)*BIN_SIZE, BIN_SIZE, dtype=np.int64)})
    iu, ju = np.triu_indices(n); counts = m[iu, ju].astype(np.float64); keep = counts > 0
    pixels = pd.DataFrame({"bin1_id": iu[keep].astype(np.int64),
                           "bin2_id": ju[keep].astype(np.int64),
                           "count":   counts[keep]})
    if os.path.exists(out):
        os.remove(out)
    cooler.create_cooler(out, bins=bins, pixels=pixels,
                         dtypes={"count": "float64"}, ordered=True, symmetric_upper=True)
    return True


def ck(c):
    m = re.match(r"chr(\d+)$", c)
    return (0, int(m.group(1))) if m else (1, {"chrX": 23}.get(c, 99))


def main():
    rows = []
    for pct in PCTS:
        for chrom in CHROMS:
            pn, ps = path_nome(chrom), path_schic(chrom)
            if not (os.path.exists(pn) and os.path.exists(ps)):
                print(f"[WARN] missing dump {chrom}"); continue
            mn, ms = load_matrix(pn), load_matrix(ps)
            if mn.size == 0 or ms.size == 0:
                print(f"[WARN] empty {chrom}"); continue
            n = min(mn.shape[0], ms.shape[0])
            mn, ms = mn[:n, :n], ms[:n, :n]
            mnc = np.minimum(mn, clip_vmax(mn, pct))
            msc = np.minimum(ms, clip_vmax(ms, pct))
            cn = os.path.join(COOL, f"nomehic_{chrom}_{pct}.cool")
            cs = os.path.join(COOL, f"schic_{chrom}_{pct}.cool")
            save_cool(mnc, chrom, cn); save_cool(msc, chrom, cs)
            try:
                nc, _ = readMcool(cn, -1); sc, _ = readMcool(cs, -1)
                scc = hicrepSCC(nc, sc, H, BIN_SIZE, IS_LOG, np.array([chrom]))
                v = float(np.asarray(scc).ravel()[0])
                rows.append({"percentile": pct, "chrom": chrom, "SCC": v})
                print(f"[OK] pct={pct} {chrom} SCC={v:.4f}")
            except Exception as e:
                print(f"[ERROR] {chrom} pct={pct}: {e}")

    if not rows:
        print("[ERROR] no SCC computed"); return
    df = pd.DataFrame(rows).sort_values(
        ["percentile", "chrom"], key=lambda s: s.map(ck) if s.name == "chrom" else s)
    df.to_csv(OUT_CSV, index=False)
    print(f"[OK] wrote {OUT_CSV}")
    print("\n=== mean/median SCC per percentile ===")
    print(df.groupby("percentile")["SCC"].agg(["mean", "median", "count"]))

    plt.figure(figsize=(7, 5))
    plt.boxplot([df.loc[df.percentile == p, "SCC"].dropna().values for p in PCTS],
                labels=[str(p) for p in PCTS], showfliers=True)
    plt.xlabel("Percentile clipping"); plt.ylabel("SCC (HiCRep)")
    plt.title("GM12878 scNOMe-HiC vs sci-Hi-C — SCC per chromosome (2.5 Mb)")
    plt.grid(axis="y", linestyle=":", alpha=0.4); plt.tight_layout()
    plt.savefig(OUT_PNG, dpi=300); plt.savefig(OUT_PDF)
    print(f"[OK] wrote {OUT_PNG} / {OUT_PDF}")


if __name__ == "__main__":
    main()
