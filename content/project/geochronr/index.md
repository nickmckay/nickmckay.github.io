---
title: "geoChronR"
subtitle: "Age-uncertain paleoclimate data analysis in R"
excerpt: "An R package for analyzing and visualizing time-uncertain paleoclimate data with advanced age modeling, ensemble analysis, and comprehensive visualization tools."
date: 2021-03-01
author: "Nick McKay"
featured: true
draft: false
tags:
- R package
- paleoclimate
- age modeling
- uncertainty quantification
- open source
categories:
- Software
- Data Analysis
# layout options: single or single-sidebar
layout: single
links:
- icon: github
  icon_pack: fab
  name: GitHub
  url: https://github.com/nickmckay/geoChronR
- icon: globe
  icon_pack: fas
  name: Website
  url: https://nickmckay.org/GeoChronR/
- icon: file-alt
  icon_pack: fas
  name: Publication
  url: https://doi.org/10.5194/gchron-3-149-2021
---

geoChronR is a comprehensive R package designed to help paleoscientists analyze and visualize time-uncertain data. As the lead developer, I created this tool to address the fundamental challenge of working with paleoclimate records where age models carry significant uncertainty.

## Key Features

**Advanced Age Modeling**
- Generate ensemble age models that capture chronological uncertainty
- Support for multiple dating methods and constraints
- Bayesian age modeling capabilities

**Time-Uncertain Analysis**
- Correlation analysis with proper uncertainty propagation
- Regression analysis accounting for age uncertainty
- Spectral analysis on time-uncertain datasets
- Principal Component Analysis (PCA) with chronological uncertainty

**Comprehensive Visualization**
- Intuitive plotting functions for age models and ensembles
- Publication-ready figures with uncertainty bands
- Interactive visualization capabilities

## Technical Details

- **Current Version**: 1.1.16
- **R Requirements**: 3.6.0 or newer
- **License**: MIT
- **Installation**: Available on GitHub with easy installation via `remotes`

```r
install.packages("remotes")
remotes::install_github("nickmckay/geoChronR")
library(geoChronR)
```

## Impact & Recognition

Published in *Geochronology* (2021) as a peer-reviewed software paper, geoChronR has become an essential tool for the paleoclimate community. The package addresses critical methodological challenges in paleoclimate research by providing robust statistical methods for age-uncertain data analysis.

## Development Team

- **Nicholas McKay** (Author/Maintainer) - Northern Arizona University
- **Julien Emile-Geay** (Author) - University of Southern California  
- **Deborah Khider** (Author) - University of Southern California

## Citation

McKay, N. P., Emile-Geay, J., and Khider, D.: geoChronR – an R package to model, analyze, and visualize age-uncertain data, *Geochronology*, 3, 149–169, https://doi.org/10.5194/gchron-3-149-2021, 2021.