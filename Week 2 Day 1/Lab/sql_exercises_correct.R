# EXERCISES: Correct answers

# 1. How many artists are in the database?
dbGetQuery(con, "
  SELECT COUNT(*) AS n_artists
  FROM artists
")
# 29,858


# 2. Artists whose name contains 'band'
dbGetQuery(con, "
  SELECT name
  FROM artists
  WHERE name LIKE '%band%'
  ORDER BY name
")
# 119 artists in total - note that it also contains 'Bandits'!


# 3. Five longest tracks
dbGetQuery(con, "
  SELECT title, duration_ms,
         ROUND(duration_ms / 60000.0, 2) AS duration_minutes
  FROM tracks
  ORDER BY duration_ms DESC
  LIMIT 5
")


# 4. How many tracks are marked as explicit?
dbGetQuery(con, "
  SELECT explicit,
         COUNT(*) AS n_tracks
  FROM tracks
  GROUP BY explicit
")
# 0 is not explicit, 1 is explicit. Could also use CASE WHEN to convert this variable
# to a string text:
dbGetQuery(con, "
  SELECT explicit,
         COUNT(*) AS n_tracks,
         CASE
          WHEN explicit = 0 THEN 'not explicit'
          WHEN explicit = 1 THEN 'explicit'
         END AS explicit_text
  FROM tracks
  GROUP BY explicit
")


# 5. Album with the most tracks
dbGetQuery(con, "
  SELECT al.title   AS album,
         COUNT(*)   AS n_tracks
  FROM tracks t
  JOIN albums al ON t.album_id = al.album_id
  GROUP BY al.album_id
  ORDER BY n_tracks DESC
  LIMIT 5
")
# Note: GROUP BY 'al.album_id' instead of 'al.title'
# because two different albums can share the same title
# (e.g. two artists both have a self-titled album called "Greatest Hits")
# When grouping by album_id, that is quite okay


# 6. Average danceability — explicit vs non-explicit
dbGetQuery(con, "
  SELECT explicit,
         ROUND(AVG(danceability), 3) AS mean_danceability,
         ROUND(AVG(energy), 3)       AS mean_energy,
         COUNT(*)                    AS n_tracks
  FROM tracks
  GROUP BY explicit
")
# Could also do the CASE WHEN construct


# 7. Five genres with highest average valence
dbGetQuery(con, "
  SELECT g.name              AS genre,
         ROUND(AVG(t.valence), 3) AS mean_valence,
         COUNT(t.track_id)   AS n_tracks
  FROM tracks t
  JOIN track_genres tg ON t.track_id  = tg.track_id
  JOIN genres g        ON tg.genre_id = g.genre_id
  GROUP BY g.name
  ORDER BY mean_valence DESC
  LIMIT 5
")
# likely soca, dancehall, children's music, latin genres at the top
# valence = musical positivity (Spotify's term)


# 8. All tracks by The Beatles, sorted by decreasing popularity
dbGetQuery(con, "
  SELECT t.title, t.popularity
  FROM tracks t
  JOIN track_artists ta ON t.track_id  = ta.track_id
  JOIN artists ar       ON ta.artist_id = ar.artist_id
  WHERE ar.name = 'The Beatles'
  ORDER BY t.popularity DESC
")

# For just the count:
dbGetQuery(con, "
  SELECT COUNT(*) AS n_tracks
  FROM tracks t
  JOIN track_artists ta ON t.track_id  = ta.track_id
  JOIN artists ar       ON ta.artist_id = ar.artist_id
  WHERE ar.name = 'The Beatles'
")


# 9. Artists appearing in the most genres
dbGetQuery(con, "
  SELECT ar.name,
         COUNT(*) AS n_genres
  FROM artist_genres ag
  JOIN artists ar ON ag.artist_id = ar.artist_id
  GROUP BY ag.artist_id, ar.name
  ORDER BY n_genres DESC
  LIMIT 10
")
# note: artist genres were derived from track_artists joined with track_genres

