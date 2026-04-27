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
length(xpathSApply(dom, "*****"))

# how many links for the models?
length(xpathSApply(dom, "*****"))

# or more specifically
length(xpathSApply(dom, "*****"))


# Extract the titles of those models
link_titles <- xpathSApply(dom, "*****", *****)
print(link_titles)

# Extract the links themselves - two ways to do it

# 1.) you can get the attributes and get links from the attributes
links <- xpathSApply(dom, "*****", *****)
str(links)
rownames(links)

# let's extract the link
links <- links['href',]
print(links)

# 2.) You can directly select the attribute with XPath using @
links2 <- xpathSApply(dom, "*****")
print(links2)


# how do those links look to you?


# EXERXCISE: PLANE CRASH DATABASE
# ================
#
# Now, let's not just inspect a website, but actually put its contents into a
# data frame.

# Download the page for 1950 plane crashes
url <- 'http://planecrashinfo.com/1950/1950.htm'
response <- ***
http_status(***)
page_content <- ***

# On some OS, you may get a "success" status, but no content.
# Try the following line to extract it properly:
page_content <- content(response, type = "text", encoding = "ISO-8859-1")

# Write it on your hard drive
writeLines(***, "planecrash_1950.html") # Go check it

# Parse the page's contents
dom <- ***

# Now, let's extract the date, the location/operator, and the aircraft.
# Write XPaths that select the described elements. What do they have in common?
column1_row1 <- '***'
column1_row2 <- '***'

# Scrape the date
date <- xpathSApply(dom, "***", ***)

# Scrape the location/operator
location <- xpathSApply(dom, "***", ***)

# Scrape the Aircraft
aircraft <- xpathSApply(dom, "***", ***)

# Bind them together and construct a data frame from it.
header <- c(date[1], location[1], aircraft[1])
df <- data.frame(date = date[-1], location = location[-1], aircraft = aircraft[-1])
names(df) <- header # What does this line do?
head(df)

# You can also go by rows. This is not advised with tabular data, but comes in
# helpful when you are dealing with non-tabular data.
url <- "http://www.planecrashinfo.com/accidents.htm"
response <- GET(url)
page_content <- content(response, as = 'text')

# Again, on some OS, you may have to write
page_content <- GET(url) |> content(type = "text", encoding = "ISO-8859-1")

writeLines(page_content, "accidents.htm") # Go check it

dom <- htmlParse(page_content)

# Select the information for the **first node**
node1 <- xpathSApply(dom, "***")[[1]]
print(xpathSApply(node1, "***", xmlValue))
## Note differences here between the 2

# Extract the information for columns 1, 2, and 7 from this node (note the ".")
cell1 <- ***
cell2 <- ***
cell7 <- ***

# Same thing for node 2
node2 <- ***
cell21 <- ***
cell22 <- ***
cell27 <- ***

# Same thing for node 3
node3 <- ***
cell31 <- ***
cell32 <- ***
cell37 <- ***

# EXERXCISE: SCRAPING SVT.SE
# ==========================
#
# Let's look at a second website: The economy news from svt.se. Here, the data
# of interest is not presented as a table, which means that working row-wise is
# a much better approach than working column-wise.

# First, as always, retrieve the website and parse it into a DOM tree.
url <- "https://www.svt.se/nyheter/ekonomi/"
response <- ***
dom <- ***

# The first challenge: Retrieve all DOM nodes that contain an article's info
news <- xpathSApply(dom, '***')

# Next, print out the link to the full article, its title, and the teaser for
# the very first item.
attrs <- xpathSApply(news[[1]], '***', ***)
title <- xpathSApply(news[[1]], '***', ***)
subtitle <- xpathSApply(news[[1]], "***", ***)
print(attrs[2]) # Why [2]?
print(title)
print(subtitle)

# Finally, generalize this to extract the same info for all news on the page.
# NOTE: You should devise a strategy in case one of these elements is missing

################################ THE END #######################################
