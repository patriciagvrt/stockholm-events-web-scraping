################################## Project 1 ##################################
# Digital Strategies for the Social Sciences
# Project 1: Scraping event information from Visit Stockholm
#
# Website: https://www.visitstockholm.com/events/
#
# This project uses the Visit Stockholm events page to create a small dataset
# about events in Stockholm. The idea is to download the HTML, understand how
# the page is structured, extract the relevant information, and save it as a
# clean dataset.
###############################################################################


# 1. PACKAGES
# These packages  to download webpages, parse HTML, check encoding,
# work with JSON from the API, and save the final CSV file.

install.packages(c("httr", "XML", "stringi", "jsonlite", "readr"))

library(httr)
library(XML)
library(stringi) #this libary can help with encoding and special simbols
library(jsonlite)
library(readr)



# 2. WORKING DIRECTORY
# Checking the folder R is currently using.

getwd()

# Setting the working directory to the project folder.
# This path may need to be changed if the script is run on another computer.

setwd("~/GitHub/Digital-Strategies-for-Social-Science-Research/project2")

# Checking again if R is now using the correct folder.

getwd()



# 3. FETCH THE MAIN WEBSITE
# Defining the URL of the Visit Stockholm events page.

url <- "https://www.visitstockholm.com/events/"

# Sending a GET request to download the page.

response <- GET(url)

# Checking the HTTP status code.
# A status code of 200 means that the request worked.

response$status_code

# Looking at the response headers, since they give information about
# the server response.

response$headers

# Checking the content type.
# This tells me that the page is HTML and uses UTF-8 encoding.

response[["headers"]][["content-type"]]



# 4. INSPECT AND CONVERT THE CONTENT

# The page content is first stored as raw data.
# When printed directly, it appears as hexadecimal numbers.

response$content

# Checking the class confirms that the content is raw.

class(response$content)

# Converting the raw response into readable HTML text.

html <- content(response, as = "text", encoding = "UTF-8")

# Checking the encoding of the converted text.

Encoding(html)

# Using stringi as an additional check for the encoding.
# This helps confirm that UTF-8 is the right encoding.

stri_enc_detect(response$content)



# 5. SAVE AND LOAD THE HTML

# Saving the HTML page locally.
# AS I learn in class this makes it easier to work with the same page while testing the code,
# instead of requesting the website every time.

writeLines(html, "visitstockholm.html")

# Reading the saved HTML file back into R.

lines <- readLines("visitstockholm.html", encoding = "UTF-8")

# Combining all lines into one single HTML string again.

html <- paste0(lines, collapse = "\n")



# 6. PARSE THE HTML INTO A DOM TREE

# Parsing the HTML text into a DOM tree.
# This is necessary because XPath works on the parsed HTML structure,
# not just on a plain text string.

dom <- htmlParse(html)

# Testing whether a known event appears in the HTML.
# If this returns TRUE, the event data is already available in the HTML,
# so Selenium is probably not need it.

grepl("The Hornstull Market", html)



# 7. TEST THE HTML STRUCTURE and EXTRACT EVENT NAMES AND LINKS

# Testing different HTML tags to understand where the useful information
# is stored on the page.

xpathSApply(dom, "//h1", xmlValue)

xpathSApply(dom, "//h2", xmlValue)

xpathSApply(dom, "//h3", xmlValue)

xpathSApply(dom, "//a", xmlValue)

# From these tests, the h3 tags seem to contain the event names.
# The a tags contain links, including the links to individual event pages.



 

# Extracting the event names from h3 elements.

event_names <- xpathSApply(dom, "//h3", xmlValue)

# Removing extra spaces from the event names.

event_names <- trimws(event_names)

# Extracting all links from the page.

all_links <- xpathSApply(dom, "//a", xmlGetAttr, "href")

# Keeping only the links that point to event pages.
# This regular expression looks for links with the Visit Stockholm event pattern.

event_links <- all_links[
  grepl("https://www.visitstockholm.com/events/.*/next/", all_links)
]

# Checking whether event names and event links have the same length.
# If they match, they can be combined into a dataframe.

length(event_names)
length(event_links)

# Creating a first dataset with event names and links.

events_df <- data.frame(
  event_name = event_names,
  link = event_links,
  stringsAsFactors = FALSE
)

events_df



# 8. FIND WHERE DATES, CATEGORIES, AND LOCATIONS ARE STORED

# Testing if the page stores text inside paragraph tags.

xpathSApply(dom, "//p", xmlValue)

# The result is empty, so the page does not seem to use <p> tags
# for dates, categories, or locations.

# Testing other tags to see where the information is stored.

xpathSApply(dom, "//span", xmlValue)

xpathSApply(dom, "//div", xmlValue)

