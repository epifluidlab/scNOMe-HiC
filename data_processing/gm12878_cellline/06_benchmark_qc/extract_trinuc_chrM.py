import os
import argparse
import pandas as pd

# All 16 trinucleotides Bis-QC reports. The MIDDLE base is the measured cytosine,
# so ACG is HCG (endogenous CpG), GCT is GCH (GpC accessibility) and the WCH set
# below is the bisulfite non-conversion background. Bis-QC itself is run with
# --pattern WCH, i.e. W = A or T; CCH is non-CpG but deliberately excluded.
ALL_TRINUC = ["ACA", "ACC", "ACG", "ACT",
              "CCA", "CCC", "CCG", "CCT",
              "GCA", "GCC", "GCG", "GCT",
              "TCA", "TCC", "TCG", "TCT"]
WCH = ["ACA", "ACC", "ACT", "TCA", "TCC", "TCT"]


def extract_values(base_folder, suffix, output, noncpg_context, endo_context, exo_context):
    rows = []

    for root, dirs, files in os.walk(base_folder):
        for fname in files:
            if fname.endswith(suffix):
                sample = fname.replace(suffix, "")
                methylation_path = os.path.join(root, fname)

                try:
                    # Read as 3 columns: trinuc, count, percent
                    methy_df = pd.read_csv(
                        methylation_path, sep='\t', header=None,
                        names=['trinuc', 'count', 'percent']
                    )

                    # Extract metrics safely (handle missing trinucs)
                    def get_percent(trinuc):
                        vals = methy_df.loc[methy_df['trinuc'] == f"{trinuc}:", 'percent']
                        return float(vals.values[0].strip('%')) if len(vals) > 0 else None

                    def get_count(trinuc):
                        vals = methy_df.loc[methy_df['trinuc'] == f"{trinuc}:", 'count']
                        return float(vals.values[0]) if len(vals) > 0 else None

                    row = {
                        'sample': sample,
                        'noncpg': get_percent(noncpg_context),
                        'endo':   get_percent(endo_context),
                        'exo':    get_percent(exo_context),
                    }
                    # Every context, so a different non-CpG proxy never needs a re-run.
                    for t in ALL_TRINUC:
                        row[t] = get_percent(t)
                        row[t + "_n"] = get_count(t)
                    # Count-weighted mean over the six WCH contexts.
                    num = sum(row[t] * row[t + "_n"] for t in WCH
                              if row[t] is not None and row[t + "_n"] is not None)
                    den = sum(row[t + "_n"] for t in WCH if row[t + "_n"] is not None)
                    row['noncpg_WCH'] = (num / den) if den else None

                    rows.append(row)

                except Exception as e:
                    print(f"⚠️ Skipping {fname}: {e}")

    cols = (['sample', 'noncpg', 'endo', 'exo', 'noncpg_WCH']
            + [c for t in ALL_TRINUC for c in (t, t + "_n")])
    df = pd.DataFrame(rows, columns=cols)
    df.to_csv(output, sep='\t', index=False)
    print(f"✅ Done! Found {len(rows)} samples (noncpg={noncpg_context}). Saved to {output}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Recursively extract trinuc methylation from chrM/autosome QC files. "
                    "Emits all 16 contexts plus the chosen noncpg/endo/exo aliases."
    )
    parser.add_argument("--folder", required=True, help="Top-level folder containing .trinuc_methy.chrM.txt files")
    parser.add_argument("--suffix", required=True, help="File suffix to remove for sample names, e.g. .hg38.calmd.trinuc_methy.chrM.txt")
    parser.add_argument("--output", required=True, help="Output TSV file name")
    parser.add_argument("--noncpg-context", default="TCT", choices=ALL_TRINUC,
                        help="Trinucleotide used for the 'noncpg' column (default TCT, the paper's choice; pass ACT for the earlier tables)")
    parser.add_argument("--endo-context", default="ACG", choices=ALL_TRINUC,
                        help="Trinucleotide used for the 'endo' column (default ACG)")
    parser.add_argument("--exo-context", default="GCT", choices=ALL_TRINUC,
                        help="Trinucleotide used for the 'exo' column (default GCT)")
    args = parser.parse_args()

    extract_values(args.folder, args.suffix, args.output,
                   args.noncpg_context, args.endo_context, args.exo_context)
