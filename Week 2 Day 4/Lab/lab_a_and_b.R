# Lab parts A and B

# Init libraries that we will be using
library(DBI)
library(RSQLite)

library(FactoMineR)
library(factoextra)
library(tidyverse)

# Obtain data
con <- dbConnect(SQLite(),"data/music.sqlite")
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
dbDisconnect(con)

# Shared preparation
genre_mat <- genre_profiles |> column_to_rownames("genre")
genre_scaled <- scale(genre_mat)
dist_mat <- dist(genre_scaled, method = "euclidean")

# PART A: Hierarchical
hc <- hclust(dist_mat, method="ward.D2")
fviz_dend(hc, k = 6, cex=0.5, rect=TRUE)
clusters_hc <- cutree(hc, k = 6)
split(names(clusters_hc), clusters_hc)

# PART B: k-means
fviz_nbclust(genre_scaled, kmeans,method="silhouette")
set.seed(6031769)
km <- kmeans(genre_scaled, centers = 6, nstart = 25)

# PART B: PAM
pam_fit <- pam(genre_scaled, k = 6)
pam_fit$medoids
fviz_silhouette(pam_fit)

# Get pca results:
pca_res <- PCA(
  genre_profiles,
  scale.unit = TRUE,
  quali.sup = 1,
  graph = FALSE
)

# PART B: Overlay on PCA
fviz_pca_ind(pca_res,
  col.ind = factor(km$cluster),
  palette="Set1",
  addEllipses = TRUE,
  label="all",
  repel=TRUE,
  legent.title="k-means cluster"
)

