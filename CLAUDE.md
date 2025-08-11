# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a personal academic website built with Hugo using the Apéro theme and R/blogdown for content management. The site is deployed on Github using Github actions and uses GitHub Pages as the repository host.

## Development Environment Setup

**Prerequisites:**
- R (version 4.4.0 or later)
- Hugo (version 0.148.2)
- The `blogdown` R package

**R Environment:**
- Uses `renv` for package management
- All dependencies are locked in `renv.lock`
- The R project is configured in `nickmckay.github.io.Rproj`

## Build Commands

**Local Development:**
```bash
# Install R dependencies (first time setup)
R -e "renv::restore()"

# Serve site locally using blogdown
R -e "blogdown::serve_site()"

# Build site manually with Hugo (if Hugo is installed)
hugo

# Build for production
hugo --environment production
```

**Publications Database Management:**
```bash
# Update publications database from Google Scholar (run weekly via cron)
Rscript R/update_publication_database.R

# Automated weekly updates via local cron job (Sunday nights):
# 0 23 * * 0 /Users/nicholas/GitHub/nickmckay.github.io/update_and_commit.sh

# Manual update script that commits changes:
./update_and_commit.sh

# Note: GitHub Actions cannot access Google Scholar (blocked)
# Publications are updated locally and committed automatically
```

**Deployment:**
- Automatic deployment via GitHub Pages when pushing to main branch
- Build command: Hugo via GitHub Actions (`.github/workflows/blogdown.yaml`)
- Publish directory: `public/` to `gh-pages` branch
- Hugo version: 0.148.2
- Site URL: https://nickmckay.org

## Content Architecture

**Content Structure:**
- `content/`: All site content in Markdown/R Markdown
  - `_index.md`: Homepage content and configuration
  - `about/`: About page with modular sections (header, main, sidebar)
  - `blog/`: Blog posts (supports .Rmd and .md files)
  - `data/`: Local databases for site content
    - `publications.csv`: Publications database with complete author lists
    - `profile_metrics.csv`: Scholar profile metrics (citations, h-index, etc.)
    - `citation_history.csv`: Citation history data for visualizations
  - `project/`: Project portfolio entries
  - `research/`: Research areas (3 main focus areas)
  - `opportunities/`: Graduate student opportunities
  - `collection/`: Grouped content series
  - `form/`: Contact forms

**Theme Configuration:**
- Uses Hugo Apéro theme located in `themes/hugo-apero/`
- Main config in `config.yaml`
- Custom styling in `assets/` directory
- Supports multiple color themes (currently using "sky" theme)

**R Markdown Integration:**
- R Markdown files (.Rmd) are processed by blogdown
- Generated HTML files are ignored by Hugo (see config.yaml ignoreFiles)
- Custom build scripts available in `R/build.R` and `R/build2.R`

## Key Configuration Files

- `config.yaml`: Main Hugo configuration including theme settings, menus, site parameters, and Google Analytics (G-DL0JCFY9KX)
- `renv.lock`: R package dependencies
- `.github/workflows/blogdown.yaml`: GitHub Actions for building the site (publications update disabled)
- `index.Rmd`: Blogdown site configuration (minimal file for blogdown)
- `static/robots.txt`: SEO configuration allowing AI crawlers
- `layouts/partials/head-custom.html`: Schema.org structured data for academic profile
- `update_and_commit.sh`: Weekly publication update script

## Content Creation Workflow

1. Create new content using blogdown functions in R
2. For blog posts: use `blogdown::new_post()` or create manually in `content/blog/`
3. For R-based content: use .Rmd files which will be rendered to HTML
4. For static content: use standard Markdown (.md) files

## Automated Publications Page

The publications page (`content/publications/index.Rmd`) automatically pulls data from Google Scholar:

**Setup Requirements:**
```r
# Run once to install dependencies:
source("R/install_publications_deps.R")
```

**Required packages:** scholar, dplyr, ggplot2, DT, knitr, kableExtra, here, stringr

**Google Scholar ID:** j8_CgoEAAAAJ (Nick McKay)

**Features:**
- Automatic citation metrics and history
- Interactive publications table with journal name standardization
- Recent publications highlighting (last 2 years)
- Top cited papers analysis
- Journal impact analysis with smart name matching

**Data Files:**
- `R/data/publications.csv`: Main publications database
- `R/data/profile_metrics.csv`: Scholar profile metrics
- `R/data/citation_history.csv`: Citation counts by year

**Updating:** Updated weekly via local cron job, not in GitHub Actions (Scholar blocks CI)
5. Images and assets go in `static/` directory or page bundles

## Development Notes

- The `public/` directory contains the generated static site (not tracked in git)
- `resources/` contains Hugo's processed assets cache
- Site uses academic icons and FontAwesome for social links
- Supports mathematical rendering via KaTeX
- Comments system configured for Utterances (GitHub-based)

## SEO & Discoverability

**Current SEO Setup:**
- Google Analytics: G-DL0JCFY9KX
- robots.txt with AI crawler permissions (GPTBot, Claude-Web, etc.)
- Schema.org structured data for academic profile
- Automatic sitemap generation enabled
- Meta tags optimized for academic content

**Website Structure:**
- Main sections: About, Research (3 areas), Blog, Projects, Publications, Opportunities, Contact
- Research areas: Paleoclimate Synthesis, Paleoclimate Informatics, Paleoclimate Record Development
- Talk section removed from navigation

## Maintenance Tasks

**Weekly (Automated):**
- Publications database update via cron job (Sunday 11 PM)
- Automatic commit and push of updated data

**As Needed:**
- Manual publication updates: `./update_and_commit.sh`
- Site rebuilds automatically on git push via GitHub Actions
- Research content updates in `content/research/_index.md`
- Opportunity postings in `content/opportunities/_index.md`

## Troubleshooting

**Common Issues:**
- Google Scholar blocking: Use local updates, not GitHub Actions
- Path issues in R scripts: Use `here()` package for robust paths
- Journal name variations: Handled by standardization function in publications page
- Missing dependencies: `renv::restore()` to reinstall packages