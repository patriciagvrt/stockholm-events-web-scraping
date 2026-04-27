################################## DSSS26 - 3 ### EXTRA ########################
#
# This file contains several additional exercises for you to work through after
# you have finished the main exercise from the lab3 script. Once you understood
# that one, feel free to start sifting through these exercises here to get an
# even better grasp of how to select data on a website.

### EXERCISE ONE: SCRAPING GITHUB ###
#
# GitHub is a space where Open Source software is developed. One of the biggest
# "data lakes" is the issue trackers where users of the software can report both
# problems they found as well as request new features to be added. While there
# is a public API that you should normally use, the website itself has a few
# very good properties that predestine it for teaching you an additional set of
# things to look out for when scraping pages: custom tags and data properties.
#
# The main task of this exercise is to select information from non-standard tags
# and data attributes, because sometimes the good parts are not the textual
# content of some elements, but the data that is present in invisible properties
#
# TASKS:
# 1.) Open a random issue tracker on GitHub, for example
#     https://www.github.com/Zettlr/Zettlr/issues
# 2.) Download that page and save it to your computer. You only need to download
#     the first page
# 3.) Parse the HTML into a DOM tree and select the following information into
#     a data frame:
#     i.) The issue number
#     ii.) The issue title
#     iii.) The issuer (author) name
#     iv.) The last-updated at time (both date AND time, not just the date)
# 4.) Take a look at the API response for the same page and compare the output.
#     Name the differences of what you can get from the website itself vis-à-vis
#     the API response. (Note: To see what the API gives you, visit
#     https://api.github.com/repos/Zettlr/Zettlr/issues -- replace Zettlr/Zettlr
#     with whatever other repository you have selected, if applicable.)

### EXERCISE TWO: SCRAPING ACTORS ###
#
# The second extra exercise concerns scraping actor information from the IMDB
# (Internet Movie Database). The website was long used for this course to teach
# web scraping techniques, but recently had a big update. Now, the website uses
# much more modern technologies including build scripts which make it harder.
# However, it is still possible to scrape the information from there. This
# exercise is about that.
#
# TASKS:
# 1.) Open a movie, for example https://www.imdb.com/title/tt8772262.
# 2.) Download the page, save it to your computer, and parse the HTML.
# 3.) Create a data frame and collect all actor information from that page.
# 4.) [BONUS] If you're *really* fast, try to use the information on the actors
#     to visit their corresponding sub-pages and try to retrieve some personal
#     details on them, too!
#

################################ THE END #######################################
