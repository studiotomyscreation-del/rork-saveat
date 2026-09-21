#!/usr/bin/env python3
"""test_rna_filtrage.py — RNA (Répertoire National des Associations) keyword filter.

STANDALONE DISCOVERY TOOL. THIS SCRIPT IS NOT PART OF THE SAVEAT iOS APP.
It is never bundled, never compiled, and never called at runtime by the app.
Run it manually from a Terminal, on demand. Python standard library only (no
pip install needed) — urllib, csv, zipfile, re, json, argparse.

Only ONE monthly resource is downloaded, not the whole history: the RNA
"148 fichiers" on data.gouv.fr are dated historical snapshots
(rna_waldec_YYYYMMDD.zip / rna_import_YYYYMMDD.zip going back years) — this
script always resolves and downloads only the single most recent
rna_waldec_*.zip. rna_import (associations with no status change since
2009, so more likely stale/defunct) is deliberately NOT downloaded here —
rna_waldec alone is the right starting point.

CORRECTION (found after a real run): that one rna_waldec_*.zip is itself
NOT a single national CSV — `unzip -l` on a real downloaded archive showed
**104 separate CSV files inside it** (one per département/territoire,
~1.459 GB uncompressed total). An earlier version of this script only read
the first entry in the archive, which silently limited an entire run to a
single département's worth of associations (found when a real run returned
only 25 matches, 24 of them in the same département). Every entry is now
read and filtered — see `list_csv_entries`/`read_csv_entry` below — with
each match tagged with the `fichier_source` it came from.

What it does, in order:
  1. Resolves the most recent rna_waldec_*.zip resource from the dataset's
     own API listing (never hardcodes a URL, since a new monthly file
     replaces it every month) and downloads it, resuming a same-sized
     partial file rather than re-downloading from scratch.
  2. Unzips it, auto-detects the CSV delimiter and text encoding — the
     official field dictionary (media.interieur.gouv.fr/rna/RNA_Liste_
     donnees_diffusees-V2.pdf) documents every column's name and meaning
     but not the delimiter/encoding actually used in the file, so this is
     detected rather than assumed.
  3. Filters on the `objet` column — confirmed by that same official PDF to
     be free text ("Objet de l'association", unlimited length), unlike
     `objet_social1`/`objet_social2` which are Waldec nomenclature CODES,
     not matchable text.
  4. Writes every match (not just 30 — the full count matters for judging
     real volume) to a CSV for Olivier to review by hand: statut
     (Active/Dissoute/Supprimée, decoded from the `position` field when its
     value is recognised, kept alongside the raw code either way), nom,
     objet complet, adresse assemblée, mots-clés qui ont matché.
  5. Does NOT geocode the matches. It only smoke-tests the new Géoplateforme
     endpoint (https://data.geopf.fr/geocodage/search/ — the successor to
     the now-decommissioned api-adresse.data.gouv.fr) against 2-3 real
     addresses from the matches, to confirm it responds sensibly, before
     any future bulk-geocoding step.

Usage:
    python3 test_rna_filtrage.py
    python3 test_rna_filtrage.py --zip-path already-downloaded.zip   # skip the download
"""

from __future__ import annotations

import argparse
import csv
import io
import json
import re
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
import zipfile
from pathlib import Path
from typing import Any

DATASET_API_URL = "https://www.data.gouv.fr/api/1/datasets/repertoire-national-des-associations/"
GEOCODE_URL = "https://data.geopf.fr/geocodage/search/"
USER_AGENT = "SAVEAT-map-sources-scan/1.0 (contact: via App Store; one-off research script, not the app)"

# Same 9 phrases from the RNA brief.
KEYWORDS = [
    "aide alimentaire",
    "banque alimentaire",
    "épicerie solidaire",
    "distribution alimentaire",
    "colis alimentaire",
    "panier solidaire",
    "frigo solidaire",
    "lutte contre le gaspillage alimentaire",
    "solidarité alimentaire",
]

# `position` isn't spelled out letter-by-letter in the official PDF for
# rna_waldec (only rna_import's example shows "A"). This maps the values we
# can reasonably infer from "Active, Dissoute ou Supprimée" — the raw code
# is always kept in the output too, so nothing is hidden behind a guess.
POSITION_LABELS = {"A": "Active", "D": "Dissoute", "S": "Supprimée"}

