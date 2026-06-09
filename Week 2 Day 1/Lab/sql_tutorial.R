# SQL tutorial

# To install necessary packages
# Only need to install once!

# DBI: Database interface - for communicating between R and a database
#install.packages("DBI")

# The SQLite database engine
#install.packages("RSQLite")

# To start using
library(RSQLite)
library(DBI)

# We will be working with a database (on file) that contains data on music!
# Specifically, a dump of tracks from Spotify.

# Download 'music.sqlite' and place in the /data/ folder.

# When we do our sql queries, we can also update/insert/delete, and all queries
# are executed at once. So before we start, make a local backup of the file you
# placed in data:

file.copy("data/music.sqlite","data/music_backup.sqlite",overwrite = TRUE)


# CONNECT TO THE DATABASE
#########################

# Typically, databases are reached by URL:s (often online or localhost) - with
# SQLite, this can be a file, as it is here in our lab.

# To connect to our database (which is a file here), we do the following:
con <- dbConnect(SQLite(), "data/music.sqlite")

# The resulting 'con' is a reference! It doesn't contain the database, but it
# rather POINTS to the data. When we query the database, we are thus querying
# with this reference, so that the database we connected is queried!
# It is possible to have multiple connections to different databases, and work
# with them separately, but then they are indeed separated.

# A database consists of 1 or more (typically more) data tables, each being like
# a csv file. Let's see what tables we have in this database:

dbListTables(con)
# So, a total of 7 tables with different names. We use these names when we query
# these tables

# Let's have a look at what variables (fields) we have in one of these tables:
dbListFields(con, "artists")

# If we want more information about a table, we can use an SQL query called
# PRAGMA. To get detailed info about the 'albums' table:
albums_info <- dbGetQuery(con, "PRAGMA table_info(albums)")
# This will return a dataframe with information about the 'albums' table, storing
# it in a dataframe called 'albums_info'. Let's have a look:

view(albums_info)
# Here we can see the fields (album_id, artist_id, title) and also the data
# types these variables are (first two are integers, 'title' is a text type)

# Note that it is quite common to store results from a sql query in a data table/frame
# Below, we will mostly just display the results directly on the console output,
# which is typically what we do when we experiment with the data. But of course,
# when we want to extract data for doing an analysis, e.g. Gower clustering, we
# would then like to store this into a dataframe (that we also save).

# Ok, so the 'artist' table has two fields (columns): artist_id and name
# Note that it doesn't say 'artist_name': this is a table about artists only,
# so that would be a bit unnecessary (but it could be 'artist_name' as well)

