/**
 * Trimmed publication dataset consumed by the explorer island.
 * Regenerated at every build from R/data/publications.csv + data/dois.csv.
 */
import type { APIRoute } from "astro";
import { getPublications, studentFirstAuthor } from "../../lib/publications";

export const GET: APIRoute = () => {
  const pubs = getPublications().map((p) => ({
    t: p.title,
    a: p.authors,
    j: p.journal,
    y: p.year,
    c: p.citations,
    p: p.pubid,
    d: p.doi,
    g: p.gradStudents,
    u: p.undergradStudents,
    sf: studentFirstAuthor(p),
  }));
  return new Response(JSON.stringify(pubs), {
    headers: { "Content-Type": "application/json" },
  });
};
