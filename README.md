
<!-- README.md is generated from README.Rmd. Please edit that file -->

# ecbr

<!-- badges: start -->

[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
[![R-CMD-check](https://github.com/m-muecke/ecbr/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/m-muecke/ecbr/actions/workflows/R-CMD-check.yaml)
<!-- badges: end -->

The goal of ecbr is to provide a simple interface to the [ECB
API](https://data.ecb.europa.eu/help/api/overview). The main difference
to other packages is that it’s a modern implementation using the
[httr2](https://httr2.r-lib.org) package.

## Installation

You can install the development version of ecbr from
[GitHub](https://github.com/) with:

``` r
# install.packages("pak")
pak::pak("m-muecke/ecbr")
```

## Usage

``` r
library(ecbr)

# fetch US dollar/Euro exchange rate
fx_rate <- ecb_data("EXR", "D.USD.EUR.SP00.A", start_period = "2021-01-01")

library(ggplot2)

ggplot(fx_rate, aes(x = date, y = value)) +
  geom_line() +
  labs(x = "", y = "", title = fx_rate[1, "title"]) +
  theme_minimal()
```

<img src="man/figures/README-demo-1.png" width="100%" />

## Related work

- [ecb](https://github.com/expersso/ecb): R interface to the European
  Central Bank’s Statistical Data Warehouse (SDW) API
