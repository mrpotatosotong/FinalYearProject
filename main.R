
# This is the user-interface definition of a Shiny web application.
# You can find out more about building applications with Shiny here:
#
# http://shiny.rstudio.com
#

library(shiny)
library(leaflet)
library(rgdal)
library(RMySQL)

dbhandle <- dbConnect(MySQL(),dbname="test",username="root")


subzone <- readOGR(dsn = ".", layer = "URA subzone map final", verbose = F)

#Creation of Shiny UI Web Interface
ui <- bootstrapPage(
  tags$style(type = "text/css", "html, body {width:100%;height:100%}"),
  leafletOutput("map", width = "100%", height = "100%"),
  absolutePanel(top = 10, right = 10,
                selectInput("T", 
                            label = "Time:",
                            choices = c("8:00:00AM - 8:59:59AM", "9:00:00AM - 9:59:59AM", "10:00:00AM - 10:59:59AM", "11:00:00AM - 11:59:59AM", "12:00:00PM - 12:59:59PM", 
                                        "1:00:00PM - 1:59:59PM", "2:00:00PM - 2:59:59PM", "3:00:00PM - 3:59:59PM", "4:00:00PM - 4:59:59PM", "5:00:00PM - 5:59:59PM", "6:00:00PM - 6:59:59PM",
                                        "7:00:00PM - 7:59:59PM","8:00:00PM - 8:59:59PM", "9:00:00PM - 9:59:59PM", "10:00:00PM - 10:59:59PM", "11:00:00PM - 11:59:59PM", "12:00:00AM - 12:59:59AM",
                                        "1:00:00AM - 1:59:59AM", "2:00:00AM - 2:59:59AM", "3:00:00AM - 3:59:59AM", "4:00:00AM - 4:59:59AM", "5:00:00AM - 5:59:59AM", "6:00:00AM - 6:59:59AM", 
                                        "7:00:00AM - 7:59:59AM"),
                            selected = "10:00:00AM - 10:59:59AM")
                )
  )

query <- dbSendQuery(dbhandle, "SELECT * FROM starhub;")
tabledata <- dbFetch(query)


#Creation of Server
server <- function(input, output, session) {
  
  #Calling server to output the map 
  output$map <- renderLeaflet({
    #Storing all the data in variable 'data' so that when the selectInput selects a timing,...
    #...it will switch to the file that shows the timing
    data<- switch(input$T,
                  "1:00:00AM - 1:59:59AM" = sincity1am159am,
                  "2:00:00AM - 2:59:59AM" = sincity2am259am,
                  "3:00:00AM - 3:59:59AM" = sincity3am359am,
                  "4:00:00AM - 4:59:59AM" = sincity4am459am,
                  "5:00:00AM - 5:59:59AM" = sincity5am559am,
                  "6:00:00AM - 6:59:59AM" = sincity6am659am,
                  "8:00:00AM - 8:59:59AM" = sincity8am859am,
                  "10:00:00AM - 10:59:59AM" = tabledata,
                  "11:00:00AM - 11:59:59AM" = sincity11am1159am,
                  "1:00:00PM - 1:59:59PM" = sincity1pm159pm,
                  "2:00:00PM - 2:59:59PM" = sincity2pm259pm,
                  "3:00:00PM - 3:59:59PM" = sincity3pm359pm,
                  "4:00:00PM - 4:59:59PM" = sincity4pm459pm,
                  "6:00:00PM - 6:59:59PM" = sincity6pm659pm,
                  "7:00:00PM - 7:59:59PM" = sincity7pm759pm,
                  "8:00:00PM - 8:59:59PM" = sincity8pm859pm,
                  "9:00:00PM - 9:59:59PM" = sincity9pm959pm,
                  "10:00:00PM - 10:59:59PM" = sincity10pm1059pm,
                  "11:00:00PM - 11:59:59PM" = sincity11pm1159pm,
                  "12:00:00AM - 12:59:59AM" = sincity12am1259am
                  # "1:00:00AM - 1:59:59AM" = sincity1am159am,
                  # "2:00:00AM - 2:59:59AM" = sincity2am259am,
                  # "3:00:00AM - 3:59:59AM" = sincity3am359am,
                  # "4:00:00AM - 4:59:59AM" = sincity4am459am,
                  # "5:00:00AM - 5:59:59AM" = sincity5am559am,
                  # "6:00:00AM - 6:59:59AM" = sincity6am659am,
                  # #"7:00:00AM - 7:59:59AM" = sincity7am759am,
                  # "8:00:00AM - 8:59:59AM" = sincity8am859am,
                  # #"9:00:00AM - 9:59:59AM" = sincity9am959am,
                  # "10:00:00AM - 10:59:59AM" = sincity10am1059am,
                  # "11:00:00AM - 11:59:59AM" = sincity11am1159am,
                  # #"12:00:00PM - 12:59:59PM" = sincity12pm1259pm,
                  # "1:00:00PM - 1:59:59PM" = sincity1pm159pm,
                  # "2:00:00PM - 2:59:59PM" = sincity2pm259pm,
                  # "3:00:00PM - 3:59:59PM" = sincity3pm359pm,
                  # "4:00:00PM - 4:59:59PM" = sincity4pm459pm,
                  # #"5:00:00PM - 5:59:59PM" = sincity5pm559pm,
                  # "6:00:00PM - 6:59:59PM" = sincity6pm659pm,
                  # "7:00:00PM - 7:59:59PM" = sincity7pm759pm,
                  # "8:00:00PM - 8:59:59PM" = sincity8pm859pm,
                  # "9:00:00PM - 9:59:59PM" = sincity9pm959pm,
                  # "10:00:00PM - 10:59:59PM" = sincity10pm1059pm,
                  # "11:00:00PM - 11:59:59PM" = sincity11pm1159pm,
                  # "12:00:00AM - 12:59:59AM" = sincity12am1259am
    )
    leaflet(subzone) %>%
      addTiles() %>% 
      addMarkers(data = data, lng = ~ LONGITUDE, lat = ~ LATITUDE, popup = data$S_ID, clusterOptions = markerClusterOptions())%>%
      addPolygons(color = "purple")%>%
      addProviderTiles("Thunderforest.Landscape", group = "Topographical") %>%
      addProviderTiles("OpenStreetMap.Mapnik", group = "Road map") %>%
      addProviderTiles("Esri.WorldImagery", group = "Satellite") %>%
      addLegend(position = 'bottomright',opacity = 0.4, 
                colors = 'blue', 
                labels = 'Singapore',
                title = 'Spatial network analytics')%>%
      addLayersControl(position = 'bottomright',
                       baseGroups = c("Topographical", "Road map", "Satellite"),
                       options = layersControlOptions(collapsed = FALSE))
    
  })
  
  
  
  
}

dbDisconnect(dbhandle)

shinyApp(ui, server)