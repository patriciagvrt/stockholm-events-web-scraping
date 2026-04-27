################################## DSSS26 - 4 ### SELENIUM #####################
#
# This file introduces you to using a Selenium server to load websites and
# control them from within R. It's basically you using a regular browser, but
# instead of you yourself clicking and typing, you tell the server to do it.
#
# Script and instructions by Hendrik Erz <hendrik@zettlr.com>
#
# (originally Étienne Ollion and Julien Boelart)
#
# (last update: April 24, 2025)
#
################################################################################
#
# Setting this up is a bit of a hassle, but it works like this:
#
# STEP 1: INSTALL DOCKER DESKTOP
#
# The first step is to install Docker Desktop. Docker is a piece of software
# that simply put allows you to run additional computers on your computer, known
# as virtual machines. Learn more here: https://en.wikipedia.org/wiki/Docker_(software)
#
# To install Docker, download the corresponding setup file for your operating
# system from here: https://www.docker.com/get-started/
# NOTE: If you're using an M1-Mac or an older Intel-Mac, pay special attention
# to which file you're downloading!
#
# Then, install it just as you would.
#
# STEP 2: DOWNLOAD THE SELENIUM IMAGE
#
# Consult the manual on how to open the Docker "Dashboard". Then, in the search
# bar at the top, search for either:
#
# - "selenium/standalone-firefox" IF YOU ARE ON AN X86 MACHINE (applies to
#   basically everyone, unless you are using an M1 Mac)
# - "seleniarm/standalone-firefox" IF YOU ARE ON AN ARM MACHINE (applies
#   basically only to M1-Mac users)
#
# This will download the corresponding Selenium image (about 1.5GB in size)
#
# Then, in the list of images, click the "play" button to start that image in a
# new container. The app will show you a settings display. Click on the arrow to
# adapt the optional settings. You will see two or three "port" settings. In the
# setting with the "4444", type "4444." In the one with "5900", type "5900".
# (The port numbers may change slightly, please refer to the documentation for
# up-to-date details: https://github.com/SeleniumHQ/docker-selenium)
#
# The 4444-port is the one your R script will connect to, the 5900 is for step 4
# below.
#
# Then, it will start the image and give you some output. The log output should
# end with a line indicating that Selenium has been successfully started.
#
# STEP 3: USE IT
#
# Now you're basically set. You will need to install the R package "selenium",
# either automatically or manually with `install.packages("selenium")`.
#
# STEP 4 (OPTIONAL): VIEW WHAT HAPPENS
#
# Right now, you are essentially controlling a web browser remotely with R code.
# This is fun, but what if you want to observe if your code is doing what it
# should? The library has a built-in screenshot function (see below) that allows
# you to capture how the browser looks at the moment, but it can be cumbersome
# to take screenshot after screenshot in order to debug any problems you
# encounter. Instead, you can open a display connection to the Selenium
# container that allows you to view in real time as the browser does its magic.
#
# To do so, the Selenium docker container supports a remote desktop connection
# using the VNC (Virtual Network Computing) protocol. It exposes this using the
# second port you have set above, 5900. To use this connection, you need to
# install a VNC client and connect to this port. There are free and open source
# options for all operating systems. Below are some suggestions. Once you have
# one set up, tell it to connect to "127.0.0.1:5900". This will then open up a
# window that shows you the Selenium container. When you, e.g., navigate with
# the R code below, you should immediately see the browser switch websites.
# The connection will ask you for a password; the default is "secret".
#
# VNC Client Options
# ==================
#
# macOS: TigerVNC. You can install this using Homebrew (https://brew.sh/).
#        To launch the viewer, open a terminal window and launch "vncviewer".
#        More info: https://tigervnc.org/doc/vncviewer.html
#
# Windows: An alternative for Windows might be https://www.tightvnc.com/. (Not
#          tested, feel free to provide feedback if it works for you.)
#
# Ubuntu: On Ubuntu, a working solution is Vinaigre. The Ubuntu App Store calls
#         it "Remote Desktop Viewer". More info:
#         https://help.ubuntu.com/community/Vinagre

# Then you can load it:
library(selenium)
# DOCUMENTATION: https://ashbythorpe.github.io/selenium-r/index.html
# The documentation gives you a lot of info on how to use it. This file gives
# you an example.

