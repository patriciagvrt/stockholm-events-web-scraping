################################## DSSS26 - 4 ##################################
#
# The fourth lab's focus is on loops and storing information on disk. Here you
# will use the previous lab's efforts and store everything in data frames.
#
# Hendrik Erz (initially Etienne Ollion & J. Boelaert)
# Tangbin Chen Modified in 2025

# PRELIMINARIES
# =============
#
# You know the drill by now!
library(httr)
library(XML)

setwd('/path/to/folder') # Change this to wherever you want to work in.

# THE SIMPLE RECIPE
# =================
#
# Recall the last exercise yesterday to scrape svt.se
url <- "https://www.svt.se/nyheter/ekonomi/"
# Step 1: Fetch the page
response <- GET(url)
# Step 2: Check the status-code
response$status_code
# Step 3: Extract the content, note that you need to check the encoding
page_content <- content(response, as = "text", encoding = "UTF-8")
# Step 3.1: save the page locally
writeLines(page_content, "svtekonomi.html")
# Step 4: Parse the html to a DOM tree
dom <- htmlParse(page_content)
# Step 5: Use XPath to select data you need to collect: for today we need the links
# of articles
news_links <- xpathSApply(dom, '//article[contains(@class, "FeedTeaser")]/a/@href')

# NEW TODAY:
# Step 6: automatically scrape
for(link in news_links){
  url <- paste0("www.svt.se", link)
  # then repeat step 1-5
  # THINKING: would it be good make a mini function for the steps 1-5?
}

# The two most common applications for loops in scraping the web is 
#   (1) extract a list of nodes from a single web page, like above, and
#   (2) download multiple paginated websites one after another in a loop.

# YOUR TURN NOW: PAGINATION 1
# ===========================
#
# First, let us have a look at a website that uses pagination:
# https://www.hendrik-erz.de/blog
# While clicking through the pages you will see how the pagination works. The
# most basic way of scraping is to simply pre-calculate all URLs you will need
# to visit.

# TODO: Create a character vector of URLs from /blog/1 to /blog/5
base_url <- "https://www.hendrik-erz.de/blog/"
urls <- paste0(base_url, 1:5) # NOTE: You can also use seq()
print(urls)

# YOUR TURN NOW: PAGINATION 2
# ===========================
#
# Some older websites paginate not by providing a page number, but rather by
# indicating what the first element is that should appear on the page. Example:
# example.com?start=1 -> First page
# 
# Visit this page and find the pagination pattern.
# https://euraxess.ec.europa.eu/jobs/search

# TODO: Create a character vector of URLs for all pages
base_url <- "https://euraxess.ec.europa.eu/jobs/search"
urls <- paste0(base_url, "?page=" , 0:1054) # NOTE: the page index starts from 0
print(urls)


# EXERCISE 1: CAPTURING PAGINATED DATA WITH FOR LOOPS
# ===================================================
#
# After having understood how to capture multiple paginated websites, it is time
# to retrieve them and store them in a data object so that you can work on the
# data later.

# 1.) Let us first capture *ALL* URLs for ALL* the pages of Hendrik's blog: 
#     https://www.hendrik-erz.de/blog
base_url <- "https://www.hendrik-erz.de/blog/"
urls <- paste0(base_url, 1:12) # THINKING: How do you know the num. of pages?
print(urls)

# 2.) GET all the pages of the blog
#     2.1.) store everything in a list
#     2.2.) save the data locally either as html or rds file
#     2.3.) sleep 1s for every fetch, use Sys.sleep(1)

# create an empity list that can contain all the responses
hendrik_blog <- vector("list",length = length(urls))
# for loop makes it easier to iterate over each element of a vector
for(i in 1:length(urls)){
  # name of the list will be the url
  hendrik_blog[[i]] <- GET(url[i])
  writeLines(content(hendrik_blog2[[i]], as = "text"), paste0("Hendrik-blog-",i,".html"))
  Sys.sleep(1) # Be polite, always pause a bit
}

# alternatively, you can use lappy
hendrik_blog <- lapply(urls, function(u){
  res <- GET(u)
  Sys.sleep(1) # Be polite, always pause a bit
  return(res)
})

# Alternatively, you can save the whole list as RDS
saveRDS(hendrik_blog, "All of Hendriks blogs.rds")

# 3.) Parse every page you just downloaded
# Apparently, lappy will make it easier for you, lappy will apply the function to
# all elements in the list
hendrik_blog_dom <- lapply(hendrik_blog, htmlParse)

# then you can apply xpath to select the information you need from Hendrik's blogs

# EXERCISE 2: ITERATING OVER NODES
# ================================
#
# Aside from pagination, you will also often have to iterate over individual
# nodes. Here, you will learn how to extract a series of job teasers, store
# them into a data frame, and save that to disk.

url <- "https://euraxess.ec.europa.eu/jobs/search?f%5B0%5D=job_research_field%3A388"
response <- GET(url)
dom <- htmlParse(response)

# 1.) The first challenge: Retrieve all DOM nodes that contain an job info
jobs <- xpathSApply(dom, '//div[@id="job-teaser-content"]')

