# lab pca tracks genres!

# First, install the necessary packages for PCA/factor analysis
# install.packages(c("FactoMineR","factoextra","tidyverse"))

# Init libraries that we will be using
library(DBI)
library(RSQLite)

library(FactoMineR)
library(factoextra)
library(tidyverse)
getwd()
con <- dbConnect(SQLite(), "data/music.sqlite")
tracks_sample <- dbGetQuery(con, "
  SELECT 
        track_id,
        
         danceability, energy, loudness, speechiness,
         acousticness, instrumentalness, liveness, valence, tempo
  FROM tracks
  ORDER BY RANDOM()          -- random sample without loading everything
  LIMIT 5000")
dbDisconnect(con)

# track_id is a unique identifier for each track (the track titles aren't)!
# So we can use this as rownames (which means it won't be included in the PCA
tracks_sample <- tracks_sample |> column_to_rownames("track_id")

# Do the analysis
pca_res <- PCA(
  tracks_sample,
  scale.unit = TRUE,
  graph = FALSE
)

# Explore pca_res using the various fviz_ functions (see other lab script)

