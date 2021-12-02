#
# This is a Shiny web application. You can run the application by clicking
# the 'Run App' button above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#
library(DBI)
library(RSQLite)
library(shinydashboard)
library(shinythemes)
library(shinyWidgets)
library(dplyr)
library(ggplot2)
library(gridExtra)
library(grid)
require(scales)
library(plotly)

db <- dbConnect(SQLite(), 'ratings.db')
Years <- dbGetQuery(db, 'SELECT distinct Year from dim_Date')
BusinessTypeId <- dbGetQuery(db, 'SELECT distinct BusinessType,BusinessTypeID from dim_BusinessType')


ui <- fluidPage(
    dashboardHeader(title = "Basic dashboard"),
    #titlePanel('Demo for Plot'),
    navbarPage(
        title = 'Navigation Bar',
        windowTitle = 'Navigation Bar', 
        position = 'fixed-top', 
        collapsible = TRUE, 
        theme = shinytheme('cosmo'), 
        ),
   
    
    
        mainPanel(
            tabsetPanel(
                
                
                
                tabPanel(title ="Ratings based on business type",
                         inputPanel(
                             selectInput(
                                 inputId = 'RatingValues',
                                 label = 'Rating Values:',
                                 choices = c(5,4,3,2,1,0),
                                 selected =5
                             )),
                         inputPanel(
                             selectInput(
                                 inputId = 'BusinessTypeID',
                                 label = 'Business Types:',
                                 choices = BusinessTypeId$BusinessType,
                                 selected="Farmers/growers"
                             ))
                         ,
                         
                         plotOutput(
                    outputId = 'Play'
                ),icon = icon("table"),
                ),
                tabPanel(title ="Sub-score distributions based on rating value",
                         
                         inputPanel(
                             selectInput(
                                 inputId = 'RatingValues2',
                                 label = 'Rating Values:',
                                 choices = c(5,4,3,2,1,0),
                                 selected =5
                             )),
                         
                         
                         
                         plotOutput(
                             outputId = 'Play2',height = "500px",width="100%"  
                         )
                ),
                tabPanel(title = "Month wise rating distribution", 
                         inputPanel(
                             selectInput(
                                 inputId = 'RatingValues1',
                                 label = 'Scheme Types:',
                                 choices = c("FHRS","FHIS"),
                                 selected ="FHRS"
                             )),
                         
                         plotOutput(
                             outputId = 'transactions'
                         )),
                
                tabPanel(title ="Top 10 local Authority vs Rating",
                         
                         inputPanel(
                             selectInput(
                                 inputId = 'RatingValues3',
                                 label = 'Rating Values:',
                                 choices = c(5,4,3,2,1,0),
                                 selected =5
                             )),
                         
                         
                         
                         plotOutput(
                             outputId = 'Play3',height = "500px",width="100%"  
                         )
                ),
                
        
        
    )
)
)
    



server <- function(input, output, session) {
     dfPlay1 <- dbGetQuery(db,
        statement = 
            'Select F.BusinessTypeID,F.Ratingkey,SchemeType,D.RatingValue, B.BusinessType, Date.Year,L.LocalAuthorityName from fact_rating F join dim_RatingTypes D on 
                F.RatingKey =D.RatingKey join dim_BusinessType B on B.BusinessTypeID= F.BusinessTypeID
                join dim_Date date on Date.RatingDate =F.RatingDate join dim_LocalAuthority L on L.LocalAuthorityCode=F.LocalAuthorityCode
                ')
    
    output$Play <- renderPlot(
        {
           
            
            df <- filter(dfPlay1,SchemeType=="FHRS"& BusinessType==input$BusinessTypeID & RatingValue==input$RatingValues)
            
            output <-ggplot(df, aes(x=year))+
                geom_bar(aes(y = (..count..)/sum(..count..))) + 
                ## version 3.0.0
                scale_y_continuous(labels=percent) +
                labs(title="Title1",
                     x ="Year", y = "Percentage of rating under Selected Category")
            output
               
        }
    )
    
    dfPlay2 <- dbGetQuery(
        db,
        statement = 
            'Select F.BusinessTypeID,F.Ratingkey,SchemeType,D.RatingValue, B.BusinessType, F.Hygiene,F.Structural, F.ConfidenceInManagement from fact_rating F join dim_RatingTypes D on 
                F.RatingKey =D.RatingKey join dim_BusinessType B on B.BusinessTypeID= F.BusinessTypeID
                join dim_Date date on Date.RatingDate =F.RatingDate 
                ')
    output$Play2 <- renderPlot(
        {
            # pool <- dbPool(
            #        drv = dbConnect(RSQLite::SQLite(), dbname = "ratings.db"))
            
            
            
            df <- filter(dfPlay2,SchemeType=="FHRS" & RatingValue==input$RatingValues2)
            
            plt1 <- ggplot(df, aes(x=Hygiene))+
                geom_bar(aes(y = (..count..)/sum(..count..))) + 
                ## version 3.0.0
                scale_y_continuous(labels=percent) +
                labs(
                     x ="Hygiene", y = "Percentage of rating under Selection")
                
                
              
            plt2 <- ggplot(df, aes(x=Structural))+
                geom_bar(aes(y = (..count..)/sum(..count..))) + 
                ## version 3.0.0
                scale_y_continuous(labels=percent) +
                labs(
                     x ="Structural", y = "Percentage of rating under Selection")
            
                
            plt3 <- ggplot(df, aes(x=ConfidenceInManagement))+
                geom_bar(aes(y = (..count..)/sum(..count..))) + 
                ## version 3.0.0
                scale_y_continuous(labels=percent) +
                labs(
                     x ="ConfidenceInManagement", y = "Percentage of rating under Selection")
            
            grid.arrange(plt1,plt2,plt3,ncol=3)
            
        }
    )
    dfplay3 <- dbGetQuery(
        db,
        statement = 
            'Select D.RatingValue,count(D.RatingValue) as Count,SchemeType, B.BusinessType, Date.Month from fact_rating F join dim_RatingTypes D on 
                F.RatingKey =D.RatingKey join dim_BusinessType B on B.BusinessTypeID= F.BusinessTypeID
                join dim_Date date on Date.RatingDate =F.RatingDate 
                group by Date.Month,B.BusinessType,D.RatingValue
                ')
    output$transactions <- renderPlot(
        {
            
           df <- filter(dfplay3,SchemeType==input$RatingValues1)
           
            ggplot(df, aes(y=Count, x=factor(month)))+
              #  geom_bar(aes(y = (..count..)/sum(..count..))) 
                geom_bar(stat = "identity") +facet_grid(~RatingValue)
            
               
            
        }
    )
     output$Play3 <- renderPlot(
        {
            dfPlay4 <- filter(dfPlay1,SchemeType=="FHRS"& RatingValue==input$RatingValues3)
                      
            dfPlay4 <-  dfPlay4 %>% group_by(LocalAuthorityName)%>% count(vars='LocalAuthorityName')
            dfPlay4 <- arrange(dfPlay4,desc(freq)) %>% head(n=10)
            ggplot(dfPlay4, aes(x = reorder(LocalAuthorityName, - freq), y = freq)) +
                geom_bar(stat = "identity")+ labs(y="Count",x="Local Authority Name")
            
            
            
        }
    )
    
}

# Complete app with UI and server components
shinyApp(ui, server)

