#DSS25 EXTRA: How to use Selenium in R
#Using RSelenium
#Script by J. Boelaert, E. Ollion, L. Labat

library(RSelenium)
library(wdman)
library(netstat)

#0. For this to work, you need to have a browser AND a webdriver with the same version
#This tells you where to place you webdriver
selenium_obj <- selenium(retcommand = T, check = F)
selenium_obj

#Go to the address mentioned in Dwebdriver.chrome.driver, place your downloaded webdriver
#Change the file name to match your own version of chrome (for me:135.0.7049.114)
#More details: https://www.zenrows.com/blog/rselenium (do read it)
######### Ok, let's start
driver <- rsDriver(browser = "chrome",
                   chromever = "135.0.7049.114", #Add your version of the chrome driver
                   port = free_port(),
                   verbose = FALSE)

rmDr <- driver$client

#############
#1. Let's go visit a page and enter something
rmDr$navigate("http://www.google.se")
webElem <- rmDr$findElement(using = 'xpath', '//textarea[@title = "Sök"]')
webElem$sendKeysToElement(list("Computational social Sciences Liu", key = "enter"))

#2. Visit a page, unlock content
rmDr$navigate("https://www.svt.se/nyheter/ekonomi/") 
# Uses xpath to locate areas on the page (search bar)
rmDr$getCurrentUrl()

page <- unlist(rmDr$getPageSource())
writeLines(page, "testsvt.html")

#Let's load some more content
rmDr$findElement(using = "xpath", value = "//span[@class='Text__text-button___GnyNb']")$clickElement()
page <- unlist(rmDr$getPageSource())
writeLines(page, "testsvt.html")

#############
#3. Entering credentials
rmDr$navigate("https://www.flashback.org/login.php") 
#Click manually on the "Jag Samtycker" button, or do it from here (do it?)
# Uses xpath to locate areas on the page (login)
webElem <- rmDr$findElement(using = 'xpath', '//input[@name = "vb_login_username"]')
webElem$sendKeysToElement(list("LiuKonto"))
webElem <- rm$findElement(using = 'xpath', '//input[@name = "vb_login_password"]')
webElem$sendKeysToElement(list("MinPass2000", key = "enter"))
rmDr$getCurrentUrl()
rmDr$navigate("https://www.flashback.org/f69") 
rmDr$findElement(using = "xpath", value = '//i[@class = "fa fa-angle-right"]')$clickElement()

rm(list=ls())
gc()

#############
#4. Downloads
driver <- rsDriver(browser = "chrome",
                   chromever = "135.0.7049.114",
                   port = free_port(),
                   verbose = FALSE)

rmDr <- driver$client

#Let's go visit a page and download a document
rmDr$navigate("https://osf.io/preprints/socarxiv/wjvfq_v1")

#Get the page
page <- unlist(rmDr$getPageSource())
ppage <- htmlParse(page)

rmDr$findElement(using = "xpath", value = "//a[@data-test-download-button='']")$clickElement()

#When done, close your headless browser and "garbage collect"
rm(rmDr)
gc()

#############
#############
#4. Mouse actions
driver <- rsDriver(browser = "chrome",
                   chromever = "135.0.7049.114",
                   port = free_port(),
                   verbose = FALSE)

rmDr <- driver$client
rmDr$navigate("https://www.hemnet.se/bostader?location_ids%5B%5D=17744") 

rmDr$setWindowSize(width = 800, height = 1200)
webElem <- rmDr$findElement(using = "xpath", value = '//body')

for (i in 1:300){
  print(i)
  webElem$sendKeysToElement(list(key = "down_arrow"))
  Sys.sleep(0.1)
  }

#You can also do this by calling some JS in R
scrolling_script <- "
    // scroll down the page 1 times
    const scrolls = 1
    let scrollCount = 0

    // scroll down and then wait for 1s
    const scrollInterval = setInterval(() => {
      window.scrollTo(0, document.body.scrollHeight)
      scrollCount++

      if (scrollCount === numScrolls) {
          clearInterval(scrollInterval)
      }
    }, 1000)
"

#Now we pass it in R
rmDr$executeScript(scrolling_script)
rmDr$executeScript(scrolling_script)

