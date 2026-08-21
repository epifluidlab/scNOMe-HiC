#!/usr/bin/env python3
import argparse
import sys
from pathlib import Path
from typing import Dict, Iterator, List, Tuple

import h5py
import numpy as np
import pandas as pd
from scipy.sparse import coo_matrix, csr_matrix, load_npz
import cooler


def parse_chroms(chroms: str) -> List[str]:
    """
    Accepts '1-22' or '1,2,3' and returns ['chr1', ...].
    """
    chroms = chroms.strip()
    if "-" in chroms:
        a, b = chroms.split("-", 1)
        start, end = int(a), int(b)
        return [f"chr{i}" for i in range(start, end + 1)]
    out = []
    for x in chroms.split(","):
        x = x.strip()
        if not x:
            continue
        out.append(f"chr{int(x)}")
    return out


def parse_celltypes_arg(s: str) -> List[str]:
    """
    Parse --cell_types argument. Accepts:
      - comma-separated: "IT-L2/3,CT-L6"
      - repeated usage is handled by argparse (see main)
    """
    if s is None:
        return []
    parts = []
    for tok in str(s).split(","):
        tok = tok.strip()
        if tok:
            parts.append(tok)
    return parts


def load_q_from_hdf5(q_h5_path: Path) -> coo_matrix:
    """
    Read hicluster Q matrix stored as CSR under /Matrix/{data,indices,indptr}.
    Your files do NOT have /Matrix/shape, so infer square shape from indptr length.
    """
    with h5py.File(q_h5_path, "r") as f:
        if "Matrix" not in f:
            raise RuntimeError(f"No /Matrix group in {q_h5_path}")
        g = f["Matrix"]
        for k in ["data", "indices", "indptr"]:
            if k not in g:
                raise RuntimeError(f"Missing /Matrix/{k} in {q_h5_path}")

        data = g["data"][()]
        indices = g["indices"][()]
        indptr = g["indptr"][()]

    n_rows = int(indptr.shape[0] - 1)
    shape = (n_rows, n_rows)  # scHiCluster per-chrom matrices are square
    Q = csr_matrix((data, indices, indptr), shape=shape)
    return Q.tocoo()


def sum_npz_for_cells(npz_paths: List[Path], where: str = "") -> Tuple[coo_matrix, coo_matrix, int]:
    """
    Return:
      S  = sum(X)
      S2 = sum(X^2)  (elementwise square)

    Skips missing files; prints a warning summary.
    """
    S = None
    S2 = None
    n_found = 0
    missing = 0

    for p in npz_paths:
        if not p.exists():
            missing += 1
            continue

        X = load_npz(p).tocoo()
        X2 = coo_matrix((X.data ** 2, (X.row, X.col)), shape=X.shape)

        if S is None:
            S = X.tocsr()
            S2 = X2.tocsr()
        else:
            S = S + X.tocsr()
            S2 = S2 + X2.tocsr()

        n_found += 1

    if missing > 0:
        msg = f"[WARN] Missing {missing}/{len(npz_paths)} npz files"
        if where:
            msg += f" at {where}"
        print(msg, file=sys.stderr)

    if S is None:
        return coo_matrix((0, 0)), coo_matrix((0, 0)), 0

    return S.tocoo(), S2.tocoo(), n_found


def sum_q_for_cells(q_h5_paths: List[Path], where: str = "") -> Tuple[coo_matrix, coo_matrix, int]:
    """
    Return:
      S  = sum(Q_cell)
      S2 = sum(Q_cell^2) (elementwise square)

    Skips missing files; prints a warning summary.
    """
    S = None
    S2 = None
    n_found = 0
    missing = 0

    for p in q_h5_paths:
        if not p.exists():
            missing += 1
            continue

        X = load_q_from_hdf5(p).tocoo()
        X2 = coo_matrix((X.data ** 2, (X.row, X.col)), shape=X.shape)

        if S is None:
            S = X.tocsr()
            S2 = X2.tocsr()
        else:
            S = S + X.tocsr()
            S2 = S2 + X2.tocsr()

        n_found += 1

    if missing > 0:
        msg = f"[WARN] Missing {missing}/{len(q_h5_paths)} hdf5 files"
        if where:
            msg += f" at {where}"
        print(msg, file=sys.stderr)

    if S is None:
        return coo_matrix((0, 0)), coo_matrix((0, 0)), 0

    return S.tocoo(), S2.tocoo(), n_found


