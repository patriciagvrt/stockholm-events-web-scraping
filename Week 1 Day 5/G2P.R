# GETTING TO PHILOSOPHY GAME
#
# c.f.: https://en.wikipedia.org/wiki/Wikipedia:Getting_to_Philosophy

# R implementation by Hendrik Erz <hendrik.erz@liu.se> (2023) | (c) GNU GPL v3

# RULES:

# 0. Visit any Wikipedia article (English Wikipedia)
# 1. Click on the first non-parenthesized, non-italicized link
# 2. Ignore external links, links to the current page, or red links
# 3. Stop when reaching "Philosophy", a page with no links, or a page that does
#    not exist, or when a loop occurs.
#
# TIPS FOR THE IMPLEMENTATION:
# * Because removing parentheses and italics can be difficult with the tools we
#   have in the course, it's also fine to apply some different selection
#   criteria:
#     * Exclude category pages ("Category:Something")
#     * Exclude disambiguation pages (ending in "(disambiguation)"), since these
#       are italicized links that one can easily detect (at the beginning of the
#       page)
# * You can check *before* visiting a link if that would lead to a loop, and
#   proceed with the next link instead (i.e. not necessarily follow the first)
# * If you're having bad luck and many of your attempts take ages to end up with
#   nothing, try to reduce the MAX_DEPTH so that you do not have to wait forever

library(httr)
library(XML)

### SUCCESSFUL SEED LINKS:
# (Use these to ensure your script is working before going to Special:Random!)

# Working start page for a chain of length 826 (April 26, 2026):
# https://en.wikipedia.org/wiki/Politics

# Working start page for a chain of length 96:
# Update April 26, 2026: This page now has a much longer chain and will
# eventually also lead to Politics, so this page has more than 826 links now.
# https://en.wikipedia.org/wiki/List_of_places_in_Cieszyn_Silesia

# Working start page for a chain length 870:
# https://en.wikipedia.org/wiki/Lois_White

start_page <- "https://en.wikipedia.org/wiki/Special:Random"

# This function will take a single Wikipedia page, and parse it according to our
# needs.
parse_page <- function (url, visited_links) {
  # The following piece ensures that the crawler simply stops if the 1000th page
  # does not get us to Philosophy.
  MAX_DEPTH <- 1000
  if (length(visited_links) > MAX_DEPTH) {
    print(paste("Maximum depth of", MAX_DEPTH, "links reached. Aborting..."))
    # Returning NULL will indicate that this was an unsuccessful attempt.
    return(NULL)
  }

  # Retrieve the URL
  response <- GET(url)

  # Don't forget to check the status code (this can sometimes happen if a "red
  # link" is not marked in the source code)
  if (response$status_code != 200) {
    print(paste("Got non-OK status code:", response$status_code, " for link ", url, ". Aborting..."))
    return(NULL)
  }

  # Actual URL we've arrived at after redirections (e.g. from Special:Random)
  current_url <- response$url

  # Print the current URL we have to see where the crawler is getting us to.
  print(paste(paste0('#', length(visited_links)), current_url))

  # The following checks whether the current_url has already been visited. If so
  # this means that we have entered a loop and thus this attempt was not
  # successful.
  if (current_url %in% visited_links) {
    print("Loop detected! Aborting...")
    return(NULL)
  }

  # Now we need to add our current_url to the list of visited links to mark it
  # as "seen"
  visited_links <- append(visited_links, current_url)

  # If the page we're on right now happens to end in Philosophy, we won!
  if (grepl('\\/Philosophy(#.+)?$', current_url, perl = TRUE)) {
    # Return the full list of links that we have visited before ending up here.
    return(visited_links)
  }

  # At this point we know it's not Philosophy, so we'll have to pick up the
  # candidates for links that we could follow. For this, we can use our
  # well-known recipe:

  # Parse the HTML
  tree <- htmlParse(response)

  # Get all links. This somewhat bulky XPath already excludes a ton of red
  # herrings, such as red links (identifiable by class=new) and external links
  # (identifiable by class=extiw). Another condition we can make use of here is
  # that the actual main body of the Wikipedia article will be wrapped in a div
  # with ID bodyContent.
  working_links <- xpathSApply(tree,"//div[@id='bodyContent']//a[@href and not(@class='new') and not(@class='extiw')]")

  # Now that we have a list of (potentially) interesting nodes, we have to
  # ensure that we actually have some left. Sometimes all the preparatory
  # fieldwork that we do will leave us with not a single link that may be of
  # interest. This is in the terminology called a "leaf", since there is no
  # layer below this page.
  if (length(working_links) == 0) {
    print("Leaf detected! Aborting...")
    return(NULL)
  }

  # Now we have to check each link one by one to see if it matters to us.
  for (link in working_links) {
    # Extract just the href-attribute because that is what we're interested here.
    href <- xmlGetAttr(link, 'href')

    if (!grepl('\\/wiki\\/.+$', href, perl = TRUE)) {
      next # Not an internal Wiki link (NOTE: Wikipedia uses relative links)
    }

    if (grepl(':', href, fixed = TRUE)) {
      next # Links to a category page/non-regular page (e.g. Special:Random)
    }

    # The startsWith function, which we did not cover in the course, checks if
    # one string (href) starts with another (current_url)
    if (startsWith(href, current_url)) {
      next
    }

    # EXERCISE: Can you say what the (#.+)? does at the end of this regular expression?
    if (grepl('\\(disambiguation\\)(#.+)?$', href, perl = TRUE)) {
      next
    }

    # At this point we have the first link that we can actually follow. Remember
    # that Wikipedia-links are relative, so we have to manually prepend the
    # Wikipedia URL.
    abs_link <- paste0('https://en.wikipedia.org', href)

    # Some sub-pages of Wikipedia do not link using /wiki/page but
    # //en.wikipedia.org/wiki/page. This normalizes the abs_link accordingly:
    if (startsWith(href, "//en.wikipedia.org")) {
      abs_link <- paste0('https:', href)
    }

    # This is where we can cheat a little: Since we cannot with the tools at
    # hand properly remove italicized links, we already check for a loop here
    # which ensures that the crawler has more luck ending in a proper link.
    if (abs_link %in% visited_links) {
      next # If the current link has already been visited, take the next one.
    }

    # At this point, recursion comes in. Note how we have skipped uninteresting
    # links (using the "next" keyword). This means that at this point we are
    # left with the first interesting link that is worth visiting. Recursion is
    # when a function (here: parse_page) calls itself. We can do this because
    # the first time we call parse_page is the "seed" where we start at some
    # random page. Here, we call the same function, but with some link on that
    # page.
    # EXERCISE: Can you tell how many of these recursive functions will be
    # "active" at the same time?
    return(parse_page(abs_link, visited_links))
  }

  print("No valid link found! Aborting...")
  return(NULL)
}

# Here we call the function with our start page and provide an empty list that
# hopefully will be returned by the function back to us, but filled with all the
# links it visited.
result <- parse_page(start_page, list())

# If the function did not return a list, but NULL instead, we know that the
# attempt was unfortunately unsuccessful. But if it isn't …:
if (!is.null(result)) {
  # We have found a chain that links to Philosophy!
  print("Found working chain!")
  print(paste("Chain length:", length(result)))
  print(paste("Starting page:", result[1]))
}
