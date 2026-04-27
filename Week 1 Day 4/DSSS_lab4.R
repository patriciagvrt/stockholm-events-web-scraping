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

# TODO: Create a character vector of URLs from /blog/1 to /blog/10

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


# EXERCISE 1: CAPTURING PAGINATED DATA WITH FOR LOOPS
# =======================================
#
# After having understood how to capture multiple paginated websites, it is time
# to retrieve them and store them in a data object so that you can work on the
# data later.

# 1.) Let us first capture all URLs for all the pages of Hendrik's blog: 
#     https://www.hendrik-erz.de/blog
# 2.) GET all the pages of the blog
#     2.1.) store everything in a list
#     2.2.) save the data locally either as html or rds file
#     2.3.) sleep 1s for every fetch, use Sys.sleep(1)
# 3.) Parse every page you just downloaded


# EXERCISE 2: ITERATING OVER NODES
# ================================
#
# Aside from pagination, you will also often have to iterate over individual
# nodes. Here, you will learn how to extract a series of job teasers, store
# them into a data frame, and save that to disk.

url <- "https://euraxess.ec.europa.eu/jobs/search?f%5B0%5D=job_research_field%3A388"

# 1.) The first challenge: Retrieve all DOM nodes that contain an job info
# 2.) Finally, extract the following information all the jobs on the page.
#    2.1.) job title
#    2.2.) job link
#    2.3.) work location
#    2.4.) application deadline
# 3.) Let's have a look at what we just got
# 4.) Save the data frame down. Since it contains exclusively text, TSV is highly
# recommended.

# BONUS EXERCISE1: COLLECTING DATA
# ===================================
# 
# If you finished quickly, here's a bonus task:
#
# 1.) Visit https://www.planecrashinfo.com/database.htm
# 2.) Extract the various links for the years from the page
# 3.) Find 5 random years, extract the tables and store the date, location, and 
#     aircraft type in a data frame and save it to disk.

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
