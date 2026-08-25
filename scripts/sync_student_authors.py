#!/usr/bin/env python3
"""Sync student-author tags from the ses-nau.org publication database.

Run from the repo root:  python3 scripts/sync_student_authors.py

Matches R/data/publications.csv rows against the SES database (local clone
of nau-ses-research/nau-ses-research.github.io) by normalized title and
copies the human-curated ses_grad_students / ses_undergrad_students tags
into the sidecar data/student_authors.csv (pubid,title,grad,undergrad).
The site build joins the sidecar on pubid.

Like data/dois.csv, this is a sidecar because the R/data/publications.csv
schema is owned by the weekly R cron pipeline and must not gain columns.
Re-run occasionally after weekly updates add new publications; rows for
papers no longer in the SES database are preserved.
"""

import csv
import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
PUB_CSV = REPO / "R" / "data" / "publications.csv"
OUT_CSV = REPO / "data" / "student_authors.csv"
SES_CSV = Path.home() / "GitHub" / "SES_Publication_Dashboard" / "data" / "publications.csv"


def norm(title: str) -> str:
    return re.sub(r"[^a-z0-9]", "", title.lower())


def main() -> int:
    if not SES_CSV.exists():
        print(f"SES database not found at {SES_CSV}; clone "
              "nau-ses-research/nau-ses-research.github.io there first.")
        return 1

    ses: dict[str, dict] = {}
    for r in csv.DictReader(open(SES_CSV, newline="")):
        ses[norm(r["title"])] = r
        if r.get("simple_title"):
            ses.setdefault(norm(r["simple_title"]), r)

    known: dict[str, dict] = {}
    if OUT_CSV.exists():
        known = {r["pubid"]: r for r in csv.DictReader(open(OUT_CSV, newline=""))}

    pubs = list(csv.DictReader(open(PUB_CSV, newline="")))
    matched = tagged = 0
    for r in pubs:
        s = ses.get(norm(r["title"]))
        if not s or not r["pubid"]:
            continue
        matched += 1
        grad = s.get("ses_grad_students", "")
        undergrad = s.get("ses_undergrad_students", "")
        if grad or undergrad:
            tagged += 1
            known[r["pubid"]] = {
                "pubid": r["pubid"], "title": r["title"],
                "grad": grad, "undergrad": undergrad,
            }
        else:
            # SES explicitly has no tags for this paper; drop any stale row
            known.pop(r["pubid"], None)

    pub_order = [r["pubid"] for r in pubs]
    order = {p: i for i, p in enumerate(pub_order)}
    OUT_CSV.parent.mkdir(exist_ok=True)
    with open(OUT_CSV, "w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=["pubid", "title", "grad", "undergrad"],
                           quoting=csv.QUOTE_MINIMAL)
        w.writeheader()
        w.writerows(sorted(known.values(), key=lambda r: order.get(r["pubid"], 10**6)))

    print(f"{len(pubs)} publications; {matched} matched in the SES database; "
          f"{tagged} with student authors -> {OUT_CSV.name} ({len(known)} rows)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
