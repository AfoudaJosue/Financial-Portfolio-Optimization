# Importation des librairies nécessaires
library(tidyverse)
library(rvest)
library(shiny)
library(shinythemes)
library(DT)
library(zoo)
library(xts)
library(quantmod)
library(PerformanceAnalytics)
library(tseries)
library(fontawesome)
linebreaks <- function(n){HTML(strrep(br(), n))}

# Importation des dataframes des noms des actions
dax_ticker_name <- read_csv("./data/dax_tickers_names.csv")
nikkei_ticker_name <- read_csv("./data/nikkei_tickers_names.csv")
sp500_ticker_name <- read_csv("./data/sp500_tickers_names.csv")
cac40_ticker_name <- read_csv("./data/cac40_tickers_names.csv")
ftse100_ticker_name <- read_csv("./data/ftse100_tickers_names.csv")

# Interface Utilisateur (Frontend)

ui <- shinyUI(fluidPage(
  theme = shinytheme("flatly"),
  # Mettre le titre en couleur
  h1("R SHINY WEB APP FOR FINANCIAL PORTFOLIO ANALYSIS",
     style = "font-family: 'Impact'; color: red; font-size: 32px;"),
  tags$a("Encourage me to further improve this app",
         href='https://www.paypal.me/aaajosue'),
  linebreaks(1),
  tags$a("Josué AFOUDA",href='https://www.linkedin.com/in/josu%C3%A9-afouda/'),

  sidebarLayout(
    sidebarPanel(
        selectInput(
            'indice',
            'Choose a stock market index',
            choices = c('France (CAC 40)',
                        'USA (S&P 500)',
                        'Germany (DAX)',
                        'England (FTSE 100)',
                        'Japan (Nikkei 225)')
            ),
        numericInput("numInputs", "Number of Assets in Portfolio", 1, max = 10),

      # dynamic inputs
      uiOutput("inputGroup"),
      uiOutput("inputWeights"),

      dateRangeInput('period', 'Date range:',
                     '2015-01-01', '2020-12-31'),

      selectInput("rebalance",
                  'Rebalance on:',
                  choices = c("None",
                              "Annualy" = "years",
                              "Quartely" = "quarters",
                              "Monthly" = "months",
                              "Weekly" = "weeks",
                              "Daily" = "days")),

      actionButton("go", icon = icon("linux"), "Submit"),

      helpText(' Subsequent figures will be drawn in an nr-by-nc array'),
      numericInput('nl', 'Select nr:', 1, min = 1, step = 1),
      numericInput('nc', 'Select nc:', 1, min = 1, step = 1)

    ),
    # show dynamic input values
    mainPanel(textOutput("message"), textOutput("inputValues"),
              textOutput("message2"), textOutput("inputValues2"),
              tabsetPanel(

                # Création des onglets et sous-onglets
                tabPanel('Prices',
                         tabsetPanel(
                           tabPanel('Data of Prices',
                                    icon = icon("table"),
                                    DTOutput('df'),
                                    downloadButton('save_price_data', label = 'Save to CSV :')),
                           tabPanel('Prices Statistics', verbatimTextOutput("prices_stats")),
                           tabPanel('Histograms of Prices', plotOutput('prices_hists', 1000, 650)),
                           tabPanel('Plot of Prices', plotOutput('plot', 1000, 650)))),

                tabPanel('Returns',
                         tabsetPanel(
                           tabPanel("Data of Returns",
                                    DTOutput('returns'),
                                    downloadButton('save_return_data', label = 'Save to CSV :')),
                           tabPanel('Returns Statistics', verbatimTextOutput("returns_stats")),
                           tabPanel('Hists of Returns', plotOutput('returns_hists', 1000, 650)),

                           tabPanel('Plot of Returns', plotOutput('plot_returns', 1000, 650)),
                           tabPanel('Beginning Of Period ', plotOutput('bop', 1000, 650)),
                           tabPanel('End of Period ', plotOutput('eop', 1000, 650)))),

                tabPanel('Aggregated Returns',
                         tabsetPanel(
                           tabPanel('Mean Aggregated Returns',
                                    selectInput('time_per',
                                                'From Daily Returns to:',
                                                choices = c('Montly Returns',
                                                            'Weekly Returns',
                                                            'Quarterly Returns',
                                                            'Yearly Returns')),

                                    DTOutput('aggregated_returns'),
                                    downloadButton('save_return_agg', label = 'Save to CSV :')),
                           tabPanel('Aggregated Returns Stats', verbatimTextOutput("agg_returns_stats")),
                           tabPanel('Aggregatd Returns Plots', plotOutput('plot_agg_returns', 1000, 650))
                         )),

                tabPanel('Analyzing performance',
                         tabsetPanel(
                           tabPanel('Correlation', plotOutput('returns_cor', 1000, 650)),

                           tabPanel('Rolling annualized mean',
                                    numericInput('Width', 'length of the window (in months):', 12, min = 1, step = 1),
                                    plotOutput('rolling_mean', 1000, 650)),
                           tabPanel('Rolling annualized Standard Deviation',
                                    plotOutput('rolling_std', 1000, 650)),
                           tabPanel('Rolling annualized Sharpe Ratio',
                                    plotOutput('rolling_sharpe', 1000, 650)),
                           tabPanel('Drawdowns',
                                    plotOutput('drawdown', 1000, 650))
                         )),

                ####ONGLET PORTOFOLIO OPTIMIZATION##############
                tabPanel('Portfolio Optimization',
                         tabsetPanel(
                           tabPanel('Mean-Variance Efficient',
                                    tabsetPanel(
                                      tabPanel('Results', verbatimTextOutput("opt1_print")),
                                      tabPanel('Visualization', plotOutput('opt1_weights', 1000, 650)))),

                           tabPanel('Imposing Constraints',
                                    tabsetPanel(
                                      tabPanel('Results', sliderInput('max_w', 'Max weigh:', 0.5, min = 0.05, max = 1.0), verbatimTextOutput("opt2_print")),
                                      tabPanel('Visualization', plotOutput('opt2_weights', 1000, 650)))),

                           tabPanel('Split-Sample evaluation',
                                    tabsetPanel(
                                      tabPanel('Estimation Sample',
                                               dateRangeInput('window_estim', 'Date range for Estimation Sample:', '2015-01-01', '2020-12-31'),
                                               verbatimTextOutput("opt3_print")),
                                      tabPanel('Evaluation Sample',
                                               dateRangeInput('window_eval', 'Date range for Evaluation Sample:', '2015-01-01', '2020-12-31'),
                                               verbatimTextOutput("opt4_print")),
                                      tabPanel('Visualization', plotOutput('opt3_weights', 1000, 650))))


                         ))
              )
    )
  )
))

