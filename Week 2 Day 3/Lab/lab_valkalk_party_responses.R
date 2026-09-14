# Valkalkylator exploration
# You will examine the party-as-respondent matrix
# 9 political parties resopnded to 28 statements, from agree to disagree
# on a 0-4 likert scale (rescaled to 0-1)



# Init libraries that we will be using
library(DBI)
library(RSQLite)

library(FactoMineR)
library(factoextra)
library(tidyverse)

getwd()
setwd("C:/Users/paty_/Documents/GitHub/Digital Strategies for Social Science Research/Week 2 Day 3/Lab")
# Query the valkalkylator database
con <- dbConnect(SQLite(),"data/valkalkylator.sqlite")

# Create sql query
sql_parties <- "
  SELECT
    p.abbreviation,
    p.full_name,
    pr.question_id,
    ROUND(pr.answer * 25.0 / 100.0, 2) AS answer
  FROM party_responses pr
  JOIN parties p ON p.party_id = pr.party_id
  ORDER BY p.abbreviation, pr.question_id
"

# Extract a data frame
party_responses <- dbGetQuery(con, sql_parties) |>
  pivot_wider(names_from = question_id,
              names_prefix = "q",
              values_from = answer)

# I will also extract the questions table into a dataframe:
questions_df <- dbReadTable(con,"questions")

# Disconnect
dbDisconnect(con)

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

# Check 'scale.unit' above: it is set to FALSE!
# Before doing PCA, all variables should be normalized, i.e. that the mean is zero and
# standard deviation is 1 (which is what we did for the music property variables)
# Why did I set it at FALSE here? Could I set it at TRUE as well?
question_cols <- grep("^q", colnames(wide))
answers_matrix <- as.matrix(wide[, question_cols])

dist_matrix <- dist(answers_matrix, method = "euclidean")
print(as.matrix(dist_matrix))  # view it as a full table

# Continue exploring these results in a similar manner as you did with the music genre data!
