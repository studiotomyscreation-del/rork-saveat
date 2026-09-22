#!/usr/bin/env python3
"""geocode_rna_candidates.py — batch-geocodes test_rna_filtrage.py's output.

STANDALONE DISCOVERY TOOL. THIS SCRIPT IS NOT PART OF THE SAVEAT iOS APP.
It is never bundled, never compiled, and never called at runtime by the app.
Run it manually from a Terminal, on demand. Python standard library only (no
pip install needed) — urllib, csv, json, re, argparse, mimetypes, uuid.

Uses the real Géoplateforme CSV batch endpoint
(POST https://data.geopf.fr/geocodage/search/csv/), verified live before
writing this script — confirmed real, working, and NOT the same thing as
the per-address GET endpoint used for the earlier smoke test. Two real
findings from that verification, both handled below:

  1. `result_status` is **not** a reliable failure signal — it reads "ok"
     even for a garbage address (the API always returns its best guess,
     however bad), and only reads "skipped" for a genuinely empty input.
     The real failure signal is `result_score` (0.0-1.0): a garbage
     address still scored 0.34, while two known-good real addresses
     scored 0.76 and 0.95. This script rejects any match below
     `--min-score` (default 0.5 — a judgment call, not an official IGN
     threshold; tune it after seeing the real score distribution).
  2. The endpoint accepts test_rna_filtrage.py's already-ASSEMBLED
     "adresse" column directly ("9 BD Frederic Latouche, 71400 Autun")
     with `columns=adresse` alone — no need to split it into separate
     street/postcode fields before sending.

What it does, in order:
  1. Reads the CSV produced by test_rna_filtrage.py (nom, statut,
     statut_code_brut, objet, adresse, mots_cles, siret, fichier_source).
  2. Splits `adresse` back into street/postal_code/city — safe because
     test_rna_filtrage.py's `assemble_address()` always builds it as
     "STREET, POSTAL CITY" (comma before the tail, postal code always the
     first token of the tail) — see `split_address`.
  3. Sends rows in batches (`--batch-size`, default 400 — comfortably under
     the documented 200 000-line/50 MB batch endpoint limit, but each
     request is fast enough to checkpoint often) to the CSV batch endpoint.
  4. A row is a real success only if `result_score >= --min-score` AND
     `result_status != "skipped"` — never invents coordinates otherwise.
     Every rejected row is kept in the progress file with its reason
     (empty address vs low score) for the final report, never silently
     dropped.
  5. Checkpoints progress after every batch (`--progress-file`) so an
     interruption never loses work — rerun the same command to resume.
  6. Writes a final CSV (`--out`) with only the successfully geocoded rows
     — nom, street, postal_code, city, latitude, longitude, geocode_score,
     statut, objet, siret, mots_cles — ready for a future Swift provider.
     department/région are NOT precomputed here: every existing provider
     (OpenStreetMapProvider, MulhouseOpenDataProvider...) derives them at
     construction time from postal_code via FrenchAdministrativeDivisions,
     and this script follows that same single-source-of-truth rule rather
     than duplicating that logic in Python.

Usage:
    python3 geocode_rna_candidates.py
    python3 geocode_rna_candidates.py --input rna_filtrage_candidats.csv --min-score 0.5
"""

from __future__ import annotations

import argparse
import csv
import io
import json
import re
import subprocess
import sys
import tempfile
import time
from pathlib import Path
from typing import Any

GEOCODE_CSV_URL = "https://data.geopf.fr/geocodage/search/csv/"
USER_AGENT = "SAVEAT-map-sources-scan/1.0 (contact: via App Store; one-off research script, not the app)"

MIN_DELAY_SECONDS = 0.5
MAX_RETRIES = 3
DEFAULT_BATCH_SIZE = 400
DEFAULT_MIN_SCORE = 0.5

# `assemble_address()` in test_rna_filtrage.py always builds "STREET, POSTAL
# CITY" (or just "POSTAL CITY" with no comma if street was empty) — the
# postal code is always the first token of whatever comes after the last
# comma (or of the whole string if there's no comma), and is always exactly
# 5 digits (a real French postal code, per the RNA `adrs_codepostal` field).
_POSTAL_CITY_PATTERN = re.compile(r"^(\d{5})\s+(.*)$")


def split_address(adresse: str) -> tuple[str, str, str]:
    """Returns (street, postal_code, city) — any part can be "" if the
    source address didn't have it. Never guesses a postal code that isn't
    there; a description of the format lives in this module's docstring."""
    if not adresse:
        return "", "", ""
    if ", " in adresse:
        street, _, tail = adresse.rpartition(", ")
    else:
        street, tail = "", adresse
    match = _POSTAL_CITY_PATTERN.match(tail.strip())
    if match:
        return street, match.group(1), match.group(2)
    return street, "", tail.strip()


