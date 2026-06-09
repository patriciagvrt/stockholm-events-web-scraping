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


dbDisconnect(con)




# Extract a data frame
party_responses <- dbGetQuery(con, sql_parties) |>
  pivot_wider(names_from = question_id,
              names_prefix = "q",
              values_from = answer)

# I will also extract the questions table into a dataframe:
questions_df <- dbReadTable(con,"questions")

# Do explore the party_responses dataframe! 9 observations with 30 variables. Note
# that it has 2 columns for party names, so we should first arrange so that
# row names are the party names. We can then drop the full_name
# You can of course instead keep the full_name and drop abbreviations:

party_responses <- party_responses |>
  column_to_rownames("abbreviation") |>
  select(-full_name)

# Also: the statements are only given by q1, q2 etc - so you don't really know
# what the statements are by looking at the party_responses dataframe
# However, I did get the questions as well - explore the 'questions_df' dataframe

# To be able to use this in conjunction with the party_responses, i.e. where
# we connect the column headers q1, q2 etc to the questions, we need to create
# a named list of the questions, using these q1, q2 names as well:

question_labels <- questions_df |>
  mutate(qid = paste0("q", question_id)) |>
  select(qid, text_english) |>
  deframe()   # turns it into a named character vector

# Then we rename columns in party_responses:
party_responses_labelled <- party_responses |>
  rename_with(~ question_labels[.x])

# Then we have a data frame (with very long column names) that we can explore:
pca_parties <- PCA(party_responses_labelled,
                   scale.unit = FALSE,
                   graph      = FALSE)


