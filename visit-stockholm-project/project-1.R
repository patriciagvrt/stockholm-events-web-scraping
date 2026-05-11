################################## Project 1 ##################################
# Digital Strategies for the Social Sciences
# Project 1: Scraping event information from Visit Stockholm
#
# Website: https://www.visitstockholm.com/events/
#
# The goal of this project is to collect public event information from the
# Visit Stockholm events page and transform the HTML content into a dataset.
###############################################################################


# 1. PACKAGES
# ===========

# Install these packages only once. After installing them, you can comment this line.
# install.packages(c("httr", "XML", "rvest", "stringi"))

library(httr)
library(XML)
library(rvest)
library(stringi)


# 2. WORKING DIRECTORY
# ====================

# Check which folder R is currently using
getwd()

# Set the working directory to the project folder..
setwd("C:/users/pg/Documents/Github/Digital-Strategies-for-Social-Science-Research/visit-stockholm-project")

# Check again to confirm that the working directory changed correctly
getwd()


# 3. FETCH THE WEBSITE
# ====================

# Define the URL of the Visit Stockholm events page
url <- "https://www.visitstockholm.com/events/"

# Send a GET request to the website
response <- GET(url)

# Check the HTTP status code.
# Status code 200 means that the request was successful.
response$status_code

# Inspect the response headers.
# Headers contain metadata about the response, such as content type and encoding.
response$headers

# Check the content type returned by the server.
# This tells us that the page is HTML and uses UTF-8 encoding.
response[["headers"]][["content-type"]]


# 4. INSPECT THE RAW CONTENT
# =========================

# The response content is stored in raw format.
# This is why it appears as hexadecimal numbers if printed directly.
response$content

# Confirm that the content is raw
class(response$content)


# 5. CONVERT RAW CONTENT TO TEXT
# ==============================

# Convert the raw response content into readable HTML text.
html <- content(response, as = "text", encoding = "UTF-8")

# Check the encoding of the converted text
Encoding(html)

# Use stringi to detect the encoding from the raw response content.
# This helps confirm that UTF-8 is the correct encoding.
stri_enc_detect(response$content)


# 6. SAVE AND LOAD THE HTML
# =========================

# Save the HTML page to a local file.
# This is useful because we can work with a saved copy instead of requesting
# the website repeatedly.
writeLines(html, "visitstockholm.html")

# Read the saved HTML file back into R.
# readLines() reads the file line by line.
lines <- readLines("visitstockholm.html", encoding = "UTF-8")

# Combine all lines into one single HTML string again.
html <- paste0(lines, collapse = "\n")


# 7. PARSE THE HTML INTO A DOM TREE
# =================================

# Parse the HTML text into a DOM tree.
# This allows us to use XPath to select specific parts of the webpage later.
dom <- htmlParse(html)


# 8. CHECK WHETHER EVENT DATA IS PRESENT IN THE HTML
# ==================================================

# This checks whether a known event name appears in the HTML.
# If the result is TRUE, the event is available in the HTML .
grepl("The Hornstull Market", html)


# 9. SAVE AND LOAD THE FULL RESPONSE OBJECT
# =========================================

# Save the full response object as an .rds file.
# This keeps the status code, headers, and raw content together.
saveRDS(response, "visitstockholm_response.rds")

# Load the full response object again if needed.
response <- readRDS("visitstockholm_response.rds")
