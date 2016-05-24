
# This is the user-interface definition of a Shiny web application.
# You can find out more about building applications with Shiny here:
#
# http://shiny.rstudio.com
#

library(shiny)
library(leaflet)
library(rgdal)
library(RMySQL)

dbDisconnect(dbhandle)
#Creation of database connection
dbhandle <- dbConnect(MySQL(),dbname="test",username="root")

#Creation of URA zone overlay
subzone <- readOGR(dsn = ".", layer = "URA subzone map final", verbose = F)

#Declaration of Unix Time to Local Time conversion function
convertUnixToLocalTime <- function(unixtime){
  return(as.POSIXct(unixtime, origin="1970-01-01"))
}

#Declaration of Local Time to Unix Time conversion function
convertLocalTimetoUnix<- function(localtime){
  return(as.POSIXct(strptime(localtime, "%Y-%m-%d %H:%M:%S")))
}

#Setting up dynamic data from database for time dropdown
timequery <- dbGetQuery(dbhandle,"SELECT DISTINCT UNIX_TIME FROM starhub;")
choices <- setNames(timequery$UNIX_TIME,convertUnixToLocalTime(timequery$UNIX_TIME))

#Creation of Shiny UI Web Interface
ui <- bootstrapPage(
  tags$style(type = "text/css", "html, body {width:100%;height:100%}"),
  leafletOutput("map", width = "100%", height = "100%"),
  absolutePanel(top = 10, left = 10,
                selectInput("T1", 
                            label = "Time 1:",
                            choices)
  ),
  absolutePanel(top = 10, right  = 10,
                selectInput("T2", 
                            label = "Time 2:",
                            choices)
  )
  
)



#Creation of Server
server <- function(input, output, session) {

  #Calling server to output the map 
  output$map <- renderLeaflet({
    #Storing all the data in variable 'data' so that when the selectInput selects a timing,...
    #...it will switch to the file that shows the timing
    tabledata1<-dbGetQuery(dbhandle, paste("SELECT * FROM starhub WHERE UNIX_TIME=",input$T1))
    tabledata2<- dbGetQuery(dbhandle, paste("SELECT * FROM starhub WHERE UNIX_TIME=",input$T2))
    leaflet(subzone) %>%
      addTiles() %>% 
      addMarkers(data = tabledata1, lng = ~ LONGITUDE, lat = ~ LATITUDE, popup = ~ S_ID, clusterOptions = markerClusterOptions())%>%
      addMarkers(data = tabledata2, lng = ~ LONGITUDE, lat = ~ LATITUDE, popup = ~ S_ID, clusterOptions = markerClusterOptions())%>%
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



shinyApp(ui, server)
