## CrossRef Deep learning tutorial (2)
##  by F. Bone / www.brightdatasci.com
##  on 20/06/2021
#############################################
#############################################

## Summary of the tutorial
#----------------------------
#(1) Load the relevant and dataset
#(2) Explore how to load data using funder's DOIs
#(3) Build a dataframe by querying extracting data for each DOI
#(4) Finalise and save the datasets


# 1. Load the relevant libraries and dataset
#--------------------------------------------
library(tidyverse)          # load the library needed
library(jsonlite)
library(httr)

setwd(dirname(rstudioapi::getActiveDocumentContext()$path))  # Point to the folder where this file is saved
DL_funder <- read_rds("DeepLearning_funderdois.RDS")        # Load the files from the previous tutorial
DL_funder_records <- read_rds("DeepLearning_article_funder.RDS")        


# 2. Explore how to load data using funder's DOIs
#-------------------------------------------------------

# Testing the code with a single DOI
base_html = "www.doi.org/"
funder_i <- paste0(base_html, DL_funder$doi.funder[[6]])
print(funder_i)

# Importing the test file into R
funder_response <- GET(funder_i)
funder_json <- fromJSON(content(funder_response,as="text"))

# Extract data from the file
funder_region <- funder_json$region
funder_country <- funder_json$address$postalAddress$addressCountry
funder_name <- funder_json$prefLabel$Label$literalForm$content
funder_type1 <- funder_json$fundingBodyType
funder_type2 <- funder_json$fundingBodySubType

# 3. Build a dataframe by querying extracting data for each DOI
#---------------------------------------------------------------

first_row <- TRUE    # Before starting the loop the first row will be TRUE

# Set up the loop
for (i in DL_funder$doi.funder){

  funder_i <- paste0(base_html, i) # We only need to adjust this code to adjust the previous code to the loop
  
  # Importing the test file into R
  funder_response <- GET(funder_i)
  funder_json <- fromJSON(content(funder_response,as="text"))
  
  # Extract data from the file
  funder_region <- funder_json$region
  funder_country <- funder_json$address$postalAddress$addressCountry
  funder_name <- funder_json$prefLabel$Label$literalForm$content
  funder_type1 <- funder_json$fundingBodyType
  funder_type2 <- funder_json$fundingBodySubType
  
  # Create a vector that will become the row
  vec_row <- c(i, funder_region, funder_country, funder_name, funder_type1, funder_type2)
  
  # Transform the vector into a dataframe
  data_row_df <- data.frame(t(vec_row))
  
  # Make vector to adjust the column names
  df_names <- c("funder_doi", "funder_region", "funder_country", "funder_name", "funder_type1", "funder_type2")
  
  # Assign the column names to the newly created dataframe
  colnames(data_row_df) <- df_names
  
  # Check whether this is the first row
  if (first_row){
    df_funder <- data_row_df      # assign to the first dataframe to the newly created row
    first_row <- FALSE         # Now that the first row has been assigned to the main dataframe, the following data will be added to this one
    
  } else {
    df_funder <- bind_rows(df_funder, data_row_df)   # Bind every row thereafter to the main dataframe
  }
}

# 4. Finalise and save the datasets
#-----------------------------------

# Rename the column names to match the df_funder
DL_funder_records <- DL_funder_records %>%
  rename(funder_doi = doi.funder)          

# Integrate with the record data
DL_funder_records <- left_join(DL_funder_records, df_funder)

# Save both datasets
saveRDS(df_funder, "DeepLearning_funder_fullrecord.RDS") # Save the dataset, with funder data matched with publications
saveRDS(DL_funder_records, "DeepLearning_article_funderfull.RDS") # Save the dataset with funders identifiers


