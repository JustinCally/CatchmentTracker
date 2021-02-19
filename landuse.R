#' Extract landuse for a given catchment polygon
#'
#' @param catchment_sf sf polyogn to extract landuse data for 
#' @param ... additional arguments passed to raster::extract
#'
#' @return data.frame
#' @export
landuse_extract <- function(catchment_sf, ...) {
  
  bbox <- sf::st_bbox(catchment_sf %>% 
                        sf::st_transform(3577)) %>% 
    unname() %>% 
    round()

raster <- raster::raster(x = paste0("/vsicurl/https://geoserver.tern.org.au/geoserver/abares/ows?",
                                   "service=WCS&version=1.0.0",
                                   "&request=GetCoverage&sourceCoverage=abares%3Aclum_50m_2018", 
                                   "&bbox=", 
                                   bbox[1], "%2C", bbox[2], "%2C", bbox[3], "%2C", bbox[4], 
                                   "&width=768&height=734&CRS=EPSG%3A3577&format=image%2Fgeotiff")) 

ex <- raster::extract(raster, melbourne, ...)[[1]]

land_use_lookup <- readRDS("land_use_lookup.rds")

table_data <- ex %>% 
  table() %>%
  t() %>% 
  as.data.frame(., stringsAsFactors = F) 

joined_data <- table_data %>%
  dplyr::select(ID = 2, 3) %>%
  dplyr::mutate(ID = as.integer(ID), 
                Frac = Freq/sum(.$Freq, na.rm = T)) %>% 
  dplyr::left_join(land_use_lookup, by = "ID") %>% 
  dplyr::arrange(desc(Frac))

return(joined_data)

}