MIN_DELAY_SECONDS = 0.5
MAX_RETRIES = 3


def _compile_keyword_pattern(keyword: str) -> re.Pattern[str]:
    """Same French-plural tolerance as scan_datagouv_national.py's fix —
    each word gets an optional e/s/es suffix, so e.g. "aide alimentaire"
    also matches "aides alimentaires"."""
    words = keyword.split(" ")
    word_patterns = [re.escape(word) + r"(?:e|s|es)?" for word in words]
    return re.compile(r"\b" + r"\s+".join(word_patterns) + r"\b", re.IGNORECASE)


KEYWORD_PATTERNS = [(keyword, _compile_keyword_pattern(keyword)) for keyword in KEYWORDS]


class RateLimitedSession:
    """Same pacing/retry rules as scan_datagouv_national.py: at least 0.5s
    between calls, exponential backoff on HTTP 429 (max 3 retries)."""

    def __init__(self, min_delay: float = MIN_DELAY_SECONDS) -> None:
        self.min_delay = min_delay
        self._last_call = 0.0

    def _wait(self) -> None:
        elapsed = time.monotonic() - self._last_call
        if elapsed < self.min_delay:
            time.sleep(self.min_delay - elapsed)

    def get_json(self, url: str) -> dict[str, Any]:
        self._wait()
        backoff = 2.0
        for attempt in range(1, MAX_RETRIES + 1):
            request = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})
            try:
                with urllib.request.urlopen(request, timeout=30) as response:
                    self._last_call = time.monotonic()
                    return json.loads(response.read().decode("utf-8"))
            except urllib.error.HTTPError as error:
                self._last_call = time.monotonic()
                if error.code == 429 and attempt < MAX_RETRIES:
                    wait = float(error.headers.get("Retry-After") or backoff)
                    print(f"  [429] rate limited, waiting {wait:.1f}s (attempt {attempt}/{MAX_RETRIES})", file=sys.stderr)
                    time.sleep(wait)
                    backoff *= 2
                    continue
                raise
        raise RuntimeError(f"Exhausted {MAX_RETRIES} retries for {url}")

    def get_raw(self, url: str, timeout: int = 30) -> bytes | None:
        self._wait()
        backoff = 2.0
        for attempt in range(1, MAX_RETRIES + 1):
            request = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})
            try:
                with urllib.request.urlopen(request, timeout=timeout) as response:
                    self._last_call = time.monotonic()
                    return response.read()
            except urllib.error.HTTPError as error:
                self._last_call = time.monotonic()
                if error.code == 429 and attempt < MAX_RETRIES:
                    wait = float(error.headers.get("Retry-After") or backoff)
                    time.sleep(wait)
                    backoff *= 2
                    continue
                return None
            except (urllib.error.URLError, TimeoutError):
                return None
        return None


# MARK: - Step 1: resolve + download the latest rna_waldec file

def resolve_latest_waldec_resource(session: RateLimitedSession) -> tuple[str, str]:
    """Scans the dataset's own resource list for every `rna_waldec_YYYYMMDD*`
    title and returns the (url, title) of the most recent one — never a
    hardcoded URL, since a new monthly file supersedes it every month."""
    payload = session.get_json(DATASET_API_URL)
    candidates: list[tuple[str, str, str]] = []
    for resource in payload.get("resources", []):
        title = resource.get("title", "") or ""
        match = re.match(r"rna_waldec_(\d{8})", title)
        if match:
            candidates.append((match.group(1), resource.get("url", ""), title))
    if not candidates:
        raise RuntimeError("Aucune ressource 'rna_waldec_*' trouvée sur le dataset — structure a peut-être changé.")
    candidates.sort(key=lambda c: c[0], reverse=True)
    _, url, title = candidates[0]
    return url, title