# Initialize the session. At least for me, Selenium was smart enough to actually
# search for and find the server running in docker. You may have to provide the
# port number here, however. Note also that "browser" needs to correspond to the
# Selenium image you downloaded. There is the option to use "chrome", but then
# you'll need to download a different image.
library(RSelenium)
remDr <- remoteDriver(
  remoteServerAddr = "localhost",
  port = 4444L,
  browserName = "firefox"
)

session <- SeleniumSession$new(browser = "firefox")

# NOTE: Under the hood, the Selenium package uses -- funnily enough -- httr to
# communicate with the Selenium server, so if something goes wrong you will see
# an HTTP error (for example with a 404 or 500). Usually, the last line
# indicates what exactly the problem was, such as "No such element".

# NOTE2: Sessions can expire! And that relatively soon! So if you don't run
# anything for a minute or so, it may bark at you that there was no session. In
# that case, you'll need to run the line above again, and re-run anything in
# between.

# This allows you to check if the session works as expected.
session$status()

# Navigate to a webpage
session$navigate("http://www.google.com")

# navigate to another webpage
session$navigate("http://www.blocket.se")

# Retrieve the URL currently loaded in the browser
session$current_url()

# Make a screenshot and have a look at it to see that the Selenium browser is
# viewing the correct website. This function is only required because the
# library gives back base64 encoded image data, and I haven't found a proper way
# of displaying that data in a plot. So you'll have to open the file
# "screenshot.png" after running the function. Not ideal, but then, you know,
# web design is war.
screenshot <- function(session) {
  base64 <- session$screenshot()
  raw <- base64enc::base64decode(base64)
  writeBin(raw, "screenshot.png")
}

# Take a screenshot. NOTE: You can also take screenshots of individual elements
# IF these are visible on the website. Selenium will bark at you if the elements
# are not visible.
screenshot(session)

# Now, let's work on a website that has some bot protection measures in place. We'll use the
# website of the German student-led sociology journal "Soziologiemagazin".
# It is hosted on Hypotheses.org, which uses the Anubis system to prevent bot access.

# Make sure you have a VNC connection to the Docker container open so that you can see how it works.

session <- SeleniumSession$new(browser = "firefox")

# First, navigate to the website:
session$navigate("https://soziologieblog.hypotheses.org/")

# Observe what happens: Anubis detects that the client accessing the website is possibly a bot and
# provides a much harder challenge than if you visited using your regular browser. It will take some
# time to do the challenge, but it will eventually work, and you can see the website.

# Next, there is a Cookie consent banner. Let's find and close it.
# By inspecting the "Accept all" (German: "Alle akzeptieren") button in the DevTools, you can
# see what you need to find the button.
button <- session$find_element(using="xpath", value="//a[contains(text(), 'Alle akzeptieren')]")

# Now we can programmatically "click" it to close the banner:
button$click()

# If you did not have a VNC connection, you can make a screenshot to confirm that it worked:
screenshot(session)

# Now, let us use the search to find content on the website. Use the inspector to find
# the correct search input (to the right side of the main content):
search <- session$find_element(using="xpath", value='//input[@class="search-field"]')
search$click()
search$send_keys("computational social science", keys$enter)

# What will work regardless of the cookie modal is to search for something. The
# page has a weird way of identifying the search bar (here I just used the
# aria-label property because that seemed the best idea to uniquely identify it.)
search_input <- session$find_element(using = 'xpath', '//input[@aria-label = "Vad vill du söka efter?"]')
# This sends the given letters to the element. The keys$enter part can also be
# used if you need other keys, such as backspace, or tab. (Typing keys$… should
# open an autocomplete that tells you which keys are available.)
search_input$send_keys("computational social science", keys$enter)
session$current_url() # Should now be the search page
screenshot(session) # Confirm by looking at it (unless you found a way to close
# the cookie banner, it will still be visible.)

## Navigate back and search for a new term
session$back()
search_input <- session$find_element(using = 'xpath', '//input[@aria-label = "Vad vill du söka efter?"]')
search_input$send_keys("corona", keys$enter)
session$current_url()
screenshot(session)

session$navigate("https://www.facebook.com")
## Gets source code (then you can use classic methods; remember to load XML)
src <- session$get_page_source()
writeLines(src, "facebook.htm")
htmlParse(src)

# Finally, you always have to close a session! Once you are done, you should also
# stop the Docker image to free up system resources (remember: As long as it is
# running there's basically a second PC running on your computer.)
session$close()
rm(session)
gc()
