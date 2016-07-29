
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
timequery <- getSQL("SELECT * FROM TIMEDROPDOWNLIST;")
timequery2 <- getSQL("SELECT * FROM TIMEDROPDOWNLIST;")
locationquery <- getSQL("SELECT LOCATION FROM COORDINATES;")
choicesloc <- setNames(locationquery$LOCATION,locationquery$LOCATION)
choices <- setNames(timequery$UNIX_TIME,timequery$READ_TIME)
choices2 <- setNames(timequery$UNIX_TIME,timequery$READ_TIME)

#Creation of Shiny UI Web Interface
ui <- bootstrapPage(
  tags$style(type = "text/css", "html, body {width:100%;height:100%}"),
  leafletOutput("map", width = "100%", height = "100%"),
  absolutePanel(top = 10, right = 10,
                selectInput("T1",
                            label = "Start Time (Where everyone at this time?):",
                            choices,selected = '1440000000'),
                #uiOutput("areaSelector"),
                selectInput("LOC",
                            label = "At this location?:",
                            choicesloc,selected = 'Admiralty'),
                selectInput("T2",
                            label = "Will be at this time?:",
                            choices2,selected = '1440003600')
  )
)

markerList <- iconList(
  before = makeIcon(
    iconUrl = "images/starhubgreen.png",
    iconWidth = 45, iconHeight = 59
  ),
  after = makeIcon(
    iconUrl = "images/starhubred.png",
    iconWidth = 45, iconHeight = 59
  )
)
#Creation of Server
server <- function(input, output, session) {
  
  #output$areaSelector <- renderUI({})
  
  
  #Calling server to output the map 
  output$map <- renderLeaflet({
    #Storing all the data in variable 'data' so that when the selectInput selects a timing,...
    #...it will switch to the file that shows the timing
    if(input$LOC == '.No Location' && input$T2 == '0'){
      tabledata1 <- getSQL(c("SELECT START_LOCATION, LONGITUDE AS STARTLONG, LATITUDE AS STARTLAT FROM MOVEMENT2, COORDINATES WHERE START_LOCATION = LOCATION AND UNIX_START = ",input$T1," GROUP BY START_LOCATION"),TRUE)
    }
    else if(input$LOC == '.No Location'){
      tabledata1<-getSQL(c("select t1.movement_id,  t1.start_location as START_LOCATION, t1.startlong as STARTLONG, t1.startlat as STARTLAT, t2.dest_location as DEST_LOCATION, t2.destlong as DESTLONG, t2.destlat as DESTLAT, t1.count as count from
(select m.*, coordinates.longitude as startlong, coordinates.latitude as startlat from movement2 m,coordinates where
                           unix_start = ", input$T1, " AND
                           UNIX_END = ", input$T2," AND
                           m.START_LOCATION = coordinates.LOCATION and
                           longitude > 0) t1
                           inner join
                           (select m.*, coordinates.longitude as destlong, coordinates.latitude as destlat from movement2 m,coordinates where
                           unix_start = ", input$T1, " AND
                           UNIX_END = ", input$T2," AND
                           m.Dest_location = coordinates.LOCATION AND
                           longitude > 0) t2
                           where
                           t1.movement_id = t2.movement_id;")
                         ,TRUE)
    }else{
      tabledata1<-getSQL(c("select t1.movement_id,  t1.start_location as START_LOCATION, t1.startlong as STARTLONG, t1.startlat as STARTLAT, t2.dest_location as DEST_LOCATION, t2.destlong as DESTLONG, t2.destlat as DESTLAT, t1.count as count from
(select m.*, coordinates.longitude as startlong, coordinates.latitude as startlat from movement2 m,coordinates where
                           unix_start = ", input$T1, " AND
                           UNIX_END = ", input$T2," AND
                           START_LOCATION = '", input$LOC, "' AND 
                           m.START_LOCATION = coordinates.LOCATION and
                           longitude > 0) t1
                           inner join
                           (select m.*, coordinates.longitude as destlong, coordinates.latitude as destlat from movement2 m,coordinates where
                           unix_start = ", input$T1, " AND
                           UNIX_END = ", input$T2," AND
                           START_LOCATION = '", input$LOC, "' AND 
                           m.Dest_location = coordinates.LOCATION AND
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
      addMarkers(data = tabledata1,~ DESTLAT,~ DESTLONG,popup = paste(sep="</br>",tabledata1$START_LOCATION,tabledata1$DEST_LOCATION,tabledata1$count), clusterOptions = markerClusterOptions(), icon = ~markerList["after"])%>%
      
      {
        for(i in 1:nrow(tabledata1)){
          . <- addPolylines(.,data = tabledata1[i,], c(tabledata1[i,]$STARTLAT,tabledata1[i,]$DESTLAT), c(tabledata1[i,]$STARTLONG,tabledata1[i,]$DESTLONG),
                            color = "green",popup = ~count, weight = ~count*3)
        }
        return(.)
        for(i in 1:nrow(tabledata1)){
          content = paste(sep="</br>",tabledata1[i,]$START_LOCATION,tabledata1[i,]$DEST_LOCATION,tabledata1[i,]$count)
          . <-  addPopups(.,tabledata1[i,]$DESTLAT, tabledata1[i,]$DESTLONG, content,
                          options = popupOptions(closeButton = TRUE))
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
