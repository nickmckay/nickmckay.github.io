#!/bin/bash
# Script to update publications locally and commit to GitHub
# Run this weekly on Monday nights via cron job

echo "Starting publication database update..."
cd /Users/nicholas/GitHub/nickmckay.github.io

# Set up Git environment for cron (cron has minimal environment)
export PATH="/usr/local/bin:/usr/bin:/bin:/opt/homebrew/bin"
export HOME="/Users/nicholas"
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

# Debug info for troubleshooting
echo "=== DEBUG INFO ==="
echo "Current PATH: $PATH"
echo "Current working directory: $(pwd)"
echo "Current user: $(whoami)"
echo "Date: $(date)"
echo "R location: $(which Rscript)"
echo "Git location: $(which git)"
echo "=================="

git config user.name "Nick McKay"
git config user.email "nick@mckays.us"

# GitHub Personal Access Token for authentication
# Read PAT from secure file outside of git repository
GITHUB_PAT=$(cat ~/.config/github/pat.txt)

# Set the remote URL with authentication for this session only
git remote set-url origin "https://nickmckay:${GITHUB_PAT}@github.com/nickmckay/nickmckay.github.io.git"

# Run the R script locally (no proxy needed)
# R script now handles its own email notifications
echo "Running R script to fetch publications..."
if /usr/local/bin/Rscript R/update_publication_database.R; then
    echo "R script completed successfully"
else
    echo "R script failed"
    exit 1
fi

# Check if files changed
echo "=== CHECKING FOR CHANGES ==="
echo "Git status:"
git status R/data/
echo "Git diff (first 10 lines):"
git diff R/data/ | head -10
echo "=========================="

if git diff --quiet R/data/; then
    echo "No changes detected"
    # Send notification for no changes using R
    /usr/local/bin/Rscript -e "source('R/send_email.R'); send_email_notification('no_changes')"
else
    echo "Changes detected, committing..."
    
    # Get a summary of what changed
    CHANGES=$(git diff --stat R/data/)
    
    if git add R/data/*.csv && git commit -m "Update publications database - $(date '+%Y-%m-%d')" && git push origin main; then
        echo "Publications database updated and pushed to GitHub"
        # Send success notification using R with git changes information
        ESCAPED_CHANGES=$(echo "$CHANGES" | sed 's/"/\\"/g')
        /usr/local/bin/Rscript -e "source('R/send_email.R'); send_email_notification('success', details='Git changes:\n$ESCAPED_CHANGES\n\nDatabase has been updated and changes pushed to GitHub. The website will be automatically rebuilt.')"
    else
        echo "Error: Failed to commit or push changes"
        # Send error notification using R
        /usr/local/bin/Rscript -e "source('R/send_email.R'); send_email_notification('error', error_msg='Failed to commit or push changes to GitHub. Changes were detected but could not be committed or pushed.')"
        exit 1
    fi
fi

# Restore original remote URL (without PAT) for security
git remote set-url origin "https://github.com/nickmckay/nickmckay.github.io.git"

echo "Update complete"