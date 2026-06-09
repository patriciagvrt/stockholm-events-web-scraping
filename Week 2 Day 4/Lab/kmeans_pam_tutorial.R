# DAY 3 - Clustering example
# Code for replicating k-means and PAM clustering shown in lecture

# First, install the necessary packages for PCA/factor analysis
# install.packages(c("FactoMineR","factoextra","tidyverse"))

# Init libraries that we will be using
library(DBI)
library(RSQLite)

library(cluster)
library(factoextra)
library(dendextend)


# First, we need to obtain the csv data that we will work with. We create a connection
# to our database...
con <- dbConnect(SQLite(),"data/music.sqlite")

# ...and use a suitable SELECT statement to get the data frame:
genre_profiles <- dbGetQuery(con, "
  SELECT g.name AS genre,
         AVG(t.danceability) AS danceability, AVG(t.energy)    AS energy,
         AVG(t.loudness)     AS loudness,     AVG(t.speechiness) AS speechiness,
         AVG(t.acousticness) AS acousticness, AVG(t.instrumentalness) AS instrumentalness,
         AVG(t.liveness)     AS liveness,     AVG(t.valence)   AS valence,
         AVG(t.tempo)        AS tempo
  FROM tracks t
  JOIN track_genres tg ON t.track_id = tg.track_id
  JOIN genres g        ON tg.genre_id = g.genre_id
  GROUP BY g.name")

# Once we have this data from the database, we can now close the connection to the database:
dbDisconnect(con)

# Turn column 'genre' into rownames (and store in new data frame)
genre_profiles2 <- genre_profiles |> column_to_rownames("genre")

# Scale the data (like PCA:s internal scale function, but here as a separate function)
genre_scaled <- scale(genre_profiles2)
# This is then no longer a data frame, but a matrix (you can inspect it)

# 1. k-means
# k-means is random so it will use random numbers. For replicability, we can set
# the random seed before: then all random numbers we pull will be the same sequence
set.seed(6031769)

km <- kmeans(
  genre_scaled,
  centers = 6,        # nbr of clusters
  nstart = 25         # Do several restarts: it will keep the best result
)

# Inspect the cluster membership
split(names(km$cluster), km$cluster)

# Visualize:
fviz_cluster(km, data = genre_scaled,
             geom = "text", repel = TRUE,
             main = "k-means clusters — Spotify genres")
# note that 'comedy' is probably its own cluster!


# What is a suitable number of clusters?

# Step 1: elbow plot across a range of k
fviz_nbclust(genre_scaled, kmeans, method = "wss", k.max = 15)

# Step 2: silhouette plot across a range of k  
fviz_nbclust(genre_scaled, kmeans, method = "silhouette", k.max = 15)
# In this case, not that informative (almost always 2 as the optimal, which is
# typically too few)

# Step 3: run k-means with your chosen k
set.seed(6031769)
km <- kmeans(genre_scaled, centers = 6, nstart = 25)

# Step 4: check the silhouette for that specific result
sil <- silhouette(km$cluster, dist(genre_scaled))
summary(sil)$avg.width   # single number: average silhouette
fviz_silhouette(sil)      # full plot: spot any misclassified observations
# Some in 3 and 5


# PAM
# Do a partition around medoids clustering, choosing 6 clusters:
pam_fit <- pam(genre_scaled,
  k    = 6,
  diss = FALSE
)
# diss = FALSE means that the input we provided is data, not a distance matrix

# Which genre is the most representative of each cluster?
pam_fit$medoids

# And you can also check exactly which genres are in which cluster:
split(names(pam_fit$clustering), pam_fit$clustering)

# Visualize the clusters
fviz_cluster(pam_fit, data = genre_scaled,
             geom = "text", repel = TRUE,
             main = "PAM clusters — Spotify genres")


# Do a silhouette plot to check any misfitted ones
fviz_silhouette(pam_fit)


# NOTE: clusters are nominal - there is no order to them. So when comparing the
# clusters obtained from k-means with those from PAM, the ordering is most likely

# Exercise:
# Save the cluster visualizations from k-means and PAM for k=6 (or any other k)
# and compare! Which one looks more properly clustered?