def download_zip(session: RateLimitedSession, url: str, out_path: Path) -> None:
    """Streams the download to disk in chunks (the file is ~90+ MB — never
    held fully in memory). Skips re-downloading if a same-URL, non-empty
    file already sits at out_path (the resumable behaviour the brief asked
    for, adapted to a single large file rather than many small requests)."""
    marker_path = out_path.with_suffix(out_path.suffix + ".source-url")
    if out_path.exists() and marker_path.exists() and marker_path.read_text(encoding="utf-8").strip() == url:
        print(f"  {out_path.name} déjà présent pour cette URL — téléchargement sauté (reprise).")
        return

    print(f"  Téléchargement de {url} ...")
    request = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})
    backoff = 2.0
    for attempt in range(1, MAX_RETRIES + 1):
        try:
            with urllib.request.urlopen(request, timeout=120) as response, out_path.open("wb") as handle:
                total = 0
                while chunk := response.read(1024 * 1024):
                    handle.write(chunk)
                    total += len(chunk)
                    print(f"\r  {total / 1_000_000:.1f} MB téléchargés...", end="", file=sys.stderr)
            print()
            marker_path.write_text(url, encoding="utf-8")
            return
        except (urllib.error.HTTPError, urllib.error.URLError, TimeoutError) as error:
            print(f"\n  Échec du téléchargement (tentative {attempt}/{MAX_RETRIES}) : {error}", file=sys.stderr)
            out_path.unlink(missing_ok=True)
            if attempt < MAX_RETRIES:
                time.sleep(backoff)
                backoff *= 2
    raise RuntimeError(f"Impossible de télécharger {url} après {MAX_RETRIES} tentatives.")


# MARK: - Step 2: locate the CSVs inside the zip, detect delimiter + encoding

def list_csv_entries(zip_path: Path) -> list[str]:
    """The monthly rna_waldec archive is NOT one national CSV — real-world
    testing found **104 files inside it** (one per département/territoire),
    something the official field dictionary never mentions and the dataset's
    own resource listing (one dated .zip per month) gave no reason to
    expect. Every entry must be read and filtered, not just the first —
    reading only entry [0] silently limited an earlier run of this script to
    a single département's worth of associations."""
    with zipfile.ZipFile(zip_path) as archive:
        csv_names = [name for name in archive.namelist() if name.lower().endswith(".csv")]
    if not csv_names:
        raise RuntimeError(f"Aucun fichier .csv trouvé dans {zip_path.name}.")
    return csv_names


def read_csv_entry(zip_path: Path, entry_name: str) -> bytes:
    with zipfile.ZipFile(zip_path) as archive:
        return archive.read(entry_name)


def decode_and_sniff(raw: bytes) -> tuple[str, str, csv.Dialect]:
    """Never assumes delimiter/encoding — the official field dictionary
    doesn't specify either. Tries UTF-8 first, falls back to the classic
    French-government-export encoding (Windows-1252 / cp1252), then sniffs
    the delimiter from the first line with csv.Sniffer."""
    for encoding in ("utf-8", "cp1252", "latin-1"):
        try:
            text = raw.decode(encoding)
            break
        except UnicodeDecodeError:
            continue
    else:
        raise RuntimeError("Impossible de décoder le fichier avec utf-8, cp1252 ou latin-1.")

    first_line = text.split("\n", 1)[0]
    try:
        dialect = csv.Sniffer().sniff(first_line, delimiters=";,\t")
    except csv.Error:
        dialect = csv.excel
        dialect.delimiter = ";"  # historically the RNA export's own convention; only a fallback if sniffing fails
    return text, encoding, dialect


# MARK: - Step 3: filter on `objet`

def assemble_address(row: dict[str, str]) -> str:
    street_parts = [
        row.get("adrs_numvoie", "").strip(),
        row.get("adrs_typevoie", "").strip(),
        row.get("adrs_libvoie", "").strip(),
    ]
    street = " ".join(part for part in street_parts if part)
    if not street:
        street = row.get("adrs_complement", "").strip()
    postal = row.get("adrs_codepostal", "").strip()
    city = row.get("adrs_libcommune", "").strip()
    tail = " ".join(part for part in [postal, city] if part)
    return ", ".join(part for part in [street, tail] if part)


def filter_associations(text: str, dialect: csv.Dialect) -> list[dict[str, str]]:
    reader = csv.DictReader(io.StringIO(text), dialect=dialect)
    if "objet" not in (reader.fieldnames or []):
        raise RuntimeError(f"Colonne 'objet' absente — colonnes trouvées : {reader.fieldnames}")

    matches: list[dict[str, str]] = []
    for row in reader:
        objet = row.get("objet", "") or ""
        if not objet:
            continue
        hit_keywords = [kw for kw, pattern in KEYWORD_PATTERNS if pattern.search(objet)]
        if not hit_keywords:
            continue
        raw_position = (row.get("position", "") or "").strip()
        matches.append({
            "nom": row.get("titre", "") or "",
            "statut": POSITION_LABELS.get(raw_position, raw_position or "inconnu"),
            "statut_code_brut": raw_position,
            "objet": objet,
            "adresse": assemble_address(row),
            "mots_cles": " | ".join(hit_keywords),
            "siret": row.get("siret", "") or "",
        })
    return matches


