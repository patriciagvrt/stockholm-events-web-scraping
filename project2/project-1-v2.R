################################## Project 1 ##################################
# Digital Strategies for the Social Sciences
# Project 1: Scraping event information from Visit Stockholm
#
# Website: https://www.visitstockholm.com/events/
#
# The goal of this project is to collect public event information from the
# Visit Stockholm events page and transform the HTML content into a dataset.
###############################################################################


# =============================================================================
# 1. PACKAGES
# =============================================================================

# Install these packages only once. After installing them, you can comment this line.

# install.packages(c("httr", "XML", "stringi", "jsonlite", "readr"))

library(httr)
library(XML)
library(stringi)
library(jsonlite)
library(readr)


# =============================================================================
# 2. WORKING DIRECTORY
# =============================================================================

# This tells me which folder R is working from right now.

getwd()

# Set the working directory to the project folder.
# Important: use / instead of \ on Windows.
# If another person runs this script, they may need to change this path.

setwd("C:/users/paty_/Documents/Github/Digital Strategies for Social Science Research/visit-stockholm-project")

# I check again if the working directory changed correctly.

getwd()


# =============================================================================
# 3. FETCH THE MAIN WEBSITE
# =============================================================================

# I define the URL of the Visit Stockholm events page.

url <- "https://www.visitstockholm.com/events/"

# I send a GET request to the website.

response <- GET(url)

# I check the HTTP status code.
# Status code 200 means that the request was successful.

response$status_code

# I check the response headers.
# The headers contain information about the server response.

response$headers

# I check the content type.
# This tells me that the website returns HTML and uses UTF-8 encoding.

response[["headers"]][["content-type"]]


# =============================================================================
# 4. INSPECT AND CONVERT THE CONTENT
# =============================================================================

# The response content is stored in raw format.
# If I print it directly, it appears as hexadecimal numbers.

response$content

# I check the class of the content.

class(response$content)

# I convert the raw response content into readable HTML text.

html <- content(response, as = "text", encoding = "UTF-8")

# I check the encoding of the converted text.

Encoding(html)

# I use stringi to detect the encoding from the raw response content.
# This helps me confirm that UTF-8 is the correct encoding.

stri_enc_detect(response$content)


# =============================================================================
# 5. SAVE AND LOAD THE HTML
# =============================================================================

# I save the HTML page to a local file.
# This is useful because I can work with a saved copy instead of requesting
# the website repeatedly.

writeLines(html, "visitstockholm.html")

# I read the saved HTML file back into R.

lines <- readLines("visitstockholm.html", encoding = "UTF-8")

# I combine all lines into one single HTML string again.

html <- paste0(lines, collapse = "\n")


# =============================================================================
# 6. PARSE THE HTML INTO A DOM TREE
# =============================================================================

# I parse the HTML text into a DOM tree.
# This allows me to use XPath to select specific parts of the page.

dom <- htmlParse(html)

# I test if a known event appears in the HTML.
# If this returns TRUE, the event is available in the HTML and Selenium is
# probably not necessary.

grepl("The Hornstull Market", html)


# =============================================================================
# 7. TEST THE HTML STRUCTURE
# =============================================================================

# I test different HTML tags to understand where the data is stored.

xpathSApply(dom, "//h1", xmlValue)

xpathSApply(dom, "//h2", xmlValue)

xpathSApply(dom, "//h3", xmlValue)

xpathSApply(dom, "//a", xmlValue)

# The h3 tags contain the event names.
# The a tags contain links, including the event links.


# =============================================================================
# 8. EXTRACT EVENT NAMES AND LINKS
# =============================================================================

# I extract all event names from h3 elements.

event_names <- xpathSApply(dom, "//h3", xmlValue)

# I remove extra spaces from the event names.

event_names <- trimws(event_names)

# I extract all links from the page.

all_links <- xpathSApply(dom, "//a", xmlGetAttr, "href")

# I keep only links that are event pages.
# This uses a regular expression to find links that follow the event page pattern.

event_links <- all_links[
  grepl("https://www.visitstockholm.com/events/.*/next/", all_links)
]

# I check if event names and event links have the same length.

length(event_names)
length(event_links)

# I create my first dataset with event names and links.

events_df <- data.frame(
  event_name = event_names,
  link = event_links,
  stringsAsFactors = FALSE
)

events_df


# =============================================================================
# 9. FIND WHERE DATES, CATEGORIES, AND LOCATIONS ARE STORED
# =============================================================================

# I test if the page has text inside paragraph tags.

xpathSApply(dom, "//p", xmlValue)

# The result is empty, so apparently the page does not use <p> tags
# to store dates, categories, or locations.

# I test other tags to find where this information is stored.

xpathSApply(dom, "//span", xmlValue)

xpathSApply(dom, "//div", xmlValue)

# The div result is too long and messy, so I save it in an object
# and only look at the first 30 results.

all_divs <- xpathSApply(dom, "//div", xmlValue)

head(all_divs, 30)

