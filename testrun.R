#### How to get catchments upstream of a point ####

# Setup
library(sf)
library(tidyverse)
library(leaflet)
library(leaflet.extras)
library(leafem)
library(data.table)
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

# catchments_union <- st_union(rolling_catchments_geo)
# 
# options(vicmap.base_url = "https://geoserver.tern.org.au/geoserver/ows")
# 
# 
# land_use <- vicmap_query("pb_clsucd9aal20190319:ckan_761be45d_59ec_4338_b933_38b4051801b0") %>%
#   # filter(BBOX(st_bbox(catchments_union))) %>%
#   collect()

library(raster)
library(sp)

crs_wgs84utm11 <- sp::CRS(SRS_string = "+init=epsg:4326")

bbox <- st_bbox(melbourne %>% st_transform(3111)) %>% unname() %>% round()

raster <- raster::raster(x = paste0("https://geoserver.tern.org.au/geoserver/abares/wms?",
                                    "service=WMS&version=1.1.0",
                                    "&request=GetMap&layers=abares%3Aclum_50m_2018", 
                                    "&bbox=", 
                                    bbox[1], "%2C", bbox[2], "%2C", bbox[3], "%2C", bbox[4], 
                                    "&width=768&height=734&srs=EPSG%3A3111&format=image%2Fgeotiff")) 


melbourne_sp <- as_Spatial(melbourne)

raster::extract(raster, melbourne  %>% st_transform(crs_wgs84utm11))

nc <- ows4R::WFSClient$new("https://geoserver.tern.org.au/geoserver/abares/wfs/clum_50m_2018", serviceVersion = "1.1.0")

nc$getCapabilities()

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
