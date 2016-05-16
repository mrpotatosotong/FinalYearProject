library(shiny)

shinyUI(pageWithSidebar(
  
  headerPanel("Spatial Network Analytics"),
  
  sidebarPanel(
    selectInput("dataset",
                "Choose a time:",
                choices = c("8am-9am", "9am-10am", "10am-11am", "11am-12pm"))),
  
  mainPanel(
    verbatimTextOutput("summary"),
    
    tableOutput("View")
  )
))