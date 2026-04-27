################################## DSSS26 - 2 ##################################
#
# This is the second lab for DSSS26. Here you will learn the first step in the
# scraping business: Downloading the internet. It will walk you through some
# techniques of retrieving web pages and parsing the resulting HTML code into a
# proper DOM tree.
#
# If you want to go more in-depth with websites and how the internet works, the
# following pages will give you some deeper understanding:
#
# * https://en.wikipedia.org/wiki/HTML
# * https://en.wikipedia.org/wiki/HTTP
# * https://en.wikipedia.org/wiki/List_of_HTTP_status_codes
# * https://en.wikipedia.org/wiki/Document_Object_Model
# * (for exercise 2) https://en.wikipedia.org/wiki/HTTP_cookie
# * (for exercise 3) https://en.wikipedia.org/wiki/Character_encoding
#
# Hendrik Erz (initially Etienne Ollion & J. Boelaert)
# Tangbin Chen modified in 2025

# PRELIMINARIES
# =============
#
# As with many usages of R, scraping requires usage of packages, i.e., extending
# the base R functionality with additional capabilities that will enable you to
# download websites and work with them.
#
# To load additional packages, use `library()`. This will load their code and
# expose additionally defined functions, data, and variables to your own code.
#
# However, before loading them, you will need to install those packages. If you
# are using RStudio, it will always prompt you if it detects that your code is
# loading a package that is not yet installed. If you are not using RStudio, or
# if you just prefer the manual way, you can install those packages using the
# `install.packages()` function.
#
# You will only need to install packages once, but load them always whenever you
# need them. It is customary to never save `install.packages`-calls in your code
# but always prepend every script with all libraries that you need.
#
# For this lab, you will need the following packages:
#
# * httr: A small library that allows you to retrieve websites
# * XML: Provides functionality for parsing HTML (HTML is a subset of XML)
# * rvest: A wrapper around httr and XML that makes a few operations easier
#

# in case you don't have them installed
install.packages(c("httr", "XML", "rvest"))

library(httr)
library(XML)
library(rvest)

# After loading all packages, you should make a habit of always setting your
# working directory to a folder on your computer where you store your data. R
# will always use that folder for reading and writing data.
getwd() # This will tell you which folder R works from right now

setwd('/path/to/folder') # Change this to wherever you want to work in.

# FETCHING WEBSITES: THE BASICS
# =============================
#
# To retrieve a website, you need to contact the server that serves it. Here, we
# will use httr.

# Let's grab our first website. Visit www.perdu.com to have a look at what it
# looks like. Use the "View source code" function of your web browser to see its
# source code.
url <- 'http://www.perdu.com'

# Let's fetch it
response <- GET(url)

# The httr package uses "Response" objects that contain a lot of information
# about the request and the server response. There are two properties you should
# always check, and one you may sometimes need to check.

response$status_code # This contains the HTTP status code returned by the server
response$headers # The response "headers" contain sometimes interesting info


# The most interesting part is the actual content, which you can access with
# the following:
response$content

class(response$content)

# You will notice that this gives you a list of weird pairs of digits and
# letters. This is hexadecimal notation. httr stores the response as "bytes" by
# default. To retrieve the content as a readable string, use the following:
content(response, as = 'text')

# sometimes you can read the encoding from the headers with dev tool on browsers
# you might also see the content-encoding in the headers, which is not telling 
# you the encoding of the characters in the content
response[["headers"]][["content-type"]]

# check the encoding with R base function
Encoding(response$content)
# Using stringi package for a more powerful detection of encoding
library(stringi)
stri_enc_detect(response$content)

# But before using those functions, it would always be good for you to check the
# headers from the browser where you may see something like:
# <meta charset="utf-8">
# It will tell you what encoding you should use

# It will be good to tell the content function what the encoding is. Usually, httr
# is able to find this out by itself (e.g., by looking at the headers), but some
# websites may report a wrong content encoding.
content(response, encoding = 'UTF-8', as = 'text')

# FETCHING WEBSITES: STORING AND LOADING
# ======================================
#
# When you're scraping many pages, it makes sense to store them locally on your
# computer and parse/work with them at a later stage. This is good practice
# since it means you will only fetch websites once, and work on your extraction
# afterwards. If you continuously use `GET` to fetch a website every time you
# changed your code, this will make the website owners angry -- and rightly so.

# To store some HTML on your computer, use the writeLines function.
writeLines(content(response, encoding = 'UTF-8', as = 'text'), "perdu.html")

# Likewise, to get it back, use readLines:
lines <- readLines('perdu.html', encoding = 'UTF-8')

# Note that readLines will only give you a list of lines. To glue them back
# together into a single string, use paste0 as shown below, but most functions
# should not care too much.
single_string <- paste0(lines, collapse = '\n')

# if you intend to use the data later in R, alternatively you can also save the 
# whole response object as .rds
saveRDS(response, "perdu.rds")

# Easy to get the object back, and you have the entire response back as how it is
# when you save it
response <- readRDS("perdu.rds")


# FETCHING WEBSITES: PARSING THE DOM
# ==================================
#
# Now that you know how to get a website, you'll need to parse the HTML into a
# proper DOM tree. This will transform the raw text into a tree which will let
# you select the specific pieces of content you are actually interested in and
# discard the rest.

## You will always need to parse the HTML, i.e., transform the text which the
# server responded with into a DOM tree
dom <- htmlParse(response)

