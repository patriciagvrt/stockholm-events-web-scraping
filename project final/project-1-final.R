################################## Project 1 ##################################
# Digital Strategies for the Social Sciences
# Project 1: Scraping event information from Visit Stockholm
# Name: Patricia Givort Cruz Cabral
# LIU-ID: patgi434
#
# Website: https://www.visitstockholm.com/events/
#
# This script scrapes the Visit Stockholm events page using a date filter
# to collect events from mid-May to end of July 2026. The page uses
# JavaScript-based pagination, so only the first page of results is
# available through static HTML scraping. The date filter is still useful
# because it returns events within the selected period rather than just
# whatever is on the unfiltered page at the time of scraping.
#
# As an API enrichment step, I use the Open-Meteo weather API to add
# daily weather information (max temperature and precipitation) for the
# date of each event in Stockholm. This is free and requires no API key.
###############################################################################


# 1. PACKAGES
# Uncomment the line below to install packages if needed:
# install.packages(c("httr", "XML", "stringi", "jsonlite", "readr", "gt"))

library(httr)
library(XML)
library(stringi)
library(jsonlite)
library(readr)
library(gt)


# 2. WORKING DIRECTORY
# Change this path if you run this on a different computer.

getwd()

# setwd("~/GitHub/Digital-Strategies-for-Social-Science-Research/project2")

getwd()


# 3. FETCH THE DATE-FILTERED PAGE
#
# I use the date filter parameters in the URL to request events from
# mid-May to end of July 2026. This tells the server to filter the results
# before sending the HTML, so no JavaScript interaction is needed for
# the filtering itself.
#
# The pagination is JavaScript-based, meaning clicking page 2 on the website
# triggers a dynamic request that cannot be replicated with a plain GET().
# For this reason, the scraper only gets the first page of results (~16 events).
# This is a limitation caused by how the website is built, not by the code.

url <- "https://www.visitstockholm.com/events/?date_from=2026-05-14&date_to=2026-07-31"

response <- GET(url)

# A status code of 200 means the request worked.

response$status_code

response[["headers"]][["content-type"]]


# 4. CONVERT THE RESPONSE TO READABLE TEXT

class(response$content)

html <- content(response, as = "text", encoding = "UTF-8")

Encoding(html)

# Double-checking encoding with stringi.

stri_enc_detect(response$content)

# Checking how many events the page reports in total.
# Even though we can only scrape the first page, this tells us
# how many events exist in the full date range.

total_text <- regmatches(html, regexpr("Showing\\s+\\d+\\s+events", html))
total_text


# 5. SAVE AND RELOAD THE HTML
# Saving locally avoids re-requesting the page every time I run the script.

writeLines(html, "visitstockholm_filtered.html")

lines <- readLines("visitstockholm_filtered.html", encoding = "UTF-8")

html <- paste0(lines, collapse = "\n")


# 6. PARSE THE HTML AND CONFIRM THE DATA IS THERE

dom <- htmlParse(html)

# Checking that a known event name is in the HTML.
# If TRUE, the data is in the static HTML and Selenium is not needed.

grepl("Quarnevalen", html)


# 7. EXPLORE THE PAGE STRUCTURE

xpathSApply(dom, "//h1", xmlValue)
xpathSApply(dom, "//h3", xmlValue)

# From testing: h3 tags contain event names, a tags contain links.


# 8. EXTRACT EVENT NAMES AND LINKS

event_names <- xpathSApply(dom, "//h3", xmlValue)
event_names <- trimws(event_names)

all_links <- xpathSApply(dom, "//a", xmlGetAttr, "href")

# Keeping only links that match the Visit Stockholm event URL pattern.
# I use a regular expression to filter out navigation and footer links.

event_links <- all_links[
  grepl("https://www.visitstockholm.com/events/.+/next/", all_links)
]

length(event_names)
length(event_links)

# First version of the dataset.

events_df <- data.frame(
  event_name = event_names,
  link       = event_links,
  stringsAsFactors = FALSE
)

events_df