# The div result is very long and messy, because divs contain many nested
# elements such as menus, filters, icons, and event cards.
# To make it easier to inspect, I save it and look only at the first results.

all_divs <- xpathSApply(dom, "//div", xmlValue)

head(all_divs, 30)

# Testing whether the page uses <time> tags for event dates.

xpathSApply(dom, "//time", xmlValue)

# The result is empty, so the dates are not stored in <time> tags.

# Collecting all text elements from the page.
# This helps show the order in which the event information appears in the HTML.

all_text <- xpathSApply(dom, "//*[text()]", xmlValue)

head(all_text, 100)

# By looking at the output, the event information seems to follow this pattern:
# event name, category, event name again, Calendar icon, date, Location icon, location.



# 9. EXTRACT CATEGORIES, DATES, AND LOCATIONS

# Cleaning the text values by removing extra spaces.

all_text <- trimws(all_text)

# Removing empty text values.

all_text <- all_text[all_text != ""]

# Finding the positions where "Calendar icon" appears.
# The event date usually appears right after this text.

calendar_positions <- which(all_text == "Calendar icon")

calendar_positions

# The first Calendar icon belongs to the filter section, not to an actual event.
# To remove that, I use a regular expression with month names and keep only
# Calendar icons that are followed by a real date.

month_pattern <- "Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec"

calendar_positions <- calendar_positions[
  grepl(month_pattern, all_text[calendar_positions + 1])
]

calendar_positions

# Extracting information based on the repeated pattern around "Calendar icon".
#
# In the HTML text pattern:
# category comes two positions before Calendar icon
# event name comes one position before Calendar icon
# date comes one position after Calendar icon
# location comes three positions after Calendar icon

event_categories <- all_text[calendar_positions - 2]

event_names <- all_text[calendar_positions - 1]

event_dates <- all_text[calendar_positions + 1]

event_locations <- all_text[calendar_positions + 3]

# Checking if all vectors have the same length before creating the dataset.

length(event_names)

length(event_categories)

length(event_dates)

length(event_locations)

length(event_links)

# Creating a more complete dataset with event name, category, date,
# location, and link.

events_df <- data.frame(
  event_name = event_names,
  category = event_categories,
  date = event_dates,
  location = event_locations,
  link = event_links,
  stringsAsFactors = FALSE
)

events_df



# 10. CHECK AND CLEAN THE DATASET

# Checking the structure of the dataset.
# This shows the columns and the type of each variable.

str(events_df)

# Looking at the first rows of the dataset.

head(events_df)

# Checking how many rows and columns the dataset has.
# Each row should represent one event.

dim(events_df)

# Checking if there are missing values.

colSums(is.na(events_df))

# Checking duplicated events.
# Some events can appear more than once because the website shows them
# in different sections.

duplicated(events_df[, c("event_name", "link")])

# Counting how many duplicated events there are.

sum(duplicated(events_df[, c("event_name", "link")]))

# Creating a clean version of the dataset without duplicated events.
# Event name and link are used together to identify duplicates.

events_df_clean <- events_df[!duplicated(events_df[, c("event_name", "link")]), ]

# Resetting the row numbers after removing duplicates.

row.names(events_df_clean) <- NULL



# I keep only valid event categories.
# This is a safety check because the HTML text extraction can sometimes capture
# other text around the event cards.

valid_categories <- c(
  "Festivals",
  "Family",
  "Eat & Drink",
  "Music",
  "Fairs",
  "Exhibitions",
  "Sports & Wellbeing",
  "Stage & Film",
  "Networking & Community",
  "Clubs & Parties",
  "Guided tours",
  "Science & Tech",
  "Christmas & New Year's",
  "Careers & Leadership",
  "Gaming & Boardgames"
)

events_df_clean <- events_df_clean[events_df_clean$category %in% valid_categories, ]

row.names(events_df_clean) <- NULL

# Checking the categories after filtering.

unique(events_df_clean$category)






# Checking the size of the clean dataset.

dim(events_df_clean)

# Looking at the clean dataset.

events_df_clean



# 11. VISIT INDIVIDUAL EVENT PAGES AND EXTRACT ADDRESS AND DESCRIPTION

# The project requires the crawler to automatically visit at least two pages.
# The main page gives the event cards, and the event links are used to visit
# the individual event pages.
#
# From each subpage, I extract the title, status code, event description,
# venue name, street address, and city.

subpage_title <- c()
subpage_status <- c()
event_description <- c()
subpage_venue <- c()
subpage_street_address <- c()
subpage_postal_code <- c()
subpage_city <- c()

