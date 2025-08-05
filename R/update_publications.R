# Script to update local publications database from Google Scholar
# Run this periodically to keep the database current

library(scholar)
library(dplyr)

# Nick McKay's Google Scholar ID
scholar_id <- "j8_CgoEAAAAJ"

# Function to safely get complete authors with progressive backoff
get_safe_complete_authors <- function(scholar_id, pubid, max_retries = 3) {
  for (i in 1:max_retries) {
    tryCatch({
      # Progressive rate limiting: longer delays for later attempts
      Sys.sleep(1 + (i-1) * 0.5)  
      result <- get_complete_authors(scholar_id, pubid)
      return(result)
    }, error = function(e) {
      if (i == max_retries) {
        warning(paste("Failed to get complete authors for pubid:", pubid, "- Error:", e$message))
        return(NA)
      }
      # Exponential backoff for retries
      Sys.sleep(2^i)  
    })
  }
}

# Get basic publication data
cat("Fetching basic publication data from Google Scholar...\n")
pubs <- get_publications(scholar_id)
profile <- get_profile(scholar_id)
citation_hist <- get_citation_history(scholar_id)

# Add complete author information for ALL publications
cat("Fetching complete author information for all publications...\n")
cat(paste("Total publications to process:", nrow(pubs), "\n"))

# Initialize the complete authors column
pubs$complete_authors_fetched <- FALSE

# Process all publications with complete authors
pubs_with_complete_authors <- pubs
for (i in 1:nrow(pubs)) {
  cat(paste("Processing", i, "of", nrow(pubs), ":", pubs$title[i], "\n"))
  
  complete_authors <- get_safe_complete_authors(scholar_id, pubs$pubid[i])
  if (!is.na(complete_authors) && complete_authors != "") {
    pubs_with_complete_authors$author[i] <- complete_authors
    pubs_with_complete_authors$complete_authors_fetched[i] <- TRUE
    cat("  ✓ Complete authors fetched\n")
  } else {
    pubs_with_complete_authors$complete_authors_fetched[i] <- FALSE
    cat("  ✗ Using truncated authors\n")
  }
  
  # Progress indicator
  if (i %% 10 == 0) {
    cat(paste("Progress:", round(i/nrow(pubs)*100, 1), "%\n"))
  }
}

# Save the data
cat("Saving publications database...\n")
write.csv(pubs_with_complete_authors, "data/publications.csv", row.names = FALSE)
write.csv(data.frame(
  total_cites = profile$total_cites,
  h_index = profile$h_index,
  i10_index = profile$i10_index,
  update_date = Sys.Date()
), "data/profile_metrics.csv", row.names = FALSE)
write.csv(citation_hist, "data/citation_history.csv", row.names = FALSE)

cat("Publications database updated successfully!\n")
cat(paste("Total publications:", nrow(pubs_with_complete_authors), "\n"))
cat(paste("Recent publications with complete authors:", 
          sum(pubs_with_complete_authors$complete_authors_fetched, na.rm = TRUE), "\n"))