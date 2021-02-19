#### How to get catchments upstream of a point ####

# Setup
library(sf)
library(tidyverse)
library(leaflet)
library(leaflet.extras)
library(leafem)
library(magrittr)

melbourne <- sf::st_read(system.file("shapes/melbourne.geojson", package="VicmapR"), quiet = T)
sample_point <- sf::st_centroid(melbourne)

data <- track_catchments(point = sample_point)

landuse <- landuse_extract(data)


#### Plot Map ####

tile <- landuse_wms(data)

pal <- colorNumeric(
  palette = "Blues",
  domain = data$nth_upstream, reverse = TRUE)

basemap <- leaflet() %>%
  addProviderTiles("CartoDB.Positron", group = 'Default') %>%
  addProviderTiles("Esri.WorldTopoMap", group = 'Terrain') %>%
  leafem::addMouseCoordinates(epsg = 4326,
                              proj4string = NULL,
                              native.crs = TRUE) %>%
  addFullscreenControl()

basemap %>% 
  leaflet::addRasterImage(tile, group = "landuse") %>%
  leaflet::addPolygons(data = data, 
                       fillColor = ~pal(nth_upstream), 
                       color = "black", 
                       weight = 0.8, 
                       fillOpacity = 0.7, 
                       group = "catchment", 
                       label = ~hydroid) %>%
  leaflet::addMarkers(data = sample_point) %>%
  addLayersControl( 
    baseGroups = c("Default", "Terrain"),
    overlayGroups = c("catchment", "landuse"),
    options = layersControlOptions(collapsed = FALSE)
  )  
