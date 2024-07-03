
<!-- README.md is generated from README.Rmd. Please edit that file -->

# ecbr

<!-- badges: start -->

[![Lifecycle:
superseded](https://img.shields.io/badge/lifecycle-superseded-blue.svg)](https://lifecycle.r-lib.org/articles/stages.html#superseded)
[![R-CMD-check](https://github.com/m-muecke/ecbr/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/m-muecke/ecbr/actions/workflows/R-CMD-check.yaml)
<!-- badges: end -->

> Note this package is retired in favor of the
> [bbk](https://github.com/m-muecke/bbk) package, which provides
> additional central bank data sources.

ecbr is a minimal R client for the [ECB
API](https://data.ecb.europa.eu/help/api/overview).

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
fx_rate
#> # A tibble: 898 × 16
#>   date       key           value title description freq  currency currency_denom
#>   <date>     <chr>         <dbl> <chr> <chr>       <chr> <chr>    <chr>         
#> 1 2021-01-04 D.USD.EUR.SP…  1.23 US d… ECB refere… daily USD      EUR           
#> 2 2021-01-05 D.USD.EUR.SP…  1.23 US d… ECB refere… daily USD      EUR           
#> 3 2021-01-06 D.USD.EUR.SP…  1.23 US d… ECB refere… daily USD      EUR           
#> 4 2021-01-07 D.USD.EUR.SP…  1.23 US d… ECB refere… daily USD      EUR           
#> 5 2021-01-08 D.USD.EUR.SP…  1.23 US d… ECB refere… daily USD      EUR           
#> # ℹ 893 more rows
#> # ℹ 8 more variables: exr_type <chr>, exr_suffix <chr>, decimals <chr>,
#> #   source_agency <chr>, time_format <chr>, collection <chr>, unit_mult <chr>,
#> #   unit <chr>
```

<img src="man/figures/README-plotting-1.png" width="100%" />

## Related work

- [ecb](https://github.com/expersso/ecb): R interface to the European
  Central Bank’s Statistical Data Warehouse (SDW) API.
- [rsdmx](https://github.com/opensdmx/rsdmx): R package for reading SDMX
  data and metadata.
- [readsdmx](https://github.com/mdequeljoe/readsdmx): R package for
  reading SDMX data and metadata.
- [pdfetch](https://github.com/abielr/pdfetch): R package for
  downloading economic and financial time series from public sources.
