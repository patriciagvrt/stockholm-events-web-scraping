################################## DSSS26 - 5 ##################################
#
# The final lab will introduce you to a final tool that will come in very
# helpful when scraping data: regular expressions. Remember that all you get
# from a website is text, but to run any analysis, you'll need to convert that
# to numbers somehow. Regular expressions allow you to subset the contents of
# the website even further, not just to the node-level, but below that. They
# allow you to extract very specific pieces of text that will make it easier for
# you to work with.
#
# Regular expressions in R work using the so-called PERL syntax. This is only
# one of several "flavors" of RegExp (or regex). To learn more on regex in
# general, as always have a look at the Wikipedia article:
# https://en.wikipedia.org/wiki/Regular_expression
#
# Additionally, regex can be difficult to fully understand and it has many weird
# behaviors that take time to fully understand. A good resource on everything
# regex is https://www.regular-expressions.info/. This website also contains a
# sub-page dedicated to regular expressions in R:
#
# https://www.regular-expressions.info/rlanguage.html
#
# Finally, writing regex is akin to writing in yet another programming language,
# since it is so complex. You will often make errors and not extract what you
# intended to. Thus, you should bookmark a regex tester website. One very good
# one that even explains regex to you is https://www.regex101.com/. The proper
# flavor to select here for displaying the regex correctly is PCRE2.
#
# CAUTION: ALWAYS SET THE PARAMETER `perl=TRUE` FOR ANY FUNCTION THAT ACCEPTS
# THAT, SINCE OTHERWISE R WILL FALL BACK TO PCRE1, WHICH MEANS YOU'LL BE MISSING
# OUT ON SOME FEATURES.
#
# Hendrik Erz (initially Etienne Ollion & J. Boelaert)
# Modified by Tangbin Chen in 2025

# PRELIMINARIES
# =============
#
# You know the drill by now!
library(httr)
library(XML)
library(stringr)
library(tidyverse)
getwd()
setwd('C:/Users/paty_/Documents/GitHub/Digital Strategies for Social Science Research/Week 1 Day 5') # Change this to wherever you want to work in.

# HERE COMES THE RECIPE AGAIN
# ===========================
#
# Recall the last exercise yesterday to scrape the academic jobs
url <- "https://euraxess.ec.europa.eu/jobs/search?f%5B0%5D=job_research_field%3A388"
# Step 1: Fetch the page
response <- GET(url)
# Step 2: Check the status-code
response$status_code
# Step 3: Extract the content, note that you need to check the encoding
page_content <- content(response, as = "text", encoding = "UTF-8")
# Step 3.1: save the page locally
writeLines(page_content, "Sociology jobs.html")
# Step 4: Parse the html to a DOM tree
dom <- htmlParse(page_content)
# Step 5: Use XPath to select data you need to collect, here we want job information
jobs <- xpathSApply(dom, '//div[@id="job-teaser-content"]')
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

# Step 6: automatically scrape all pages
links <- paste0("&page=" , 0:35)
for(link in news_links){
  # then repeat step 1-5
}

# NEW TODAY:
# Step 7: Clean the data
# For example, here the number of offers is appended to the corresponding 
# working location for each record, but for a better data management, we will
# want them to be separated into two columns
jobs_df <- jobs_df %>%
  mutate(num_offers = str_extract(location, "Number of offers:\\s\\d+"),
         num_offers = str_extract(num_offers, "\\d+"),
         # or alternatively
         num_offers = str_match(location, "Number of offers:\\s(\\d+)")[,2],
         # coerce it into integer
         num_offers = as.integer(num_offers),
         # removes whitespace at the start and end, and replaces all internal
         # whitespace with a single space
         location = str_squish(location),
         # remove number of offers from location column
         location = str_remove(location, "Number of offers:\\s\\d+,\\s"))
head(jobs_df)

# THINKING: Can you think of an alternative way of doing this?
# HINT: use tidyr::separate

