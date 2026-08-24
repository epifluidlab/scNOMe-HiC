import os
import argparse
import pandas as pd
import subprocess

def fast_line_count(filepath):
    """Use system wc -l for high-speed line counting."""
    result = subprocess.run(["wc", "-l", filepath], capture_output=True, text=True)
    return int(result.stdout.strip().split()[0])

def extract_counts(base_folder, middle, output):
    results = {}

    for root, dirs, files in os.walk(base_folder):
        for fname in files:
            if middle in fname and fname.endswith(".bed"):
                full_path = os.path.join(root, fname)
                sample = fname.split(middle)[0]

                if sample not in results:
                    results[sample] = {'GCH': None, 'HCG': None}

                if ".GCH" in fname:
                    results[sample]['GCH'] = fast_line_count(full_path) - 1
                elif ".HCG" in fname:
                    results[sample]['HCG'] = fast_line_count(full_path) - 1

    df = pd.DataFrame(
        [[s, v['GCH'], v['HCG']] for s, v in results.items()],
        columns=['sample', 'GCH', 'HCG']
    )
    df.to_csv(output, sep='\t', index=False)
    print(f"✅ Done! Found {len(results)} samples. Saved to {output}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Recursively extract GCH/HCG row counts from all subfolders.")
    parser.add_argument("--folder", required=True, help="Top-level folder containing sample subfolders")
    parser.add_argument("--middle", required=True, help="Middle part of filenames, e.g. .hg38.calmd.cytosine.filtered.sort.")
    parser.add_argument("--output", required=True, help="Output TSV file name")
    args = parser.parse_args()

    extract_counts(args.folder, args.middle, args.output)

