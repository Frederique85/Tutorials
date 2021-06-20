## CrossRef Deep learning tutorial
##  by F. Bone / www.brightdatasci.com
##  on 20/06/2021
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
library(rcrossref)
library(tidyverse)

# 2. Query CrossRef through the API
#------------------------------------
DL <- cr_works(query="deep learning", 
               filter=c(from_print_pub_date="2020-01-01", 
                        until_print_pub_date="2020-12-31"), 
               limit= 100, .progress="text")                 # Query crossref

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