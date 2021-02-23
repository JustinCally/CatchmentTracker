
<!-- README.md is generated from README.Rmd. Please edit that file -->

# CatchmentTracker

<!-- badges: start -->

<!-- badges: end -->

The goal of CatchmentTracker is to track upstream catchments from a
given point and classify the landuse of the resulting catchment and
upstream catchments. This is done through generating several WFS queries
to:

  - Catchment Data: [Bureau of Meteorology (BOM) Geofabric
    Data](http://geofabric.bom.gov.au/documentation/)  
  - Landuse Data: [Terrestrial Ecosystem Research Network’s
    Geoserver](https://geoserver.tern.org.au/geoserver/web/)

## Installation

Tthe development version from [GitHub](https://github.com/) with:

``` r
# install.packages("devtools")
devtools::install_github("JustinCally/CatchmentTracker")
```

## Example

This is a basic example which shows you how to solve a common problem:

``` r
library(CatchmentTracker)
## basic example code

latitude <- -37.25
longitude <- 145.15

df <- data.frame(long = longitude, lat = latitude)

point <- sf::st_as_sf(df, coords = c("long", "lat"), crs = 4283)

catchments <- track_catchments(point = point)

landuse_df <- landuse_extract(catchments)

knitr::kable(landuse_df)
```
