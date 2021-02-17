#### How to get catchments upstream of a point ####

# Setup
library(sf)
library(tidyverse)
library(leaflet)
library(leaflet.extras)
library(leafem)
library(data.table)
library(raster)
if(!("VicmapR" %in% installed.packages())) {
  remotes::install_github("JustinCally/VicmapR")
}
library("VicmapR")
crs <- 4283
source('rolling_join.R')
options(vicmap.base_url = "http://geofabric.bom.gov.au/simplefeatures/ahgf_shcatch/wfs")
# options(vicmap.max_geom_pred_size = 3000)

layers <- listLayers()

melbourne <- sf::st_read(system.file("shapes/melbourne.geojson", package="VicmapR"), quiet = T)
sample_point <- melbourne %>% st_centroid()
melb_bbox <- st_buffer(sample_point %>% st_transform(3111), 50000) %>% st_transform(4283)
  
catchment_sample <- vicmap_query("ahgf_shcatch:AHGFCatchment") %>% 
  filter(INTERSECTS(melb_bbox)) %>%
  collect()

# options(vicmap.base_url = "http://geofabric.bom.gov.au/simplefeatures/ahgf_shcarto/wfs")

catchment_exact <- vicmap_query("ahgf_shcatch:AHGFCatchment") %>% 
  filter(INTERSECTS(sample_point)) %>%
  collect()

catchment_start <- catchment_exact %>% 
  sf::st_drop_geometry() %>%
  select(UNIQUEID = id, 
         hydroid) %>%
  unique() 
  
catchment_lookup <- catchment_sample %>% 
  sf::st_drop_geometry() %>%
  select(hydroid,
         nextdownid) %>% 
  filter(!is.na(nextdownid)) %>%
  unique()

# Note you can add an argument j_max to limit the number of catchments upstream (e.g. only select 10)

rolling_catchments_1 <- rolling_join(x = catchment_start , 
                                          y = catchment_lookup, 
                                          by.x = "hydroid",
                                          pre.y = "nextdownid",
                                          post.y = "hydroid", 
                                          id.name = "HYDROIDID",
                                          j_max = 10, 
                                          remove_loops = T) #Function that continually joins data until exhausted

# Make into a long format
rolling_catchments_long <- data.table::melt.data.table(as.data.table(rolling_catchments_1), 
                                                       id.vars = 'UNIQUEID', 
                                                       value.name = "hydroid") %>% unique() %>% na.omit()

# Select cols
rolling_catchments_geo <- left_join(rolling_catchments_long, catchment_sample %>%
                                      select(hydroid, shape_area)) %>% 
  st_as_sf()

#### Landuese data ####


bbox <- st_bbox(melbourne %>% st_transform(3577)) %>% unname() %>% round()

raster <- raster::stack(x = paste0("/vsicurl/https://geoserver.tern.org.au/geoserver/abares/ows?",
                                    "service=WCS&version=1.0.0",
                                    "&request=GetCoverage&sourceCoverage=abares%3Aclum_50m_2018", 
                                    "&bbox=", 
                                    bbox[1], "%2C", bbox[2], "%2C", bbox[3], "%2C", bbox[4], 
                                    "&width=768&height=734&CRS=EPSG%3A3577&format=image%2Fgeotiff")) 

ex <- raster::extract(raster, melbourne)[[1]]

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


#### Plot Map ####

pal <- colorNumeric(
  palette = "Blues",
  domain = rolling_catchments_geo$shape_area)

basemap <- leaflet() %>%
  addProviderTiles("CartoDB.Positron", group = 'Default') %>%
  addProviderTiles("Esri.WorldTopoMap", group = 'Terrain') %>%
  leafem::addMouseCoordinates(epsg = crs,
                              proj4string = NULL,
                              native.crs = TRUE) %>%
  addFullscreenControl()

basemap %>% 
  leaflet::addPolygons(data = rolling_catchments_geo, 
                       fillColor = ~pal(shape_area), 
                       color = "black", 
                       weight = 0.8, 
                       fillOpacity = 0.7, 
                       group = "catchment", 
                       label = ~hydroid) %>%
  leaflet::addMarkers(data = sample_point) %>%
  addLayersControl( 
    baseGroups = c("Default", "Terrain"),
    overlayGroups = c("catchment"),
    options = layersControlOptions(collapsed = FALSE)
  )  