class RateLimitedSession:
    """Same pacing/retry rules as the other scripts in this project: at
    least 0.5s between calls, exponential backoff on HTTP 429.

    Shells out to the system `curl` binary for the actual request rather
    than `urllib.request` — a real, empirical finding while building this
    script: a hand-rolled `urllib.request` multipart POST to this exact
    endpoint failed every single time in the dev sandbox
    (`ConnectionResetError` / `ws_closed_mid_exchange` at the proxy level,
    even for a 5-row batch), while the equivalent `curl -F ...` call
    succeeded reliably and fast (<1s) at the same batch sizes. `curl` ships
    natively on macOS, so this costs nothing in portability."""

    def __init__(self, min_delay: float = MIN_DELAY_SECONDS) -> None:
        self.min_delay = min_delay
        self._last_call = 0.0

    def post_multipart_csv(self, url: str, fields: dict[str, str], file_field: str, file_bytes: bytes) -> bytes:
        elapsed = time.monotonic() - self._last_call
        if elapsed < self.min_delay:
            time.sleep(self.min_delay - elapsed)

        with tempfile.NamedTemporaryFile(suffix=".csv", delete=False) as handle:
            handle.write(file_bytes)
            temp_path = Path(handle.name)

        backoff = 2.0
        try:
            for attempt in range(1, MAX_RETRIES + 1):
                command = ["curl", "-sS", "-X", "POST", url, "-A", USER_AGENT,
                           "-F", f"{file_field}=@{temp_path};type=text/csv"]
                for name, value in fields.items():
                    command += ["-F", f"{name}={value}"]
                command += ["--max-time", "60", "-w", "\n%{http_code}"]

                result = subprocess.run(command, capture_output=True, timeout=90)
                self._last_call = time.monotonic()
                if result.returncode != 0:
                    raise RuntimeError(f"curl a échoué (code {result.returncode}) : {result.stderr.decode(errors='replace')}")

                body, _, status_code = result.stdout.rpartition(b"\n")
                status = int(status_code) if status_code.isdigit() else 0
                if status == 429 and attempt < MAX_RETRIES:
                    print(f"  [429] rate limited, waiting {backoff:.1f}s (attempt {attempt}/{MAX_RETRIES})", file=sys.stderr)
                    time.sleep(backoff)
                    backoff *= 2
                    continue
                if status != 200:
                    raise RuntimeError(f"HTTP {status} depuis {url} : {body[:300]!r}")
                return body
        finally:
            temp_path.unlink(missing_ok=True)
        raise RuntimeError(f"Exhausted {MAX_RETRIES} retries for {url}")


class ProgressStore:
    def __init__(self, path: Path) -> None:
        self.path = path
        self.geocoded: dict[str, dict[str, str]] = {}
        self.failed: dict[str, str] = {}
        if path.exists():
            self._load()

    def _load(self) -> None:
        data = json.loads(self.path.read_text(encoding="utf-8"))
        self.geocoded = data.get("geocoded", {})
        self.failed = data.get("failed", {})

    def save(self) -> None:
        payload = {"geocoded": self.geocoded, "failed": self.failed}
        self.path.write_text(json.dumps(payload, ensure_ascii=False, indent=2), encoding="utf-8")

    @property
    def processed_ids(self) -> set[str]:
        return set(self.geocoded) | set(self.failed)


def read_candidates(path: Path) -> list[dict[str, str]]:
    with path.open(newline="", encoding="utf-8") as handle:
        reader = csv.DictReader(handle)
        rows = list(reader)
    for index, row in enumerate(rows):
        row["_id"] = str(index)
    return rows


def geocode_batch(session: RateLimitedSession, rows: list[dict[str, str]], min_score: float) -> tuple[dict[str, dict[str, str]], dict[str, str]]:
    buffer = io.StringIO()
    writer = csv.writer(buffer)
    writer.writerow(["id", "adresse"])
    for row in rows:
        writer.writerow([row["_id"], row.get("adresse", "")])
    csv_bytes = buffer.getvalue().encode("utf-8")

    raw_response = session.post_multipart_csv(
        GEOCODE_CSV_URL,
        fields={"columns": "adresse"},
        file_field="data",
        file_bytes=csv_bytes,
    )
    reader = csv.DictReader(io.StringIO(raw_response.decode("utf-8")))

    geocoded: dict[str, dict[str, str]] = {}
    failed: dict[str, str] = {}
    for result in reader:
        row_id = result["id"]
        status = result.get("result_status", "")
        score_raw = result.get("result_score", "")
        if status == "skipped" or not result.get("adresse", "").strip():
            failed[row_id] = "adresse vide"
            continue
        try:
            score = float(score_raw) if score_raw else 0.0
        except ValueError:
            score = 0.0
        if score < min_score:
            failed[row_id] = f"score trop bas ({score:.2f} < {min_score})"
            continue
        lat, lon = result.get("latitude", ""), result.get("longitude", "")
        if not lat or not lon:
            failed[row_id] = "pas de coordonnées renvoyées malgré un score correct"
            continue
        geocoded[row_id] = {"latitude": lat, "longitude": lon, "score": f"{score:.4f}"}
    return geocoded, failed


