/**
 * Typed build-time access to the publication database.
 *
 * R/data/*.csv are owned by the weekly R cron pipeline
 * (R/update_publication_database.R): never add columns there. DOIs live in
 * the sidecar data/dois.csv (written by scripts/enrich_dois.py) and are
 * joined here on the Google Scholar pubid.
 */
import { parse } from "csv-parse/sync";
import { readFileSync } from "node:fs";

export interface Publication {
  title: string;
  authors: string;
  journal: string;
  number: string;
  citations: number;
  year: number | null;
  pubid: string;
  doi: string;
  gradStudents: string[];
  undergradStudents: string[];
}

export interface ProfileMetrics {
  totalCites: number;
  hIndex: number;
  i10Index: number;
  updateDate: string;
}

function csv(path: string): Record<string, string>[] {
  return parse(readFileSync(path, "utf-8"), { columns: true });
}

function splitMulti(v: string | undefined): string[] {
  return v ? v.split("; ").filter(Boolean) : [];
}

let _pubs: Publication[] | null = null;

/** All publications, newest first (ties broken by citations). */
export function getPublications(): Publication[] {
  if (_pubs) return _pubs;
  const doiRows = new Map(csv("data/dois.csv").map((r) => [r.pubid, r]));
  const dois = new Map([...doiRows].map(([id, r]) => [id, r.doi]));
  // Crossref final-publication years: preferred over the Scholar year, which
  // inherits the preprint's year when Scholar merges two-stage EGU papers.
  const finalYears = new Map(
    [...doiRows].filter(([, r]) => r.year).map(([id, r]) => [id, parseInt(r.year, 10)]),
  );
  const students = new Map(csv("data/student_authors.csv").map((r) => [r.pubid, r]));
  _pubs = csv("R/data/publications.csv")
    .map((r) => ({
      title: r.title,
      // Scholar occasionally garbles the author field (e.g. "2013/5")
      authors: /^\d{4}\/\d+$/.test(r.author ?? "") ? "" : (r.author ?? ""),
      journal: r.journal ?? "",
      number: r.number ?? "",
      citations: parseInt(r.cites, 10) || 0,
      year: finalYears.get(r.pubid) ?? (r.year ? parseInt(r.year, 10) : null),
      pubid: r.pubid,
      doi: dois.get(r.pubid) || "",
      gradStudents: splitMulti(students.get(r.pubid)?.grad),
      undergradStudents: splitMulti(students.get(r.pubid)?.undergrad),
    }))
    .sort((a, b) => (b.year ?? 0) - (a.year ?? 0) || b.citations - a.citations);
  return _pubs;
}

export function getProfileMetrics(): ProfileMetrics {
  const r = csv("R/data/profile_metrics.csv")[0];
  return {
    totalCites: parseInt(r.total_cites, 10) || 0,
    hIndex: parseInt(r.h_index, 10) || 0,
    i10Index: parseInt(r.i10_index, 10) || 0,
    updateDate: r.update_date ?? "",
  };
}

/** Citations per year, ascending. */
export function getCitationHistory(): { year: number; cites: number }[] {
  return csv("R/data/citation_history.csv")
    .map((r) => ({ year: parseInt(r.year, 10), cites: parseInt(r.cites, 10) || 0 }))
    .filter((r) => Number.isFinite(r.year))
    .sort((a, b) => a.year - b.year);
}

/** Publication counts per year across the full span, gaps filled with 0. */
export function getPubsPerYear(): { year: number; count: number }[] {
  const counts = new Map<number, number>();
  for (const p of getPublications()) {
    if (p.year !== null) counts.set(p.year, (counts.get(p.year) ?? 0) + 1);
  }
  const years = [...counts.keys()];
  const out: { year: number; count: number }[] = [];
  for (let y = Math.min(...years); y <= Math.max(...years); y++) {
    out.push({ year: y, count: counts.get(y) ?? 0 });
  }
  return out;
}

/** Ported from the old publications page's standardize_journal_name() in R. */
const JOURNAL_STANDARDIZATIONS: [RegExp, string][] = [
  [/^Nature$/i, "Nature"],
  [/^Nature Clim/i, "Nature Climate Change"],
  [/^Nature Commun/i, "Nature Communications"],
  [/^Nature Geosci/i, "Nature Geoscience"],
  [/^Science$/i, "Science"],
  [/^Science Adv/i, "Science Advances"],
  [/^Proc.*Natl.*Acad.*Sci/i, "Proceedings of the National Academy of Sciences"],
  [/^Pnas$/i, "Proceedings of the National Academy of Sciences"],
  [/^J.*Geophys.*Res/i, "Journal of Geophysical Research"],
  [/^Jgr/i, "Journal of Geophysical Research"],
  [/^Geophys.*Res.*Lett/i, "Geophysical Research Letters"],
  [/^Grl$/i, "Geophysical Research Letters"],
  [/^Clim.*Past$/i, "Climate of the Past"],
  [/^Clim.*Dyn/i, "Climate Dynamics"],
  [/^J.*Clim/i, "Journal of Climate"],
  [/^Paleoceanogr/i, "Paleoceanography and Paleoclimatology"],
  [/^Quat.*Sci.*Rev/i, "Quaternary Science Reviews"],
  [/^Qsr$/i, "Quaternary Science Reviews"],
  [/^Earth.*Planet.*Sci.*Lett/i, "Earth and Planetary Science Letters"],
  [/^Epsl$/i, "Earth and Planetary Science Letters"],
  [/^Geology$/i, "Geology"],
  [/^Paleobiology$/i, "Paleobiology"],
  [/^Holocene$/i, "The Holocene"],
];

/** Heuristic ported from ses-nau.org: is the first author a tagged student? */
export function studentFirstAuthor(p: Publication): boolean {
  const students = [...p.gradStudents, ...p.undergradStudents];
  if (students.length === 0 || !p.authors) return false;
  const first = p.authors.split(",")[0].toLowerCase();
  const tokens = first.replace(/[^a-z\s-]/g, "").split(/[\s-]+/).filter(Boolean);
  return students.some((name) => {
    const parts = name.toLowerCase().split(/\s+/);
    const surname = parts[parts.length - 1];
    const initial = parts[0]?.[0];
    return (
      tokens.includes(surname) &&
      (!initial || tokens.some((t) => t !== surname && t.startsWith(initial)))
    );
  });
}

export function standardizeJournalName(name: string): string {
  const clean = name
    .trim()
    .toLowerCase()
    .replace(/\b\w/g, (c) => c.toUpperCase());
  if (!clean) return clean;
  for (const [pattern, standard] of JOURNAL_STANDARDIZATIONS) {
    if (pattern.test(clean)) return standard;
  }
  return clean;
}
