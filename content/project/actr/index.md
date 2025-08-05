---
title: "actR"
subtitle: "Abrupt Change Toolkit in R"
excerpt: "An R package for detecting and analyzing abrupt changes in paleoclimate datasets with robust statistical methods and uncertainty quantification."
date: 2023-01-01
author: "Nick McKay"
featured: true
draft: false
tags:
- R package
- abrupt change
- paleoclimate
- change detection
- LinkedEarth
categories:
- Software
- Data Analysis
# layout options: single or single-sidebar
layout: single
links:
- icon: github
  icon_pack: fab
  name: GitHub
  url: https://github.com/LinkedEarth/actR
- icon: globe
  icon_pack: fas
  name: LinkedEarth
  url: https://linked.earth/actR
---

actR (Abrupt Change Toolkit in R) is an R package I'm developing to streamline abrupt change detection in paleoclimate datasets. This tool addresses the critical need for standardized, statistically robust methods to identify and analyze rapid climate transitions in the geological record.

## Key Features

**Comprehensive Change Detection**
- Single-site abrupt change detection algorithms
- Error propagation throughout the analysis workflow
- Robust null hypothesis testing framework
- Support for age-uncertain data

**Data Integration**
- Optimized for LiPD (Linked Paleo Data) format
- Flexible input handling for matrix and vector data
- Standardized data preparation with `prepareInput()`

**Statistical Rigor**
- Uncertainty propagation with `propagateUncertainty()`
- Hypothesis testing with `testNullHypothesis()`
- Multiple visualization methods via `summary()` and `plot()`

## Project Context

actR is funded by the Belmont Forum as part of the "Abrupt Changes in Climate and Ecosystems - Data & e-Infrastructure (ACCEDE)" project. This international collaboration aims to improve our understanding of rapid environmental changes through enhanced data analysis tools.

## Development Status

Currently in experimental development with basic functionality available. The package represents an active area of research in paleoclimate methodology, focusing on the detection and characterization of abrupt environmental changes.

## Installation

```R
remotes::install_github("LinkedEarth/actR")
```

## Development Team

- **Nicholas McKay** (Author, Maintainer) - Northern Arizona University
- **David Edge** - Northern Arizona University
- **Chris Hancock** - Northern Arizona University
- **Julien Emile-Geay** - University of Southern California
- **Michael Erb** - Northern Arizona University

## Research Applications

actR enables researchers to:
- Identify rapid climate transitions in proxy records
- Quantify the timing and magnitude of abrupt changes
- Assess the statistical significance of detected changes
- Compare change detection across multiple records and regions

The toolkit contributes to our understanding of climate system stability and the potential for rapid transitions in Earth's climate system.