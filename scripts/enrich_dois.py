#!/usr/bin/env python3
"""Look up DOIs for R/data/publications.csv and write them to data/dois.csv.

Run from the repo root:  python3 scripts/enrich_dois.py [--limit N] [--dry-run] [--loose]

DOIs live in a sidecar CSV (pubid,title,doi) rather than in
R/data/publications.csv because that file's schema is owned by the weekly
R cron pipeline (R/update_publication_database.R), which rewrites it with a
fixed column set. The site build joins the sidecar on pubid.

Conservative matching (ported from the ses-nau.org pipeline): a candidate is
accepted only when the normalized (alphanumeric, lowercased) titles are
equal, or one contains the other and they differ by less than 20 characters,
AND the publication year matches within one year. Rows already present in
data/dois.csv are skipped, so this is safe to re-run after weekly updates
add new publications.

Uses anonymous Crossref/OpenAlex pools with a descriptive User-Agent.
"""

import argparse
import csv
import difflib
import json
import re
import sys
import time
import urllib.parse
import urllib.request
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
PUB_CSV = REPO / "R" / "data" / "publications.csv"
DOI_CSV = REPO / "data" / "dois.csv"
UA = "nickmckay.org publications pipeline (https://github.com/nickmckay/nickmckay.github.io)"


def norm(title: str) -> str:
    return re.sub(r"[^a-z0-9]", "", title.lower())


def _accept(want: str, got: str, year: str, got_year) -> bool:
    if not got:
        return False
    contained = (want in got or got in want) and abs(len(want) - len(got)) < 20
    if want != got and not contained:
        return False
    if year and got_year and abs(int(year) - int(got_year)) > 1:
        return False
    return True


def _accept_loose(want: str, got: str, year: str, got_year,
                  first_author_surname: str, got_surnames: set[str]) -> bool:
    """Second-pass matching: fuzzier titles, but the year must agree within
    one AND our first author's surname must appear among the candidate's
    authors. The author check is what makes the looseness safe."""
    if not got or not first_author_surname:
        return False
    if not (year and got_year and abs(int(year) - int(got_year)) <= 1):
        return False
    if first_author_surname not in got_surnames:
        return False
    if want in got or got in want:
        return True
    return difflib.SequenceMatcher(None, want, got).ratio() >= 0.93


def first_surname(authors: str) -> str:
    """Normalized surname of the first author from our 'NP McKay, ...'
    or 'McKay, NP' style strings."""
    first = (authors or "").split(",")[0].strip()
    if not first:
        return ""
    parts = first.split()
    cand = parts[-1] if len(parts) > 1 else parts[0]
    return re.sub(r"[^a-z]", "", cand.lower())


def lookup_doi(title: str, year: str, authors: str = "",
               loose: bool = False) -> str | None:
    """Crossref first (fast, tolerant of our volume), OpenAlex as fallback."""
    want = norm(title)
    surname = first_surname(authors) if loose else ""
    q = urllib.parse.quote(title[:250])
    # --- Crossref
    url = f"https://api.crossref.org/works?query.bibliographic={q}&rows=3"
    req = urllib.request.Request(url, headers={"User-Agent": UA})
    try:
        with urllib.request.urlopen(req, timeout=30) as r:
            items = json.load(r)["message"]["items"]
        for it in items:
            got = norm((it.get("title") or [""])[0])
            got_year = (it.get("issued", {}).get("date-parts", [[None]]) or [[None]])[0][0]
            if _accept(want, got, year, got_year):
                return it.get("DOI") or None
            if loose:
                got_surnames = {
                    re.sub(r"[^a-z]", "", (a.get("family") or "").lower())
                    for a in it.get("author", [])
                }
                if _accept_loose(want, got, year, got_year, surname, got_surnames):
                    return it.get("DOI") or None
    except Exception as e:  # noqa: BLE001 - fall through to OpenAlex
        print(f"  crossref error ({type(e).__name__})", flush=True)
        time.sleep(2)
    # --- OpenAlex fallback
    url = f"https://api.openalex.org/works?search={q}&per-page=3"
    req = urllib.request.Request(url, headers={"User-Agent": UA})
    try:
        with urllib.request.urlopen(req, timeout=30) as r:
            results = json.load(r).get("results", [])
    except Exception as e:  # noqa: BLE001 - network lookups fail; skip row
        print(f"  openalex error ({type(e).__name__}); skipping", flush=True)
        time.sleep(2)
        return None
    for w in results:
        got = norm(w.get("title") or w.get("display_name") or "")
        if _accept(want, got, year, w.get("publication_year")):
            doi = (w.get("doi") or "").replace("https://doi.org/", "")
            return doi or None
    return None


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--limit", type=int, help="only process the first N missing-DOI rows")
    ap.add_argument("--dry-run", action="store_true")
    ap.add_argument("--loose", action="store_true",
                    help="second-pass matching: fuzzier titles, but requires "
                         "year agreement AND first-author surname match")
    args = ap.parse_args()

    with open(PUB_CSV, newline="") as f:
        pubs = list(csv.DictReader(f))

    known: dict[str, dict] = {}
    if DOI_CSV.exists():
        with open(DOI_CSV, newline="") as f:
            known = {r["pubid"]: r for r in csv.DictReader(f)}

    todo = [r for r in pubs
            if r["pubid"] and r["title"] and not known.get(r["pubid"], {}).get("doi")]
    if args.limit:
        todo = todo[: args.limit]
    print(f"{len(pubs)} publications; {len(todo)} to look up", flush=True)

    def write_out():
        if args.dry_run:
            return
        DOI_CSV.parent.mkdir(exist_ok=True)
        pub_order = [r["pubid"] for r in pubs if r["pubid"] in known]
        with open(DOI_CSV, "w", newline="") as f:
            w = csv.DictWriter(f, fieldnames=["pubid", "title", "doi"],
                               quoting=csv.QUOTE_MINIMAL)
            w.writeheader()
            w.writerows(known[p] for p in pub_order)

    found = 0
    for i, r in enumerate(todo, 1):
        doi = lookup_doi(r["title"], r["year"], r.get("author", ""), loose=args.loose)
        if doi:
            known[r["pubid"]] = {"pubid": r["pubid"], "title": r["title"], "doi": doi}
            found += 1
        if i % 25 == 0:
            print(f"  {i}/{len(todo)} processed, {found} DOIs found", flush=True)
            write_out()  # checkpoint so an interrupted run keeps its progress
        time.sleep(0.2)

    total = sum(1 for r in known.values() if r.get("doi"))
    print(f"Done: {found}/{len(todo)} matched ({total} publications now have DOIs)", flush=True)
    if args.dry_run:
        print("Dry run: not writing.")
        return 0
    write_out()
    print(f"Wrote {DOI_CSV}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