# 9. FIND AND EXTRACT CATEGORIES, DATES, AND LOCATIONS
#
# The page does not use clean semantic HTML tags for dates and categories.
# I extract all text elements and look for the repeated pattern around
# "Calendar icon": category, event name, Calendar icon, date,
# Location icon, location. I use this pattern to extract the data by offset.

all_text <- xpathSApply(dom, "//*[text()]", xmlValue)
all_text <- trimws(all_text)
all_text <- all_text[all_text != ""]

# Finding all positions of "Calendar icon" in the text vector.

calendar_positions <- which(all_text == "Calendar icon")

calendar_positions

# The first Calendar icon belongs to the date filter bar at the top of the page.
# I remove it by checking if the next element looks like a real event date.

month_pattern <- "Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec"

calendar_positions <- calendar_positions[
  grepl(month_pattern, all_text[calendar_positions + 1])
]

calendar_positions

# Extracting by fixed offset around "Calendar icon":
# category  = 2 positions before
# event name = 1 position before
# date       = 1 position after
# location   = 3 positions after

event_categories <- all_text[calendar_positions - 2]
event_names      <- all_text[calendar_positions - 1]
event_dates      <- all_text[calendar_positions + 1]
event_locations  <- all_text[calendar_positions + 3]

# Checking lengths before building the dataset.

length(event_names)
length(event_categories)
length(event_dates)
length(event_locations)
length(event_links)

# Building the full dataset.

events_df <- data.frame(
  event_name = event_names,
  category   = event_categories,
  date       = event_dates,
  location   = event_locations,
  link       = event_links,
  stringsAsFactors = FALSE
)

events_df

# Sample table for the report.

events_sample_table <- head(
  events_df[, c("event_name", "category", "date", "location")], 10
) |>
  gt() |>
  tab_header(title = "Sample of the scraped events dataset (May-July 2026)")

gtsave(events_sample_table, "events_sample_table.png")


# 10. CLEAN THE DATASET

str(events_df)
dim(events_df)
colSums(is.na(events_df))

# Removing duplicate events.
# The website sometimes shows the same event in multiple sections of the page.

sum(duplicated(events_df[, c("event_name", "link")]))

events_df_clean <- events_df[!duplicated(events_df[, c("event_name", "link")]), ]
row.names(events_df_clean) <- NULL

# Filtering to valid categories.
# The date-filtered page uses both main filter categories (like Music,
# Exhibitions) and subcategories (like Pop, Jazz & Blues, Stand-up & Spoken
# Word). I keep all of them since they are real categories from the website.

valid_categories <- c(
  "Festivals", "Family", "Eat & Drink", "Music", "Fairs", "Exhibitions",
  "Sports & Wellbeing", "Stage & Film", "Networking & Community",
  "Clubs & Parties", "Guided tours", "Science & Tech",
  "Christmas & New Year's", "Careers & Leadership", "Gaming & Boardgames",
  "Pop", "Jazz & Blues", "Stand-up & Spoken Word", "Hip hop, Soul & RnB",
  "Hard Rock & Metal", "Indie & Punk", "Dance & Electronic",
  "Dance & Circus", "Classical music", "Folk & Country",
  "World Music", "Rock", "Opera & Musical"
)

events_df_clean <- events_df_clean[events_df_clean$category %in% valid_categories, ]
row.names(events_df_clean) <- NULL

unique(events_df_clean$category)
dim(events_df_clean)
events_df_clean


# 11. VISIT INDIVIDUAL EVENT SUBPAGES
#
# Looping through each event link to extract description, venue, address,
# postal code, and city from the individual event pages.
# This is what makes the crawler automatically visit more than one page.

subpage_title          <- c()
subpage_status         <- c()
event_description      <- c()
subpage_venue          <- c()
subpage_street_address <- c()
subpage_postal_code    <- c()
subpage_city           <- c()

