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


#10. EXTRACT LINKS AND TITLES


# Test to see what elements we have inside the page

xpathSApply(dom, "//h1", xmlValue)
xpathSApply(dom, "//h2", xmlValue)
xpathSApply(dom, "//h3", xmlValue)
xpathSApply(dom, "//a", xmlValue)
#“I first inspected the HTML structure using XPath. 
#The main page title was stored in h1, section titles were stored in h2, 
#and individual event titles were stored in h3. I used the h3 elements to extract the event names.

# Now I'm going to store the events name in a object

event_names <- xpathSApply(dom, "//h3", xmlValue)

event_names
# Clean the extra spaces and see how many I got

event_names <- trimws(event_names)
length(event_names)

# I will take all the events links since the a that I used
# got my non usefull facts liken menu and privacy policy thats why
# I got 49 results intead of only 26

all_links <- xpathSApply(dom, "//a", xmlGetAttr, "href")

all_links

event_links <- all_links[14:39]

event_links
# I see that the events links are from 14 to 39 so I created
# a object with only the events links

length(event_names)
length(event_links)

# I tested if event names and event links have the same length.
# Both have length 26, so now I can create the first table.

length(event_names)
length(event_links)

events_df <- data.frame(
  event_name = event_names,
  link = event_links
)

events_df

# Now I have my first dataset with event names and links.
# The next step is to check where the dates, categories, and locations are stored.


# First, I test if the page has text inside paragraph tags.

xpathSApply(dom, "//p", xmlValue)

# The result is empty, so apparently the page does not use <p> tags
# to store dates, categories, or locations.


# Now I will test other HTML tags to find where this information is stored.

xpathSApply(dom, "//span", xmlValue)

xpathSApply(dom, "//div", xmlValue)

# The result from //div is too broad because divs contain many nested elements.
# This means that the text from menus, filters, event cards, and footer appears
# mixed together.
# Therefore, //div is not specific enough for extracting the final dataset.

# However, when I look at all text elements, I can identify a repeated pattern
# in the event cards:
# event name, category, event name again, Calendar icon, date, Location icon, location.

all_divs <- xpathSApply(dom, "//div", xmlValue)

head(all_divs, 30)


# I also test if the page uses <time> tags to store event dates.

xpathSApply(dom, "//time", xmlValue)

# The result is empty, so the dates are not stored in <time> tags.


# Now I collect all text elements from the page.
# This helps me see the order of the text in the HTML.

all_text <- xpathSApply(dom, "//*[text()]", xmlValue)

head(all_text, 100)

# Looking at the result, I can see that the event information follows a pattern:
# event name, category, event name again, Calendar icon, date, Location icon, location.
# This means I can use the position of "Calendar icon" to extract the date
# and the position of "Location icon" to extract the location.

# Now I clean the text by removing extra spaces.

all_text <- trimws(all_text)

# I remove empty text values.

all_text <- all_text[all_text != ""]


# I find the positions where "Calendar icon" appears.
# The date usually comes right after "Calendar icon".

calendar_positions <- which(all_text == "Calendar icon")

calendar_positions


# I create a pattern with month names.
# This helps me keep only the Calendar icons that are followed by a real date.

month_pattern <- "Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec"

calendar_positions <- calendar_positions[
  grepl(month_pattern, all_text[calendar_positions + 1])
]

calendar_positions


# Now I extract the information using the position around "Calendar icon".
# In the HTML pattern:
# category comes two positions before Calendar icon
# event name comes one position before Calendar icon
# date comes one position after Calendar icon
# location comes three positions after Calendar icon

event_categories <- all_text[calendar_positions - 2]

event_names <- all_text[calendar_positions - 1]

event_dates <- all_text[calendar_positions + 1]

event_locations <- all_text[calendar_positions + 3]


# I check if all vectors have the same length before creating the final table.

length(event_names)
length(event_categories)
length(event_dates)
length(event_locations)
length(event_links)


# Now I create a more complete dataset with event name, category, date,
# location, and link.

events_df <- data.frame(
  event_name = event_names,
  category = event_categories,
  date = event_dates,
  location = event_locations,
  link = event_links
)

events_df


# Finally, I save the dataset as a CSV file.

write.csv(events_df, "visitstockholm_events.csv", row.names = FALSE)

# =============================================================================
# CLEANING AND CHECKING THE DATASET
# =============================================================================

# First, I check the structure of my dataset.
# This helps me see the columns and the type of each variable.

str(events_df)


# I also check the first rows of the dataset.

head(events_df)


# I check how many rows and columns I have.
# In this case, each row should represent one event.

dim(events_df)


# I check if there are missing values in the dataset.
# This is important because missing values can affect the analysis later.

colSums(is.na(events_df))


# I check if there are duplicated events.
# Some events can appear more than once because the website may show the same
# event in different sections.

duplicated(events_df[, c("event_name", "link")])


# I count how many duplicated events there are.

sum(duplicated(events_df[, c("event_name", "link")]))


# Now I create a clean version of the dataset without duplicated events.
# I use event_name and link to identify duplicates.

events_df_clean <- events_df[!duplicated(events_df[, c("event_name", "link")]), ]


# I check the size of the clean dataset.

dim(events_df_clean)


# I look at the clean dataset.

events_df_clean


# =============================================================================
# DESCRIPTIVE ANALYSIS
# =============================================================================

# Now I start with a simple descriptive analysis.
# First, I count how many events there are in each category.

category_count <- table(events_df_clean$category)

category_count


# I transform this table into a data frame because it is easier to save,
# print, and use later.

category_df <- as.data.frame(category_count)

# I rename the columns to make them easier to understand.

names(category_df) <- c("category", "number_of_events")

category_df


# I order the categories from the most common to the least common.

category_df <- category_df[order(category_df$number_of_events, decreasing = TRUE), ]

category_df


# I also check which locations appear most often in the dataset.

location_count <- table(events_df_clean$location)

location_count


# I transform the location table into a data frame.

location_df <- as.data.frame(location_count)

names(location_df) <- c("location", "number_of_events")

location_df


# I order the locations from the most common to the least common.

location_df <- location_df[order(location_df$number_of_events, decreasing = TRUE), ]

location_df