# I also test if the page uses <time> tags to store event dates.

xpathSApply(dom, "//time", xmlValue)

# The result is empty, so the dates are not stored in <time> tags.

# Now I collect all text elements from the page.
# This helps me see the order of the text in the HTML.

all_text <- xpathSApply(dom, "//*[text()]", xmlValue)

head(all_text, 100)

# Looking at the result, I can see that event information follows a pattern:
# event name, category, event name again, Calendar icon, date, Location icon, location.


# =============================================================================
# 10. EXTRACT CATEGORIES, DATES, AND LOCATIONS
# =============================================================================

# I clean all text values by removing extra spaces.

all_text <- trimws(all_text)

# I remove empty text values.

all_text <- all_text[all_text != ""]

# I find the positions where "Calendar icon" appears.
# The date usually comes right after "Calendar icon".

calendar_positions <- which(all_text == "Calendar icon")

calendar_positions

# The first Calendar icon belongs to the filter section, not to an event.
# I use a regular expression with month names to keep only real event dates.

month_pattern <- "Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec"

calendar_positions <- calendar_positions[
  grepl(month_pattern, all_text[calendar_positions + 1])
]

calendar_positions

# Now I extract information using the position around "Calendar icon".
#
# In the HTML pattern:
# category comes two positions before Calendar icon
# event name comes one position before Calendar icon
# date comes one position after Calendar icon
# location comes three positions after Calendar icon

event_categories <- all_text[calendar_positions - 2]

event_names <- all_text[calendar_positions - 1]

event_dates <- all_text[calendar_positions + 1]

event_locations <- all_text[calendar_positions + 3]

# I check if all vectors have the same length before creating the dataset.

length(event_names)

length(event_categories)

length(event_dates)

length(event_locations)

length(event_links)

# I create a more complete dataset with event name, category, date, location,
# and link.

events_df <- data.frame(
  event_name = event_names,
  category = event_categories,
  date = event_dates,
  location = event_locations,
  link = event_links,
  stringsAsFactors = FALSE
)

events_df


# =============================================================================
# 11. CHECK AND CLEAN THE DATASET
# =============================================================================

# I check the structure of my dataset.
# This helps me see the columns and the type of each variable.

str(events_df)

# I check the first rows of the dataset.

head(events_df)

# I check how many rows and columns I have.
# Each row should represent one event.

dim(events_df)

# I check if there are missing values in the dataset.

colSums(is.na(events_df))

# I check if there are duplicated events.
# Some events can appear more than once because the website may show the same
# event in different sections.

duplicated(events_df[, c("event_name", "link")])

# I count how many duplicated events there are.

sum(duplicated(events_df[, c("event_name", "link")]))

# I create a clean version of the dataset without duplicated events.
# I use event_name and link to identify duplicates.

events_df_clean <- events_df[!duplicated(events_df[, c("event_name", "link")]), ]

# I reset the row numbers after removing duplicates.

row.names(events_df_clean) <- NULL

# I check the size of the clean dataset.

dim(events_df_clean)

# I look at the clean dataset.

events_df_clean


# =============================================================================
# 12. VISIT INDIVIDUAL EVENT PAGES
# =============================================================================

# The project requires the crawler to automatically visit at least two pages.
# Until now, I collected data from the main events page.
# Now I use the event links to visit the individual event pages automatically.
# This means my crawler is not only using one page, but many sub-pages.

subpage_title <- c()
subpage_status <- c()

# I loop through all event links in the clean dataset.
# For each link, I send a GET request, convert the response to HTML text,
# parse the HTML, and extract the title from the individual event page.

for (i in 1:nrow(events_df_clean)) {
  
  # Get the link of one event.
  
  event_url <- events_df_clean$link[i]
  
  # Print progress, so I can see which page is being downloaded.
  
  print(paste("Downloading subpage", i, "of", nrow(events_df_clean)))
  
  # Download the individual event page.
  
  event_response <- GET(event_url)
  
  # Store the status code from the subpage.
  # Status code 200 means the subpage was successfully downloaded.
  
  subpage_status[i] <- event_response$status_code
  
  # Convert the response to readable HTML text.
  
  event_html <- content(event_response, as = "text", encoding = "UTF-8")
  
  # Parse the HTML into a DOM tree.
  
  event_dom <- htmlParse(event_html)
  
  # Extract the h1 title from the individual event page.
  # I use this to show that I visited and parsed each subpage.
  
  title <- xpathSApply(event_dom, "//h1", xmlValue)
  title <- trimws(title)
  
  # If the title is missing, I store NA.
  
  if (length(title) == 0) {
    title <- NA
  }
  
  # Store the result.
  
  subpage_title[i] <- title[1]
  
  # I add a small pause between requests to avoid sending too many requests
  # too fast.
  
  Sys.sleep(1)
}

# I add the information from the subpages to my clean dataset.

events_df_clean$subpage_title <- subpage_title

events_df_clean$subpage_status <- subpage_status

# I check the result.