def write_final_csv(rows: list[dict[str, str]], store: ProgressStore, out_path: Path) -> int:
    fieldnames = ["nom", "street", "postal_code", "city", "latitude", "longitude", "geocode_score", "statut", "objet", "siret", "mots_cles"]
    written = 0
    with out_path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=fieldnames)
        writer.writeheader()
        for row in rows:
            geo = store.geocoded.get(row["_id"])
            if not geo:
                continue
            street, postal_code, city = split_address(row.get("adresse", ""))
            writer.writerow({
                "nom": row.get("nom", ""),
                "street": street,
                "postal_code": postal_code,
                "city": city,
                "latitude": geo["latitude"],
                "longitude": geo["longitude"],
                "geocode_score": geo["score"],
                "statut": row.get("statut", ""),
                "objet": row.get("objet", ""),
                "siret": row.get("siret", ""),
                "mots_cles": row.get("mots_cles", ""),
            })
            written += 1
    return written


def main() -> None:
    parser = argparse.ArgumentParser(description="Batch-geocode test_rna_filtrage.py's CSV output via the Géoplateforme CSV endpoint.")
    parser.add_argument("--input", type=Path, default=Path("rna_filtrage_candidats.csv"))
    parser.add_argument("--out", type=Path, default=Path("rna_filtrage_geocoded.csv"))
    parser.add_argument("--progress-file", type=Path, default=Path("geocode_rna_progress.json"))
    parser.add_argument("--batch-size", type=int, default=DEFAULT_BATCH_SIZE)
    parser.add_argument("--min-score", type=float, default=DEFAULT_MIN_SCORE)
    args = parser.parse_args()

    if not args.input.exists():
        print(f"Fichier introuvable : {args.input}", file=sys.stderr)
        sys.exit(1)

    rows = read_candidates(args.input)
    print(f"{len(rows)} ligne(s) lue(s) depuis {args.input}.")

    session = RateLimitedSession()
    store = ProgressStore(args.progress_file)

    remaining = [row for row in rows if row["_id"] not in store.processed_ids]
    print(f"{len(remaining)} ligne(s) restante(s) à géocoder ({len(store.processed_ids)} déjà traitée(s)).")

    try:
        for start in range(0, len(remaining), args.batch_size):
            batch = remaining[start:start + args.batch_size]
            print(f"[{start}-{start + len(batch)}/{len(remaining)}] géocodage du lot en cours...")
            geocoded, failed = geocode_batch(session, batch, args.min_score)
            store.geocoded.update(geocoded)
            store.failed.update(failed)
            store.save()
            print(f"  -> {len(geocoded)} réussi(s), {len(failed)} échoué(s) sur ce lot "
                  f"(total cumulé : {len(store.geocoded)} réussi(s), {len(store.failed)} échoué(s))")
    except KeyboardInterrupt:
        print("\nInterrompu — progression sauvegardée, relance la même commande pour reprendre.", file=sys.stderr)
        sys.exit(130)
    except (RuntimeError, subprocess.SubprocessError) as error:
        print(f"ERREUR : {error} — progression sauvegardée, relance la même commande pour reprendre.", file=sys.stderr)
        sys.exit(1)

    written = write_final_csv(rows, store, args.out)

    total = len(rows)
    success = len(store.geocoded)
    fail = len(store.failed)
    print(f"\nGéocodage terminé : {success}/{total} réussi(s) ({success / total * 100:.1f}%), "
          f"{fail}/{total} échoué(s) ({fail / total * 100:.1f}%).")

    reason_counts: dict[str, int] = {}
    for reason in store.failed.values():
        key = reason.split(" (")[0]
        reason_counts[key] = reason_counts.get(key, 0) + 1
    for reason, count in sorted(reason_counts.items(), key=lambda kv: -kv[1]):
        print(f"  - {reason} : {count}")

    print(f"\nFichier final écrit : {args.out} ({written} ligne(s) géolocalisée(s), prêtes pour un futur provider Swift).")
    print(f"Progression : {args.progress_file}")


if __name__ == "__main__":
    main()
