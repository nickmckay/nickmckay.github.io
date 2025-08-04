# Install required packages for automated publications page
# Run this script once to set up the dependencies

# Required packages for publications page
packages_needed <- c(
  "scholar",     # Google Scholar data
  "dplyr",       # Data manipulation  
  "ggplot2",     # Plotting
  "DT",          # Interactive tables
  "knitr",       # R Markdown processing
  "kableExtra"   # Enhanced table formatting
)

# Check which packages are not installed
packages_missing <- packages_needed[!packages_needed %in% installed.packages()[,"Package"]]

# Install missing packages
if(length(packages_missing) > 0) {
  cat("Installing missing packages:", paste(packages_missing, collapse = ", "), "\n")
  install.packages(packages_missing)
} else {
  cat("All required packages are already installed.\n")
}

# Update renv snapshot to include new packages
if(requireNamespace("renv", quietly = TRUE)) {
  cat("Updating renv snapshot...\n")
  renv::snapshot()
  cat("renv snapshot updated successfully.\n")
} else {
  cat("renv not available - packages installed to system library.\n")
}

cat("Setup complete! The publications page should now work properly.\n")