head(events_df_clean)


# =============================================================================
# 13. CREATE A VARIABLE USING REGEX
# =============================================================================

# I use a regular expression to identify whether the date contains a dash.
# If the date contains "-", I classify it as a multi-day event.
# If not, I classify it as a single-day event.

events_df_clean$event_duration_type <- ifelse(
  grepl("-", events_df_clean$date),
  "Multi-day event",
  "Single-day event"
)

# I check the new variable.

events_df_clean[, c("event_name", "date", "event_duration_type")]

# I count how many events are single-day and how many are multi-day.

duration_count <- table(events_df_clean$event_duration_type)

duration_count

duration_df <- as.data.frame(duration_count)

names(duration_df) <- c("event_duration_type", "number_of_events")

duration_df


# =============================================================================
# 14. DESCRIPTIVE ANALYSIS BY CATEGORY
# =============================================================================

# I count how many events there are in each category.

category_count <- table(events_df_clean$category)

category_count

# I transform this table into a data frame because it is easier to use later.

category_df <- as.data.frame(category_count)

# I rename the columns to make them easier to understand.

names(category_df) <- c("category", "number_of_events")

category_df

# I order the categories from the most common to the least common.

category_df <- category_df[
  order(category_df$number_of_events, decreasing = TRUE),
]

category_df


# =============================================================================
# 15. DESCRIPTIVE ANALYSIS BY LOCATION
# =============================================================================

# I check which locations appear most often in the dataset.

location_count <- table(events_df_clean$location)

location_count

# I transform the location table into a data frame.

location_df <- as.data.frame(location_count)

names(location_df) <- c("location", "number_of_events")

location_df

# I order the locations from the most common to the least common.

location_df <- location_df[
  order(location_df$number_of_events, decreasing = TRUE),
]

location_df


# =============================================================================
# 16. VISUALIZATION
# =============================================================================

# I create a horizontal bar plot because some category names are long.
# This makes the labels easier to read.

png("visitstockholm_category_plot.png", width = 1000, height = 700)

# I increase the left margin to make space for long category names.

par(mar = c(5, 12, 4, 2))

barplot(
  category_df$number_of_events,
  names.arg = category_df$category,
  horiz = TRUE,
  las = 1,
  main = "Number of Visit Stockholm events by category",
  xlab = "Number of events",
  cex.names = 0.9
)

dev.off()

# I also show the plot in RStudio.

par(mar = c(5, 12, 4, 2))

barplot(
  category_df$number_of_events,
  names.arg = category_df$category,
  horiz = TRUE,
  las = 1,
  main = "Number of Visit Stockholm events by category",
  xlab = "Number of events",
  cex.names = 0.9
)


# =============================================================================
# 17. OPTIONAL API ENRICHMENT: GEOCODING LOCATIONS
# =============================================================================

# To aim for a higher grade, I enrich my dataset with latitude and longitude.
# I use the Nominatim API from OpenStreetMap to geocode event locations.
# I only request unique locations to avoid unnecessary requests.

unique_locations <- unique(events_df_clean$location)

geo_df <- data.frame(
  location = unique_locations,
  lat = NA,
  lon = NA,
  stringsAsFactors = FALSE
)

for (i in 1:nrow(geo_df)) {
  
  # I create a search query with the location name and Stockholm.
  # URLencode makes spaces and special characters safe for a URL.
  
  query <- URLencode(paste(geo_df$location[i], "Stockholm, Sweden"))
  
  api_url <- paste0(
    "https://nominatim.openstreetmap.org/search?q=",
    query,
    "&format=json&limit=1"
  )
  
  print(paste("Geocoding location", i, "of", nrow(geo_df)))
  
  # Nominatim requires a User-Agent.
  
  api_response <- GET(
    api_url,
    add_headers(
      "User-Agent" = "visit-stockholm-student-project/1.0"
    )
  )
  
  api_text <- content(api_response, as = "text", encoding = "UTF-8")
  
  api_json <- fromJSON(api_text)
  
  # If the API returns a result, I store latitude and longitude.
  
  if (length(api_json) > 0 && nrow(api_json) > 0) {
    geo_df$lat[i] <- api_json$lat[1]
    geo_df$lon[i] <- api_json$lon[1]
  }
  
  # I pause between requests to avoid sending too many requests too fast.
  
  Sys.sleep(1)
}

# I merge the geolocation data back into my events dataset.

events_df_final <- merge(
  events_df_clean,
  geo_df,
  by = "location",
  all.x = TRUE
)

# I check the final enriched dataset.

head(events_df_final)

str(events_df_final)

dim(events_df_final)


# =============================================================================
# 18. SAVE FINAL FILE
# =============================================================================

# I save only the final dataset.
# I use write_excel_csv because it saves the file in a way that Excel reads
# special characters better, including Swedish letters such as å, ä, and ö.

write_excel_csv(
  events_df_final,
  "visitstockholm_events_final.csv"
)


# =============================================================================
#
###############################################################################

