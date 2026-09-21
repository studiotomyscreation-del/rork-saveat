#!/usr/bin/env python3
"""scan_datagouv_national.py — data.gouv.fr candidate scanner for SAVEAT's map.

STANDALONE DISCOVERY TOOL. THIS SCRIPT IS NOT PART OF THE SAVEAT iOS APP.
It is never bundled, never compiled, and never called at runtime by the app.
Run it manually from a Terminal, on demand, whenever you want to refresh the
list of candidate data.gouv.fr datasets worth a manual look. It is Python
standard library only (no pip install needed) — urllib, json, csv, time,
argparse.

What it does, in order:
  1. Lists every organisation on data.gouv.fr badged "local-authority"
     (GET /api/1/organizations/?badge=local-authority), paginated.
  2. For each organisation, lists its own datasets
     (GET /api/1/datasets/?organization=<id>).
  3. Keeps only the datasets whose title OR description contains at least
     one of KEYWORDS (case-insensitive substring match).
  4. Writes every match to a CSV report for a human to review one by one —
     exactly like the Mulhouse dataset was reviewed before any Swift code
     was written for it. This script writes NO Swift code and makes NO
     relevance judgement beyond "a keyword matched somewhere" — a keyword
     match is a candidate, not a verdict (see the false positives already
     found this project: "Territoires Zéro Déchet Zéro Gaspillage",
     "MONDIAL FRIGO IFC").

Resumable: progress (organisations already processed, matches found so far)
is checkpointed to --progress-file after every organisation, so a network
failure or a Ctrl-C never loses work — rerun the same command and it picks
up where it left off.

Usage:
    python3 scan_datagouv_national.py --limit 20        # smoke test first
    python3 scan_datagouv_national.py                   # full ~1538-org scan
    python3 scan_datagouv_national.py --resume           # continue after a stop
"""

from __future__ import annotations

import argparse
import csv
import json
import re
import sys
import time
import urllib.error
import urllib.request
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any

API_BASE = "https://www.data.gouv.fr/api/1"
USER_AGENT = "SAVEAT-map-sources-scan/1.0 (contact: via App Store; one-off research script, not the app)"

# Every phrase from the brief, kept exactly as given.
KEYWORDS = [
    "épicerie solidaire",
    "frigo solidaire",
    "frigo partagé",
    "gaspillage alimentaire",
    "invendus alimentaires",
    "aide alimentaire",
    "banque alimentaire",
    "colis alimentaire",
    "distribution alimentaire",
    "panier solidaire",
    "panier anti-gaspi",
    "solidarité alimentaire",
    "don alimentaire",
    "restos du coeur",
    "croix-rouge alimentaire",
]


def _compile_keyword_pattern(keyword: str) -> re.Pattern[str]:
    """A plain substring match on the literal keyword misses ordinary French
    plurals and adjective agreement — caught by an offline test: the exact
    Mulhouse dataset that anchored this whole investigation is titled
    "Epiceries Solidaires" (plural), which "épicerie solidaire" (singular)
    does not match as a substring. Each word of the keyword is turned into
    a French-aware root: an optional trailing "e"/"s"/"es" is allowed, so
    "épicerie solidaire" also matches "épiceries solidaires", "aide
    alimentaire" also matches "aides alimentaires", etc. This only ever
    WIDENS the candidate list — never narrows it — which is the safe
    direction for a discovery tool a human still reviews by hand.
    """
    words = keyword.split(" ")
    word_patterns = [re.escape(word) + r"(?:e|s|es)?" for word in words]
    return re.compile(r"\b" + r"\s+".join(word_patterns) + r"\b", re.IGNORECASE)


KEYWORD_PATTERNS = [(keyword, _compile_keyword_pattern(keyword)) for keyword in KEYWORDS]

MIN_DELAY_SECONDS = 0.5
MAX_RETRIES = 3
PAGE_SIZE = 100


@dataclass
class Organization:
    id: str
    name: str
    badges: list[str] = field(default_factory=list)
    siren: str | None = None  # `business_number_id` — the API has no direct
    # commune/EPCI/département/région type field; SIREN prefix rules could
    # classify this in a later pass, never guessed here.


@dataclass
class Match:
    organization_id: str
    organization_name: str
    dataset_title: str
    dataset_url: str
    matched_keywords: list[str]
    license: str
    last_update: str


class RateLimitedSession:
    """Thin wrapper around urllib with the pacing/retry rules from the brief:
    at least 0.5s between calls, exponential backoff on HTTP 429 (max 3
    retries), and a clean, catchable failure after that so the caller can
    checkpoint and stop rather than crash mid-run."""

    def __init__(self, min_delay: float = MIN_DELAY_SECONDS) -> None:
        self.min_delay = min_delay
        self._last_call = 0.0

    def get_json(self, url: str) -> dict[str, Any]:
        elapsed = time.monotonic() - self._last_call
        if elapsed < self.min_delay:
            time.sleep(self.min_delay - elapsed)

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
                    retry_after = error.headers.get("Retry-After")
                    wait = float(retry_after) if retry_after else backoff
                    print(f"  [429] rate limited, waiting {wait:.1f}s (attempt {attempt}/{MAX_RETRIES})", file=sys.stderr)
                    time.sleep(wait)
                    backoff *= 2
                    continue
                raise
        raise RuntimeError(f"Exhausted {MAX_RETRIES} retries for {url}")


