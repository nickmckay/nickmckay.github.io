#!/bin/bash
# Script to update publications locally and commit to GitHub
# Run this weekly on Sunday nights via cron job

echo "Starting publication database update..."
cd /Users/nicholas/GitHub/nickmckay.github.io

# Run the R script locally (no proxy needed)
Rscript R/update_publication_database.R

# Check if files changed
if git diff --quiet R/data/; then
    echo "No changes detected"
else
    echo "Changes detected, committing..."
    git add R/data/*.csv
    git commit -m "Update publications database - $(date '+%Y-%m-%d')"
    git push origin main
    echo "Publications database updated and pushed to GitHub"
fi

echo "Update complete"