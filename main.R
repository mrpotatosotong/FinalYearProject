
# This is the user-interface definition of a Shiny web application.
# You can find out more about building applications with Shiny here:
#
# http://shiny.rstudio.com
#

library(shiny)
library(shinyBS)
library(leaflet)
library(rgdal)
library(RMySQL)

#Function GetQuery with SQL and parameter inputs
getSQL <- function(SQL, parameter = FALSE){
  #Creation of database connection
  dbhandle <- dbConnect(MySQL(),dbname="test",username="root")
  if(parameter != FALSE){
    print(parameter)
    print(sprintf(SQL,parameter))
    SQL <- sprintf(SQL,parameter)
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
timequery <- getSQL("SELECT UNIX_TIME, from_unixtime(UNIX_TIME, '%Y-%m-%d %H:%i') AS TS FROM STARHUB s WHERE minute(from_unixtime(UNIX_TIME, '%Y-%m-%d %H:%i')) % 5 = 0 GROUP BY TS ORDER BY TS;")
choices <- setNames(timequery$UNIX_TIME,timequery$TS)

detect <- function(timing,timing2){
  if(timing <= timing2){
    timing = timing2
  }
  return(getSQL("SELECT * FROM starhub WHERE UNIX_TIME=%s;",timing))
}


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
                            choices,selected = tail(choices,1))
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
  
  #Calling server to output the map 
  output$map <- renderLeaflet({
    #Storing all the data in variable 'data' so that when the selectInput selects a timing,...
    #...it will switch to the file that shows the timing
    tabledata1<-getSQL("SELECT * FROM starhub WHERE UNIX_TIME=%s;",input$T1)
    print(tabledata1)
    tabledata2<- detect(input$T2,input$T1)
    leaflet(subzone) %>%
      addTiles() %>% 
      
      addMarkers(data = tabledata1, lng = ~ LONGITUDE, lat = ~ LATITUDE, popup = ~ S_ID, clusterOptions = markerClusterOptions(), icon = ~markerList["before"])%>%
      addMarkers(data = tabledata2, lng = ~ LONGITUDE, lat = ~ LATITUDE, popup = ~ S_ID, clusterOptions = markerClusterOptions(), icon = ~markerList["after"])%>%
      addPolygons(color = "purple")%>%
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
