
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
devtools::install_github("JustinCally/CatchmentTracker", ref = 'master')
```

## Example

This is a basic example which shows you how to solve a common problem:

``` r
library(CatchmentTracker)
## basic example code

latitude <- -37.8107306254817
longitude <- 144.943636530752

df <- data.frame(long = longitude, lat = latitude)

point <- sf::st_as_sf(df, coords = c("long", "lat"), crs = 4283)

catchments <- track_catchments(point = point)
#> although coordinates are longitude/latitude, st_union assumes that they are planar
#> although coordinates are longitude/latitude, st_union assumes that they are planar

landuse_df <- landuse_extract(catchments)
#> although coordinates are longitude/latitude, st_union assumes that they are planar

knitr::kable(landuse_df)
```

|  ID |   Freq |  Frac |     COUNT | LU\_CODEV8 | TERTIARY\_V                                   | SECONDARY\_                             | PRIMARY\_V8                                           | CLASSES\_18 | C18\_DESCRI                                                            |
| --: | -----: | ----: | --------: | :--------- | :-------------------------------------------- | :-------------------------------------- | :---------------------------------------------------- | ----------: | :--------------------------------------------------------------------- |
| 541 | 127391 | 0.509 |   3479617 | 5.4.1      | 5.4.1 Urban residential                       | 5.4 Residential and farm infrastructure | 5 Intensive uses                                      |          15 | Urban intensive uses (5.3, 5.4, 5.4.1, 5.5, 5.6, 5.7)                  |
| 320 |  51038 | 0.204 |  75197165 | 3.2.0      | 3.2.0 Grazing modified pastures               | 3.2 Grazing modified pastures           | 3 Production from dryland agriculture and plantations |           7 | Grazing modified pastures (3.2)                                        |
| 117 |  15339 | 0.061 |  57827404 | 1.1.7      | 1.1.7 Other conserved area                    | 1.1 Nature conservation                 | 1 Conservation and natural environments               |           1 | Nature conservation (1.1)                                              |
| 542 |  15081 | 0.060 |   2754200 | 5.4.2      | 5.4.2 Rural residential with agriculture      | 5.4 Residential and farm infrastructure | 5 Intensive uses                                      |          14 | Rural residential and farm infrastructure (5.4.2, 5.4.3, 5.4.4, 5.4.5) |
| 572 |  12634 | 0.050 |   5739132 | 5.7.2      | 5.7.2 Roads                                   | 5.7 Transport and communication         | 5 Intensive uses                                      |          15 | Urban intensive uses (5.3, 5.4, 5.4.1, 5.5, 5.6, 5.7)                  |
| 114 |   7058 | 0.028 |  31666136 | 1.1.4      | 1.1.4 Natural feature protection              | 1.1 Nature conservation                 | 1 Conservation and natural environments               |           1 | Nature conservation (1.1)                                              |
| 116 |   5641 | 0.023 |  10965372 | 1.1.6      | 1.1.6 Protected landscape                     | 1.1 Nature conservation                 | 1 Conservation and natural environments               |           1 | Nature conservation (1.1)                                              |
| 552 |   5303 | 0.021 |    422289 | 5.5.2      | 5.5.2 Public services                         | 5.5 Services                            | 5 Intensive uses                                      |          15 | Urban intensive uses (5.3, 5.4, 5.4.1, 5.5, 5.6, 5.7)                  |
| 543 |   3192 | 0.013 |   3029443 | 5.4.3      | 5.4.3 Rural residential without agriculture   | 5.4 Residential and farm infrastructure | 5 Intensive uses                                      |          14 | Rural residential and farm infrastructure (5.4.2, 5.4.3, 5.4.4, 5.4.5) |
| 353 |   1286 | 0.005 |     61863 | 3.5.3      | 3.5.3 Seasonal vegetables and herbs           | 3.5 Seasonal horticulture               | 3 Production from dryland agriculture and plantations |           9 | Dryland horticulture (3.4, 3.5)                                        |
| 330 |    875 | 0.003 | 118266804 | 3.3.0      | 3.3.0 Cropping                                | 3.3 Cropping                            | 3 Production from dryland agriculture and plantations |           8 | Dryland cropping (3.3)                                                 |
| 349 |    676 | 0.003 |    215674 | 3.4.9      | 3.4.9 Grapes                                  | 3.4 Perennial horticulture              | 3 Production from dryland agriculture and plantations |           9 | Dryland horticulture (3.4, 3.5)                                        |
| 526 |    713 | 0.003 |    162317 | 5.2.6      | 5.2.6 Horse studs                             | 5.2 Intensive animal production         | 5 Intensive uses                                      |          13 | Intensive horticulture and animal production (5.1, 5.2)                |
| 530 |    638 | 0.003 |    308696 | 5.3.0      | 5.3.0 Manufacturing and industrial            | 5.3 Manufacturing and industrial        | 5 Intensive uses                                      |          15 | Urban intensive uses (5.3, 5.4, 5.4.1, 5.5, 5.6, 5.7)                  |
| 592 |    709 | 0.003 |     34682 | 5.9.2      | 5.9.2 Landfill                                | 5.9 Waste treatment and disposal        | 5 Intensive uses                                      |          16 | Mining and waste (5.8, 5.9)                                            |
| 551 |    451 | 0.002 |    272359 | 5.5.1      | 5.5.1 Commercial services                     | 5.5 Services                            | 5 Intensive uses                                      |          15 | Urban intensive uses (5.3, 5.4, 5.4.1, 5.5, 5.6, 5.7)                  |
| 553 |    416 | 0.002 |   1203574 | 5.5.3      | 5.5.3 Recreation and culture                  | 5.5 Services                            | 5 Intensive uses                                      |          15 | Urban intensive uses (5.3, 5.4, 5.4.1, 5.5, 5.6, 5.7)                  |
| 560 |    464 | 0.002 |    185907 | 5.6.0      | 5.6.0 Utilities                               | 5.6 Utilities                           | 5 Intensive uses                                      |          15 | Urban intensive uses (5.3, 5.4, 5.4.1, 5.5, 5.6, 5.7)                  |
| 130 |    261 | 0.001 | 279946807 | 1.3.0      | 1.3.0 Other minimal use                       | 1.3 Other minimal use                   | 1 Conservation and natural environments               |           3 | Other minimal use (1.3)                                                |
| 364 |    367 | 0.001 |    103824 | 3.6.4      | 3.6.4 No defined use                          | 3.6 Land in transition                  | 3 Production from dryland agriculture and plantations |          18 | Land in transition (3.6, 4.6)                                          |
| 533 |    149 | 0.001 |     26628 | 5.3.3      | 5.3.3 Major industrial complex                | 5.3 Manufacturing and industrial        | 5 Intensive uses                                      |          15 | Urban intensive uses (5.3, 5.4, 5.4.1, 5.5, 5.6, 5.7)                  |
| 622 |    268 | 0.001 |    307276 | 6.2.2      | 6.2.2 Water storage - intensive use/farm dams | 6.2 Reservoir/dam                       | 6 Water                                               |          17 | Water (6.0)                                                            |
| 511 |     95 | 0.000 |     10325 | 5.1.1      | 5.1.1 Production nurseries                    | 5.1 Intensive horticulture              | 5 Intensive uses                                      |          13 | Intensive horticulture and animal production (5.1, 5.2)                |
| 524 |     56 | 0.000 |     70160 | 5.2.4      | 5.2.4 Piggeries                               | 5.2 Intensive animal production         | 5 Intensive uses                                      |          13 | Intensive horticulture and animal production (5.1, 5.2)                |
| 531 |     58 | 0.000 |     48170 | 5.3.1      | 5.3.1 General purpose factory                 | 5.3 Manufacturing and industrial        | 5 Intensive uses                                      |          15 | Urban intensive uses (5.3, 5.4, 5.4.1, 5.5, 5.6, 5.7)                  |
| 575 |     23 | 0.000 |     74559 | 5.7.5      | 5.7.5 Navigation and communication            | 5.7 Transport and communication         | 5 Intensive uses                                      |          15 | Urban intensive uses (5.3, 5.4, 5.4.1, 5.5, 5.6, 5.7)                  |
