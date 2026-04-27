### DEMONSTRATION: WEB SERVERS ARE EVERYWHERE ###
#
# Until now you have downloaded websites and HTML from various websites such as
# google.com, hendrik-erz.de, or Github.com. However, a web server is just any
# old program that runs on a computer. If you use Zotero to manage your
# literature, this means that you actually have a web server right here on your
# computer!
#
# The following script shows you how to access this web server, and gives an
# example for how you could automate something.

# First, as always, we need some packages, so let's import them.
library(httr)
library(jsonlite)

# Next, let us try to see if we can contact Zotero. Run the following three
# lines of code.
# Note, however, that Zotero needs to be running. If you close Zotero, this will
# also stop the web server, which means that there is no program listening that
# could answer your request -> you would receive no response (and R will tell
# you an error).
url <- "http://127.0.0.1:23119/connector/ping"
response <- GET(url)
content(response, as = 'text')
# If Zotero is running, the content should tell you as much.

# This is the way that the Browser Connector from Zotero actually tells your
# Zotero application to add a new item to your list of references. And this
# means, you could use this knowledge to add new items to the app!
#
# Some basic documentation can be found here:
# https://www.zotero.org/support/dev/client_coding/connector_http_server

### EXAMPLE: SEARCHING FOR LITERATURE ###
#
# To end with a real-world example, we can use this web server to automatically
# search our database. For the next steps, you will need to have the Zotero
# plugin "Better BibTex" installed. Otherwise, they will not work. If you do not
# yet have it installed, simply follow the steps on the official website:
# https://retorque.re/zotero-better-bibtex/

# To work with BBT (Better BibTex), we need to send POST-requests. These require
# a bit of setup. The logic is exactly the same as if you're logging in to a
# website (without the whole cookie-shenanigans).

# First, we need to provide some data to the request:
body <- list(
  jsonrpc = "2.0", # BBT uses the JSONRPC specification version 2.0
  method = "item.search", # What we want to do (=search for an item)
  params = list("Vaswani") # Parameters (here: The search string)
)

# Next, the endpoint for the BBT API is the following:
url <- "http://127.0.0.1:23119/better-bibtex/json-rpc"
# Let us send the request
response <- POST(
  url,
  # These headers are specific for BBT, and are explained in their documentation
  add_headers("Content-Type" = "application/json", "Accept" = "application/json"),
  encode = 'json',
  body = body
)

# Like any other web server, these responses also come with a status code which
# should be 200 if everything went well.
response$status_code

# BBT returns no HTML, but JSON. So, we use the known functions to retrieve the
# JSON response and turn it into a data object. If you search for something that
# your Zotero actually contains, it will contain actual results.
json_data <- content(response, as = 'text')
data <- fromJSON(json_data)
data

# You can see every method that BBT supports on their website:
# https://retorque.re/zotero-better-bibtex/exporting/json-rpc/index.html

### THE END ###