# DAY 3 - Clustering example
# Code for replicating Hierarchical Clustering example shown in the lectures

# First, install the necessary packages for PCA/factor analysis
# install.packages(c("FactoMineR","factoextra","tidyverse"))

# Init libraries that we will be using
library(DBI)
library(RSQLite)

library(cluster)
library(factoextra)
library(dendextend)

# Now we also need a library for plotting dendrograms

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

# 2. Compute distance matrix
dist_mat <- dist(genre_scaled, method="euclidean")
# This creates a matrix that is filled in its lower triangle. If you inspect it on
# the console, it will look quite empty, but all values are there (below the diagonal)
# note that the distance from A to B is the same as distance from B to A, i.e.
# dist(A,B) = dist(B,A)
# So all values in the top-right triangle of the matrix are the same as those in the
# bottom-left triangle

# These distances thus capture how far apart the genres are, if the 9 properties
# of the genres are points in 9-dimensional space and you calculate the distance
# (pythagoras) between these points

# 3. Time to do the hierarchical clustering of these points. We use the 'ward.D2'
# method:
hc <- hclust(dist_mat, method="ward.D2")

# The resulting object (hc here) is a 'hclust' object:
class(hc)
# This contains details about the dendrogram, clusters etc

# 4.Given the hclust object you got, you can now create the dendrogram
plot(hc, cex = 0.75, main ="Genre dendrogram (ward.D2 linkages)")

# You might have to adjust the 'cex' value (font size) to see the different
# branches!

# You can add rectangles around the chosen number of clusters
rect.hclust(
  hc,
  k=6
)

# 5. You can create even nicer dendrograms using fviz_dend() - here as a phylogenic tree
# and coloring branches by 6 clusters
fviz_dend(hc,
          k          = 6,          # colour by 6 clusters
          cex        = 0.75,
          type ="phylogenic",
          repel = TRUE,
          main       = "Genres — hierarchical clustering (Ward)"
)
# Though there might be a bug if you draw the more traditional types

# 6. Cut to the selected number of clusters: k
k <- 6
clusters_hc <- cutree(hc, k=k)

# You can then check which genres are in which clusters:
split(names(clusters_hc), clusters_hc)

# What would you call each cluster?

# FINALLY:

# 7. Add cluster membership back to the original data frame:
# Here it might be good to call this column not just 'cluster' but also
# indicate the size of the cluster (=6). But you should also keep track of the
# specific distance metric (euclidean) and clustering method (ward.D2) that was
# used to generate this:
genre_profiles <- genre_profiles |>
  mutate(cluster_6 = factor(clusters_hc[genre]))

# And voila - now you suddenly have a new categorical (nominal) variable 'cluster'
# for each entry, indicating which of the 6 groups of genres you are chosen


# EXERCISES

# In the exercise above, there were a couple of decisions being made for you

# - distance (euclidean): distances between genres in the 9-dimensional space
#   was determined based on standard Pythagoran euclidean distances
# - Linkage type (ward.D2): at each agglomerative step, clusters were merged
#   based on the ward.D2.
# - k = 6: based on the dendrogram, the decision was made to partition this into
#   6 clusters.

# Try with different choices!

# DISTANCES:
# dist(): also try method="manhattan". Or try 'correlation distances':
# dist_corr <- as.dist(1 - cor(t(genre_scaled)))

# CLUSTERING METHODS:
# hclust(..., method="ward.D2") - also try these methods:
# complete, average, mcquitty, centroid

# NUMBER OF CLUSTERS (k):
# When drawing boxes in the dendrogram and cutting it after, we chose 6 clusters
# above. But try a bit more (8-10) as well as less (3-5).