#!/usr/bin/env python
"""Build QC/cellline_qc_table.xlsx for the gm_sc_new (scNH GM12878 4plex) cells.

Per-cell columns:
  total                 TotalFragments                        (04.alignment_snakemake/*.summary.txt.gz)
  uniquely_mapped       UniqMapped
  uniquely_mapped_mapq30/rate
  pcr_dup / pcr_dup_rate  UniqMappedMapQ30 - UniqMappedMapQ30NoPcr
  dedup_mapq30          UniqMappedMapQ30NoPcr
  cis                   UniqMappedMapQ30NoPcrCis
  cis_gt1kb             UniqMappedMapQ30NoPcrCisMore1kb
  trans                 UniqMappedMapQ30NoPcrTrans
  trans_cis_ratio       trans / cis
  HCG / WCG / GCH       site counts   (QC/cellline.gch_hcg_count.txt)
  noncpg_meth_chrM/chr21  non-CpG methylation % = ACT trinucleotide methylation
                        rate (QC/cellline.{chrM,chr21}.txt, col 'noncpg', which
                        make_qc_notebook.py fills from _trinuc_percent(.,'ACT')
                        on *.calmd.trinuc_methy.{chrM,chr21}.txt.gz).
                        This is the "bisulfite conversion" QC metric; low = good.
  qc_pass               all thresholds in configs/config.yaml (same logic as
                        make_qc_notebook.py / QC/cellline_passed.txt)

Usage: <scwgbs python> make_qc_excel.py
"""
import gzip
from pathlib import Path

import pandas as pd

try:
    import yaml

    def load_cfg(path):
        return yaml.safe_load(open(path))
except ImportError:  # minimal flat "key: value" parser fallback
    def load_cfg(path):
        cfg = {}
        for line in open(path):
            line = line.split("#")[0].strip()
            if not line or ":" not in line or line.startswith("-"):
                continue
            k, v = line.split(":", 1)
            v = v.strip().strip('"').strip("'")
            if not v:
                continue
            try:
                cfg[k.strip()] = int(v)
            except ValueError:
                try:
                    cfg[k.strip()] = float(v)
                except ValueError:
                    cfg[k.strip()] = v
        return cfg

WORKDIR = Path(__file__).resolve().parent
ALIGN_DIR = WORKDIR / "04.alignment_snakemake"
QC_DIR = WORKDIR / "QC"
OUT_XLSX = QC_DIR / "cellline_qc_table.xlsx"

CFG = load_cfg(WORKDIR / "configs" / "config.yaml")

SUMMARY_KEYS = [
    "TotalFragments",
    "UniqMapped",
    "UniqMappedMapQ30",
    "UniqMappedMapQ30NoPcr",
    "UniqMappedMapQ30NoPcrTrans",
    "UniqMappedMapQ30NoPcrCis",
    "UniqMappedMapQ30NoPcrCisMore1kb",
]


def parse_summary(path):
    """summary.txt.gz lines: 'Key:\\tcount\\tpercent%'"""
    vals = {}
    with gzip.open(path, "rt") as fh:
        for line in fh:
            parts = line.rstrip("\n").split("\t")
            if len(parts) < 2:
                continue
            key = parts[0].rstrip(":")
            try:
                vals[key] = int(parts[1])
            except ValueError:
                continue
    return {k: vals.get(k) for k in SUMMARY_KEYS}


prefixes = [p.strip() for p in open(QC_DIR / "cellline_prefixes_used.txt") if p.strip()]

rows = []
missing = []
for prefix in prefixes:
    f = ALIGN_DIR / f"{prefix}.summary.txt.gz"
    if not f.exists():
        missing.append(prefix)
        continue
    row = {"prefix": prefix}
    row.update(parse_summary(f))
    rows.append(row)

aln = pd.DataFrame(rows)

# ---- counts and rates -------------------------------------------------
aln["pcr_dup"] = aln["UniqMappedMapQ30"] - aln["UniqMappedMapQ30NoPcr"]
aln["pcr_dup_rate"] = 100.0 * aln["pcr_dup"] / aln["UniqMappedMapQ30"]
aln["uniquely_mapped_rate"] = 100.0 * aln["UniqMapped"] / aln["TotalFragments"]
aln["mapq30_rate"] = 100.0 * aln["UniqMappedMapQ30"] / aln["TotalFragments"]
aln["trans_cis_ratio"] = aln["UniqMappedMapQ30NoPcrTrans"] / aln["UniqMappedMapQ30NoPcrCis"]
aln["cis_gt1kb_rate"] = 100.0 * aln["UniqMappedMapQ30NoPcrCisMore1kb"] / aln["UniqMappedMapQ30NoPcr"]
aln["trans_rate"] = 100.0 * aln["UniqMappedMapQ30NoPcrTrans"] / aln["UniqMappedMapQ30NoPcr"]

aln = aln.rename(columns={
    "TotalFragments": "total",
    "UniqMapped": "uniquely_mapped",
    "UniqMappedMapQ30": "uniquely_mapped_mapq30",
    "UniqMappedMapQ30NoPcr": "dedup_mapq30",
    "UniqMappedMapQ30NoPcrCis": "cis",
    "UniqMappedMapQ30NoPcrCisMore1kb": "cis_gt1kb",
    "UniqMappedMapQ30NoPcrTrans": "trans",
})

# ---- methylation / conversion ----------------------------------------
counts = pd.read_csv(QC_DIR / "cellline.gch_hcg_count.txt", sep="\t").rename(
    columns={"sample": "prefix"})
