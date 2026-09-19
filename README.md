# Stockholm Events Web Scraping

Web scraping project in R that collects, cleans, and structures public event information from the Visit Stockholm website.

The project was developed as part of the MSc in Computational Social Science at Linköping University and focuses on building a small structured dataset from publicly available cultural event information.

## Research Question

What kinds of events are currently promoted on the Visit Stockholm events page, and how are they distributed by category?

The project was motivated by the idea of transforming information from an event website into structured data that could later support applications such as personal event recommendations or calendar integration.

## Data Source

The data were collected from the public Visit Stockholm events website.

The dataset should be interpreted as a snapshot of the events available at the time of scraping, rather than a complete historical or yearly archive.

Only publicly available event information was collected. No personal data, login credentials, or private information were used. :contentReference[oaicite:0]{index=0}

## Data Collection Workflow

The scraper follows a multi-step process:

1. Send an HTTP request to the Visit Stockholm events page.
2. Check the response status and encoding.
3. Convert the HTML response into readable UTF-8 text.
4. Parse the HTML into a DOM structure.
5. Use XPath to identify event names and links.
6. Filter URLs to keep only event pages.
7. Visit individual event pages.
8. Extract additional event information.
9. Clean and standardize the resulting data.
10. Save the final structured dataset as CSV.

The main page is downloaded using `GET()`, converted to UTF-8 text, and parsed using `htmlParse()`. XPath is then used to navigate the HTML structure. :contentReference[oaicite:1]{index=1}

Event names were identified in `h3` elements, while event links were extracted from anchor elements and filtered using regular expressions. :contentReference[oaicite:2]{index=2}

## Variables Collected

The final dataset includes information such as:

- event name
- category
- date
- location
- event link
- description
- venue
- street address
- postal code
- city

The scraper also visits individual event subpages to enrich the original dataset with more detailed information. :contentReference[oaicite:3]{index=3}

## Data Cleaning

Several cleaning steps were necessary because the website was designed for human browsing rather than structured data extraction.

The project includes:

- removal of duplicated events
- validation of event categories
- handling of Swedish characters and UTF-8 encoding
- extraction of postal codes using regular expressions
- separation of address components
- standardization of output for CSV files

Some events appeared more than once on the website, so duplicates were removed using combinations of event name and URL. :contentReference[oaicite:4]{index=4}

## Challenges

### Dynamic content

The original goal was to collect events across a longer time period using the website's calendar.

However, the calendar interface uses dynamic interaction that was not available through the static HTML response.

I experimented with RSelenium, but browser-driver and dependency problems made the solution difficult to reproduce consistently.

For this reason, the final project uses static HTML scraping and visits the event pages available from the main results page. :contentReference[oaicite:5]{index=5}

### Encoding

Swedish characters such as `å`, `ä`, and `ö` required additional attention when exporting the dataset.

The source website uses UTF-8, but spreadsheet software can interpret CSV encoding differently. The final export therefore uses tools designed to improve compatibility with UTF-8 text. :contentReference[oaicite:6]{index=6}

## Analysis

After building the dataset, I performed a small exploratory analysis of the scraped events.

The analysis includes:

- number of events by category
- distribution of single-day and multi-day events
- sample of the structured event dataset

These analyses demonstrate how unstructured web content can be transformed into data that can be summarized and analysed computationally.

## Repository Structure

```text
.
├── data/
│   └── visitstockholm_events_final.csv
│
├── figures/
│   ├── duration_type_table.png
│   ├── events_sample_table.png
│   └── visitstockholm_category_plot.png
│
├── report/
│   └── visit_stockholm_scraping_report.pdf
│
├── src/
│   └── scrape_visit_stockholm.R
│
├── README.md
└── LICENSE
