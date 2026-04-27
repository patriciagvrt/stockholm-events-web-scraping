################################## DSSS26 - 3 ##################################
#
# The third lab will finally get to extracting data from websites. Here you will
# learn how to extract the specific pieces of information from the mess of HTML.
# This lab introduces XPaths, which you will need to extract those pieces of
# content you are actually interested in.
#
# For more info:
# * https://en.wikipedia.org/wiki/XPath
#
# Hendrik Erz (initially Etienne Ollion & J. Boelaert)
# Modified by Tangbin Chen in 2025

# PRELIMINARIES
# =============
#
# As last time, let's first load the required packages and set the working
# directory.
library(httr)
library(XML)

setwd('/path/to/folder') # Change this to wherever you want to work in.

# THE SIMPLE RECIPE
# ================
#
# Download the content of the page https://huggingface.co/models and
# parse the HTML into a DOM tree.

# Recall what we learned from lab 2
url <- "https://huggingface.co/models"
# Step 1: Fetch the page
response <- GET(url)
# Step 2: Check the status-code
response$status_code
# Step 3: Extract the content, note that you need to check the encoding
page_content <- content(response, as = "text", encoding = "UTF-8")
# Step 4: Parse the html to a DOM tree
dom <- htmlParse(page_content)

# NEW TODAY: Extract parts of the page you are interested in, here we want to 
# have all the links for the models
# Step 5: Use XPath to select data you need to collect
xpathSApply(dom, "//article/a/@href")

# YOUR TURN - SIMPLE TASKS
# ================
# Let's see how many links we can possibly get from the webpage. How many are there?
length(xpathSApply(dom, "//a"))

# how many links for the models?
length(xpathSApply(dom, "//article/a"))

# or more specifically
length(xpathSApply(dom, "//article[contains(@class, 'overview-card-wrapper')]/a"))

# Extract the titles of those models
link_titles <- xpathSApply(dom, "//article/a//h4", xmlValue)
print(link_titles)

# Extract the links themselves - two ways to do it

# 1.) you can get the attributes and get links from the attributes
links <- xpathSApply(dom, "//article/a", xmlAttrs)
str(links)
rownames(links)

# let's extract the link
links <- links['href',]
print(links)

# 2.) You can directly select the attribute with XPath using @
links2 <- xpathSApply(dom, "//a/@href")
print(links2)


# how do those links look to you?


# EXERXCISE: PLANE CRASH DATABASE
# ================
#
# Now, let's not just inspect a website, but actually put its contents into a
# data frame.

# Download the page for 1950 plane crashes
url <- 'http://planecrashinfo.com/1950/1950.htm'
response <- GET(url)
http_status(response)

# On some OS, you may get a "success" status, but no content.
# Try the following line to extract it properly:
page_content <- content(response, type = "text", encoding = "ISO-8859-1")

# Write it on your hard drive
writeLines(page_content, "planecrash_1950.html") # Go check it

# Parse the page's contents
dom <- htmlParse(page_content)

# Now, let's extract the date, the location/operator, and the aircraft.
# Write XPaths that select the described elements. What do they have in common?
column1_row1 <- '//tr[1]/td[1]'
column1_row2 <- '//tr[2]/td[1]'

# Scrape the date
date <- xpathSApply(dom, "//td[1]", xmlValue)

# Scrape the location/operator
location <- xpathSApply(dom, "//td[2]", xmlValue)

# Scrape the Aircraft
aircraft <- xpathSApply(dom, "//td[3]", xmlValue)

# Bind them together and construct a data frame from it.
header <- c(date[1], location[1], aircraft[1])
df <- data.frame(date = date[-1], location = location[-1], aircraft = aircraft[-1])
names(df) <- header
head(df)

# You can also go by rows. This is not advised with tabular data, but comes in
# helpful when you are dealing with non-tabular data.
url <- "http://www.planecrashinfo.com/accidents.htm"
response <- GET(url)

