#### How to get catchments upstream of a point ####

# Setup
library(sf)
library(tidyverse)
library(leaflet)
library(leaflet.extras)
library(leafem)
library(data.table)
crs <- 4283
source('rolling_join.R')

#### Get geofabric and catchment data ####

# Specify raw file path 
# raw_data_path <- "C:/Users/callyj/OneDrive - Environment Protection Authority Victoria/WORK/repositories/blog_code/j-cally-code/_posts/2020-01-22-air-filters-in-schools/data-raw/stream_attributes_v1.1.gdb"

# You can loop in all layers
# geofabric <- lapply(as.list(geo_fabric_layers$name) , function(x) {
#   sf::st_read(raw_data_path, x) 
# })

# Save as intermediate file because it takes a long time to read in 

# Easier just to load in the terrain layer
geofabric_terrain_rds <- paste0(getwd(), "/intermediate_data/geofabric_terrain.rds")
if(!file.exists(geofabric_terrain_rds)){
  geofabric_terrain <- sf::st_read(raw_data_path, layer = "terrain_lut")
  saveRDS(geofabric_terrain, file = geofabric_terrain_rds)
} else {
  geofabric_terrain <- readRDS(geofabric_terrain_rds)
}

catchments_rds <- paste0(getwd(), "/intermediate_data/catchments.rds")

if(!file.exists(catchments_rds)){
  catchments <- dplyr::tbl(con, "ahgfcatchment") %>% 
    dplyr::mutate(geom = st_astext(geom)) %>% 
    dplyr::collect() %>% 
    sf::st_as_sf(wkt = "geom", crs = crs)
  
  saveRDS(object = catchments, file = catchments_rds)
} else {
  catchments <- readRDS(catchments_rds)
}

#### Get schools data ####
# Read in schools 
schools <- dbGetQuery(con, "SELECT *, ST_AsText(geom) as geometry FROM schools;") %>%
  select(-geom) %>%
  st_as_sf(wkt = "geometry", crs = 4283) %>% 
  mutate(UNIQUEID = 1:nrow(.)) %>% 
  filter(education_sector == "Government") %>%
  head(50) #select only 50 schools

#### Find catchments near schools ####

# Add stream details for each catchment section 
catchment_with_geofabric <- catchments %>% left_join(geofabric_terrain, by = c("segmentno" = "SEGMENTNO"))

#Schools to catchment
catchments_near_schools <- catchment_with_geofabric %>% 
  sf::st_join(schools) %>% 
  filter(!is.na(UNIQUEID))

#### Join the data through a while loop ####

catchment_start <- catchments_near_schools %>% 
  sf::st_drop_geometry() %>%
  select(UNIQUEID,
         hydroid)

catchment_lookup <- catchments %>% 
  sf::st_drop_geometry() %>%
  select(hydroid,
         nextdownid) %>% 
  filter(!is.na(nextdownid))

# Note you can add an argument j_max to limit the number of catchments upstream (e.g. only select 10)

rolling_catchments_1 <- SOC::rolling_join(x = catchment_start , 
                                          y = catchment_lookup, 
                                          by.x = "hydroid",
                                          pre.y = "nextdownid",
                                          post.y = "hydroid", 
                                          id.name = "HYDROID_ID", 
                                          j_max = 10, 
                                          remove_loops = T) #Function that continually joins data until exhausted

# Make into a long format
rolling_catchments_long <- data.table::melt.data.table(as.data.table(rolling_catchments_1), 
                                                       id.vars = 'UNIQUEID', value.name = "hydroid") %>% unique() %>% na.omit()

# Select cols
rolling_catchments_geo <- left_join(rolling_catchments_long, catchment_with_geofabric %>%
                                      select(hydroid, CATRELIEF, CONFINEMENT, CATSLOPE, CATSTORAGE)) %>%
  st_as_sf()


#### Plot Map ####

# Format map data
schools_data_map <- sf::st_transform(schools, crs) %>% 
  left_join(catchments_near_schools %>% 
              st_drop_geometry() %>% 
              select(UNIQUEID, 
                     CATSTORAGE)) %>%
  mutate(school_label = paste0(school_name, " (", school_type, ")"))

catchments_near_schools_sp <- as_Spatial(rolling_catchments_geo)

#Define Polygon palette
pal <- colorNumeric(
  palette = "Reds", reverse = F,
  domain = catchments_near_schools$CATSTORAGE)

# Define Marker colour
getColor <- function(df) {
  sapply(df$CATSTORAGE, function(CATSTORAGE) {
    if(is.na(CATSTORAGE)) {
      "gray"
    } else if(CATSTORAGE < 33) {
      "green"
    } else if(CATSTORAGE < 66) {
      "orange"
    } else {
      "red"
    } })
}

icons <- leaflet::awesomeIcons(
  icon = 'bonfire',
  iconColor = 'white',
  library = 'ion',
  markerColor = getColor(schools_data_map)
)

basemap <- leaflet() %>%
  addProviderTiles("CartoDB.Positron", group = 'Default') %>%
  addProviderTiles("Esri.WorldTopoMap", group = 'Terrain') %>%
  leafem::addMouseCoordinates(epsg = crs,
                              proj4string = NULL,
                              native.crs = TRUE) %>%
  addFullscreenControl()

basemap %>% 
  leaflet::addPolygons(data = catchments_near_schools_sp, 
                       fillColor = ~pal(CATSTORAGE), 
                       color = "black", 
                       weight = 0.2, 
                       opacity = 1, 
                       group = "catchment", 
                       label = ~CATSTORAGE) %>%
  leaflet::addAwesomeMarkers(data = schools_data_map, 
                             icon = icons,
                             group = "schools", 
                             label = ~school_label) %>%
  addLegend("bottomright", 
            pal = pal, 
            values = ~CATSTORAGE, 
            data = catchments_near_schools_sp, 
            title = "% Valley Bottoms", 
            labFormat = labelFormat(digits = 2),
            opacity = 1) %>%
  addLayersControl( 
    baseGroups = c("Default", "Terrain"),
    overlayGroups = c("catchment", "schools"),
    options = layersControlOptions(collapsed = FALSE)
  )  
