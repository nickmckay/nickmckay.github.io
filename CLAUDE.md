# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Nick McKay's personal academic website (https://nickmckay.org), rebuilt in August 2026 on the same stack as ses-nau.org: Astro 5 + Tailwind 4 + Preact islands, deployed to GitHub Pages via GitHub Actions. The previous Hugo/blogdown site was retired in that migration (the old blog posts are archived in `archive/hugo/`).

## Architecture

```
local weekly R cron  ->  R/data/*.csv on main  ->  Astro build (GitHub Actions)  ->  actions/deploy-pages
```

- `src/pages/`: one Astro file per page (about, research, opportunities, contact, publications, 404) plus `project/` (content-collection driven) and `data/publications.json.ts` (build-time JSON feed for the explorer island).
- `src/content/projects/*.md`: the five project pages (lipd, lipdverse, presto, geochronr, actr); schema in `src/content.config.ts`. URLs are `/project/<slug>/`.
- `src/layouts/Base.astro`: chrome, GA4 (G-DL0JCFY9KX), Person JSON-LD, OG/Twitter/citation meta.
- `src/lib/publications.ts`: build-time loader for the publication CSVs; joins DOIs; journal-name standardization.
- `src/components/`: Nav, Footer, SocialLinks, PageHero, StatTile, BarChart (build-time SVG charts), PublicationExplorer.tsx (Preact island: search/year-filter/sort).
- `public/`: CNAME, robots.txt, favicon, images. These MUST stay in `public/` so they land in the deployed `dist/`.
- Redirects (old Hugo URLs -> new) are meta-refresh stubs declared in `astro.config.mjs`.

## Commands

```bash
npm install        # first-time setup
npm run dev        # local dev server
npm run build      # build to dist/
node scripts/check_links.mjs   # internal link check (run after build; CI runs it too)
```

## Publications data contract (IMPORTANT)

`R/data/publications.csv`, `R/data/profile_metrics.csv`, and `R/data/citation_history.csv` are owned by the weekly R cron pipeline:

- Local cron (Thursday 11 PM) runs `update_and_commit.sh` (gitignored) -> `R/update_publication_database.R` -> rewrites the CSVs -> commits and pushes to main -> GitHub Actions rebuilds the site.
- **Never add or remove columns in `R/data/publications.csv`.** The R script assigns whole 9-column rows into the loaded data frame (`final_pubs[idx, ] <- current_pub`), so a schema change corrupts the weekly run. Fixing values in existing cells is fine (rows with `complete_authors_fetched=TRUE` are preserved by the merge).
- DOIs live in the sidecar `data/dois.csv` (`pubid,title,doi`), written by `scripts/enrich_dois.py` and joined at build time in `src/lib/publications.ts`. New publications arrive DOI-less; re-run `python3 scripts/enrich_dois.py` occasionally (safe to re-run; add `--loose` for a fuzzier second pass) and commit the result.
- Student-author tags live in the sidecar `data/student_authors.csv` (`pubid,title,grad,undergrad`), synced from the curated ses-nau.org database by `scripts/sync_student_authors.py` (needs the local clone at `~/GitHub/SES_Publication_Dashboard`). Re-run alongside enrich_dois.py after weekly updates. The explorer shows student chips and offers "student authors only" / "student first author" filters, mirroring ses-nau.org.
- GitHub Actions cannot reach Google Scholar; Scholar updates happen only via the local cron.

## Deployment

- Pages source is "GitHub Actions" (`.github/workflows/deploy.yml`): push to main -> build (node 22, `npm ci`, `npm run build`, link check) -> deploy `dist/`. PRs get a build check plus a `site-preview` artifact.
- Custom domain: `public/CNAME` (nickmckay.org). Keep CNAME/robots/favicon inside `public/`.
- Sitemap: `@astrojs/sitemap` emits `/sitemap-index.xml` (robots.txt points there).

## Maintenance

- **Annually (fall):** refresh the recruiting cycle on `/opportunities/` (`src/pages/opportunities.astro`); the posting currently targets a Fall 2027 start.
- After weekly data pushes, the site rebuilds automatically; no manual step.
- Related site: https://ses-nau.org (repo `nau-ses-research/nau-ses-research.github.io`, local clone `~/GitHub/SES_Publication_Dashboard`) shares the same stack and the original versions of BarChart/PublicationExplorer/check_links/enrich_dois.