################################## SERVER (BACKEND) ################################################################################"
server <- shinyServer(function(input, output) {

    # Variable réactive qui indique les différents marchés boursiers
    market <- reactive({
        if (input$indice == 'France (CAC 40)') {
            cac40_ticker_name$NameOfStock
        } else if (input$indice == 'England (FTSE 100)') {
            ftse100_ticker_name$NameOfStock
        } else if (input$indice == 'Japan (Nikkei 225)') {
            nikkei_ticker_name$NameOfStock
        } else if (input$indice == 'Germany (DAX)') {
            dax_ticker_name$NameOfStock
        } else {
            sp500_ticker_name$NameOfStock
        }
    })



  # observe changes in "numInputs", and create corresponding number of inputs
  observeEvent(input$numInputs, {
    output$inputGroup = renderUI({
      input_list <- lapply(1:input$numInputs, function(i) {
        # for each dynamically generated input, give a different name
        inputName <- paste("Asset ", i, sep = "")
        selectInput(inputName, inputName, choices = market())
      })
      do.call(tagList, input_list)
    })
  })

  ###################
  observeEvent(input$numInputs, {
    output$inputWeights = renderUI({
      input_list_weight <- lapply(1:input$numInputs, function(i) {
        # for each dynamically generated input, give a different name
        inputWeight <- paste("Weight ", i, sep = "")
        sliderInput(inputWeight, inputWeight, 0.01, min = 0.0, max = 1.0)
      })
      do.call(tagList, input_list_weight)
    })
  })
  #####################

  # Affichages des actifs choisis par l'utilisateur
  observeEvent(input$go, {
    output$message <- renderText({
      print('Your portfolio consists of the following assets:')
    })
  })

  # Variable reactive qui enregistre les symboles
  tickers <- reactive({

    paste(lapply(1:input$numInputs, function(i) {
      inputName <- paste("Asset ", i, sep = "")
      #input[[inputName]]
      str_split(input[[inputName]], pattern = ",")[[1]][2]
    }))

  })

  observeEvent(input$go, {
    output$inputValues <- renderText({

      tickers()

    })
  })

  ########################################################################
  observeEvent(input$go, {
    output$message2 <- renderText({
      print('Check that the sum of the weights is exactly equal to 1. The respective weights of these assets are:')
    })
  })

  # Variable reactive qui enregistre les poids des actifs
  num_weights <- reactive({

    paste(lapply(1:input$numInputs, function(i) {
      inputWeight <- paste("Weight ", i, sep = "")
      #sliderInput(inputWeight, inputWeight, 0.1, min = 0.05, max = 1.0)
      input[[inputWeight]]
    }))

  })

  observeEvent(input$go, {
    output$inputValues2 <- renderText({

      num_weights()

    })
  })

  #######################################################################


  # Variable reactive des prix de cloture
  close_price_df <- reactive({

    stocks <- new.env()
    getSymbols(tickers(),
               env = stocks,
               from = as.Date(input$period[1]),
               to = as.Date(input$period[2]))
    do.call(merge, lapply(stocks, Cl))

  })

  observeEvent(input$go, {
    output$df <- renderDT({

      datatable(close_price_df(), rownames = FALSE, filter = 'top', style = 'bootstrap')

    })
  })

  output$save_price_data <- downloadHandler(
    filename <- function() {
      paste("price_data_", Sys.Date(), ".csv", sep=",")
    },
    content <- function(file) {
      write.csv(close_price_df(), file)
    }
  )

  observeEvent(input$go, {
    output$prices_stats <- renderPrint({

      summary(close_price_df())

    })
  })


  # Histogrammes des prix de clotures
  observeEvent(input$go, {
    output$prices_hists <- renderPlot({
      par(mfrow = c(input$nl, input$nc))

      for (i in 1:input$numInputs) {
        chart.Histogram(close_price_df()[, i],
                        xlab = 'Closing Prices')
      }

    })
  })

  observeEvent(input$go, {
    output$plot <- renderPlot({

      plot.zoo(close_price_df(), main = 'Closing Stocks Prices',
               col = 1:input$numInputs)
    })
  })

  # Rendements journaliers des stocks
  stocks_returns <- reactive({

    Return.calculate(close_price_df())[-1]

  })

  output$save_return_data <- downloadHandler(
    filename <- function() {
      paste("return_data_", Sys.Date(), ".csv", sep=",")
    },
    content <- function(file) {
      write.csv(stocks_returns(), file)
    }
  )

  # Rendements journaliers du Portefeuille
  pf <- reactive({

    if (input$rebalance == "None") {
      Return.portfolio(stocks_returns(),
                       weights = as.numeric(num_weights()),
                       rebalance_on = NA,
                       verbose = TRUE)
    } else {
      Return.portfolio(stocks_returns(),
                       weights = as.numeric(num_weights()),
                       rebalance_on = input$rebalance,
                       verbose = TRUE)
    }

  })

  # Fusion des rendements des stocks et du portefuille
  returns_df <- reactive({

    merge(stocks_returns(), pf()$returns)

  })

  # Rendements des actions et du portefeuille

  observeEvent(input$go, {
    output$returns <- renderDT({

      datatable(returns_df(), rownames = FALSE, filter = 'top', style = 'bootstrap')

    })
  })

  # statistiques sur les rendements
  observeEvent(input$go, {
    output$returns_stats <- renderPrint({

      summary(returns_df())

    })
  })


  # Histogrammes des rendements
  observeEvent(input$go, {
    output$returns_hists <- renderPlot({
      par(mfrow = c(input$nl, input$nc))

      for (i in 0:input$numInputs + 1) {
        chart.Histogram(returns_df()[, i], methods = c("add.density", "add.normal"))
      }

    })
  })

  # Correlation
  observeEvent(input$go, {
    output$returns_cor <- renderPlot({
      chart.Correlation(stocks_returns())
    })
  })

  # Evolution des rendements
  observeEvent(input$go, {
    output$plot_returns <- renderPlot({

      plot.zoo(returns_df(), main = 'Stocks and Portfolio Returns',
               col = 1:input$numInputs + 1)

    })
  })

  # BOP
  observeEvent(input$go, {
    output$bop <- renderPlot({

      plot.zoo(pf()$BOP.Weight, main = 'BOP.Weight', col = 1:input$numInputs)

    })
  })

  # EOP
  observeEvent(input$go, {
    output$eop <- renderPlot({

      plot.zoo(pf()$EOP.Weight, main = 'EOP.Weight', col = 1:input$numInputs)

    })
  })

  # Agregation des rendements moyens
  agg_returns_df <- reactive({
    if (input$time_per == 'Montly Returns') {
      apply.monthly(returns_df(), mean)
    } else if (input$time_per == 'Weekly Returns') {
      apply.weekly(returns_df(), mean)
    } else if (input$time_per == 'Quarterly Returns') {
      apply.quarterly(returns_df(), mean)
    } else if (input$time_per == 'Yearly Returns') {
      apply.yearly(returns_df(), mean)
    }
  })

  observeEvent(input$go, {
    output$aggregated_returns <- renderDT({

      datatable(agg_returns_df(), rownames = FALSE, filter = 'top', style = 'bootstrap')

    })
  })

  output$save_return_agg <- downloadHandler(
    filename <- function() {
      paste("returns_aggregated_", Sys.Date(), ".csv", sep=",")
    },
    content <- function(file) {
      write.csv(agg_returns_df(), file)
    }
  )

  # Stats sur les donnees aggregees
  observeEvent(input$go, {
    output$agg_returns_stats <- renderPrint({
      summary(agg_returns_df())
    })
  })


  # Histogrammes

  # Plots
  observeEvent(input$go, {
    output$plot_agg_returns <- renderPlot({
      plot(agg_returns_df(), main = input$time_per)
      addLegend("topleft", on=1,
                legend.names = colnames(agg_returns_df()), lty = 1)
    })
  })

  # Monthly mean returns of portfolio
  MonthlyReturns <- reactive({
    apply.monthly(pf()$returns, mean)
  })


  # Rendements moyens annualises
  observeEvent(input$go, {
    output$rolling_mean <- renderPlot({
      chart.RollingPerformance(R = MonthlyReturns(),
                               width = input$Width,
                               FUN = "Return.annualized")
    })
  })

  # Voaltilites annualisees
  observeEvent(input$go, {
    output$rolling_std <- renderPlot({
      chart.RollingPerformance(R = MonthlyReturns(),
                               width = input$Width,
                               FUN = "StdDev.annualized")
    })
  })

  # Ratio de Sharpe annualises
  observeEvent(input$go, {
    output$rolling_sharpe <- renderPlot({
      chart.RollingPerformance(R = MonthlyReturns(),
                               width = input$Width,
                               FUN = "SharpeRatio.annualized")
    })
  })

  # Pertes potentielles
  observeEvent(input$go, {
    output$drawdown <- renderPlot({
      chart.Drawdown(MonthlyReturns(), main = "Evolution of the drawdowns")
    })
  })

  # ONGLET OPTIMISATION DE PORTEFEUILLE##########################################

  # Creation d'un portefeuille optimise a partir des actifs
  opt <- reactive({
    portfolio.optim(apply.monthly(stocks_returns(), mean))
  })

  # Affichage des resultats de l'optimisation
  observeEvent(input$go, {
    output$opt1_print <- renderPrint({
      opt()
    })
  })

  # Recuperation des poids de ce portefeuille optimise
  pf_weights <- reactive({
    w <- opt()$pw
    names(w) <- colnames(stocks_returns())
    w
  })

  observeEvent(input$go, {
    output$opt1_weights <- renderPlot({
      barplot(pf_weights())
    })
  })

  # Imposing weigh constraints

  max_weights <- reactive({
    rep(input$max_w, ncol(stocks_returns()))
  })

  opt2 <- reactive({
    portfolio.optim(apply.monthly(stocks_returns(), mean), reshigh = max_weights())
  })

  # Affichage des resultats de l'optimisation
  observeEvent(input$go, {
    output$opt2_print <- renderPrint({
      opt2()
    })
  })

  # Recuperation des poids de ce portefeuille optimise
  pf_weights2 <- reactive({
    w2 <- opt2()$pw
    names(w2) <- colnames(stocks_returns())
    w2
  })

  observeEvent(input$go, {
    output$opt2_weights <- renderPlot({
      barplot(pf_weights2())
    })
  })

  # Split-sample evaluation

  returns_estim <- reactive({
    window(apply.monthly(stocks_returns(), mean), start = input$window_estim[1], end = input$window_estim[2])
  })

  returns_eval <- reactive({
    window(apply.monthly(stocks_returns(), mean), start = input$window_eval[1], end = input$window_eval[2])
  })

  pf_estim <- reactive({
    portfolio.optim(returns_estim())
    # On peut aussi imposer une contrainte sur les poids : portfolio.optim(returns_estim(), reshigh = max_weights())
  })

  pf_eval <- reactive({
    portfolio.optim(returns_eval())

  })

  observeEvent(input$go, {
    output$opt3_print <- renderPrint({
      pf_estim()
    })
  })

  observeEvent(input$go, {
    output$opt4_print <- renderPrint({
      pf_eval()
    })
  })

  observeEvent(input$go, {
    output$opt3_weights <- renderPlot({
      plot(pf_estim()$pw, pf_eval()$pw,
           xlab = 'estimation portfolio weights',
           ylab = 'evaluation portfolio weights',
           main = 'Evaluation portfolio weights VS Estimation portfolio weights')
      abline(a = 0, b = 1, lty = 3)
    })
  })


})

# Run the application
shinyApp(ui = ui, server = server)


