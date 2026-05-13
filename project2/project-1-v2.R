################################## Project 1 ##################################
# Digital Strategies for the Social Sciences
# Project 1: Scraping event information from Visit Stockholm
#
# Website: https://www.visitstockholm.com/events/
#
# The idea here is to build a small dataset about events happening in Stockholm
# by scraping the Visit Stockholm events page. I download the HTML, figure out
# where the data actually lives in the page structure, extract it, and then
# enrich it with geolocation data from an API.
###############################################################################


# 1. PACKAGES
# I need httr to send HTTP requests, XML to parse the HTML, stringi to deal
# with encoding (Stockholm has a lot of Swedish characters that can go wrong),
# jsonlite to work with the API response, and readr to save the final CSV.

#install.packages(c("httr", "XML", "stringi", "jsonlite", "readr"))

library(httr)
library(XML)
library(stringi)
library(jsonlite)
library(readr)



# 2. WORKING DIRECTORY
# First checking where R thinks we are right now.

getwd()

# Setting the folder to the project folder.
# If you run this on a different computer, you will need to change this path.

setwd("~/GitHub/Digital-Strategies-for-Social-Science-Research/project2")

# Checking again to confirm.

getwd()



# 3. FETCH THE MAIN PAGE
# This is the main events page I want to scrape.

url <- "https://www.visitstockholm.com/events/"

# Sending a GET request to download the page content.

response <- GET(url)

# A status code of 200 means the request worked fine.

response$status_code

# Looking at the headers to understand what kind of response came back.

response$headers

# Checking the content type. This tells me the page is HTML with UTF-8 encoding,
# which is what I expected.

response[["headers"]][["content-type"]]



# 4. CONVERT THE RESPONSE TO READABLE TEXT

# The raw response is in hexadecimal and not useful to read directly.

#response$content

# I can see that the response is in hexadecimal 
# I comment so it wont be too extensive in the code file

# Confirming the class is  raw.

class(response$content)

# Converting the raw response into a readable HTML string using UTF-8 encoding.

html <- content(response, as = "text", encoding = "UTF-8")

# Checking the encoding of the result.

Encoding(html)

# Using stringi to double-check the encoding detection.
# This helped me confirm that UTF-8 was the right choice for this page.

stri_enc_detect(response$content)



# 5. SAVE AND RELOAD THE HTML

# Saving the HTML locally so I don't have to re-request the page every time
# I run the script while testing. This was very useful during development
# because I could just reload the saved file instead of hitting the server
# over and over.

writeLines(html, "visitstockholm.html")

# Reading the saved file back in.

lines <- readLines("visitstockholm.html", encoding = "UTF-8")

# Joining the lines back into one HTML string.

html <- paste0(lines, collapse = "\n")



# 6. PARSE THE HTML AND CHECK IF THE DATA IS THERE

# Parsing the HTML into a DOM tree so I can use XPath to navigate the structure.
# XPath doesn't work on raw text strings, it needs the parsed tree.

dom <- htmlParse(html)

# Before doing anything else, I wanted to check if the event data is actually
# embedded in the HTML, or if it loads dynamically with JavaScript.
# If this returns TRUE, I don't need Selenium — the data is already there.

grepl("The Hornstull Market", html)



# 7. EXPLORE THE PAGE STRUCTURE AND EXTRACT NAMES + LINKS

# I tested different tags to figure out where the useful information was stored.
# This exploration step was important because the page doesn't use obvious
# semantic tags for its event data.

xpathSApply(dom, "//h1", xmlValue)

xpathSApply(dom, "//h2", xmlValue)

xpathSApply(dom, "//h3", xmlValue)

xpathSApply(dom, "//a", xmlValue)

# From testing, h3 tags contain the event names and a tags contain the links.



# Extracting event names from h3 elements.

event_names <- xpathSApply(dom, "//h3", xmlValue)

# Removing extra whitespace.

event_names <- trimws(event_names)

# Extracting all links from the page.

all_links <- xpathSApply(dom, "//a", xmlGetAttr, "href")

# Keeping only links that match the Visit Stockholm event URL pattern.
# I used a regular expression here to filter out navigation links,
# footer links, and other things that are not event pages.

event_links <- all_links[
  grepl("https://www.visitstockholm.com/events/.*/next/", all_links)
]

