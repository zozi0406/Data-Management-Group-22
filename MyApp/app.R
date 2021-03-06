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

# Conencting to database
db <- dbConnect(SQLite(), 'ratings.db')
# getting all years with rating
Years <- dbGetQuery(db, 'SELECT distinct Year from dim_Date')

# getting unique business type and Id forfilters
BusinessTypeId <- dbGetQuery(db, 'SELECT distinct BusinessType,BusinessTypeID from dim_BusinessType')


ui <- fluidPage(
    dashboardHeader(title = "Basic dashboard"),
    navbarPage(
        title = 'Dashboard',
        windowTitle = 'Dashboard', 
        position = 'fixed-top', 
        collapsible = TRUE, 
        theme = shinytheme('cosmo'), 
        ),
   
    
        mainPanel(
            tabsetPanel(
                
                
                # This tab will handle the plot1 with Business type as a selector and rating value as another selector
                tabPanel(title ="Trend of Business types",
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
                    outputId = 'Play1'
                ),icon = icon("table"),
                ),
                
                # This tab will handle the plot2 with  rating value as selector
                tabPanel(title ="Sub-score distributions",
                         
                         inputPanel(
                             selectInput(
                                 inputId = 'RatingValues2',
                                 label = 'Rating Values:',
                                 choices = c(5,4,3,2,1,0),
                                 selected =5
                             )),
                         
                         
                         
                         plotOutput(
                             outputId = 'Play2',height = "500px",width="100%"  
                         ),icon = icon("table")
                ),
           
                # This tab will handle the plot2 with  rating value as selector
                tabPanel(title ="Top 10 local Authority",
                         
                         inputPanel(
                             selectInput(
                                 inputId = 'RatingValues3',
                                 label = 'Rating Values:',
                                 choices = c(5,4,3,2,1,0),
                                 selected =5
                             )),
                         
                         
                         
                         plotOutput(
                             outputId = 'Play3',height = "500px",width="100%"  
                         ),icon = icon("table")
                ),
                
        
        
    )
)
)
    