for (i in 1:nrow(events_df_clean)) {

  event_url <- events_df_clean$link[i]

  print(paste("Downloading subpage", i, "of", nrow(events_df_clean)))

  event_response <- GET(event_url)

  subpage_status[i] <- event_response$status_code

  event_html <- content(event_response, as = "text", encoding = "UTF-8")

  event_dom <- htmlParse(event_html)

  # Extracting the h1 title from the subpage.

  title <- xpathSApply(event_dom, "//h1", xmlValue)
  title <- trimws(title)
  if (length(title) == 0) { title <- NA }
  subpage_title[i] <- title[1]

  # All text elements from the subpage.

  page_text <- xpathSApply(event_dom, "//*[text()]", xmlValue)
  page_text <- trimws(page_text)
  page_text <- page_text[page_text != ""]

  # Description appears right before "All dates" in the text order.
  # Same anchor idea as the extraction on the main page.

  all_dates_position <- which(page_text == "All dates")
  if (length(all_dates_position) > 0) {
    event_description[i] <- page_text[all_dates_position[1] - 1]
  } else {
    event_description[i] <- NA
  }

  # Address follows "Getting there".
  # Pattern: Getting there, Location icon, venue, street address, [postal code], city.
  # Some pages include a postal code, some do not.
  # Swedish postal codes are 3 digits, optional space, 2 digits (e.g. "121 77").

  getting_there_position <- which(page_text == "Getting there")

  if (length(getting_there_position) > 0) {

    pos <- getting_there_position[1]

    subpage_venue[i]          <- page_text[pos + 2]
    subpage_street_address[i] <- page_text[pos + 3]

    possible_postal_code <- page_text[pos + 4]
    possible_city        <- page_text[pos + 5]

    postal_code_pattern <- "^\\d{3}\\s?\\d{2}$"

    if (grepl(postal_code_pattern, possible_postal_code)) {
      subpage_postal_code[i] <- possible_postal_code
      subpage_city[i]        <- possible_city
    } else {
      subpage_postal_code[i] <- NA
      subpage_city[i]        <- possible_postal_code
    }

  } else {
    subpage_venue[i]          <- NA
    subpage_street_address[i] <- NA
    subpage_postal_code[i]    <- NA
    subpage_city[i]           <- NA
  }

  # Polite pause between requests.

  Sys.sleep(1)
}

# Adding the subpage columns to the clean dataset.

events_df_clean$subpage_title     <- subpage_title
events_df_clean$subpage_status    <- subpage_status
events_df_clean$event_description <- event_description
events_df_clean$subpage_venue     <- subpage_venue
events_df_clean$street_address    <- subpage_street_address
events_df_clean$postal_code       <- subpage_postal_code
events_df_clean$city              <- subpage_city

events_df_clean[, c("event_name", "event_description", "location",
                    "subpage_venue", "street_address", "postal_code",
                    "city", "subpage_status")]


# 12. CREATE A VARIABLE USING REGEX
#
# Classifying events as single-day or multi-day using a regular expression.
# If the date string contains a dash (like "May 14 - Jul 31"), the event
# spans multiple days. If there is no dash, it is a single-day event.

events_df_clean$event_duration_type <- ifelse(
  grepl("-", events_df_clean$date),
  "Multi-day event",
  "Single-day event"
)

events_df_clean[, c("event_name", "date", "event_duration_type")]

duration_count <- table(events_df_clean$event_duration_type)
duration_count

duration_df <- as.data.frame(duration_count)
names(duration_df) <- c("event_duration_type", "number_of_events")
duration_df

duration_table <- duration_df |>
  gt() |>
  tab_header(title = "Number of events by duration type")

gtsave(duration_table, "duration_type_table.png")


# 13. ENRICH WITH WEATHER DATA USING THE OPEN-METEO API
#
# Open-Meteo is a free weather API that requires no API key.
# I use it to add daily weather information for Stockholm for each
# event date: maximum temperature (Celsius) and total precipitation (mm).
#
# This enrichment makes sense for this project because weather affects
# whether outdoor events are enjoyable, and it connects to the idea of
# helping people decide which events to attend.
#
# Stockholm coordinates: latitude 59.33, longitude 18.07
# The API accepts a date range and returns daily values in one request.

stockholm_lat <- 59.33
stockholm_lon <- 18.07
date_from     <- "2026-05-14"
date_to       <- "2026-07-31"