# Checking that names and links have the same length before combining them.

length(event_names)
length(event_links)

# First version of the dataset — just names and links for now.

events_df <- data.frame(
  event_name = event_names,
  link = event_links,
  stringsAsFactors = FALSE
)

events_df



# 8. FINDING WHERE DATES, CATEGORIES, AND LOCATIONS ARE STORED

# Testing paragraph tags first — empty, so dates and categories are not in <p>.

xpathSApply(dom, "//p", xmlValue)

# Testing span and div tags.

xpathSApply(dom, "//span", xmlValue)

xpathSApply(dom, "//div", xmlValue)

# The div result is very messy because divs wrap everything including menus,
# filters, and icons. Saving it and looking at just the first few results
# was more useful.

all_divs <- xpathSApply(dom, "//div", xmlValue)

head(all_divs, 30)

# Testing time tags — empty, so dates are not stored there either.

xpathSApply(dom, "//time", xmlValue)

# Collecting ALL text elements from the page to understand the structure.
# This was the approach that actually worked — by seeing the order of
# all text elements, I could spot a repeating pattern around the events.

all_text <- xpathSApply(dom, "//*[text()]", xmlValue)

head(all_text, 100)

# The pattern I found: event name, category, event name again,
# "Calendar icon", date, "Location icon", location.
# Once I saw this, I could use "Calendar icon" as an anchor to extract
# everything around it.



# 9. EXTRACT CATEGORIES, DATES, AND LOCATIONS

# Cleaning up whitespace and removing empty text nodes.

all_text <- trimws(all_text)

all_text <- all_text[all_text != ""]

# Finding all positions where "Calendar icon" appears in the text vector.
# The date is always one position after this.

calendar_positions <- which(all_text == "Calendar icon")

calendar_positions

# The first "Calendar icon" is in the filter section at the top of the page,
# not from an actual event. I filter those out by checking whether the next
# element is actually a month name. If it's not, it's not a real event date.

month_pattern <- "Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec"

calendar_positions <- calendar_positions[
  grepl(month_pattern, all_text[calendar_positions + 1])
]

calendar_positions

# Extracting information based on the fixed pattern around "Calendar icon":
# category  = 2 positions before Calendar icon
# event name = 1 position before Calendar icon
# date       = 1 position after Calendar icon
# location   = 3 positions after Calendar icon

event_categories <- all_text[calendar_positions - 2]

event_names <- all_text[calendar_positions - 1]

event_dates <- all_text[calendar_positions + 1]

event_locations <- all_text[calendar_positions + 3]

# Checking lengths before creating the dataset.

length(event_names)

length(event_categories)

length(event_dates)

length(event_locations)

length(event_links)

# Building the dataset.

events_df <- data.frame(
  event_name = event_names,
  category = event_categories,
  date = event_dates,
  location = event_locations,
  link = event_links,
  stringsAsFactors = FALSE
)

events_df



# 10. CLEAN THE DATASET

# Checking structure and contents.

str(events_df)

head(events_df)

dim(events_df)

# Checking for missing values.

colSums(is.na(events_df))

# Checking for duplicate events — the website sometimes shows the same event
# in multiple sections of the page.

duplicated(events_df[, c("event_name", "link")])

sum(duplicated(events_df[, c("event_name", "link")]))

# Removing duplicates using event name and link together.

events_df_clean <- events_df[!duplicated(events_df[, c("event_name", "link")]), ]

row.names(events_df_clean) <- NULL



# Filtering to keep only rows that have a valid event category.
# The text extraction sometimes grabs extra text from around the event cards,
# so this step removes anything that does not belong to a known category.

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

# Checking the categories look right after filtering.

unique(events_df_clean$category)

# Checking the size of the cleaned dataset.

dim(events_df_clean)

events_df_clean



# 11. VISIT INDIVIDUAL EVENT PAGES

# The project requires the crawler to visit at least two pages automatically.
# Here I loop through the event links and visit each individual event page
# to extract more detailed information: description, venue, street address, and city.
#
# This is where the scraper moves beyond just the listing page and actually
# follows each event to its own subpage.

subpage_title <- c()
subpage_status <- c()
event_description <- c()
subpage_venue <- c()
subpage_street_address <- c()
subpage_postal_code <- c()
subpage_city <- c()

