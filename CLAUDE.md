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

**Deployment:**
- Automatic deployment via Netlify when pushing to main branch
- Build command: `hugo`
- Publish directory: `public/`
- Hugo version: 0.148.2

## Content Architecture

**Content Structure:**
- `content/`: All site content in Markdown/R Markdown
  - `_index.md`: Homepage content and configuration
  - `about/`: About page with modular sections (header, main, sidebar)
  - `blog/`: Blog posts (supports .Rmd and .md files)
  - `project/`: Project portfolio entries
  - `talk/`: Speaking engagements and presentations
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

- `config.yaml`: Main Hugo configuration including theme settings, menus, and site parameters
- `renv.lock`: R package dependencies
- `.github/workflows/blogdown.yaml`: Github actions for building the site
- `index.Rmd`: Blogdown site configuration (minimal file for blogdown)

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

**Required packages:** scholar, dplyr, ggplot2, DT, knitr, kableExtra

**Google Scholar ID:** j8_CgoEAAAAJ (Nick McKay)

**Features:**
- Automatic citation metrics and history
- Interactive publications table
- Recent publications highlighting
- Top cited papers analysis
- Journal impact analysis

**Updating:** Rebuilds automatically when site is generated via blogdown
5. Images and assets go in `static/` directory or page bundles

## Development Notes

- The `public/` directory contains the generated static site (not tracked in git)
- `resources/` contains Hugo's processed assets cache
- Site uses academic icons and FontAwesome for social links
- Supports mathematical rendering via KaTeX
- Comments system configured for Utterances (GitHub-based)