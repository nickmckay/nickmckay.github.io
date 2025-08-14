#!/bin/bash
# Script to update publications locally and commit to GitHub
# Run this weekly on Monday nights via cron job

echo "Starting publication database update..."
cd /Users/nicholas/GitHub/nickmckay.github.io

# Set up Git environment for cron (cron has minimal environment)
export PATH="/usr/local/bin:/usr/bin:/bin"
git config user.name "Nick McKay"
git config user.email "nick@mckays.us"

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

echo "Update complete"