for (i in 1:nrow(events_df_clean)) {
  
  # Getting the link of one event.
  
  event_url <- events_df_clean$link[i]
  
  # Printing progress to see which subpage is being downloaded.
  
  print(paste("Downloading subpage", i, "of", nrow(events_df_clean)))
  
  # Downloading the individual event page.
  
  event_response <- GET(event_url)
  
  # Saving the status code from the subpage.
  # Status code 200 means that the subpage was successfully downloaded.
  
  subpage_status[i] <- event_response$status_code
  
  # Converting the response to readable HTML text.
  
  event_html <- content(event_response, as = "text", encoding = "UTF-8")
  
  # Parsing the subpage HTML into a DOM tree.
  
  event_dom <- htmlParse(event_html)
  
  # Extracting the h1 title from the individual event page.
  
  title <- xpathSApply(event_dom, "//h1", xmlValue)
  title <- trimws(title)
  
  if (length(title) == 0) {
    title <- NA
  }
  
  subpage_title[i] <- title[1]
  
  
  # Collecting all text elements from the subpage.
  # This helps find the description and address information.
  
  page_text <- xpathSApply(event_dom, "//*[text()]", xmlValue)
  
  page_text <- trimws(page_text)
  
  page_text <- page_text[page_text != ""]
  
  
  # The event description usually appears right before "All dates".
  # I use "All dates" as an anchor to locate the description.
  
  all_dates_position <- which(page_text == "All dates")
  
  if (length(all_dates_position) > 0) {
    event_description[i] <- page_text[all_dates_position[1] - 1]
  } else {
    event_description[i] <- NA
  }
  
  
  # The address information usually appears after "Getting there".
  # The pattern on the subpages is: Getting there, Location icon, venue name, street address, city.
  
  getting_there_position <- which(page_text == "Getting there")
  
  if (length(getting_there_position) > 0) {
    
    # Using the first "Getting there" section.
    
    pos <- getting_there_position[1]
    
    subpage_venue[i] <- page_text[pos + 2]
    subpage_street_address[i] <- page_text[pos + 3]
    
    # Some pages include a postal code between the street address and the city.
    # Swedish postal codes usually look like "121 77" or "11138".
    # This regular expression checks if the next value is a postal code.
    
    possible_postal_code <- page_text[pos + 4]
    possible_city <- page_text[pos + 5]
    
    postal_code_pattern <- "^\\d{3}\\s?\\d{2}$"
    
    if (grepl(postal_code_pattern, possible_postal_code)) {
      
      subpage_postal_code[i] <- possible_postal_code
      subpage_city[i] <- possible_city
      
    } else {
      
      subpage_postal_code[i] <- NA
      subpage_city[i] <- possible_postal_code
    }
    
  } else {
    
    # If the page does not have a Getting there section, missing values are stored.
    
    subpage_venue[i] <- NA
    subpage_street_address[i] <- NA
    subpage_postal_code[i] <- NA
    subpage_city[i] <- NA
  }
  
  
  # Adding a small pause between requests to avoid sending too many requests
  # too quickly.
  
  Sys.sleep(1)
}

# Adding the information from the subpages to the clean dataset.

events_df_clean$subpage_title <- subpage_title

events_df_clean$subpage_status <- subpage_status

events_df_clean$event_description <- event_description

events_df_clean$subpage_venue <- subpage_venue

events_df_clean$street_address <- subpage_street_address

events_df_clean$postal_code <- subpage_postal_code

events_df_clean$city <- subpage_city

# Checking the extracted subpage information.

events_df_clean[, c(
  "event_name",
  "event_description",
  "location",
  "subpage_venue",
  "street_address",
  "postal_code",
  "city",
  "subpage_status"
)]



# 12. CREATE A VARIABLE USING REGEX

# Using a regular expression to identify whether the date contains a dash.
# If the date contains "-", the event is classified as a multi-day event.
# Otherwise, it is classified as a single-day event.
# This part is based on Lab 5, where we learned to use regular expressions
# to identify and extract patterns in text.



events_df_clean$event_duration_type <- ifelse(
  grepl("-", events_df_clean$date),
  "Multi-day event",
  "Single-day event"
)

# Checking the new variable.

events_df_clean[, c("event_name", "date", "event_duration_type")]

# Counting how many events are single-day and how many are multi-day.

duration_count <- table(events_df_clean$event_duration_type)

duration_count

duration_df <- as.data.frame(duration_count)

names(duration_df) <- c("event_duration_type", "number_of_events")

duration_df

# DOWNLOAD ONE EVENT IMAGE

# To make a vizuaztion of the amin event  to download one non-text file from an event page.
# I use the first event page and look for the Open Graph image.

test_event_url <- events_df_clean$link[1]

test_event_response <- GET(test_event_url)

test_event_html <- content(test_event_response, as = "text", encoding = "UTF-8")

test_event_dom <- htmlParse(test_event_html)

