#' Extract landuse for a given catchment polygon
#'
#' @param catchment_sf sf polyogn to extract landuse data for
#' @param ... additional arguments passed to raster::extract
#'
#' @return data.frame
#' @export
landuse_extract <- function(catchment_sf, ...) {

  catchment_sf <- catchment_sf %>%
    sf::st_union() %>%
    sf::st_as_sf() %>%
    sf::st_transform(3577)

  bbox <- sf::st_bbox(catchment_sf) %>%
    unname() %>%
    round()

raster <- raster::raster(x = paste0("/vsicurl/https://geoserver.tern.org.au/geoserver/abares/ows?",
                                   "service=WCS&version=1.0.0",
                                   "&request=GetCoverage&sourceCoverage=abares%3Aclum_50m_2018",
                                   "&bbox=",
                                   bbox[1], "%2C", bbox[2], "%2C", bbox[3], "%2C", bbox[4],
                                   "&width=768&height=734&CRS=EPSG%3A3577&format=image%2Fgeotiff"))

ex <- raster::extract(raster, catchment_sf, ...)[[1]]

land_use_lookup <- readRDS("land_use_lookup.rds")

table_data <- ex %>%
  table() %>%
  t() %>%
  as.data.frame(., stringsAsFactors = F)

joined_data <- table_data %>%
  dplyr::select(ID = 2, 3) %>%
  dplyr::mutate(ID = as.integer(ID),
                Frac = round(Freq/sum(.$Freq, na.rm = T), digits = 3)) %>%
  dplyr::left_join(land_use_lookup, by = "ID") %>%
  dplyr::arrange(dplyr::desc(Frac))

return(joined_data)

}

#' Get Landuse Tiles
#'
#' @param catchment_sf sf polygon of catchments to have landuse extracted for them
#'
#' @return raster
#' @export
landuse_wms <- function(catchment_sf) {

  catchment_sf <- catchment_sf %>%
    sf::st_transform(3577)

  bbox <- sf::st_bbox(catchment_sf) %>%
    unname() %>%
    round()

  url <-  paste0("/vsicurl/https://geoserver.tern.org.au/geoserver/abares/wms?",
                 "service=WMS&version=1.1.0",
                  "&request=GetMap&layers=abares%3Aclum_50m_2018",
                   "&bbox=",
                   bbox[1], "%2C", bbox[2], "%2C", bbox[3], "%2C", bbox[4],
                  "&width=768&height=734&SRS=EPSG%3A3577&format=image%2Fgeotiff")

  raster <- raster::raster(url) %>% raster::mask(catchment_sf)

  return(raster)

}

#' Landuse lookup codes
#'
#' @name land_use_lookup
#' @docType data
#' @references \url{https://data.gov.au/dataset/ds-dga-8d5d0a09-d100-407b-b326-6e775025feee/details?q=land%20use%20catchment}
#' @keywords data
"land_use_lookup"
