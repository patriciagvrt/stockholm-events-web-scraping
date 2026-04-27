################################## DSSS26 - 2 ### EXTRA ########################
# 
# This file will briefly introduce you to the use of API from Statistics Sweden(SCB),
# who produce and disenminate huge amount of official data from Sweden.
# 
# Here is an introduction of the API: 
# https://www.scb.se/en/services/open-data-api/pxwebapi/api-for-the-statistical-database/
# 
# Here is a tutorial on how to use the R package to get data from SCB's API:
# https://ropengov.github.io/pxweb/articles/pxweb.html


# BONUS EXERCISE: WORKING WITH APIS
# =========================================================
# When the websites provide you with APIs, it is always a good idea to use the 
# API. For one thing, you will free yourself from crawling page by page, for 
# another, there is usually very detailed instruction and codebooks on how to use
# the API.

# To start with, let's visit this page: https://www.statistikdatabasen.scb.se/pxweb/en/ssd/
# SCB offers you a wide range of data to download. Let's look at the education,
# navigate yourself to: Education and research -> Historical statistics on education
# -> Higher education -> Qualifications awarded at Higher Education Institutions 
# by professional qualifications and sex. Academic year 1936/37 - 2022/23

install.packages("pxweb")
library(pxweb)

# following the path above, you can get EVERYTHING you need for downloading the data
d <- pxweb_interactive("api.scb.se")

# Follow the steps in the console. 
# - save the JSON request in your working directory
# - copy paste the code the package write for you
# - Woo-hoo, you get the data already.
# - Thank the developers.

# With the interaction above, we get the code below:
# Download data 
px_data <- 
  pxweb_get(url = "https://api.scb.se/OV0104/v1/doris/en/ssd/UF/UF0550/UF0550C/Historisk11b",
            query = "[path to jsonfile]")

# Convert to data.frame 
px_data_frame <- as.data.frame(px_data, column.name.type = "text", variable.value.type = "text")

# Get pxweb data comments 
px_data_comments <- pxweb_data_comments(px_data)
px_data_comments_df <- as.data.frame(px_data_comments)

# Cite the data as (don't forget to give credits to people who contribute to the
# data and the package)
pxweb_cite(px_data)

# EXERCISE 1: download any data you are interested in. Tip: you can take a look
# at https://www.statistikdatabasen.scb.se/pxweb/en/ssd/ to find an interesting
# table.


################################ THE END #######################################

