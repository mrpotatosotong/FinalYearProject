
# This is the user-interface definition of a Shiny web application.
# You can find out more about building applications with Shiny here:
#
# http://shiny.rstudio.com
#

#By MrPotato for FYP AY2016/2017 Semester 3 Year 3. Contact Telegram @iamttl and @ShintoSamy

library(foreach)
library(iterators)
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
  print(result)
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
                            label = "Start Time (Everyone who is at this location at this time...):",
                            choices),
                uiOutput("areaSelector"),
                selectInput("T2",
                            label = "End Time (...where did they go at that time?):",
                            choices2)
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
      tabledata1<-getSQL(c("select t1.movement_id,  t1.start_location as START_LOCATION, t1.startlong as STARTLONG, t1.startlat as STARTLAT, t2.dest_location as DEST_LOCATION, t2.destlong as DESTLONG, t2.destlat as DESTLAT, t1.count as count from
(select movement.*, coordinates.longitude as startlong, coordinates.latitude as startlat from movement,coordinates where
                           unix_start = ", input$T1, " AND
                           UNIX_END = ", input$T2," AND
                           movement.START_LOCATION = coordinates.LOCATION and
                           longitude > 0) t1
                           inner join
                           (select movement.*, coordinates.longitude as destlong, coordinates.latitude as destlat from movement,coordinates where
                           unix_start = ", input$T1, " AND
                           UNIX_END = ", input$T2," AND
                           movement.Dest_location = coordinates.LOCATION AND
                           longitude > 0) t2
                           where
                           t1.movement_id = t2.movement_id;")
                         ,TRUE)
    }else{
      tabledata1<-getSQL(c("select t1.movement_id,  t1.start_location as START_LOCATION, t1.startlong as STARTLONG, t1.startlat as STARTLAT, t2.dest_location as DEST_LOCATION, t2.destlong as DESTLONG, t2.destlat as DESTLAT, t1.count as count from
(select movement.*, coordinates.longitude as startlong, coordinates.latitude as startlat from movement,coordinates where
                           unix_start = ", input$T1, " AND
                           UNIX_END = ", input$T2," AND
                           START_LOCATION = '", input$LOC, "' AND 
                           movement.START_LOCATION = coordinates.LOCATION and
                           longitude > 0) t1
                           inner join
                           (select movement.*, coordinates.longitude as destlong, coordinates.latitude as destlat from movement,coordinates where
                           unix_start = ", input$T1, " AND
                           UNIX_END = ", input$T2," AND
                           START_LOCATION = '", input$LOC, "' AND 
                           movement.Dest_location = coordinates.LOCATION AND
                           longitude > 0) t2
                           where
                           t1.movement_id = t2.movement_id;")
                         ,TRUE)
    }
    
    ipeople <- iter(tabledata1, by = "row")
    leaflet(subzone)%>%
      addTiles() %>%
      addPolygons(color = "white")%>%
      addMarkers(data = tabledata1,~ STARTLAT,~ STARTLONG,popup = ~START_LOCATION, clusterOptions = markerClusterOptions(), icon = ~markerList["before"])%>%
      addMarkers(data = tabledata1,~ DESTLAT,~ DESTLONG,popup = ~DEST_LOCATION, clusterOptions = markerClusterOptions(), icon = ~markerList["after"])%>%
      {
        for(i in 1:nrow(tabledata1)){
          . <- addPolylines(.,data = tabledata1[i,], c(tabledata1[i,]$STARTLAT,tabledata1[i,]$DESTLAT), c(tabledata1[i,]$STARTLONG,tabledata1[i,]$DESTLONG),
                            color = "red",popup = ~count, weight = ~count*3)
        }
        return(.)
      }%>%
      #addPolylines(data = tabledata1[1:nrow(tabledata1),], c(tabledata1$STARTLAT,tabledata1$DESTLAT), c(tabledata1$STARTLONG,tabledata1$DESTLONG), color = "black", weight = 10)%>%
      addProviderTiles("Thunderforest.Landscape", group = "Topographical") %>%
      addProviderTiles("OpenStreetMap.Mapnik", group = "Road map") %>%
      addProviderTiles("Esri.WorldImagery", group = "Satellite") %>%
      addLegend(position = 'bottomright',opacity = 0.4, 
                colors = c('green','red','grey'), 
                labels = c('Starting Time','Ending Time','Screen Grey: No Destination Coordinate.'),
                title = 'Spatial network analytics')%>%
      addLayersControl(position = 'bottomright',
                       baseGroups = c("Topographical", "Road map", "Satellite"),
                       options = layersControlOptions(collapsed = FALSE))
  })
  
  
}



shinyApp(ui, server)