chrm = pd.read_csv(QC_DIR / "cellline.chrM.txt", sep="\t").rename(
    columns={"sample": "prefix", "noncpg": "noncpg_chrM",
             "endo": "endo_chrM", "exo": "exo_chrM"})
chr21 = pd.read_csv(QC_DIR / "cellline.chr21.txt", sep="\t").rename(
    columns={"sample": "prefix", "noncpg": "noncpg_chr21",
             "endo": "endo_chr21", "exo": "exo_chr21"})

df = (aln.merge(counts, on="prefix", how="left")
         .merge(chrm[["prefix", "noncpg_chrM"]], on="prefix", how="left")
         .merge(chr21[["prefix", "noncpg_chr21"]], on="prefix", how="left"))

# "BS conversion" here = non-CpG methylation %, i.e. the ACT trinucleotide
# methylation rate straight from *.calmd.trinuc_methy.{chrM,chr21}.txt.gz
# (same as make_qc_notebook.py: noncpg <- _trinuc_percent(path, 'ACT')).
df["noncpg_meth_chrM"] = df["noncpg_chrM"]
df["noncpg_meth_chr21"] = df["noncpg_chr21"]

# ---- QC pass flag (same thresholds/logic as make_qc_notebook.py) ------
noncpg_t = CFG["noncpg_threshold"]
qc_pass = (
    (df["total"] > CFG["fragnum_threshold"]) &
    (df["noncpg_chr21"] < noncpg_t) &
    (df["noncpg_chrM"] < noncpg_t) &
    (df["GCH"] > CFG["GCH_threshold"]) &
    (df["HCG"] > CFG["HCG_threshold"]) &
    (df["trans_rate"] > CFG["transrate_threshold"]) &
    (df["cis_gt1kb"] > CFG["cis1kbnum_threshold"])
)
df["qc_pass"] = qc_pass

COLS = [
    "prefix", "total", "uniquely_mapped", "uniquely_mapped_rate",
    "uniquely_mapped_mapq30", "mapq30_rate", "pcr_dup", "pcr_dup_rate",
    "dedup_mapq30", "cis", "cis_gt1kb", "cis_gt1kb_rate", "trans", "trans_rate",
    "trans_cis_ratio", "HCG", "WCG", "GCH",
    "noncpg_meth_chrM", "noncpg_meth_chr21", "qc_pass",
]
df = df[COLS].sort_values("prefix").reset_index(drop=True)

for c in ["uniquely_mapped_rate", "mapq30_rate", "pcr_dup_rate", "cis_gt1kb_rate",
          "trans_rate", "noncpg_meth_chrM", "noncpg_meth_chr21"]:
    df[c] = df[c].round(3)
df["trans_cis_ratio"] = df["trans_cis_ratio"].round(5)

# ---- write ------------------------------------------------------------
# Excel gets human-readable headers; the TSV keeps the snake_case names so
# downstream scripts can index it programmatically.
PRETTY = {
    "prefix": "Cell",
    "total": "Total fragments",
    "uniquely_mapped": "Uniquely mapped",
    "uniquely_mapped_rate": "Uniquely mapped (%)",
    "uniquely_mapped_mapq30": "Uniquely mapped, MAPQ30",
    "mapq30_rate": "MAPQ30 (%)",
    "pcr_dup": "PCR duplicates",
    "pcr_dup_rate": "PCR duplicates (%)",
    "dedup_mapq30": "Deduplicated contacts (MAPQ30)",
    "cis": "Cis contacts",
    "cis_gt1kb": "Cis contacts >1 kb",
    "cis_gt1kb_rate": "Cis >1 kb (%)",
    "trans": "Trans contacts",
    "trans_rate": "Trans (%)",
    "trans_cis_ratio": "Trans / cis ratio",
    "HCG": "HCG sites (CpG methylation)",
    "WCG": "WCG sites",
    "GCH": "GCH sites (accessibility)",
    "noncpg_meth_chrM": "Non-CpG methylation, chrM (%)",
    "noncpg_meth_chr21": "Non-CpG methylation, chr21 (%)",
    "qc_pass": "QC pass",
}

num = df.select_dtypes("number").columns
summary = df[num].agg(["mean", "median", "min", "max"]).T.reset_index().rename(
    columns={"index": "metric"})
summary["metric"] = summary["metric"].map(PRETTY).fillna(summary["metric"])
summary = summary.rename(columns={"metric": "Metric", "mean": "Mean",
                                  "median": "Median", "min": "Min", "max": "Max"})
summary.insert(1, "Cells (n)", len(df))
summary["QC pass (n)"] = int(df["qc_pass"].sum())

df_x = df.rename(columns=PRETTY)
with pd.ExcelWriter(OUT_XLSX, engine="openpyxl") as xl:
    df_x.to_excel(xl, sheet_name="Per-cell QC", index=False)
    df_x[df["qc_pass"].values].to_excel(xl, sheet_name="QC passed", index=False)
    summary.to_excel(xl, sheet_name="Summary stats", index=False)

    # widen columns and freeze the header + cell-name column
    for ws in xl.book.worksheets:
        ws.freeze_panes = "B2"
        for col in ws.columns:
            width = max(len(str(c.value)) for c in col if c.value is not None)
            ws.column_dimensions[col[0].column_letter].width = min(width + 2, 34)

df.to_csv(QC_DIR / "cellline_qc_table.tsv", sep="\t", index=False)

print(f"cells parsed: {len(df)}  (missing summary files: {len(missing)})")
if missing:
    print("  missing:", ", ".join(missing[:10]))
print(f"QC pass: {int(df['qc_pass'].sum())}/{len(df)}")
print("wrote:", OUT_XLSX)
print("wrote:", QC_DIR / "cellline_qc_table.tsv")
