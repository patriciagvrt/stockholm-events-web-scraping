# EXERCISES!

# As always, initialize the libraries you will need:
library(RSQLite)
library(DBI)

# Connect to the database (assuming you are in root of /data):
con <- dbConnect(SQLite(), "data/music.sqlite")



# Write the SQL to answer each question. Test and build your queries in the
# same way as in the tutorial, i.e:
# dbGetQuery(con, "
#   -- your query here, in one or many lines --
# ")

# 1. How many artists are in the database?

# 2. Find all artists whose name contains the word "band" (case-insensitive).
#    Hint: LIKE is case-insensitive in SQLite by default for ASCII characters.

# 3. What are the 5 longest tracks in the database (by duration_ms)?
#    Show the track title and duration. Bonus: also show duration in minutes!

# 4. How many tracks are marked as explicit?
#    Hint: explicit is stored as 1 (yes) or 0 (no).

# 5. Which album has the most tracks? Show the album title and track count.
#    Hint: JOIN tracks and albums, then GROUP BY and ORDER BY.

# 6. What is the average danceability for explicit vs non-explicit tracks?
#    Hint: GROUP BY explicit.

# 7. Which 5 genres have the highest average valence (musical positivity)?
#    Hint: you need track_genres and genres.

# 8. Find all tracks by 'The Beatles'. How many are there?
#    Hint: you need track_artists and artists.

# 9. Which artists appear in the most genres?
#    Hint: use artist_genres, GROUP BY artist_id, then join to get the name.

