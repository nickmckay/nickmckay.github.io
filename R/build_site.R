# Custom build script that updates publications then builds the site
cat("Starting site build process...\n")

# Step 1: Update publications database
cat("Step 1: Updating publications database...\n")
source("R/build.R")

# Step 2: Build the site
cat("Step 2: Building Hugo site...\n")
blogdown::build_site(build_rmd = TRUE)

cat("Site build completed!\n")