def coo_to_pixels_upper(coo: coo_matrix, chrom_offset: int, denom_cells: int) -> pd.DataFrame:
    """
    Convert COO -> pixels dataframe (upper triangle only), and convert SUM -> MEAN
    by dividing by denom_cells.
    """
    if denom_cells <= 0 or coo.shape == (0, 0) or coo.nnz == 0:
        return pd.DataFrame(
            {
                "bin1_id": np.array([], dtype=np.int64),
                "bin2_id": np.array([], dtype=np.int64),
                "count": np.array([], dtype=np.float32),
            }
        )

    df = pd.DataFrame(
        {
            "bin1_id": coo.row.astype(np.int64),
            "bin2_id": coo.col.astype(np.int64),
            "count": (coo.data.astype(np.float32) / np.float32(denom_cells)),
        }
    )
    df = df[df["bin1_id"] <= df["bin2_id"]]
    df["bin1_id"] += chrom_offset
    df["bin2_id"] += chrom_offset
    return df


def set_group_n_cells(cool_path: Path, n_cells: int):
    """
    Force-write group_n_cells to the COOL root attributes so that:
        cooler.Cooler(...).info['group_n_cells']
    exists (the notebook requires this exact key).
    """
    with h5py.File(cool_path, "r+") as f:
        f.attrs["group_n_cells"] = int(n_cells)