class ProgressStore:
    """Checkpoint file: organisations list (fetched once), which org IDs have
    already been scanned for datasets, and matches found so far. Reread on
    startup so a stopped run resumes instead of restarting from zero."""

    def __init__(self, path: Path) -> None:
        self.path = path
        self.organizations: list[Organization] = []
        self.processed_org_ids: set[str] = set()
        self.matches: list[Match] = []
        if path.exists():
            self._load()

    def _load(self) -> None:
        data = json.loads(self.path.read_text(encoding="utf-8"))
        self.organizations = [Organization(**org) for org in data.get("organizations", [])]
        self.processed_org_ids = set(data.get("processed_org_ids", []))
        self.matches = [Match(**match) for match in data.get("matches", [])]

    def save(self) -> None:
        payload = {
            "organizations": [org.__dict__ for org in self.organizations],
            "processed_org_ids": sorted(self.processed_org_ids),
            "matches": [match.__dict__ for match in self.matches],
        }
        self.path.write_text(json.dumps(payload, ensure_ascii=False, indent=2), encoding="utf-8")


def fetch_local_authorities(session: RateLimitedSession) -> list[Organization]:
    organizations: list[Organization] = []
    page = 1
    while True:
        url = f"{API_BASE}/organizations/?badge=local-authority&page_size={PAGE_SIZE}&page={page}"
        payload = session.get_json(url)
        for row in payload.get("data", []):
            organizations.append(
                Organization(
                    id=row["id"],
                    name=row.get("name", ""),
                    badges=[b.get("kind", b) if isinstance(b, dict) else b for b in row.get("badges", [])],
                    siren=row.get("business_number_id"),
                )
            )
        print(f"  organisations page {page}: {len(payload.get('data', []))} rows (total so far: {len(organizations)})")
        if not payload.get("next_page"):
            break
        page += 1
    return organizations


def find_matches_for_organization(session: RateLimitedSession, org: Organization) -> list[Match]:
    matches: list[Match] = []
    page = 1
    while True:
        url = f"{API_BASE}/datasets/?organization={org.id}&page_size={PAGE_SIZE}&page={page}"
        payload = session.get_json(url)
        for dataset in payload.get("data", []):
            title = dataset.get("title", "") or ""
            description = dataset.get("description", "") or ""
            haystack = f"{title}\n{description}"
            hit_keywords = [kw for kw, pattern in KEYWORD_PATTERNS if pattern.search(haystack)]
            if not hit_keywords:
                continue
            dataset_url = dataset.get("page") or f"https://www.data.gouv.fr/fr/datasets/{dataset.get('slug', '')}/"
            license_field = dataset.get("license", "") or ""
            last_update = dataset.get("last_update", "") or ""
            matches.append(
                Match(
                    organization_id=org.id,
                    organization_name=org.name,
                    dataset_title=title,
                    dataset_url=dataset_url,
                    matched_keywords=hit_keywords,
                    license=license_field,
                    last_update=last_update,
                )
            )
        if not payload.get("next_page"):
            break
        page += 1
    return matches


def write_csv_report(matches: list[Match], out_path: Path) -> None:
    with out_path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.writer(handle)
        writer.writerow([
            "organisation", "organisation_id", "dataset_title", "dataset_url",
            "matched_keywords", "license", "last_update",
        ])
        for match in matches:
            writer.writerow([
                match.organization_name,
                match.organization_id,
                match.dataset_title,
                match.dataset_url,
                " | ".join(match.matched_keywords),
                match.license,
                match.last_update,
            ])


def main() -> None:
    parser = argparse.ArgumentParser(description="Scan data.gouv.fr territorial organisations for anti-waste food datasets.")
    parser.add_argument("--limit", type=int, default=None, help="Only scan the first N organisations (smoke test).")
    parser.add_argument("--progress-file", type=Path, default=Path("data_gouv_scan_progress.json"))
    parser.add_argument("--out", type=Path, default=Path("data_gouv_scan_candidates.csv"))
    args = parser.parse_args()

    session = RateLimitedSession()
    store = ProgressStore(args.progress_file)

    if not store.organizations:
        print("Fetching territorial organisations (badge=local-authority)...")
        store.organizations = fetch_local_authorities(session)
        store.save()
    else:
        print(f"Resuming with {len(store.organizations)} organisations already listed from a previous run.")

    targets = store.organizations[: args.limit] if args.limit else store.organizations
    remaining = [org for org in targets if org.id not in store.processed_org_ids]
    print(f"{len(remaining)} organisation(s) left to scan out of {len(targets)} target(s).")

    try:
        for index, org in enumerate(remaining, start=1):
            print(f"[{index}/{len(remaining)}] {org.name} ({org.id})")
            try:
                found = find_matches_for_organization(session, org)
            except (urllib.error.HTTPError, urllib.error.URLError, RuntimeError) as error:
                print(f"  ERROR: {error} — saving progress and stopping so nothing is lost.", file=sys.stderr)
                store.save()
                write_csv_report(store.matches, args.out)
                sys.exit(1)
            if found:
                print(f"  -> {len(found)} candidate dataset(s) matched.")
                store.matches.extend(found)
            store.processed_org_ids.add(org.id)
            store.save()
    except KeyboardInterrupt:
        print("\nInterrupted — progress saved, rerun the same command to resume.", file=sys.stderr)
        store.save()
        write_csv_report(store.matches, args.out)
        sys.exit(130)

    write_csv_report(store.matches, args.out)
    print(f"\nDone. {len(store.matches)} candidate dataset(s) across {len(store.processed_org_ids)} organisation(s).")
    print(f"Report: {args.out}")
    print(f"Progress checkpoint: {args.progress_file}")


if __name__ == "__main__":
    main()
