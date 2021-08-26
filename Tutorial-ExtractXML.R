## CrossRef Deep learning tutorial (2)
##  by F. Bone / www.brightdatasci.com
##  on 20/06/2021
#############################################
#############################################

## Summary of the tutorial
#----------------------------
#(1) Load the relevant libraries and the dataset from PubMed
#(2) Explore and do a first extraction of the data of interest
#(3) Extract MeSH data through a for loop
#(4) Extract MeSH data using purrr
#(5) Final tidying of the data and saving

# 1. Load the relevant libraries and dataset
#--------------------------------------------
library(tidyverse)          # load the library needed
library(xml2)

# load the data from the web using xml2
mesh_xml <- read_xml("https://nlmpubs.nlm.nih.gov/projects/mesh/MESH_FILES/xmlmesh/desc2021.xml")

# 2. Explore and do a first extraction of the data of interest
#--------------------------------------------------------------
mesh_terms <- xml_find_all(mesh_xml, ".//DescriptorRecord")

# Extract a sample so the code runs faster
mesh_terms_sample <- mesh_terms[1:1000]

# 3. Extract MeSH data through a for loop
#-------------------------------------------

# View items in the columns we would like to extract
mesh_descriptors <- xml_text(xml_find_first(mesh_terms_sample[1], ".//DescriptorUI"))
mesh_list <- xml_text(xml_find_all(mesh_terms_sample[1], ".//TreeNumberList"))
mesh_name <- xml_text(xml_find_first(mesh_terms_sample[1], ".//DescriptorName"))

# Collapse each variable extracted into a row vector 
row <- t(c(mesh_descriptors, 
           mesh_list, 
           mesh_name))

# Set columns name for the dataframe
col <- c("DescriptorUI", "TreeNumberList", "DescriptorName")

# Transform the vector into a dataframe with the right column names
mesh_data_sample <- data.frame(row)
colnames(mesh_data_sample) <- col


# For loop to extract the targeted data
for (i in 2:1000){
  
  mesh_descriptors <- xml_text(xml_find_first(mesh_terms_sample[i], ".//DescriptorUI"))
  mesh_list <- xml_text(xml_find_all(mesh_terms_sample[i], ".//TreeNumberList"))
  mesh_name <- xml_text(xml_find_first(mesh_terms_sample[i], ".//DescriptorName"))
  
  row <- t(c(mesh_descriptors, 
             mesh_list, 
             mesh_name))
  
  df_temp <- data.frame(row)
  colnames(df_temp) <- col
  
  # Integrate the new row for the 999 other rows of the sample
  mesh_data_sample <- bind_rows(mesh_data_sample, df_temp)

}

# Clean the column within MeSH list
mesh_data_sample <- mesh_data_sample %>%
  mutate(mesh_list= gsub("(?<=[[:digit:]])(?=[[:upper:]])", ";", as.character(mesh_list), perl=TRUE)) %>%
  mutate(mesh_list = ifelse(mesh_list =="character(0)", "",mesh_list))

# 4. Extract MeSH data using purrr
#-------------------------------------
# Delete the mesh_data_sample dataset
rm(mesh_data_sample)

#### Example ####
# Example code for transformation
mesh_descriptors <- xml_text(xml_find_first(mesh_terms_sample[1], ".//DescriptorUI")) #code taken from above

# Example transformation (1)
mesh_descriptors <- mesh_terms_sample %>%
  map(function(x) xml_text(xml_find_first( x, ".//DescriptorUI")))

# Example transformation (2)
mesh_descriptors <- mesh_terms_sample %>%
  map(~ xml_text(xml_find_first( .x, ".//DescriptorUI")))
#### Example ####

# Extract the descriptors
mesh_descriptors <- mesh_terms_sample %>%
  map(~ xml_text(xml_find_first( .x, ".//DescriptorUI")))

# Extract the Tree number of the MeSH terms
mesh_list <- mesh_terms_sample %>%
  map(~ xml_text(xml_find_all(.x, ".//TreeNumber")))

# Extract the Descriptor names of the MeSH terms
mesh_name <- mesh_terms_sample %>%
  map(~ xml_text(xml_find_first(.x, ".//DescriptorName")))

# Merge the data in a unique table
mesh_data_sample <- tibble(mesh_descriptors = mesh_descriptors, 
                    mesh_list = mesh_list, 
                    mesh_name = mesh_name)

mesh_data_sample

# Unlist some of the columns
mesh_data_sample <- mesh_data_sample  %>%
  mutate(mesh_name = flatten_chr(mesh_name)) %>%
  mutate(mesh_descriptors = flatten_chr(mesh_descriptors))%>%
  rowwise()%>%
  mutate(mesh_list = paste(mesh_list, collapse = ';'))


# 5. Final tidying of the data and saving
#-------------------------------------------
# Save the dataset
write_csv(mesh_data_sample, "mesh_data_sample.csv")
