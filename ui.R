# ui for word_game
# see https://stackoverflow.com/questions/35599470/shiny-dashboard-display-a-dedicated-loading-page-until-initial-loading-of
library(shinyjs)

ui <- fluidPage(
  useShinyjs(),
  div(
    id="start_page",
    includeHTML("opening_text.txt"),
    actionButton("start", "Start!", 
      width="350px", style="color: #fff; background-color: #E04A4A;"),
    br(),
    br()
  ),
  hidden(
    div(
      id = "loading_page",
      h1("Loading"),
      em("This may take a few seconds")
    )
  ),
  hidden(
    div(
      id = "game",
      htmlOutput("mid_text"),
	  uiOutput("b1"),
      br(),
      uiOutput("b2"),
      br(),
      uiOutput("b3"),
      br(),
      br(),
      uiOutput("unknown"),
      br(),
      htmlOutput("progress_tracker")
    )
  ),
  hidden(
    div(
      id = "save_page",
      h1("Saving...")
    )
  ),
  hidden(
    div(
      id = "end_page",
      htmlOutput("end_text"),
      actionButton("restart", "Click here to restart (with new words)", 
        width="350px", style="color: #fff; background-color: #E04A4A;"
      ),
      br(), br(),
      p("Here are the results that you added:"), 
      br(), 
      plotOutput("final_results", width="350px"),
      br(),
      actionButton("end", "click here to exit", 
        width="350px", style="color: #fff; background-color: #616161;"
      )
    )
  )
)