response$headers$`content-type`

# if not specified, then use stringi::stri_enc_detect which can also detect the
# encoding of raw data
stringi::stri_enc_detect(response$content)

page_content <- content(response, as = 'text', encoding = "windows-1252")


# Again, on some OS, you may have to write
page_content <- GET(url) |> content(type = "text", encoding = "ISO-8859-1")

writeLines(page_content, "accidents.htm") # Go check it

dom <- htmlParse(page_content)

# Select the information for the **first node**
node1 <- xpathSApply(dom, "//tr")[[1]]
node1 <- xpathSApply(dom, "//tr[1]")[[1]] # same, but any difference?

print(xpathSApply(node1, ".//td[1]", xmlValue))
print(xpathSApply(node1, "//td[1]", xmlValue))
## Note differences here between the 2

# Extract the information for columns 1, 2, and 7 from this node (note the ".")
cell1 <- xpathSApply(node1, ".//td[1]", xmlValue) # airline
cell2 <- xpathSApply(node1, ".//td[2]", xmlValue) # country
cell7 <- xpathSApply(node1, ".//td[7]", xmlValue) # comments

# Same thing for node 2
node2 <- xpathSApply(dom, "//tr[2]")[[1]]
node2 <- xpathSApply(dom, "//tr")[[2]]

cell21 <- xpathSApply(node2, ".//td[1]", xmlValue)
cell22 <- xpathSApply(node2, ".//td[2]", xmlValue)
cell27 <- xpathSApply(node2, ".//td[7]", xmlValue)

# Same thing for node 3
node3 <- xpathSApply(dom, "//tr[3]")[[1]]
cell31 <- xpathSApply(node3, ".//td[1]", xmlValue)
cell32 <- xpathSApply(node3, ".//td[2]", xmlValue)
cell37 <- xpathSApply(node3, ".//td[7]", xmlValue)
cell37 <- xpathSApply(node3, ".//td[last()]", xmlValue)

# EXERXCISE: SCRAPING SVT.SE
# ==========================
#
# The solution is updated to adapt to the changes in svt.se 2025-04-15
# 
# Let's look at a second website: The economy news from svt.se. Here, the data
# of interest is not presented as a table, which means that working row-wise is
# a much better approach than working column-wise.

# First, as always, retrieve the website and parse it into a DOM tree.
url <- "https://www.svt.se/nyheter/ekonomi/"
response <- GET(url)
response$headers$`content-type`
stringi::stri_enc_detect(response$content)

dom <- htmlParse(response)

# The first challenge: Retrieve all DOM nodes that contain an article's info
news <- xpathSApply(dom, '//article[contains(@class, "FeedTeaser")]')

# Next, print out the link to the full article, its title, and the teaser for
# the very first item.
attrs <- xpathSApply(news[[1]], './a[@href]', xmlAttrs)
title <- xpathSApply(news[[1]], './/h1[contains(@class,"TeaserHeadline")]', xmlValue)
# or you can directly get it from the attributes
xpathSApply(news[[1]], './/a/@title')

subtitle <- xpathSApply(news[[1]], './/span[contains(@class,"Text")]', xmlValue)

print(attrs[2])
print(title)
print(subtitle)

# Finally, generalize this to extract the same info for all news on the page.
# make it a data frame
news_df <- data.frame()
for (info in news) {
    link <- xpathSApply(info, './a/@href')
    title <- xpathSApply(info, './/h1[contains(@class,"TeaserHeadline")]', xmlValue)
    subtitle <- xpathSApply(info, './/span[contains(@class,"Text")]', xmlValue)
  temp <- data.frame(
    link = ifelse(length(link) == 0, NA, link),
    title = ifelse(length(title) == 0, NA, title),
    subtitle = ifelse(length(subtitle) == 0, NA, subtitle)
  )
  news_df <- bind_rows(news_df,temp)
}

################################ THE END #######################################
