## CrossRef Deep learning tutorial (2)
##  by F. Bone / www.brightdatasci.com
##  on 25/07/2021
#############################################
#############################################

## Summary of the tutorial
#----------------------------
#(1) Load the relevant libraries and datasets
#(2) Explore the data to choose the variable for visualisation
#(3) Convert the dataset to a network for visualisation
#(4) Change the network from funder to countries
#(5) Build the Chord Diagram


# 1. Load the relevant libraries and datasets
#---------------------------------------------
library(tidyverse)          # load the library needed
library(circlize)

setwd(dirname(rstudioapi::getActiveDocumentContext()$path))  # Point to the folder where this file is saved
DL_funder <- read_rds("DeepLearning_funder_fullrecord.RDS")        # Load the files from the previous tutorial
DL_funder_records <- read_rds("DeepLearning_article_funderfull.RDS")        

# 2. Explore the data to choose the variable for visualisation
#--------------------------------------------------------------

# 2.1 Explore which variable is most suited
length(unique(DL_funder$funder_country))
length(unique(DL_funder$funder_region))
length(unique(DL_funder$funder_type1))
length(unique(DL_funder$funder_type2))


# 3. Convert the dataset to a network for visualisation
#-------------------------------------------------------

df <- data.frame(matrix(ncol = 3, nrow = 0))
colnames(df) <- c('from', 'to', 'value')

# 3.1 Create an edgelist
for (doi_t in unique(DL_funder_records$doi)) {

  # Create a temporary dataset for each record (e.g. record)
  df_temp <- DL_funder_records %>%
    filter(doi == doi_t) 
  
  # only create the edgelist if there is more than two funders per record
  if (nrow(df_temp) == 2 ){

    dois_funder <- sort(df_temp$funder_doi)
    dois_funder <- data.frame(t(c( dois_funder , 1)))
    colnames(dois_funder) <- c('from', 'to', 'value')
    df <- rbind(df, dois_funder)

    
  } else if (nrow(df_temp) > 2 ){

    # If there is more than two funders per papers, we are iterating over all funders
    dois_funder <- sort(df_temp$funder_doi)
    
    for (i in 1:(nrow(df_temp)-1)){
      for(j in (i+1):nrow(df_temp)){
        dois_temp <- data.frame(t(c(dois_funder[i], dois_funder[j], 1)))
        colnames(dois_temp) <- c('from', 'to', 'value')
        df <- rbind(df, dois_temp)
        
      }
    }
  }
}

# 3.2 Merge the weights of the daframe
df_net <- df %>%
  group_by(from, to) %>%
  summarise(value=n()) %>%
  ungroup() %>%
  arrange(desc(value))


# 4. Change the network from funder to countries
#-------------------------------------------------

# 4.1 Extract the funder and country levels into a dataset
funder_country <- DL_funder %>%
  select(funder_doi, funder_country)

# 4.2 Make a new adjacency list with countries instead of funders
country_net <- left_join(df_net, funder_country, by = c("from"= 'funder_doi')) %>%
  select( -from) %>%
  rename(from = funder_country)

country_net <- left_join(country_net, funder_country, by = c("to"= 'funder_doi')) %>%
  select( -to) %>%
  rename(to = funder_country)

# 4.3 Merge countries and values 
country_net <- country_net %>%
  rowwise() %>%
  mutate(small = min(as.character(from), as.character(to))) %>%
  mutate(big = max(as.character(from), as.character(to))) %>%
  group_by (small, big) %>%
  summarise(value=sum(value)) %>%
  ungroup() %>%
  rename(from = small, to=big)



# 5.  Build the Chord Diagram
#-----------------------------

# 5.1 Build chord diagram
chordDiagram(country_net)

# 5.2 Remove link to self
country_net_noself <- country_net %>%
  filter(from != to)

#Adjust the graph
circos.clear()
chordDiagram(country_net_noself,  annotationTrack = c("grid", "axis"))
circos.track(track.index = 1, panel.fun = function(x, y) {
  circos.text(CELL_META$xcenter, CELL_META$ylim[2.8], CELL_META$sector.index, 
              facing = "clockwise", niceFacing = TRUE, adj = c(0, 0.5))
}, bg.border = NA)

# 5.3 Remove countries with too little links

# Create a dataset to check how many connections each country has
from <- country_net_noself %>%
  select(from, value) %>%
  rename(country = from )

to <- country_net_noself %>%
  select(to, value) %>%
  rename(country = to )

country_summary <- bind_rows(from, to) %>%
  group_by(country)%>%
  summarise(value=sum(value))%>%
  arrange(value)

# Remove any countries which has less than 10 co-funded with other countries
country_remove <- country_summary %>%
  filter(value <10)%>%
  select(country)

country_final <- country_net_noself %>%
  filter(!(to %in% country_remove$country))%>%
  filter(!(from %in% country_remove$country))

# Plot the Chord diagram again
circos.clear()

chordDiagram(country_final,  annotationTrack = c("grid"), annotationTrackHeight = c(0.03, 0.2))
circos.track(track.index = 1, panel.fun = function(x, y) {
  circos.text(CELL_META$xcenter, CELL_META$ylim[2.8], CELL_META$sector.index, 
              facing = "clockwise", niceFacing = TRUE, adj = c(0, 0.5))
}, bg.border = NA)

# Save files
write_csv(df_net, "df_net.csv")
write_csv(country_net, "country_net.csv")
write_csv(country_net_noself, "country_net_noself.csv")
write_csv(country_final, "country_final.csv")