# You can also directly parse an HTML file from disk:
dom <- htmlParse(readLines('perdu.html', encoding = 'UTF-8'))

# Now, you can query `dom` to extract pieces of content (next lab session)

# Should you choose to use rvest instead of httr to scrape websites, htmlParse
# happily accepts its response, too:
response <- read_html(url)
dom <- htmlParse(response)

# rvest also allows you to "chain" requests for rapid access to the contents which
# is also available with httr2
title <- read_html(url) |> html_elements('h1') |> html_text2()
title

# FETCHING WEBSITES: ISSUES AND STEPSTONES
# ========================================
#
# The web is a harsh place, and more often than not, websites will trick you,
# play with you, or outright not play nice. In this final section before the
# exercises, we will learn about a few of them.

# 1.) The website may move

# Visit the following website and note that it will redirect you.
url <- 'https://www.nrcresearchpress.com/journal/cjfas'

# Let's see what this manifests as:
response <- GET(url)
response$status_code # Can you explain this status code?

# Run GET again, but this time in "verbose" mode (i.e., the function will be
# very chatty about what happens)
GET(url, config = httr::config(verbose = TRUE))

# You will notice that there are actually several requests happening. One
# response tells you that it has "Moved Permanently".

# We can use cURL to only download the headers of the response (this is faster
# than waiting for the server to send us the -- possibly large -- website) and
# inspect them. These functions will be introduced later in the course.
headers <- curlGetHeaders(url)
locations <- grep(headers, pattern = 'Location', value = TRUE)

moved_url <- stringr::str_extract(locations, pattern = 'https?://.*')

print(moved_url)

# 2.) You may not see what you expect

# Let's parse the response. What is odd about this result?
htmlParse(response)

# EXERCISES
# =========
#
# The next exercises are meant for you to familiarize yourself with the basics
# of retrieving websites.

# EXERCISE ONE: SCRAPING A NEW WEBSITE
# ====================================
#
# Visit the website www.hendrik-erz.de/blog and inspect it. Then do the
# following:
#
# 1.) Download the website.
# 2.) Save the website into an HTML file and open it. What are the differences?
# 3.) Parse the HTML into a DOM tree.
# 4.) Try to find a website on which this will not work.
# 5.) BONUS: Download https://httpbin.org/status/418, save it to your computer,
#     open the resulting file, and explain what it is.

url <- "https://www.hendrik-erz.de/blog"
response <- GET(***)
print(***) # Check the status code
page_content = ***
writeLines(page_content, "test.htm")
dom <- ***

url <- "https://httpbin.org/status/418"
# TODO: Fetch this website, save it into a textfile, and explain what this is.

# EXERCISE TWO: POST DATA
# =======================
#
# Until now, we have only used so-called GET-requests. However, many websites
# require log-ins or the submission of form-data. To do so, httr offers you the
# HTTP-verb POST. In this exercise, you will use it to scrape data from the
# Swedish Reddit-alternative FlashBack.
#
# This requires you to "post" data to the login page of Flashback using the
# right login credentials. The credentials you will use are:
#
# Username: LiuKonto
# Password: MinPass2000
#
# To find out how to post the appropriate data, refer to the help pages of the
# POST function. Also, you will need to find out the appropriate names. Remember
# that HTML forms consist of elements in the following form:
# <input type="some type" name="the input's name">. You will need to provide the
# appropriate "name"s for each input element.
#
# 1.) Write a scraper that enters log-in credentials to
#     https://www.flashback.org/login.php (using httr's POST)
# 2.) Extract the cookies from the server's response, since these will be your
#     key to unlocking the website in other requests.
# 3.) Scrape the index page, providing the cookies you got from the server.
# 4.) Save the index page to your computer, and open it with your browser.
#     Ensure that the website tells you that you are logged in in the top-right.
#
# 5.) BONUS: If you managed to do this, doing the same on Étienne's website
#     should be a piece of cake: https://ollion.cnrs.fr/2024/02/14/dss24/
#
login <- "https://www.flashback.org/login.php"
home <- "https://www.flashback.org"

# TIP 1: You will need to find a total of six input fields on the website and
#        provide these when performing the POST action.
# TIP 2: FlashBack does something fishy, and there are two inputs for which you
#        will need to provide the password as an MD5-hash. Since this is out-of-
#        scope, we have provided you with the correct value already:
username <- "LiuKonto"
password <- "MinPass2000"
md5password <- cli::hash_md5(password)

parameters <- list(
  # TODO: Add the appropriate input fields to this list
  # These are hidden inputs that are required by the website
  vb_login_md5password = md5password,
  vb_login_md5password_utf = md5password,
  do = "login",
  url = "/login.php"
)
response <- POST(***)
flashback_cookies <- cookies(response) # Retrieve cookies

# Now we can request the home page
response <- GET(***, set_cookies(.cookies = ***))
page_content <- ***
writeLines(page_content, 'flashback.htm')

# EXERCISE THREE: WEBSITES THAT DON'T FOLLOW GOOD PRACTICES
# =========================================================
#
# The final exercise will put you in the position of having to deal with a
# website that doesn't do what almost all others do:
# https://css.cnrs.fr/scrape/reperdue
#
# Your task is to download the website on your computer. You may have to look
# closer at its source code to understand what is happening.

url <- "https://css.cnrs.fr/scrape/reperdue"
response <- ***
page_content <- ***
writeLines(page_content, 'reperdue.htm')

################################ THE END #######################################