# 2.) Finally, extract the following information all the jobs on the page.
#    2.1.) job title
#    2.2.) job link
#    2.3.) work location
#    2.4.) application deadline

jobs_df <- data.frame()
for (info in jobs) {
  link <- xpathSApply(info, './/h3/a/@href')
  title <- xpathSApply(info, './/h3//span', xmlValue)
  location <- xpathSApply(info, './/div[contains(@class,"Work-Locations")]/div[2]', xmlValue)
  deadline <- xpathSApply(info, './/div[contains(@class,"Application-Deadline")]/div[2]', xmlValue)
  # make sure missing data is filled with NA
  temp <- data.frame(
    link = ifelse(length(link) == 0, NA, link),
    title = ifelse(length(title) == 0, NA, title),
    location = ifelse(length(location) == 0, NA, location),
    deadline = ifelse(length(deadline) == 0, NA, deadline)
  )
  jobs_df <- dplyr::bind_rows(jobs_df,temp)
}

# Then in next lab, we will talk about how to clean data in this data frame

# Now, let's have a look at what we just got
head(jobs_df,3)

# Save the data frame down. Since it contains exclusively text, TSV is highly
# recommended.
write.table(jobs_df, "jobs.tsv", row.names = FALSE, sep = "\t")

# BONUS EXERCISE 1: COLLECTING DATA
# =================================
#
# If you finished quickly, here's a bonus task:
#
# 1.) Visit https://www.planecrashinfo.com/database.htm

# First, let us define a helper function that can scrape these year-pages.
scrape_page <- function(url) {
  # So that you know where you are
  print(paste("Retrieving page:", url, "..."))
  # Retrieve the URL
  response <- GET(url)
  # Again, on some machines, not specifying the encoding will work, on others,
  # this is required, so let's just be verbose here.
  page_content <- content(response, as = "text", encoding = "ISO-8859-1")
  # Next, extract the table. Instead of using xpath, we'll quickly use rvest for
  # this. HOWEVER: This should not stop you from understanding how to use xpath
  # for this purpose, so if you don't know how this would look like in xpath,
  # please do yourself a favor and revisit lab 3, which uses the same website
  # but does this process manually! It is really important that you understand
  # what rvest does here fully automated!
  
  # The main table doesn't use "th" elements for the header (as it should), so
  # by setting header = TRUE, we direct rvest to take the first "td" row as a
  # header
  
  # need to specify the pkg since read_html, html_table requires another pkg 'rvest'
  tables <- rvest::read_html(page_content) |> rvest::html_table(header = TRUE)
  if (length(tables) == 0) {
    print("Could not retrieve any tables. Returning an empty data.frame")
    return(data.frame())
  } else {
    # The first table should be the main one.
    return(tables[[1]])
  }
}

# 2.) Extract the various links for the years from the page
# To do this, we need to get the relevant links from this page
url <- "https://www.planecrashinfo.com/database.htm"
response <- GET(url)
dom <- htmlParse(response)

# getting links for the page with the tables desired
links <- xpathSApply(dom, "//table//a/@href")

# 3.) Find 5 random years, extract the tables and store the date, location, and
#     aircraft type in a data frame and save it to disk.
# 
# With the helper function out of the way, load the website, and parse it.
# Now prepare the magic: We use the NULL/rbind logic to create a data frame from
# each sub-page.

# take 5 random year, let's try not to crash the web server
set.seed(58183)
link_sample <- links[sample(1:length(links),5)]

df <- NULL
for (link in link_sample) {
  Sys.sleep(2) # Don't crash the web server!
  if (!startsWith(link, "/")) {
    link <- paste0("/", link) # Some links are missing the leading /
  }
  
  # Convert the relative links into absolute ones
  full_url <- paste0('https://www.planecrashinfo.com', link)
  # Use the helper function to convert that thing into a data frame
  this_page_df <- scrape_page(full_url)
  # Finally, glue all of the smaller data frames together
  df <- rbind(df, this_page_df)
}

# See what we got:
View(df)

# BONUS EXERCISE 2: URLS WITH QUERIES
# ===================================
#
# Let's apply some filters to the job vacancies listed on EURAXESS, take a look:
# https://euraxess.ec.europa.eu/jobs/search?f%5B0%5D=job_country%3A770&f%5B1%5D=job_research_field%3A388&f%5B2%5D=job_research_profile%3A447&f%5B3%5D=offer_type%3Ajob_offer
# A bit readable right. Let's make it even more readable
library(urltools)
url_decode("https://euraxess.ec.europa.eu/jobs/search?f%5B0%5D=job_country%3A770&f%5B1%5D=job_research_field%3A388&f%5B2%5D=job_research_profile%3A447&f%5B3%5D=offer_type%3Ajob_offer")
# TODO: Can you try to find the way to create the URLs for different queries?
# TIP: You can find relevant info from source tab in DevTools (F12 magic)
# NOTE: You don't need to scrape all the URLs you get, will be enough to find the
#       patterns of the URLs. Euraxess does not seem to be happy with scrapers.

################################ THE END #######################################