def write_report(matches: list[dict[str, str]], out_path: Path) -> None:
    fieldnames = ["nom", "statut", "statut_code_brut", "objet", "adresse", "mots_cles", "siret", "fichier_source"]
    with out_path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(matches)


# MARK: - Step 5: geocoding endpoint smoke test (2-3 addresses, no bulk geocoding)

def smoke_test_geocoding(session: RateLimitedSession, matches: list[dict[str, str]], sample_size: int = 3) -> None:
    sample = [m for m in matches if m["adresse"]][:sample_size]
    if not sample:
        print("  Aucune adresse exploitable trouvée pour le test de géocodage.")
        return
    print(f"\nTest de l'endpoint Géoplateforme sur {len(sample)} adresse(s) réelle(s) (pas de géocodage en masse) :")
    for match in sample:
        params = urllib.parse.urlencode({"q": match["adresse"], "limit": 1})
        url = f"{GEOCODE_URL}?{params}"
        raw = session.get_raw(url)
        if raw is None:
            print(f"  ÉCHEC — {match['adresse']!r} : pas de réponse de l'endpoint.")
            continue
        try:
            payload = json.loads(raw.decode("utf-8"))
            features = payload.get("features", [])
        except json.JSONDecodeError:
            print(f"  ÉCHEC — {match['adresse']!r} : réponse non-JSON.")
            continue
        if features:
            coords = features[0]["geometry"]["coordinates"]
            print(f"  OK — {match['adresse']!r} -> lon={coords[0]}, lat={coords[1]}")
        else:
            print(f"  0 résultat — {match['adresse']!r} (adresse peut-être incomplète)")


def main() -> None:
    parser = argparse.ArgumentParser(description="Filter the latest RNA_waldec export for anti-waste-food associations.")
    parser.add_argument("--zip-path", type=Path, default=Path("rna_waldec_latest.zip"), help="Where to save/reuse the downloaded zip.")
    parser.add_argument("--out", type=Path, default=Path("rna_filtrage_candidats.csv"))
    parser.add_argument("--skip-geocode-test", action="store_true")
    args = parser.parse_args()

    session = RateLimitedSession()

    print("Résolution du fichier rna_waldec le plus récent...")
    url, title = resolve_latest_waldec_resource(session)
    print(f"  -> {title}\n  -> {url}")

    download_zip(session, url, args.zip_path)

    print("Repérage des fichiers CSV dans l'archive...")
    entry_names = list_csv_entries(args.zip_path)
    print(f"  {len(entry_names)} fichier(s) CSV trouvé(s) — l'archive n'est pas un fichier national unique, "
          f"chacun est traité (probablement un par département/territoire).")

    matches: list[dict[str, str]] = []
    detected_format: tuple[str, str] | None = None
    for index, entry_name in enumerate(entry_names, start=1):
        raw_entry = read_csv_entry(args.zip_path, entry_name)
        text, encoding, dialect = decode_and_sniff(raw_entry)
        if detected_format is None:
            detected_format = (encoding, dialect.delimiter)
            print(f"  Format détecté sur {entry_name} : encodage={encoding}, délimiteur={dialect.delimiter!r}")
        entry_matches = filter_associations(text, dialect)
        for match in entry_matches:
            match["fichier_source"] = entry_name
        matches.extend(entry_matches)
        print(f"  [{index}/{len(entry_names)}] {entry_name} : {len(entry_matches)} match(es) (total cumulé : {len(matches)})")

    print(f"\n{len(matches)} association(s) matchée(s) au total sur les mots-clés, sur les {len(entry_names)} fichiers.")

    write_report(matches, args.out)
    print(f"Rapport complet écrit : {args.out} ({len(matches)} lignes, à relire — au moins les 30 premières comme demandé)")

    if not args.skip_geocode_test:
        smoke_test_geocoding(session, matches)


if __name__ == "__main__":
    main()