for (i in 1:nrow(events_df_clean)) {
  
  event_url <- events_df_clean$link[i]
  
  # Printing progress so I can see what is happening while it runs.
  
  print(paste("Downloading subpage", i, "of", nrow(events_df_clean)))
  
  # Downloading the individual event page.
  
  event_response <- GET(event_url)
  
  # Saving the status code for each subpage.
  
  subpage_status[i] <- event_response$status_code
  
  # Converting to readable HTML text.
  
  event_html <- content(event_response, as = "text", encoding = "UTF-8")
  
  # Parsing the subpage HTML into a DOM tree.
  
  event_dom <- htmlParse(event_html)
  
  # Extracting the h1 title from the subpage.
  
  title <- xpathSApply(event_dom, "//h1", xmlValue)
  title <- trimws(title)
  
  if (length(title) == 0) {
    title <- NA
  }
  
  subpage_title[i] <- title[1]
  
  
  # Collecting all text elements from the subpage.
  
  page_text <- xpathSApply(event_dom, "//*[text()]", xmlValue)
  
  page_text <- trimws(page_text)
  
  page_text <- page_text[page_text != ""]
  
  
  # The event description usually appears right before "All dates" in the
  # text order. I use that as an anchor — same idea as on the main page.
  
  all_dates_position <- which(page_text == "All dates")
  
  if (length(all_dates_position) > 0) {
    event_description[i] <- page_text[all_dates_position[1] - 1]
  } else {
    event_description[i] <- NA
  }
  
  
  # The address section follows a "Getting there" heading on each subpage.
  # After "Getting there" comes: Location icon, venue name, street address, city.
  # But some pages also include a postal code between the street address and city,
  # so I handle both cases with a regex check.
  
  getting_there_position <- which(page_text == "Getting there")
  
  if (length(getting_there_position) > 0) {
    
    pos <- getting_there_position[1]
    
    subpage_venue[i] <- page_text[pos + 2]
    subpage_street_address[i] <- page_text[pos + 3]
    
    # Swedish postal codes look like "121 77" or "11138".
    # This regex checks if the next value matches that pattern.
    # If it does, I extract it separately; if not, I skip it and go straight to the city.
    
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
    
    # If the page doesn't have a "Getting there" section, storing NA.
    
    subpage_venue[i] <- NA
    subpage_street_address[i] <- NA
    subpage_postal_code[i] <- NA
    subpage_city[i] <- NA
  }
  
  
  # Pausing between requests to be polite to the server and avoid getting blocked.
  
  Sys.sleep(1)
}

# Adding the subpage data to the clean dataset.

events_df_clean$subpage_title <- subpage_title

events_df_clean$subpage_status <- subpage_status

events_df_clean$event_description <- event_description

events_df_clean$subpage_venue <- subpage_venue

events_df_clean$street_address <- subpage_street_address

events_df_clean$postal_code <- subpage_postal_code

events_df_clean$city <- subpage_city

# Checking what the subpage extraction gave us.

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

# Using a regular expression to classify events as single-day or multi-day.
# If the date string contains a dash (like "14 May - 16 May"), it spans multiple
# days. If there is no dash, it is just one day.
# This is an application of the regex concepts from Lab 5.

events_df_clean$event_duration_type <- ifelse(
  grepl("-", events_df_clean$date),
  "Multi-day event",
  "Single-day event"
)

# Checking the result.

events_df_clean[, c("event_name", "date", "event_duration_type")]

# Counting how many events fall into each type.

duration_count <- table(events_df_clean$event_duration_type)

duration_count

duration_df <- as.data.frame(duration_count)

names(duration_df) <- c("event_duration_type", "number_of_events")

duration_df



# 13. DOWNLOAD ONE EVENT IMAGE (non-text file)

# To include an example of downloading a non-text file, I download the main
# image from the first event page. The image URL is stored in the og:image
# meta tag, which is a common way websites define their preview image.

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

# Downloading and saving it as a JPG file.

if (length(test_image_url) > 0) {
  
  image_response <- GET(
    test_image_url[1],
    write_disk("visitstockholm_event_image.jpg", overwrite = TRUE)
  )
  
  image_response$status_code
}



# 14. DESCRIPTIVE ANALYSIS BY CATEGORY

# Counting events per category.

category_count <- table(events_df_clean$category)

category_count

# Converting to a dataframe so it is easier to sort and work with.