# Let's select the first 5 lines in the 'artists' table:
dbGetQuery(con, "
  SELECT * FROM artists LIMIT 5
")

# We see a list of 5 artists: should be from '!nvite' to '"Puppy Dog Pals" Cast'
# Note the artist_id for each of these: these are the unique identifiers for the
# entries in this table. In short, instead of referring to artist 'The Cure',
# the database can access this particular artist as artist_id 25837

# Let's dissect the actual SQL query:
# SELECT * FROM artists LIMIT 5

# SELECT: this indicates that we want to select some data from something. It could
# be a single table like here, but could also be a combination of tables

# SELECT * : after select we should specify what we want to select, i.e. the fields
# There is no field called '*' though! Instead, * means that we want all fields
# So in this case, we would get both 'artist_id' and 'name'

# FROM artists : This informs where we want to get the data from. 'artists' is
# one of the tables in the database (recall there are many) so we specify it here
# One can select from multiple table at the same time (more about that later)

# LIMIT 5 : This is an optional argument, simply saying that we want to limit the
# number of selected artists to 5

# There are a lot more that a SELECT query could contain of course!

# Let's say that we only had the artist_id in question. We can then query for the
# name of that artist:

# Get the name of the artist with a specific artist_id:
dbGetQuery(con, "
  SELECT name FROM artists WHERE artist_id=25837
")

# Get the artist_id of the artist given the name:
dbGetQuery(con, "
  SELECT artist_id FROM artists WHERE name='The Cure'
")

# Get the artist_id for the band "The Carl Nordlund Cat Band"
dbGetQuery(con, "
  SELECT artist_id FROM artists WHERE name='The Carl Nordlund Cat Band'
")
# Note that there is no such band (at least not in this database)

# Get artist_id and name for all artist names that starts with the string 'carl ':
dbGetQuery(con, "
  SELECT * FROM artists WHERE name LIKE 'carl %'
")

# Get all names for artists whose names end with 'john':
dbGetQuery(con, "
  SELECT name FROM artists WHERE name LIKE '%john'
")

# Get all entries in the 'album' table where 'title' contains 'cats' somewhere:
dbGetQuery(con, "
  SELECT * FROM albums WHERE title LIKE '%cats%'
")

# These last three select queries used a conditional with the LIKE expression. The string
# that then followed had a '%' sign in it. This is like a wildcard character (like
# the * in Regex) that allows for anything. In the last example, it thus allows
# for anything + "cats" + anything. That anything could actually be nothing, so
# an album named "Cats" would be okay!

# We might be more interested in the number of entries there is, than the actual
# entries. For this, we can use the COUNT(*) expression:
dbGetQuery(con, "
  SELECT COUNT(*) FROM albums WHERE title LIKE '%cats%'
")

# There are thus 12 albums that have the characters 'cats' in their title

# As you might recall from the 'artist' table, the artist_id for 'The Cure' was
# 25837. If you have a look at the 'album' table and see what fields it has:
dbGetQuery(con, "PRAGMA table_info(albums)")
# ... you can see that the 'albums' table ALSO has a field called 'artist_id'!
# This is a foreign key: it is of the same datatype as the 'artist_id' in the
# 'artist' table (where it is a primary key), and this is how we can make queries
# that connect these two # tables! THIS IS WHY IT'S CALLED A RELATIONAL DATABASE! :)

# And here is the real beauty with SQL: we can query two tables at the same time
# The query below gets the name of the first 10 tracks in the 'tracks' table,
# and also shows the name of the album where those tracks are:

dbGetQuery(con, "
  SELECT
    t.title AS track_title,
    al.title AS album_title
  FROM tracks t
  INNER JOIN albums al ON t.album_id = al.album_id
  LIMIT 10
")

# Quite a lot going on in the above.
# First: note that we are querying FROM two tables: 'tracks' and 'albums'
# When we do that, we also add a new name to each: 't' to 'tracks' and 'al' to 'albums'
# By doing this, we can then use 't' and 'al' in the rest of the query
# We select the title of the track and the title of the album. To be specific about
# which table each should be taken from, we use 't.title' to refer to the field
# 'title' that is in the table with the 't' marking, which is the tracks. In the
# same vein, we use 'al.title' to refer to the album title as the 'albums' table
# is here referred to with the 'al'. However, to make sure that these names don't
# collide in the output, we use 'AS' to rename them! So we are selecting title
# from tracks and calling that 'track_title', and we select title from albums and
# calling that 'album_title'.
# Note that FROM only contains 'tracks t'. The albums al are instead specified
# in the INNER JOIN in the linebelow. This means that internally, it first selects
# from the 'tracks' table, and then adds stuff from what is specified in the JOIN
# statement. In this JOIN statement, we also need to specify how these entries
# should be attached: we attach by the album_id in t and al, so t.album_id = al.album_id

# The INNER before JOIN means that only rows that match in BOTH tables should be kept.
# If there are tracks that have no album_id (these being NULL) or no match: then
# they disappear from the result.

# We can now easily expand the above to also include the artist name. We then have
# to get the name from the 'artists' table and rename it to 'artists_name' so we
# know what 'name' means (which made sense when we only looked at the 'artists'
# table). We add a new INNER JOIN line where we add the 'artists' table
# (calling it 'ar') and making sure that these are connected by correct artist_id
# between albums and artists
dbGetQuery(con, "
  SELECT t.title  AS track_title,
         al.title AS album_title,
         ar.name  AS artist_name
  FROM tracks t
  INNER JOIN albums  al ON t.album_id   = al.album_id
  INNER JOIN artists ar ON al.artist_id = ar.artist_id
  LIMIT 10
")

# Note that there is no direct connection between 'tracks' and 'artists'. Tracks
# have info about which album they are part of, but tracks don't know who the artist
# is. However, this is something the album knows!

# LEFT JOIN is an alternative: these keeps all rows from the "left" table (the first
# one, which is tracks here), even if there is no match.

# INNER JOIN only keeps rows that match in both tables.
# What if some tracks have no album_id? They disappear.
# LEFT JOIN keeps ALL rows from the left table even if there is no match:

dbGetQuery(con, "
  SELECT t.title, al.title AS album
  FROM tracks t
  LEFT JOIN albums al ON t.album_id = al.album_id
  WHERE al.album_id IS NULL   -- only show the ones with no album
")
# This will however return null, as all tracks have a reference to an album


# ORDERING

# It is possible to sort/order the output in basically any way you want:
# Sort tracks by popularity, most popular first
dbGetQuery(con, "
  SELECT title, popularity
  FROM tracks
  ORDER BY popularity DESC
  LIMIT 10
")
# And I note that I don't recognize a singular one of these tracks! :D
# So apparently I'm not listening to very popular music!

# Provide a list of the 10 least Least danceable tracks (and their measure
# of danceable)
dbGetQuery(con, "
  SELECT title, danceability
  FROM tracks
  ORDER BY danceability ASC
  LIMIT 10
")


# GROUPING

# Instead of returning individual rows, we can 'collapse' several rows into
# suitable groups based on variables, and compute summaries for each group.
# Aggregate functions are COUNT(), AVG(), MIN(), MAX(), SUM()

# How many tracks are there in the database?
dbGetQuery(con, "SELECT COUNT(*) AS n_tracks FROM tracks")
# 89740 tracks!

# The average, minimum and maximum popularity across all tracks
dbGetQuery(con, "
  SELECT AVG(popularity) AS mean_pop,
         MIN(popularity) AS min_pop,
         MAX(popularity) AS max_pop
  FROM tracks
")

# How many albums does each artist have?
# The GROUP BY collapses all rows with the same artist_id into one summary row
dbGetQuery(con, "
  SELECT artist_id, COUNT(*) AS n_albums
  FROM albums
  GROUP BY artist_id
  ORDER BY n_albums DESC
  LIMIT 10
")
# artist_id isn't very informative, so we fix this with a JOIN further down!

# HAVING: this is like WHERE (a condition) but for groups, so this is checked
# after aggregation
# Artists with at least 20 albums (showing artist_id and the number of albums)
dbGetQuery(con, "
  SELECT artist_id, COUNT(*) AS n_albums
  FROM albums
  GROUP BY artist_id
  HAVING COUNT(*) >= 20
  ORDER BY n_albums DESC
")

# Note: we can't use WHERE COUNT(*) >= 20 - this is because WHERE is checked
# before the grouping. HAVING runs after.


# JUNCTION TABLES
# This is where your database pays off! The 'tracks_genres' and 'track_artists'
# are tables that ONLY contains foreign keys! These are used to create many-to-many
# connections between two tables. An artist has many tracks, and a track can have
# many artists.

# Recall from the lecture: some relationships are many-to-many.
# A track can belong to multiple genres. An artist can appear on many tracks.
# These can't live as a column — they need their own junction table.

# What genres does a track belong to?
dbGetQuery(con, "
  SELECT t.title, g.name AS genre
  FROM tracks t
  INNER JOIN track_genres tg ON t.track_id = tg.track_id
  INNER JOIN genres g        ON tg.genre_id = g.genre_id
  WHERE t.title = 'Bohemian Rhapsody'
")

# This actually produces two entries: there are two tracks with this name, one is
# the original with Queen, the other is a cover version by Hayseed Dixie.

# So first: selecting from tracks (will be the two with the title "Bohemian Rhapsody")
# Then we glue on entities from the 'track_genres tg' table whose tg.track_id is the same
# as the track_id values we got from 'tracks t'. These entries from 'track_genres' have 'genre_id' values.
# Then we attach entities from the 'genres g' table whose g.genre_id is the same as
# the genre_id values that we previously attached. So, its like a chain of attaching things!

# One way to think about this is to think about it in steps (and this is a good way to create
# sql queries).
# First we select the track_id and title track that has title = 'Bohemian Rhapsody':
dbGetQuery(con, "
  SELECT t.track_id, t.title
  FROM tracks t
  WHERE t.title = 'Bohemian Rhapsody'
")
# And yes, a bit silly to extract the title of the track as that is what we already had
# but bear with me!

# Ok, we then get the two entries for this title.

# Then we attach the track genres data to this by extending the above with a JOIN
# and also display that genre id:
dbGetQuery(con, "
  SELECT t.track_id, t.title, tg.genre_id
  FROM tracks t
  INNER JOIN track_genres tg ON t.track_id = tg.track_id
  WHERE t.title = 'Bohemian Rhapsody'
")
# Same list as before, now with an additional column: genre_id. This is thus brought
# in from the 'track_genres' table

# The 'genre_id' is not so informative. Instead, we want the genre name. We get
# this from the 'genres' table, that has fields for genre_id and name. As we
# have genre_id from the previous JOIN, we can now add this additional JOIN. We
# also add the genre name to the select part (but renaming it to genre_name so
# we know what it is)
dbGetQuery(con, "
  SELECT t.track_id, t.title, tg.genre_id, g.name AS genre_name
  FROM tracks t
  INNER JOIN track_genres tg ON t.track_id = tg.track_id
  INNER JOIN genres g ON tg.genre_id = g.genre_id
  WHERE t.title = 'Bohemian Rhapsody'
")
# And although we use track_id and genre_id to connect the three tables (in the
# two INNER JOIN statements), we don't really need to get them in the output:
dbGetQuery(con, "
  SELECT t.title AS track_title, g.name AS genre_name
  FROM tracks t
  INNER JOIN track_genres tg ON t.track_id = tg.track_id
  INNER JOIN genres g ON tg.genre_id = g.genre_id
  WHERE t.title = 'Bohemian Rhapsody'
")

# Creating and understanding this SQL query IS tricky! It can take a while to
# understand how it works. but the most important is not to know the syntax itself,
# but actually how it works in principle.

# Who are the artists on a specific multi-artist track?
dbGetQuery(con, "
  SELECT t.title, ar.name AS artist
  FROM tracks t
  INNER JOIN track_artists ta ON t.track_id  = ta.track_id
  INNER JOIN artists ar       ON ta.artist_id = ar.artist_id
  WHERE t.title = 'Stand In Awe'
")
# 3 artists here!

# Now the big one: average audio features per genre, getting analytical
# This joins four tables and is the query we discussed in the lecture
dbGetQuery(con, "
  SELECT g.name                  AS genre,
         ROUND(AVG(t.energy), 3)       AS mean_energy,
         ROUND(AVG(t.danceability), 3) AS mean_dance,
         ROUND(AVG(t.valence), 3)      AS mean_valence,
         COUNT(t.track_id)             AS n_tracks
  FROM tracks t
  INNER JOIN track_genres tg ON t.track_id  = tg.track_id
  INNER JOIN genres g        ON tg.genre_id = g.genre_id
  GROUP BY g.name
  ORDER BY mean_energy DESC
  LIMIT 15
")


# CASE WHEN
# Nice way to convert and intervalize values
dbGetQuery(con, "
  SELECT title, energy,
         CASE
           WHEN energy > 0.7 THEN 'high'
           WHEN energy > 0.4 THEN 'medium'
           ELSE 'low'
         END AS energy_category
  FROM tracks
  LIMIT 15
")


# FROM SQL TO R

# Everything above just printed to the console.
# When you want to analyse the result, store it as a data frame:

genre_profiles <- dbGetQuery(con, "
  SELECT g.name                        AS genre,
         AVG(t.danceability)           AS danceability,
         AVG(t.energy)                 AS energy,
         AVG(t.valence)                AS valence,
         AVG(t.tempo)                  AS tempo,
         AVG(t.acousticness)           AS acousticness,
         COUNT(t.track_id)             AS n_tracks
  FROM tracks t
  INNER JOIN track_genres tg ON t.track_id  = tg.track_id
  INNER JOIN genres g        ON tg.genre_id = g.genre_id
  GROUP BY g.name
")

# Now this is a normal R data frame:
class(genre_profiles)
dim(genre_profiles)
head(genre_profiles)

# Quick plot — what does the energy distribution across genres look like?
library(ggplot2)
ggplot(genre_profiles, aes(x = reorder(genre, energy), y = energy)) +
  geom_col(fill = "steelblue") +
  coord_flip() +
  labs(title = "Mean energy by genre", x = NULL, y = "Mean energy")


# This data frame is exactly what we feed into PCA and clustering next week.
# Save it so you have it ready:
write.csv(genre_profiles, "data/genre_profiles.csv", row.names = FALSE)

# Always close the connection when done
dbDisconnect(con)