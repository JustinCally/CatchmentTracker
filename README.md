
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
#> although coordinates are longitude/latitude, st_union assumes that they are planar
#> although coordinates are longitude/latitude, st_union assumes that they are planar

landuse_df <- landuse_extract(catchments)
#> although coordinates are longitude/latitude, st_union assumes that they are planar

knitr::kable(landuse_df)
```

|  ID |   Freq |  Frac |     COUNT | LU\_CODEV8 | TERTIARY\_V                                 | SECONDARY\_                             | PRIMARY\_V8                                           | CLASSES\_18 | C18\_DESCRI                                                            |
| --: | -----: | ----: | --------: | :--------- | :------------------------------------------ | :-------------------------------------- | :---------------------------------------------------- | ----------: | :--------------------------------------------------------------------- |
| 320 | 182770 | 0.753 |  75197165 | 3.2.0      | 3.2.0 Grazing modified pastures             | 3.2 Grazing modified pastures           | 3 Production from dryland agriculture and plantations |           7 | Grazing modified pastures (3.2)                                        |
| 543 |  32465 | 0.134 |   3029443 | 5.4.3      | 5.4.3 Rural residential without agriculture | 5.4 Residential and farm infrastructure | 5 Intensive uses                                      |          14 | Rural residential and farm infrastructure (5.4.2, 5.4.3, 5.4.4, 5.4.5) |
| 542 |  20446 | 0.084 |   2754200 | 5.4.2      | 5.4.2 Rural residential with agriculture    | 5.4 Residential and farm infrastructure | 5 Intensive uses                                      |          14 | Rural residential and farm infrastructure (5.4.2, 5.4.3, 5.4.4, 5.4.5) |
| 572 |   5610 | 0.023 |   5739132 | 5.7.2      | 5.7.2 Roads                                 | 5.7 Transport and communication         | 5 Intensive uses                                      |          15 | Urban intensive uses (5.3, 5.4, 5.4.1, 5.5, 5.6, 5.7)                  |
| 330 |   1001 | 0.004 | 118266804 | 3.3.0      | 3.3.0 Cropping                              | 3.3 Cropping                            | 3 Production from dryland agriculture and plantations |           8 | Dryland cropping (3.3)                                                 |
| 111 |    391 | 0.002 |  62723741 | 1.1.1      | 1.1.1 Strict nature reserves                | 1.1 Nature conservation                 | 1 Conservation and natural environments               |           1 | Nature conservation (1.1)                                              |