# Step 8: Data analysis
# Now you have all the data you need, now you can answer your RQ with the data

# YOUR TURN NOW: Clean deadline column
# ====================================
# 
# 1.) extract time zone into a new column
# 2.) remove the timezone from deadline column
# 3.) Separate the date and time from deadline column

jobs_df <- jobs_df %>%
  mutate(# extract time zone into a new column
         ddl_tz = str_match(deadline, "\\((\\w+)\\)")[,2],
         # remove the timezone from deadline column
         deadline = str_remove(deadline, "\\s\\(.+\\)"))
head(jobs_df)

# You can use separate function to split column with regex
         # Separate the date and time from deadline column
jobs_df <- jobs_df %>%
  separate(deadline,
           into = c("ddl_date", "ddl_time"),
           sep = "\\s-\\s")
head(jobs_df)


# YOUR TURN: Extract the table from ICANN TLD REGISTRY
# ====================================================
#
# Today, we will have a look at the ICANN registry of TLDs. This is a list of
# every registered top-level-domain that the ICANN maintains. It lists each
# top-level-domain (such as .com, .org, or .se) with its corresponding contact
# information.
#
# We'll assume that we need the contact information in a parsed state. Thus, we
# first follow the usual way of downloading the website and parsing its HTML.
# Then, the star of today's show will enter, which will allow us to extract info
# such as telephone numbers and email addresses.

url <- "https://www.icann.org/resources/pages/listing-2012-02-25-en"

# 1.) download the data and parse the HTML into a DOM tree.
response <- GET(url)
page_content <- content(response, as = 'text')
dom <- htmlParse(page_content)

# 2.) extract the data store it into a data frame. There is a trick when
# dealing with tables on websites: You can simply parse the table immediately
# into a data frame like so:
all_tables <- xpathSApply(dom, "//table") # Returns a list of all tables
main_table <- all_tables[[1]] # Why do we do this?  Need the XML item
table <- readHTMLTable(main_table)

# View the column headers: You will notice that the function has automatically
# extracted the first row's contents as column names.
names(table)

# Let's have a look at the fourth column:
print(table[1, 4])

# As you can see, it's extremely dirty, so let us clean it up now!

# EXERCISE 1: CLEANING WHITESPACE
# ===============================
#
# The first order of business usually is to remove excess whitespace. In this
# particular case, this consists of excess tab-characters, and unusual newlines.

# For ease of access, we'll just copy out the column:
contact <- table$Contacts

contact <- gsub(pattern = "\\t+", replacement = "", x = contact, perl = T)
# You don't have to name all arguments to keep it short
contact <- gsub("\\t+", "", contact, perl = T)

print(contact[1]) # Double check your work

# Next, replace CRLF with regular line feeds (more info: https://en.wikipedia.org/wiki/Newline)
contact <- gsub("[\r\n]+", "\n", contact, perl = T)

print(contact[1]) # Double check your work

# Alternatively with stringr
contact2 <- table$Contacts
contact2 <- str_replace_all(contact2, pattern = "\\t+", replacement = "")
contact2 <- str_replace_all(contact2, pattern = "[\\r\\n]+", replacement = "\n")
print(contact2[1]) # Double check your work

all(contact2 == contact)

# alternatively, if you don't need to keep the newlines i.e. "\n"
contact <- str_squish(table$Contacts)

# !!ATTENTION!!
# =============
# 
# It can be tricky when working with text in R, especially with special
# characters. You can try the code below.
# It is always good to check your pattern on regex101 and test it in R
# using stringr::str_view() for visual inspection.

text <- "line1\n\tline2"
str_replace_all(text,"[\\r\\n\\t]+", " ")
str_replace_all(text,"[\r\n\t]+", " ")
# take a look at how your string literal is parsed by R
writeLines("[\\r\\n\\t]+")
writeLines("[\r\n\t]+")