test_image_url <- xpathSApply(
  test_event_dom,
  "//meta[@property='og:image']",
  xmlGetAttr,
  "content"
)

test_image_url

# I download it as a JPG file.

if (length(test_image_url) > 0) {
  
  image_response <- GET(
    test_image_url[1],
    write_disk("visitstockholm_event_image.jpg", overwrite = TRUE)
  )
  
  image_response$status_code
}

# 13. DESCRIPTIVE ANALYSIS BY CATEGORY

# Counting how many events there are in each category.

category_count <- table(events_df_clean$category)

category_count

# Transforming the table into a dataframe because it is easier to work with.

category_df <- as.data.frame(category_count)

# Renaming the columns to make them easier to understand.

names(category_df) <- c("category", "number_of_events")

category_df

# Ordering the categories from most common to least common.

category_df <- category_df[
  order(category_df$number_of_events, decreasing = TRUE),
]

category_df


# 14. DESCRIPTIVE ANALYSIS BY LOCATION

# Counting how many times each location appears in the dataset.

location_count <- table(events_df_clean$location)

location_count

# Transforming the location table into a dataframe.

location_df <- as.data.frame(location_count)

names(location_df) <- c("location", "number_of_events")

location_df

# Ordering the locations from most common to least common.

location_df <- location_df[
  order(location_df$number_of_events, decreasing = TRUE),
]

location_df



# 15. VISUALIZATION

# Creating a horizontal bar plot because some category names are long.
# I increase the image size and the left margin so the labels are not cut.

png("visitstockholm_category_plot.png", width = 1400, height = 900)

par(mar = c(5, 18, 4, 2))

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

# Showing the same plot in RStudio.

#par(mar = c(5, 18, 4, 2))

#barplot(
#  category_df$number_of_events,
#  names.arg = category_df$category,
#  horiz = TRUE,
#  las = 1,
#  main = "Number of Visit Stockholm events by category",
#  xlab = "Number of events",
#  cex.names = 0.9
#)


# 16. PREPARE ADDRESS FOR GEOCODING and  API - GEOCODING ADDRESSES

# Creating a geocoding query.
# If the street address exists, I use street address + city + Sweden.
# If the street address is missing, I use the location name + Stockholm + Sweden.

events_df_clean$geocode_query <- ifelse(
  is.na(events_df_clean$street_address),
  paste(events_df_clean$location, "Stockholm, Sweden"),
  paste(events_df_clean$street_address, events_df_clean$postal_code, events_df_clean$city, "Sweden")
)

# Checking the geocoding query.

events_df_clean[, c("event_name", "location", "street_address", "postal_code", "city", "geocode_query")]



# I planned toenriched the dataset  with latitude and longitude.
# The address extracted from the individual event pages is used when available.
# Only unique address queries are requested to avoid unnecessary API calls.

unique_queries <- unique(events_df_clean$geocode_query)

geo_df <- data.frame(
  geocode_query = unique_queries,
  lat = NA,
  lon = NA,
  stringsAsFactors = FALSE
)

for (i in 1:nrow(geo_df)) {
  
  # URLencode makes spaces and special characters safe for a URL.
  
  query <- URLencode(geo_df$geocode_query[i])
  
  api_url <- paste0(
    "https://nominatim.openstreetmap.org/search?q=",
    query,
    "&format=json&limit=1"
  )
  
  print(paste("Geocoding address", i, "of", nrow(geo_df)))
  
  # Nominatim requires a User-Agent.
  
  api_response <- GET(
    api_url,
    add_headers(
      "User-Agent" = "visit-stockholm-student-project/1.0"
    )
  )
  
  api_text <- content(api_response, as = "text", encoding = "UTF-8")
  
  api_json <- fromJSON(api_text)
  
  # If the API returns a result, latitude and longitude are stored.
  
  if (length(api_json) > 0 && nrow(api_json) > 0) {
    geo_df$lat[i] <- api_json$lat[1]
    geo_df$lon[i] <- api_json$lon[1]
  }
  
  # Pausing between requests to avoid sending too many requests too quickly.
  
  Sys.sleep(1)
}

# Merging the geolocation data back into the event dataset.

events_df_final <- merge(
  events_df_clean,
  geo_df,
  by = "geocode_query",
  all.x = TRUE
)
# I remove the geocode_query column from the final dataset because it was only
# used as a helper column for the geocoding API.

events_df_final$geocode_query <- NULL

# Checking the final enriched dataset.

head(events_df_final)

str(events_df_final)

dim(events_df_final)



# 17. SAVE FINAL FILE

# Saving only the final dataset.
# write_excel_csv is used because it usually handles special characters better, and I
# had a small problem with the special caracters
# when the file is opened in Excel.

write_excel_csv(
  events_df_final,
  "visitstockholm_events_final.csv"
)