server <- function(input, output, session) {
  
# 1. This plot is implementing Percentage of rating under Selected Category over the years

# QUERY
  
#  'Select F.BusinessTypeID,F.Ratingkey,SchemeType,D.RatingValue, B.BusinessType, Date.Year,L.LocalAuthorityName from fact_rating F join dim_RatingTypes D on 
# F.RatingKey =D.RatingKey join dim_BusinessType B on B.BusinessTypeID= F.BusinessTypeID
# join dim_Date date on Date.RatingDate =F.RatingDate join dim_LocalAuthority L on L.LocalAuthorityCode=F.LocalAuthorityCode 
# WHERE SchemeType=="FHRS" and  BusinessType==input$BusinessTypeID and RatingValue==input$RatingValues'
   
     dfPlay1 <- dbGetQuery(db,
        statement = 
            'Select F.BusinessTypeID,F.Ratingkey,SchemeType,D.RatingValue, B.BusinessType, Date.Year,L.LocalAuthorityName from fact_rating F join dim_RatingTypes D on 
                F.RatingKey =D.RatingKey join dim_BusinessType B on B.BusinessTypeID= F.BusinessTypeID
                join dim_Date date on Date.RatingDate =F.RatingDate join dim_LocalAuthority L on L.LocalAuthorityCode=F.LocalAuthorityCode
                ')
# Plotting a graph using ggplot showing year vs percentage of rating under each category  
    output$Play1 <- renderPlot(
        {
           
            
            df <- filter(dfPlay1,SchemeType=="FHRS"& BusinessType==input$BusinessTypeID & RatingValue==input$RatingValues)
            
            output <-ggplot(df, aes(x=year))+
                geom_bar(aes(y = (..count..)/sum(..count..)),fill="steelblue") + 
                ## version 3.0.0
                scale_y_continuous(labels=percent) +
                labs(caption = "This plot shows trend of selected category for a particular rating",
                     x ="Year", y = "Percentage of rating under Selected Category")
            output
               
        }
    )

# 2. This navigation option  describes relaltionship between the sub score distribution based on food authority rating value    
   
# Query
#    'Select F.BusinessTypeID,F.Ratingkey,SchemeType,D.RatingValue, B.BusinessType, F.Hygiene,F.Structural, F.ConfidenceInManagement from fact_rating F join dim_RatingTypes D on 
#                F.RatingKey =D.RatingKey join dim_BusinessType B on B.BusinessTypeID= F.BusinessTypeID
#                join dim_Date date on Date.RatingDate =F.RatingDate where SchemeType=="FHRS" & RatingValue==input$RatingValues2
#                '   
    
     dfPlay2 <- dbGetQuery(
        db,
        statement = 
            'Select F.BusinessTypeID,F.Ratingkey,SchemeType,D.RatingValue, B.BusinessType, F.Hygiene,F.Structural, F.ConfidenceInManagement from fact_rating F join dim_RatingTypes D on 
                F.RatingKey =D.RatingKey join dim_BusinessType B on B.BusinessTypeID= F.BusinessTypeID
                join dim_Date date on Date.RatingDate =F.RatingDate 
                ')
# This plot will show the sub score distribution for hygiene,structural and confidence in management for selected rating value    
     output$Play2 <- renderPlot(
        {
            
            
            df <- filter(dfPlay2,SchemeType=="FHRS" & RatingValue==input$RatingValues2)
            
            plt1 <- ggplot(df, aes(x=Hygiene))+
                geom_bar(fill="blue",aes(y = (..count..)/sum(..count..))) + 
                ## version 3.0.0
                scale_y_continuous(labels=percent) +
                labs(
                     x ="Hygiene", y = "Percentage of rating under Selection")
                
                
              
            plt2 <- ggplot(df, aes(x=Structural))+
                geom_bar(fill = "#FF6666",aes(y = (..count..)/sum(..count..))) + 
                ## version 3.0.0
                scale_y_continuous(labels=percent) +
                labs(
                     x ="Structural", y = "Percentage of rating under Selection")+
                theme(
                       axis.text.y=element_blank(),  #remove y axis labels
                       axis.ticks.y=element_blank()  #remove y axis ticks
                )
            
                
            plt3 <- ggplot(df, aes(x=ConfidenceInManagement))+
                geom_bar(fill="orange",aes(y = (..count..)/sum(..count..))) + 
                ## version 3.0.0
                scale_y_continuous(labels=percent) +
                labs(
                     x ="ConfidenceInManagement", y = "Percentage of rating under Selection") +
            theme(
              axis.text.y=element_blank(),  #remove y axis labels
              axis.ticks.y=element_blank()  #remove y axis ticks
            )
            
            grid.arrange(plt1,plt2,plt3,ncol=3)
            
        }
    )
    
#3. Top ten Authority for selected rating value
# Query
#  'Select F.BusinessTypeID,F.Ratingkey,SchemeType,D.RatingValue, B.BusinessType, Date.Year,L.LocalAuthorityName from fact_rating F join dim_RatingTypes D on 
# F.RatingKey =D.RatingKey join dim_BusinessType B on B.BusinessTypeID= F.BusinessTypeID
# join dim_Date date on Date.RatingDate =F.RatingDate join dim_LocalAuthority L on L.LocalAuthorityCode=F.LocalAuthorityCode 
# WHERE SchemeType=="FHRS" and RatingValue==input$RatingValues'     
     

# This chart will render the  plot showing top 10 local Authorities based on rating at each level
output$Play3 <- renderPlot(
        {
            dfPlay4 <- filter(dfPlay1,SchemeType=="FHRS"& RatingValue==input$RatingValues3)
                      
            dfPlay4 <-  dfPlay4 %>% group_by(LocalAuthorityName)%>% count(vars='LocalAuthorityName')
            dfPlay4 <- rename(dfPlay4,freq=n)
            dfPlay4 <- arrange(dfPlay4,desc(freq)) %>% head(n=10)
            plt4 <- ggplot(dfPlay4, aes(x = reorder(LocalAuthorityName, - freq), y = freq ))+
                geom_bar(stat = "identity")+ labs(y="Count",x="Local Authority Name") +
              geom_text(aes(label = freq), vjust = -0.2)
            
            
            plt4
        }
    )
    
}

# Complete app with UI and server components
shinyApp(ui, server)