category_df <- as.data.frame(category_count)

names(category_df) <- c("category", "number_of_events")

category_df

# Sorting from most to least common.

category_df <- category_df[
  order(category_df$number_of_events, decreasing = TRUE),
]

category_df



# 15. DESCRIPTIVE ANALYSIS BY LOCATION

# Counting events per location.

location_count <- table(events_df_clean$location)

location_count

location_df <- as.data.frame(location_count)

names(location_df) <- c("location", "number_of_events")

location_df

location_df <- location_df[
  order(location_df$number_of_events, decreasing = TRUE),
]

location_df



# 16. VISUALIZATION

# Saving a horizontal bar chart of events by category.
# I used a horizontal layout because some category names are quite long and
# would not fit on a vertical axis without overlapping.
# The left margin is increased to make space for the labels.

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

# Uncomment to view directly in RStudio (without saving to file):

# par(mar = c(5, 18, 4, 2))
# barplot(
#   category_df$number_of_events,
#   names.arg = category_df$category,
#   horiz = TRUE,
#   las = 1,
#   main = "Number of Visit Stockholm events by category",
#   xlab = "Number of events",
#   cex.names = 0.9
# )



# 17. GEOCODING WITH THE NOMINATIM API

# I enriched the dataset with latitude and longitude using the Nominatim API
# from OpenStreetMap. This is free to use but requires a User-Agent header.
#
# For each event, I build a geocoding query:
# - If I have a street address, I use street address + postal code + city + Sweden.
# - If not, I fall back to using the location name + Stockholm + Sweden.

events_df_clean$geocode_query <- ifelse(
  is.na(events_df_clean$street_address),
  paste(events_df_clean$location, "Stockholm, Sweden"),
  paste(events_df_clean$street_address, events_df_clean$postal_code, events_df_clean$city, "Sweden")
)

# Checking the queries before sending them.

events_df_clean[, c("event_name", "location", "street_address", "postal_code", "city", "geocode_query")]



# To avoid making the same API request twice for the same address,
# I geocode only the unique queries and then merge the results back in.

unique_queries <- unique(events_df_clean$geocode_query)

geo_df <- data.frame(
  geocode_query = unique_queries,
  lat = NA,
  lon = NA,
  stringsAsFactors = FALSE
)

for (i in 1:nrow(geo_df)) {
  
  # URLencode makes sure spaces and special characters are safe for a URL.
  
  query <- URLencode(geo_df$geocode_query[i])
  
  api_url <- paste0(
    "https://nominatim.openstreetmap.org/search?q=",
    query,
    "&format=json&limit=1"
  )
  
  print(paste("Geocoding address", i, "of", nrow(geo_df)))
  
  # Nominatim requires a User-Agent header to identify the application.
  # Without this, the API will reject the request.
  
  api_response <- GET(
    api_url,
    add_headers(
      "User-Agent" = "visit-stockholm-student-project/1.0"
    )
  )
  
  api_text <- content(api_response, as = "text", encoding = "UTF-8")
  
  api_json <- fromJSON(api_text)
  
  # If the API returned a result, I store the latitude and longitude.
  
  if (length(api_json) > 0 && nrow(api_json) > 0) {
    geo_df$lat[i] <- api_json$lat[1]
    geo_df$lon[i] <- api_json$lon[1]
  }
  
  # Pausing between requests — Nominatim has a usage policy that asks
  # for no more than one request per second.
  
  Sys.sleep(1)
}

# Merging the geolocation results back into the event dataset.

events_df_final <- merge(
  events_df_clean,
  geo_df,
  by = "geocode_query",
  all.x = TRUE
)

# The geocode_query column was only needed as a helper for the merge,
# so I remove it from the final dataset.

events_df_final$geocode_query <- NULL

# Checking the final dataset.

head(events_df_final)

str(events_df_final)

dim(events_df_final)



# 18. SAVE THE FINAL DATASET

# Saving the final dataset as a CSV file.
# I use write_excel_csv instead of write_csv because it adds a BOM (byte order mark)
# at the start of the file. This helps Excel open the file correctly and display
# Swedish characters like å, ä, ö without them turning into strange symbols.
# I had this problem with a regular write_csv and this fixed it.

write_excel_csv(
  events_df_final,
  "visitstockholm_events_final.csv"
)