weather_url <- paste0(
  "https://api.open-meteo.com/v1/forecast",
  "?latitude=",  stockholm_lat,
  "&longitude=", stockholm_lon,
  "&daily=temperature_2m_max,precipitation_sum",
  "&timezone=Europe/Stockholm",
  "&start_date=", date_from,
  "&end_date=",   date_to
)

print("Fetching weather data from Open-Meteo...")

weather_response <- GET(weather_url)

weather_response$status_code

weather_text <- content(weather_response, as = "text", encoding = "UTF-8")

weather_json <- fromJSON(weather_text)

# The API returns a daily element with dates, max temperature, and precipitation.

weather_df <- data.frame(
  date_api  = weather_json$daily$time,
  temp_max  = weather_json$daily$temperature_2m_max,
  precip_mm = weather_json$daily$precipitation_sum,
  stringsAsFactors = FALSE
)

head(weather_df)

# The event dates from the scraper look like "May 16" or "May 14 - May 17".
# I extract the start date from each event's date string and convert it to
# YYYY-MM-DD format so I can join it with the weather data.
# For multi-day events I use the first date of the range.

extract_start_date <- function(date_str) {

  # Extracting the first "Month Day" pattern from the date string.

  match <- regmatches(date_str, regexpr("[A-Z][a-z]+ \\d{1,2}", date_str))

  if (length(match) == 0 || is.na(match)) return(NA)

  # Converting "May 16" to "2026-05-16".

  parsed <- as.Date(paste(match, "2026"), format = "%b %d %Y")

  return(as.character(parsed))
}

events_df_clean$event_date_api <- sapply(
  events_df_clean$date,
  extract_start_date
)

# Checking the result before merging.

events_df_clean[, c("event_name", "date", "event_date_api")]

# Merging weather data into the events dataset.

events_df_final <- merge(
  events_df_clean,
  weather_df,
  by.x = "event_date_api",
  by.y = "date_api",
  all.x = TRUE
)

# Checking the merged result.

events_df_final[, c("event_name", "date", "event_date_api", "temp_max", "precip_mm")]


# 14. DESCRIPTIVE ANALYSIS BY CATEGORY

category_count <- table(events_df_final$category)

category_df <- as.data.frame(category_count)
names(category_df) <- c("category", "number_of_events")

category_df <- category_df[order(category_df$number_of_events, decreasing = TRUE), ]

category_df


# 15. DESCRIPTIVE ANALYSIS BY LOCATION

location_count <- table(events_df_final$location)

location_df <- as.data.frame(location_count)
names(location_df) <- c("location", "number_of_events")

location_df <- location_df[order(location_df$number_of_events, decreasing = TRUE), ]

location_df


# 16. VISUALIZATION
#
# Horizontal bar chart of events by category.
# Horizontal layout because some category names are long and would
# not fit on a vertical axis without overlapping.

png("visitstockholm_category_plot.png", width = 1400, height = 900)

par(mar = c(5, 18, 4, 2))

barplot(
  category_df$number_of_events,
  names.arg = category_df$category,
  horiz = TRUE,
  las = 1,
  main = "Visit Stockholm events by category (May-July 2026)",
  xlab = "Number of events",
  cex.names = 0.9
)

dev.off()

# Uncomment to view directly in RStudio:
# par(mar = c(5, 18, 4, 2))
# barplot(
#   category_df$number_of_events,
#   names.arg = category_df$category,
#   horiz = TRUE, las = 1,
#   main = "Visit Stockholm events by category (May-July 2026)",
#   xlab = "Number of events", cex.names = 0.9
# )


# 17. SAVE THE FINAL DATASET
#
# Using write_excel_csv() instead of write_csv() because it adds a BOM
# (byte order mark) that helps Excel display Swedish characters correctly.
# I had encoding problems with write_csv and this fixed it.

write_excel_csv(
  events_df_final,
  "visitstockholm_events_may_july_2026.csv"
)

print(paste("Done! Final dataset saved with", nrow(events_df_final), "events."))
