# Script to update local publications database from Google Scholar
# Run this periodically to keep the database current

library(scholar)
library(dplyr)
library(here)

# Nick McKay's Google Scholar ID
scholar_id <- "j8_CgoEAAAAJ"
doneNow <- FALSE

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

# Get basic publication data from Google Scholar
cat("Fetching basic publication data from Google Scholar...\n")
tryCatch({
  current_pubs <- get_publications(scholar_id)
  profile <- get_profile(scholar_id)
  citation_hist <- get_citation_history(scholar_id)
  
  # Check if Scholar data was retrieved successfully
  if (is.null(current_pubs) || nrow(current_pubs) == 0) {
    stop("No publications retrieved from Google Scholar")
  }
  if (is.null(profile) || is.null(citation_hist)) {
    stop("Profile or citation history not retrieved from Google Scholar")
  }
  
  cat(paste("Successfully retrieved", nrow(current_pubs), "publications from Google Scholar\n"))
}, error = function(e) {
  cat("Failed to fetch data from Google Scholar:", e$message, "\n")
  cat("GitHub Actions may be blocked by Google Scholar. Skipping database update.\n")
  cat("Using existing database without updates.\n")
  
  # Exit gracefully - database will remain unchanged
  quit(status = 0)
})

# Load existing database if it exists
pub_file <- here("R", "data", "publications.csv")
existing_db_exists <- file.exists(pub_file)
if (existing_db_exists) {
  cat("Loading existing publications database...\n")
  existing_pubs <- read.csv(pub_file, stringsAsFactors = FALSE)
  cat(paste("Existing database contains", nrow(existing_pubs), "publications\n"))
} else {
  cat("No existing database found - will create fresh database\n")
  existing_pubs <- data.frame()
}

# Determine which publications need complete author information
cat("Comparing current publications with existing database...\n")
pubs_to_update <- data.frame()

for (i in 1:nrow(current_pubs)) {
  current_pub <- current_pubs[i,]
  
  # Check if this publication exists in our database with complete authors
  if (existing_db_exists) {
    existing_match <- existing_pubs[existing_pubs$title == current_pub$title, ]
    
    if (nrow(existing_match) > 0) {
      authors_fetched <- existing_match$complete_authors_fetched[1]
      # Check if complete authors were fetched (handle different data types)
      if (!is.na(authors_fetched) && (authors_fetched == TRUE || authors_fetched == "TRUE")) {
        # Publication exists with complete authors - skip
        next
      }
    }
  }
  
  # This publication needs complete author information
  pubs_to_update <- rbind(pubs_to_update, current_pub)
}

cat(paste("Found", nrow(pubs_to_update), "publications that need complete author information\n"))

# Process publications that need updates
if (nrow(pubs_to_update) > 0) {
  cat("Fetching complete author information for publications that need updates...\n")
  
  for (i in 1:nrow(pubs_to_update)) {
    pub <- pubs_to_update[i,]
    cat(paste("Processing", i, "of", nrow(pubs_to_update), ":", pub$title, "\n"))
    
    complete_authors <- get_safe_complete_authors(scholar_id, pub$pubid)
    if (!is.na(complete_authors) && complete_authors != "") {
      pubs_to_update$author[i] <- complete_authors
      pubs_to_update$complete_authors_fetched[i] <- TRUE
      cat("  ✓ Complete authors fetched\n")
    } else {
      pubs_to_update$complete_authors_fetched[i] <- FALSE
      cat("  ✗ Using truncated authors\n")
    }
    
    # Progress indicator
    if (i %% 5 == 0) {
      cat(paste("Progress:", round(i/nrow(pubs_to_update)*100, 1), "%\n"))
    }
  }
} else {
  cat("No publications need updating - database is current!\n")
  doneNow <- TRUE
}

if(!doneNow){
  # Merge updated publications with existing database
  cat("Merging updated publications with existing database...\n")
  if (existing_db_exists && nrow(existing_pubs) > 0) {
    # Start with existing database
    final_pubs <- existing_pubs
    
    # Update or add new publications
    for (i in 1:nrow(current_pubs)) {
      current_pub <- current_pubs[i,]
      existing_idx <- which(final_pubs$title == current_pub$title)
      
      if (length(existing_idx) > 0) {
        # Update existing publication (in case citation counts changed)
        final_pubs[existing_idx[1], ] <- current_pub
        
        # Preserve complete author information if we have it
        updated_pub <- pubs_to_update[pubs_to_update$title == current_pub$title, ]
        if (nrow(updated_pub) > 0) {
          final_pubs$author[existing_idx[1]] <- updated_pub$author[1]
          final_pubs$complete_authors_fetched[existing_idx[1]] <- updated_pub$complete_authors_fetched[1]
        }
      } else {
        # Add new publication
        new_pub <- current_pub
        updated_pub <- pubs_to_update[pubs_to_update$title == current_pub$title, ]
        if (nrow(updated_pub) > 0) {
          new_pub$author <- updated_pub$author[1]
          new_pub$complete_authors_fetched <- updated_pub$complete_authors_fetched[1]
        } else {
          new_pub$complete_authors_fetched <- FALSE
        }
        final_pubs <- rbind(final_pubs, new_pub)
      }
    }
  } else {
    # No existing database - use current publications with updates
    final_pubs <- current_pubs
    final_pubs$complete_authors_fetched <- FALSE
    
    # Apply updates
    for (i in 1:nrow(pubs_to_update)) {
      updated_pub <- pubs_to_update[i,]
      idx <- which(final_pubs$title == updated_pub$title)
      if (length(idx) > 0) {
        final_pubs$author[idx[1]] <- updated_pub$author
        final_pubs$complete_authors_fetched[idx[1]] <- updated_pub$complete_authors_fetched
      }
    }
  }
  
  
  pubs_with_complete_authors <- final_pubs
  
  # Save the data
  cat("Saving publications database...\n")
  write.csv(pubs_with_complete_authors, here("R", "data", "publications.csv"), row.names = FALSE)
  write.csv(data.frame(
    total_cites = profile$total_cites,
    h_index = profile$h_index,
    i10_index = profile$i10_index,
    update_date = Sys.Date()
  ), here("R", "data", "profile_metrics.csv"), row.names = FALSE)
  write.csv(citation_hist, here("R", "data", "citation_history.csv"), row.names = FALSE)
  
  cat("Publications database updated successfully!\n")
  cat(paste("Total publications:", nrow(pubs_with_complete_authors), "\n"))
  cat(paste("Publications with complete authors:", 
            sum(as.logical(pubs_with_complete_authors$complete_authors_fetched), na.rm = TRUE), "\n"))
  cat(paste("Publications updated in this run:", nrow(pubs_to_update), "\n"))
  
  if (nrow(pubs_to_update) == 0) {
    cat("Database was already current - no API calls needed!\n")
  } else {
    cat(paste("Complete author information fetched for", 
              sum(as.logical(pubs_to_update$complete_authors_fetched), na.rm = TRUE), 
              "of", nrow(pubs_to_update), "updated publications\n"))
  }
}