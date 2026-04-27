################################## DSSS26 - 4 ### EXTRA ########################
#
# This file contains several additional exercises for you to work through after
# you have finished the main exercise from the lab4 script. Once you understood
# that one, feel free to start sifting through these exercises here to get an
# even better grasp of how to select data on a website.

# REMINDER: Please be mindful NOT TO OVERLOAD the servers you’re scraping! Limit
#           your request rate and respect each site’s crawl‑delay settings.

### EXERCISE ONE: REVISITING WHAT YOU'VE LEARNED ###
#
# It is always good to re-do any practice you've already had. There is a handy
# website that literally tells you to scrape it. It offers various challenges
# that you should now be able to handle easily that you have gotten the gist of
# web scraping.
#
# First, some refresher that only uses the things you've learned in labs 1-3!
#
# TASKS:
# 1.) Here is a wonderful genealogy project and this is a page of our old friend
#     https://genealogy.math.ndsu.nodak.edu/id.php?id=74313
# 2.) Download that page and save it to your computer.
# 3.) Parse the HTML into a DOM tree and save the information of the students of
#     our old friend Newton. Make sure you have the link of students' page also
#     stored in a separate column.
# 4.) Add up the difficulty a bit, add the name and link of the advisors of Newton
#     in the same table as above.
# 5.) For bonus points, go to every students' page and collect the same information
#     and repeat this for 5 generations
# 6.) Thinking: if you need to go further along the genealogy path, how would you
#     automate the process?
# 7.) Thinking: look at the structure of the data you just collected, does it
#     remind you of any other courses? (smirking face)

### EXERCISE TWO: PAGINATION ET AL. ###
#
# The second extra exercise concerns pagination. Here you'll have to use loops
# to scrape everything.
#
# TASKS:
# 1.) Open https://www.nature.com/nature-index/institution-outputs/generate/all/global/academic
#     at the same time, check this: https://www.nature.com/robots.txt, some pages
#     are not allowed to be scraped
# 2.) Look for "Region or country/territory", and search for "Sweden", and take 
#     a look at the change of the URLs.
# 3.) Using that knowledge, download only the data for "Netherlands",
#     but use only a single request -- don't apply the search manually!
# 4.) Write a function that takes a single page and extracts all rows of data
#     from that, and return it as a data frame.
# 5.) Use that function to extract the data for the Nordic countries: Sweden, Denmark,
#     Norway, Finland, Iceland.
# 6.) Bonus question: Do you think you can retrieve the Nature index for all 
#     institutions in Europe? With or without SELENIUM?


### EXERCISE THREE: SELENIUM ###
#
# Finally, here is an exercise that needs you to use Selenium. Since Selenium
# can be a pain to set up, you can safely ignore this challenge if you have
# trouble setting it up. However, if you want to be smart, you can answer the
# bonus question without even touching Selenium, so I invite you to take a look!
#
# Should you have been able to install Selenium, however, try to see if you can
# solve the other challenges, too!
#
# TASKS:
# 1.) Open https://unsplash.com/blog/partnerships/
# 2.) Click on "Load more posts" and see what the data it loads looks like. Also 
#     use inspect to see its structure.
# 3.) Open a Selenium session, navigate to "Load more posts" click on it
# 4.) Make a loop to automatically load all the posts,
# 5.) Scrape the post information, i.e., the article title, author and published
#     date into a data frame.
# 6.) Bonus question (you can save it until we have lab 5): make a list of partners
#     of unsplash and the date when they become partners (you can do so by analyzing
#     the title of the posts, at this stage you can focus on those titled 
#     "Unsplash × AAAA").
# 7.) Bonus question: The website gives you a good hint as to what it takes to
#     get to that data *without* using Selenium. Follow their 'advice' of looking
#     at the network tab, extract the URL that it uses to fetch the data,
#     understand its structure, and then use a classical for-loop to extract all
#     years.

################################ THE END #######################################
