##  Guardian COVID tutorial
##  by F. Bone / www.brightdatasci.com
##  on 10/11/2021
#############################################
#############################################

## Summary of the tutorial
#----------------------------
# Get an API key (not in code)
# Understand API characteristics
#(1) Set-up your R script
#(2) Plan and build the query for identifying articles
#(4) Check the datasets, merge them and save your data

# 1. Load the relevant libraries
#--------------------------------
library(httr)
library(jsonlite)
library(tidyverse)

# 2. Build the query
#------------------------------------

# Build all the parts of the query
base_url <- "https://content.guardianapis.com/search"
query_prefix <- "?q="
query_keywords <- "covid"
start_date_prefix <- "&from-date="
date <- "2019-01-01"
api_key_prefix <- "&api-key="
api_key <- YourApiKey # Don't forget to change this to your own API key

# Put the query together
query_full <- paste0(base_url, query_prefix, query_keywords, start_date_prefix, date, api_key_prefix, api_key)
fetch <- GET(query_full)

# transform the call into a readable component
return <- rawToChar(fetch$content)
return_all <- jsonlite::fromJSON(return)
Guardian_data <- as.data.frame(return_all$response$results)

head(Guardian_data, n=10)


DL_data <- DL$data           # Extract the data into a dataframe

head(DL_data, n=10)          # Check out the structure of the dataset
names(DL_data)               # Look at all of the variable names

# Check how many records to download only for journal articles and conference proceedings

DL_articles <- cr_works(query="deep learning", 
                        filter=c(from_print_pub_date="2020-01-01", 
                                 until_print_pub_date="2020-12-31",
                                 type="journal-article"), 
                        limit= 20, .progress="text")



DL_proceedings <- cr_works(query="deep learning", 
                           filter=c(from_print_pub_date="2020-01-01", 
                                    until_print_pub_date="2020-12-31",
                                    type="proceedings-article"), 
                           limit= 20, .progress="text")

DL_articles$meta$total_results
DL_proceedings$meta$total_results

# 3. Update the query and collect all the data
#----------------------------------------------

# Download the two full datasets in independant queries (these are large datasets and may take several hours)
DL_articles <- cr_works(query="deep learning", 
                        filter=c(from_print_pub_date="2020-01-01", 
                                 until_print_pub_date="2020-12-31",
                                 type="journal-article"), 
                        cursor = "*", cursor_max = 62200, .progress="text")

DL_proceedings <- cr_works(query="deep learning", 
                           filter=c(from_print_pub_date="2020-01-01", 
                                    until_print_pub_date="2020-12-31",
                                    type="proceedings-article"), 
                           cursor = "*", cursor_max = 25742, .progress="text")

# 4. Check the datasets, merge them and save your data
#------------------------------------------------------
DL_articles <- DL_articles$data        #Extract the data as a dataframe
DL_proceedings <- DL_proceedings$data   


names(DL_articles)                      # View the structure of each dataset
names(DL_proceedings)

DL <- bind_rows(DL_articles, DL_proceedings) # Merge the two datasets

saveRDS(DL, "DeepLearning_dataset.RDS") # Save the final file

