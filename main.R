
# This is the user-interface definition of a Shiny web application.
# You can find out more about building applications with Shiny here:
#
# http://shiny.rstudio.com
#


library(shiny)
library(leaflet)
library(rgdal)
library(RMySQL)

#Function GetQuery with SQL and parameter inputs
getSQL <- function(SQL, parameter = FALSE){
  #Creation of database connection
  dbhandle <- dbConnect(MySQL(),dbname="test",username="root", password="VFR4cde3")
  print(parameter)
  print(paste(SQL,collapse = ""))
  if(any(parameter != FALSE)){
    SQL <- paste(SQL,collapse = "")
  }
  result <- dbGetQuery(dbhandle, SQL)
  cons <- dbListConnections(MySQL())
  for(con in cons)
    dbDisconnect(con)
  return(result)
}

#Creation of URA zone overlay
subzone <- readOGR(dsn = ".", layer = "URA subzone map final", verbose = F)

#Declaration of Unix Time to Local Time conversion function
convertUnixToLocalTime <- function(unixtime){
  return(as.POSIXct(unixtime, origin="1970-01-01"))
}

#Declaration of Local Time to Unix Time conversion function
convertLocalTimetoUnix<- function(localtime,format = "%Y-%m-%d %H:%M:%S"){
  return(as.POSIXct(strptime(localtime, format)))
}

#Setting up data binding from database for time dropdown
timequery <- getSQL("SELECT UNIX_START, from_unixtime(UNIX_START+28800, '%Y-%m-%d %H:%i') AS TS FROM MOVEMENT s WHERE hour(from_unixtime(UNIX_START, '%Y-%m-%d %H:%i')) % 1 = 0 GROUP BY TS ORDER BY TS;")
timequery2 <- getSQL("SELECT UNIX_END, from_unixtime(UNIX_END+28800, '%Y-%m-%d %H:%i') AS TS FROM MOVEMENT s WHERE hour(from_unixtime(UNIX_END, '%Y-%m-%d %H:%i')) % 1 = 0 GROUP BY TS ORDER BY TS;")

choices <- setNames(timequery$UNIX_START,timequery$TS)
choices2 <- setNames(timequery2$UNIX_END,timequery2$TS)

#Creation of Shiny UI Web Interface
ui <- bootstrapPage(
  tags$style(type = "text/css", "html, body {width:100%;height:100%}"),
  leafletOutput("map", width = "100%", height = "100%"),
  absolutePanel(top = 10, right = 10,
                selectInput("T1",
                            label = "Time 1:",
                            choices),
                selectInput("T2",
                            label = "Time 2:",
                            choices2),
                uiOutput("areaSelector")
  )
)

markerList <- iconList(
  before = makeIcon(
    iconUrl = "http://leafletjs.com/docs/images/leaf-green.png",
    iconWidth = 38, iconHeight = 95,
    iconAnchorX = 22, iconAnchorY = 94,
    shadowUrl = "http://leafletjs.com/docs/images/leaf-shadow.png",
    shadowWidth = 50, shadowHeight = 64,
    shadowAnchorX = 4, shadowAnchorY = 62
  ),
  after = makeIcon(
    iconUrl = "http://leafletjs.com/docs/images/leaf-red.png",
    iconWidth = 38, iconHeight = 95,
    iconAnchorX = 22, iconAnchorY = 94,
    shadowUrl = "http://leafletjs.com/docs/images/leaf-shadow.png",
    shadowWidth = 50, shadowHeight = 64,
    shadowAnchorX = 4, shadowAnchorY = 62
  )
)
#Creation of Server
server <- function(input, output, session) {
  
  output$areaSelector <- renderUI({
    locationquery <- getSQL(c("SELECT DISTINCT START_LOCATION FROM MOVEMENT WHERE unix_start = ", input$T1, " AND 
                         UNIX_END = ", input$T2, ";"),TRUE)
    choicesloc <- setNames(locationquery$START_LOCATION,locationquery$START_LOCATION)
    selectInput("LOC",
                label = "Starting Location:",
                choicesloc)
  })
  #Calling server to output the map 
  output$map <- renderLeaflet({
    #Storing all the data in variable 'data' so that when the selectInput selects a timing,...
    #...it will switch to the file that shows the timing
    if(is.null(input$LOC)){
      tabledata1<-getSQL(c("SELECT LONGITUDE, LATITUDE, START_LOCATION FROM MOVEMENT, coordinates WHERE 
                         movement.START_LOCATION = coordinates.LOCATION and 
                           unix_start = ", input$T1, " AND 
                           UNIX_END = ", input$T2, " AND 
                           LONGITUDE > 0;")
                         ,TRUE)
      tabledata2<-getSQL(c("SELECT LONGITUDE, LATITUDE, DEST_LOCATION FROM MOVEMENT, coordinates WHERE 
                           movement.DEST_LOCATION = coordinates.LOCATION and 
                           unix_start = ", input$T1, " AND 
                           UNIX_END = ", input$T2," AND 
                           LONGITUDE > 0;"),TRUE)
    }else{
      tabledata1<-getSQL(c("SELECT LONGITUDE, LATITUDE, START_LOCATION FROM MOVEMENT, coordinates WHERE 
                         movement.START_LOCATION = coordinates.LOCATION and 
                           unix_start = ", input$T1, " AND 
                           UNIX_END = ", input$T2, " AND
                           START_LOCATION = '", input$LOC, "' AND 
                           LONGITUDE > 0;")
                         ,TRUE)
      tabledata2<-getSQL(c("SELECT LONGITUDE, LATITUDE, DEST_LOCATION FROM MOVEMENT, coordinates WHERE 
                           movement.DEST_LOCATION = coordinates.LOCATION and 
                           unix_start = ", input$T1, " AND 
                           UNIX_END = ", input$T2," AND 
                           START_LOCATION = '", input$LOC, "' AND 
                           LONGITUDE > 0;"),TRUE)
    }

                       
    leaflet(subzone) %>%
      addTiles() %>% 
      addMarkers(data = tabledata1,~ LATITUDE,~ LONGITUDE,popup = ~START_LOCATION, clusterOptions = markerClusterOptions(), icon = ~markerList["before"])%>%
      addMarkers(data = tabledata2,~ LATITUDE,~ LONGITUDE,popup = ~DEST_LOCATION, clusterOptions = markerClusterOptions(), icon = ~markerList["after"])%>%
      addPolygons(color = "white")%>%
      addProviderTiles("Thunderforest.Landscape", group = "Topographical") %>%
      addProviderTiles("OpenStreetMap.Mapnik", group = "Road map") %>%
      addProviderTiles("Esri.WorldImagery", group = "Satellite") %>%
      addLegend(position = 'bottomright',opacity = 0.4, 
                colors = c('green','red'), 
                labels = c('Starting Time','Ending Time'),
                title = 'Spatial network analytics')%>%
      addLayersControl(position = 'bottomright',
                       baseGroups = c("Topographical", "Road map", "Satellite"),
                       options = layersControlOptions(collapsed = FALSE))
  })
  
  
}



shinyApp(ui, server)
