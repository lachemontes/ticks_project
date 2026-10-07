#!/usr/bin/env python3
"""
best_hits_by_pident.py
Select the best BLAST hit per query (by pident) from an outfmt-6 file.

Usage:
    python best_hits_by_pident.py input.tsv output.csv
"""

import sys
import pandas as pd
from pathlib import Path

# Standard BLAST outfmt 6 columns
BLAST_COLS = [
    "qseqid", "sseqid", "pident", "length", "mismatch", "gapopen",
    "qstart", "qend", "sstart", "send", "evalue", "bitscore",
]


def main(in_path, out_path):
    p = Path(in_path)
    if not p.exists():
        raise FileNotFoundError(f"Input not found: {p}")

    # Read outfmt 6 (tab-separated, no header)
    df = pd.read_csv(p, sep="\t", header=None, names=BLAST_COLS)

    id_col = "qseqid"
    df["pident"] = pd.to_numeric(df["pident"], errors="coerce")
    df = df.dropna(subset=["pident"]).copy()

    if len(df) == 0:
        print(f"  [WARN] No hits in {p.name} — writing empty output.")
        pd.DataFrame(columns=BLAST_COLS).to_csv(out_path, index=False)
        return

    # Best hit per query: pident desc, then evalue asc, bitscore desc, length desc
    tie_keys = ["pident", "evalue", "bitscore", "length"]
    tie_asc  = [False, True, False, False]
    df_sorted = df.sort_values(by=tie_keys, ascending=tie_asc, kind="mergesort")
    best = df_sorted.drop_duplicates(subset=id_col, keep="first").copy()

    best.to_csv(out_path, index=False)

    print(f"  Best hits: {len(best)} queries (from {len(df)} rows) -> {Path(out_path).name}")


if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: python best_hits_by_pident.py <input.tsv> <output.csv>")
        sys.exit(1)
    main(sys.argv[1], sys.argv[2])