# dot (.) can match anything but not line breaks -> '\n' and '\r'
str_extract_all(text, pattern = '.+')
# you can use a prebuilt class for whitespace: space, tab, newline, etc.
str_extract(text, pattern = '[[:space:]]+')

# good to always test your regex -> visualize match locations
str_view(text, pattern = '.+')


# EXERCISE 2: EXTRACTING PHONE NUMBERS
# ====================================
#
# The final lesson of today will be to properly extract telephone and fax
# numbers. There are various formats in which these could be stored, and luckily
# (for our training purposes), the website really doesn't care to keep the
# format uniform, so you'll have to match a ton of cases.

# HINT 1: Eyeballing the patterns of the telephone numbers -> find general patterns
#         -> identify the most common format -> copypaste to regex101 -> start
#         to create your regex

# HINT 2: if you find it difficult to solve the puzzle directly, you can try
# 1.) First, simply match all characters that exist in these numbers
# First, the ugly way: Simply match all characters that exist in these numbers:
numbers <- str_extract(contact, "[+\\d \\(\\)\\-\\.]+")
head(numbers) # Double check

# Seems that there is no match for quite some entries, let's see what happens if
# we extract all that matches here
numbers <- str_extract_all(contact, "[+\\d \\(\\)\\-\\.]+")
head(numbers) # Double check

# 2.) Second, check the output, there will be a ton of irrelevant things. So 
#     let's make the regex more strict and require at least three characters:

# In this first iteration, this will match a ton of irrelevant things. So let's
# make the regex more strict and require at least three characters:
numbers <- str_extract_all(contact, "[+\\d \\(\\)\\-\\.]{3,}")
head(numbers) # Double check

# 3.) Still a lot of issues. Next step: Require the numbers to start with a plus.
numbers <- str_extract_all(contact, "\\+[\\d \\(\\)\\-\\.]{3,}")
head(numbers) # Double check

# 4.) Should be better, but still problematic, so improve the regex even more
numbers <- str_extract(contact, "\\+\\d+( ?\\(\\d+\\))*[\\d \\.-]+")
head(numbers) # Double check
sum(is.na(numbers))

# 5.) It seems that we did not capture all of the phone numbers, maybe we can
#     ask the regex to find things after "Tel"
# Probably can not be as elegant as we wish this time
numbers <- str_extract(contact, "Tel: (([\\+\\d ]+)|(\\d+)|(\\(\\+?\\d+\\))) ?(\\(\\d+\\))*[\\d \\.-]+")
head(numbers) # Double check
sum(is.na(numbers))

# 6.) Check the entries with no matched text, what is the issue here? Modify the
#     regex to be more accurate
missing <- contact[is.na(numbers)]
print(str_view(missing, "Tel:")) # now you see, here is an unusual space here {\u00a0}
# Phew, finally it works
print(str_view(missing, "Tel:\\s(([\\+\\d ]+)|(\\d+)|(\\(\\+?\\d+\\))) ?(\\(\\d+\\))*[\\d \\.-]+"))

numbers <- str_extract(contact, "Tel:\\s(([\\+\\d ]+)|(\\d+)|(\\(\\+?\\d+\\))) ?(\\(\\d+\\))*[\\d \\.-]+")
missing <- contact[is.na(numbers)]
missing
# only two that do not follow good practice failed to be captured, I am gonna move
# on now =.=

# 7.) Let's put this into the data frame
table <- table %>%
  mutate(telephone = str_extract(Contacts, 
                                 "Tel:\\s(([\\+\\d ]+)|(\\d+)|(\\(\\+?\\d+\\))) ?(\\(\\d+\\))*[\\d \\.-]+"),
         telephone = str_remove(telephone, "^Tel:\\s*"))


# BONUS EXERCISE: EXTRACT EMAIL ADDRESSES
# =========================================
#
# A regular expression that is used by many different programmers oftentimes a
# day is one to extract email addresses. If you're here, I pose to you the
# challenge to extract the email addresses instead, good luck~


################################ THE END #######################################

