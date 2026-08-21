#!/usr/bin/env python3
import argparse
from pathlib import Path
from typing import Dict, Iterator, List, Tuple

import numpy as np
import pandas as pd
import h5py
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


def sum_npz_for_cells(npz_paths: List[Path]) -> Tuple[coo_matrix, coo_matrix]:
    """
    Return:
      S  = sum(X)
      S2 = sum(X^2)  (elementwise square)
    """
    S = None
    S2 = None
    for p in npz_paths:
        X = load_npz(p).tocoo()
        X2 = coo_matrix((X.data ** 2, (X.row, X.col)), shape=X.shape)

        if S is None:
            S = X.tocsr()
            S2 = X2.tocsr()
        else:
            S = S + X.tocsr()
            S2 = S2 + X2.tocsr()

    return S.tocoo(), S2.tocoo()


def sum_q_for_cells(q_h5_paths: List[Path]) -> Tuple[coo_matrix, coo_matrix]:
    """
    Return:
      S  = sum(Q_cell)
      S2 = sum(Q_cell^2) (elementwise square)
    """
    S = None
    S2 = None
    for p in q_h5_paths:
        X = load_q_from_hdf5(p).tocoo()
        X2 = coo_matrix((X.data ** 2, (X.row, X.col)), shape=X.shape)

        if S is None:
            S = X.tocsr()
            S2 = X2.tocsr()
        else:
            S = S + X.tocsr()
            S2 = S2 + X2.tocsr()

    return S.tocoo(), S2.tocoo()


def coo_to_pixels_upper(coo: coo_matrix, chrom_offset: int, n_cells: int) -> pd.DataFrame:
    """
    Convert COO -> pixels dataframe (upper triangle only), and convert SUM -> MEAN by dividing by n_cells.
    The diff notebook expects MEAN matrices and multiplies by n (group_n_cells) internally.
    """
    df = pd.DataFrame(
        {
            "bin1_id": coo.row.astype(np.int64),
            "bin2_id": coo.col.astype(np.int64),
            "count": (coo.data.astype(np.float32) / np.float32(n_cells)),
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

    # Cooler may not always surface "metadata" as top-level info keys depending on version,
    # so we still set group_n_cells explicitly via set_group_n_cells().
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
    ap.add_argument("--allow_whitespace", action="store_true",
                    help="Read cell_table with any whitespace separator (tabs/spaces).")
    args = ap.parse_args()

    # robust reading: your earlier file was space-separated
    if args.allow_whitespace:
        cell_df = pd.read_csv(args.cell_table, sep=r"\s+")
    else:
        cell_df = pd.read_csv(args.cell_table, sep="\t")

    if not {"cell_id", "cell_type"}.issubset(cell_df.columns):
        raise SystemExit("cell_table must have columns: cell_id, cell_type (use --allow_whitespace if needed)")

    chroms = parse_chroms(args.chroms)
    chrom_sizes = cooler.read_chromsizes(args.chrom_sizes, all_names=True)

    # normalize to 'chr*' naming if needed
    if not any(str(c).startswith("chr") for c in chrom_sizes.index):
        chrom_sizes.index = ["chr" + str(c) for c in chrom_sizes.index]

    # keep only requested chromosomes
    chrom_sizes = chrom_sizes.loc[[c for c in chroms if c in chrom_sizes.index]]
    bins_df = cooler.binnify(chrom_sizes, args.res)

    chrom_offset: Dict[str, int] = {}
    running = 0
    for c in chrom_sizes.index:
        chrom_offset[c] = running
        running += int(np.ceil(chrom_sizes[c] / args.res))

    in_dir = Path(args.in_dir)
    out_root = Path(args.out_dir)

    for ct, sub in cell_df.groupby("cell_type"):
        cells = sub["cell_id"].astype(str).tolist()
        n_cells = len(cells)
        if n_cells == 0:
            continue

        print(f"[celltype] {ct}  n_cells={n_cells}")

        # Layout required by 01.diff.ipynb:
        # indir/<ct>/<ct>/<ct>.<matrix>.cool
        ct_dir = out_root / ct / ct
        ct_dir.mkdir(parents=True, exist_ok=True)

        def pixels_for_matrix(matrix_name: str) -> Iterator[pd.DataFrame]:
            for chrom in chroms:
                cnum = int(chrom.replace("chr", ""))
                chrom_dir = in_dir / chrom

                if matrix_name in ("E", "E2", "T", "T2"):
                    kind = "E" if "E" in matrix_name else "T"
                    npz_paths = [
                        chrom_dir / f"{cell}_chr{cnum}_{args.mode}_dist_trim.{kind}.npz"
                        for cell in cells
                    ]
                    S, S2 = sum_npz_for_cells(npz_paths)
                    coo = S2 if matrix_name.endswith("2") else S

                elif matrix_name in ("Q", "Q2"):
                    q_paths = [chrom_dir / f"{cell}_chr{cnum}_{args.mode}.hdf5" for cell in cells]
                    S, S2 = sum_q_for_cells(q_paths)
                    coo = S2 if matrix_name == "Q2" else S

                else:
                    raise ValueError(matrix_name)

                yield coo_to_pixels_upper(coo, chrom_offset[chrom], n_cells)

        for mx in ["Q", "Q2", "E", "E2", "T", "T2"]:
            out_cool = ct_dir / f"{ct}.{mx}.cool"
            print(f"  -> writing {out_cool}")
            write_cool(out_cool, bins_df, pixels_for_matrix(mx), n_cells)

    print("Done.")


if __name__ == "__main__":
    main()
