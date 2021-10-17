## CrossRef Deep learning tutorial
##  by F. Bone / www.brightdatasci.com
##  on 16/10/2021
#############################################
#############################################

## Summary of the tutorial
#----------------------------
#(1) Load the relevant libraries
#(2) Query crossRef through the API
#(3) Update the query and collect all the data
#(4) Check the datasets, merge them and save your data

# 1. Load the relevant libraries
#--------------------------------
library(httr)
library(tidyverse)
library(jsonlite)

# 2. Query CrossRef through the API
#------------------------------------
# Build the Crossref query with all the components
api_first <- "http://api.crossref.org/works?query="
query <- "deep+learning"
filter <- "&filter="
from_date <- "from-pub-date:2020-01-01,"
to_date <- "until-pub-date:2020-12-31"
limit <- "&rows=100"
polite <- "&mailto=email@address.com"

# Put the query together and call it
query_full <- paste0(api_first, query,filter,funder, from_date,to_date, limit, polite)

# Call the query
fetch <- GET(query_full)

# transform the call into a readable component
return <- rawToChar(fetch$content)
return_all <- jsonlite::fromJSON(return)
DL_data <- as.data.frame(return_all$message$items)  # Extract the data into a dataframe


head(DL_data, n=10)          # Check out the structure of the dataset
names(DL_data)               # Look at all of the variable names

# Check how many records to download only for journal articles and conference proceedings
#Check for journal articles
type <- "type:journal-article,"
limit <- "&rows=20"

DL_articles_query <- paste0(api_first, query,filter,type, from_date,to_date,  limit, polite)
fetch <- GET(DL_articles_query)

# transform the call into a readable component
return <- rawToChar(fetch$content)
DL_articles <- jsonlite::fromJSON(return)

DL_articles$message$`total-results`

# Check for conference proceedings
type <- "type:proceedings-article,"
limit <- "&rows=20"

DL_proceedings_query <- paste0(api_first, query, filter,type, from_date,to_date,limit, polite)
fetch <- GET(DL_proceedings_query )
return <- rawToChar(fetch$content)
DL_proceedings <- jsonlite::fromJSON(return)

DL_proceedings$message$`total-results`

# 3. Update the query and collect all the data
#----------------------------------------------
cursor <-"&cursor="
cursor_item <-"*"
type <- "type:journal-article,"
limit <- "&rows=400"

first <-TRUE
check <-TRUE

while (check){
  DL_articles_query <- paste0(api_first, query,filter,type, from_date,to_date, limit, polite, cursor, cursor_item )
  fetch <- GET(DL_articles_query)
  
  # transform the call into a readable component
  return <- rawToChar(fetch$content)
  DL_articles_temp_list <- jsonlite::fromJSON(return)
  DL_articles_temp <- as.data.frame(DL_articles_temp_list$message$items)
  
  if (first){
    first <- FALSE
    DL_articles <- DL_articles_temp 
    cursor_item <- DL_articles_temp_list$message$`next-cursor`
    check <- (nrow(DL_articles_temp)==400)
    print("first")
  } else {
    DL_articles <- bind_rows(DL_articles, DL_articles_temp)
    cursor_item <- DL_articles_temp_list$message$`next-cursor`
    check <- (nrow(DL_articles_temp)==400)
    
  }

}

# Replicate for conference proceedings
cursor <-"&cursor="
cursor_item <-"*"
type <- "type:proceedings-article,"
limit <- "&rows=400"

first <-TRUE
check <-TRUE

while (check){
  DL_proceedings_query <- paste0(api_first, query,filter,type, from_date,to_date, limit, polite, cursor, cursor_item )
  fetch <- GET(DL_proceedings_query)
  
  # transform the call into a readable component
  return <- rawToChar(fetch$content)
  DL_proceedings_temp_list <- jsonlite::fromJSON(return)
  DL_proceedings_temp <- as.data.frame(DL_proceedings_temp_list$message$items)
  
  if (first){
    first <- FALSE
    DL_proceedings <- DL_proceedings_temp 
    cursor_item <- DL_proceedings_temp_list$message$`next-cursor`
    check <- (nrow(DL_proceedings_temp)==400)
    print("first")
  } else {
    DL_proceedings <- bind_rows(DL_proceedings, DL_proceedings_temp)
    cursor_item <- DL_proceedings_temp_list$message$`next-cursor`
    check <- (nrow(DL_proceedings_temp)==400)
    
  }
  
}


# 4. Check the datasets, merge them and save your data
#------------------------------------------------------

names(DL_articles)                      # View the structure of each dataset
names(DL_proceedings)

DL <- bind_rows(DL_articles, DL_proceedings) # Merge the two datasets

saveRDS(DL, "DeepLearning_dataset.RDS") # Save the final file

