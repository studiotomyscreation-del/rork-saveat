#!/usr/bin/env python3
"""sample_rna_candidates.py — prints a diverse, cross-département sample of
rna_filtrage_candidats.csv to stdout (writes no new file), for pasting into
chat when a drag-and-drop upload of the full CSV isn't going through.

STANDALONE DISCOVERY TOOL. THIS SCRIPT IS NOT PART OF THE SAVEAT iOS APP.
It is never bundled, never compiled, and never called at runtime by the app.

Picks up to --per-file rows per distinct fichier_source (département/
territoire), in file order, until it reaches --sample-size. This avoids
sampling only the first N raw rows of the CSV, which — since matches are
written out file-by-file in archive order — would all come from whichever
département happens to be listed first and say nothing about the other 103.
"""
from __future__ import annotations

import argparse
import csv
from collections import defaultdict
from pathlib import Path


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("csv_path", type=Path)
    parser.add_argument("--sample-size", type=int, default=40)
    parser.add_argument("--per-file", type=int, default=2)
    args = parser.parse_args()

    per_source_count: dict[str, int] = defaultdict(int)
    sample: list[dict[str, str]] = []
    seen_sources: set[str] = set()

    with args.csv_path.open(newline="", encoding="utf-8") as handle:
        reader = csv.DictReader(handle)
        for row in reader:
            source = row.get("fichier_source", "?")
            seen_sources.add(source)
            if per_source_count[source] >= args.per_file:
                continue
            sample.append(row)
            per_source_count[source] += 1
            if len(sample) >= args.sample_size:
                break

    print(f"# {len(seen_sources)} fichier(s) source distincts vus avant d'atteindre l'échantillon "
          f"({len(per_source_count)} représentés dans l'échantillon ci-dessous)\n")
    for i, row in enumerate(sample, start=1):
        objet = (row.get("objet") or "")[:160]
        print(f"[{i}] {row.get('nom', '')!r} — {row.get('statut', '')} — source: {row.get('fichier_source', '')}")
        print(f"    objet: {objet}")
        print(f"    adresse: {row.get('adresse', '')}")
        print(f"    mots_clés: {row.get('mots_cles', '')}")
        print()


if __name__ == "__main__":
    main()
