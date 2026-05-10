################################## Project 1 ##################################
# Thsi is the first proejct for Digital STrategies, my ideia is to extract information
# from the website: https://www.visitstockholm.com/events/?

# First step install of packages and load libaries
install.packages(c("httr", "XML", "rvest"))

library(httr)
library(XML)
library(rvest)


getwd() # This will tell you which folder R works from right now

setwd('C:\Users\pg\Documents\GitHub\Digital-Strategies-for-Social-Science-Research/visit-stockholm-project') # Change this to wherever you want to work in.


url <- 'https://www.visitstockholm.com/events/?'

# Let's fetch it
response <- GET(url)
