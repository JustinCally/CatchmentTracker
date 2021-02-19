#
# This is a Shiny web application. You can run the application by clicking
# the 'Run App' button above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)

# Define UI for application that draws a histogram
ui <- fluidPage(

    # Application title
    titlePanel("Sampling Site Data Input"),

    # Sidebar with a slider input for number of bins 
    sidebarLayout(
        sidebarPanel(
            numericInput("longitude",
                        "Longitude:",
                        min = 110,
                        max = 162, value = 147), 
            numericInput("latitude", 
                         "Latitude", 
                         min = -45, 
                         max = -8, value = -37), 
            textInput("name", 
                      "Name of point"), 
            actionButton("submit", "Submit")
        ),

        # Show a plot of the generated distribution
        mainPanel(
           leafletOutput("map"), 
           DT::DTOutput("table")
        )
    )
)

# Define server logic required to draw a histogram
server <- function(input, output) {
    
    observeEvent(input$submit, {
        
        df <- data.frame(Name = input$name, long = input$longitude, lat = input$latitude)
        
        point <- sf::st_as_sf(df, coords = c("long", "lat"), crs = 4283)
        
        catchments <- track_catchments(point = point)
        
        landuse_df <- landuse_extract(catchments)
        
        landuse_tile <- landuse_wms(catchments)

    output$map <- leaflet::renderLeaflet({
        
        pal <- colorNumeric(
            palette = "Blues",
            domain = landuse_df$nth_upstream, reverse = TRUE)
        
        basemap <- leaflet() %>%
            addProviderTiles("CartoDB.Positron", group = 'Default') %>%
            addProviderTiles("Esri.WorldTopoMap", group = 'Terrain') %>%
            leafem::addMouseCoordinates(epsg = 4326,
                                        proj4string = NULL,
                                        native.crs = TRUE) %>%
            addFullscreenControl()
        
        basemap %>% 
            leaflet::addRasterImage(landuse_tile, group = "landuse") %>%
            leaflet::addPolygons(data = catchments, 
                                 fillColor = ~pal(nth_upstream), 
                                 color = "black", 
                                 weight = 0.8, 
                                 fillOpacity = 0.7, 
                                 group = "catchment", 
                                 label = ~hydroid) %>%
            leaflet::addMarkers(data = point, label = ~Name) %>%
            addLayersControl( 
                baseGroups = c("Default", "Terrain"),
                overlayGroups = c("catchment", "landuse"),
                options = layersControlOptions(collapsed = FALSE)
            )  
        
    })
    
    output$table <- DT::renderDataTable(landuse_df)
    
    })
}

# Run the application 
shinyApp(ui = ui, server = server)