def write_cool(out_cool: Path, bins_df: pd.DataFrame, pixels_iter: Iterator[pd.DataFrame], group_n_cells: int):
    out_cool.parent.mkdir(parents=True, exist_ok=True)

    cooler.create_cooler(
        cool_uri=str(out_cool),
        bins=bins_df,
        pixels=pixels_iter,
        ordered=True,
        dtypes={"count": np.float32},
    )
    set_group_n_cells(out_cool, group_n_cells)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--cell_table", required=True, help="TSV/whitespace table with columns: cell_id, cell_type")
    ap.add_argument("--in_dir", required=True, help="Directory containing chr1/, chr2/, ...")
    ap.add_argument("--out_dir", required=True, help="Output root; will create <ct>/<ct>/<ct>.*.cool")
    ap.add_argument("--chrom_sizes", required=True, help="chrom.sizes file")
    ap.add_argument("--mode", required=True, help="e.g. pad2_std1_rp0.5_sqrtvc")
    ap.add_argument("--res", type=int, default=10000)
    ap.add_argument("--chroms", default="1-22")
    ap.add_argument(
        "--allow_whitespace",
        action="store_true",
        help="Read cell_table with any whitespace separator (tabs/spaces).",
    )
    ap.add_argument(
        "--mean_over_found",
        action="store_true",
        help="If set, divide by number of FOUND per-chrom files (instead of total group cell count). "
             "WARNING: this can make scaling inconsistent with group_n_cells used downstream.",
    )
    # NEW: restrict to selected cell types (can repeat; can pass comma-separated)
    ap.add_argument(
        "--cell_types",
        action="append",
        default=[],
        help="Only process these cell_type values. Can be repeated or comma-separated. "
             "Example: --cell_types 'IT-L2/3,CT-L6'  or  --cell_types IT-L2/3 --cell_types CT-L6",
    )

    args = ap.parse_args()

    # robust reading: your earlier file was space-separated
    if args.allow_whitespace:
        cell_df = pd.read_csv(args.cell_table, sep=r"\s+")
    else:
        cell_df = pd.read_csv(args.cell_table, sep="\t")

    if not {"cell_id", "cell_type"}.issubset(cell_df.columns):
        raise SystemExit("cell_table must have columns: cell_id, cell_type (use --allow_whitespace if needed)")

    # Expand/normalize requested cell types
    requested_cts: List[str] = []
    for entry in args.cell_types:
        requested_cts.extend(parse_celltypes_arg(entry))
    requested_cts = [x for x in requested_cts if x]  # drop empty

    if requested_cts:
        # Filter to requested cell types
        before = cell_df.shape[0]
        cell_df = cell_df[cell_df["cell_type"].astype(str).isin(set(requested_cts))].copy()
        after = cell_df.shape[0]
        if after == 0:
            present = sorted(cell_df["cell_type"].astype(str).unique().tolist())
            raise SystemExit(
                f"No rows left after filtering by --cell_types={requested_cts}. "
                f"Check spelling/case. (No matching cell_type in cell_table.)"
            )
        print(f"[info] Filtering to cell_types={requested_cts}: rows {before} -> {after}", file=sys.stderr)

    chroms_req = parse_chroms(args.chroms)
    chrom_sizes = cooler.read_chromsizes(args.chrom_sizes, all_names=True)

    # normalize to 'chr*' naming if needed
    if not any(str(c).startswith("chr") for c in chrom_sizes.index):
        chrom_sizes.index = ["chr" + str(c) for c in chrom_sizes.index]

    # keep only requested chromosomes that exist in chrom.sizes
    chroms = [c for c in chroms_req if c in chrom_sizes.index]
    if len(chroms) == 0:
        raise SystemExit(f"No requested chromosomes found in chrom.sizes. Requested={chroms_req[:5]}...")

    chrom_sizes = chrom_sizes.loc[chroms]
    bins_df = cooler.binnify(chrom_sizes, args.res)

    chrom_offset: Dict[str, int] = {}
    running = 0
    for c in chrom_sizes.index:
        chrom_offset[c] = running
        running += int(np.ceil(chrom_sizes[c] / args.res))

    in_dir = Path(args.in_dir)
    out_root = Path(args.out_dir)

    # Iterate in a stable order for reproducibility (optional)
    for ct in sorted(cell_df["cell_type"].astype(str).unique().tolist()):
        sub = cell_df[cell_df["cell_type"].astype(str) == ct]
        cells = sub["cell_id"].astype(str).tolist()
        n_cells = len(cells)
        if n_cells == 0:
            continue

        print(f"[celltype] {ct}  n_cells={n_cells}")

        # Layout required by 01.diff.ipynb:
        # outdir/<ct>/<ct>/<ct>.<matrix>.cool
        ct_dir = out_root / ct / ct
        ct_dir.mkdir(parents=True, exist_ok=True)

        def pixels_for_matrix(matrix_name: str) -> Iterator[pd.DataFrame]:
            any_yielded = False

            for chrom in chroms:
                cnum = int(chrom.replace("chr", ""))
                chrom_dir = in_dir / chrom
                where = f"ct={ct} chrom={chrom} mx={matrix_name}"

                if matrix_name in ("E", "E2", "T", "T2"):
                    kind = "E" if "E" in matrix_name else "T"
                    npz_paths = [
                        chrom_dir / f"{cell}_chr{cnum}_{args.mode}_dist_trim.{kind}.npz"
                        for cell in cells
                    ]
                    S, S2, n_found = sum_npz_for_cells(npz_paths, where=where)
                    coo = S2 if matrix_name.endswith("2") else S

                elif matrix_name in ("Q", "Q2"):
                    q_paths = [chrom_dir / f"{cell}_chr{cnum}_{args.mode}.hdf5" for cell in cells]
                    S, S2, n_found = sum_q_for_cells(q_paths, where=where)
                    coo = S2 if matrix_name == "Q2" else S

                else:
                    raise ValueError(matrix_name)

                # If nothing found for this chrom, skip it completely.
                if n_found == 0 or coo.shape == (0, 0):
                    print(f"[WARN] No input files found; skipping {where}", file=sys.stderr)
                    continue

                denom = n_found if args.mean_over_found else n_cells
                dfpix = coo_to_pixels_upper(coo, chrom_offset[chrom], denom)

                # It is possible to have a found file but 0 nnz; don't yield empty chunks repeatedly.
                if len(dfpix) == 0:
                    continue

                any_yielded = True
                yield dfpix

            # Ensure cooler.create_cooler() always sees at least one chunk.
            if not any_yielded:
                yield pd.DataFrame(
                    {
                        "bin1_id": np.array([], dtype=np.int64),
                        "bin2_id": np.array([], dtype=np.int64),
                        "count": np.array([], dtype=np.float32),
                    }
                )

        for mx in ["Q", "Q2", "E", "E2", "T", "T2"]:
            out_cool = ct_dir / f"{ct}.{mx}.cool"
            print(f"  -> writing {out_cool}")
            write_cool(out_cool, bins_df, pixels_for_matrix(mx), n_cells)

    print("Done.")


if __name__ == "__main__":
    main()
