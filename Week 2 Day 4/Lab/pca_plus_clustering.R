# Combining PCA and clustering
# PCA: provides the map (where observations sit in 2D)
# Clustering: gives you the color (which group each belongs to)
# Together: more interpretable

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

# Move 'genre' to row names
genre_profiles <- genre_profiles |> column_to_rownames("genre")

# Get pca results:
pca_res <- PCA(
  genre_profiles,
  scale.unit = TRUE,
  graph = FALSE
)

# Now, prepare hierarchical clustering
genre_scaled <- scale(genre_profiles)

# Calc dist (euclidean)
dist_mat <- dist(genre_scaled, method="euclidean")

# Do hierarchical clustering on this
hc <- hclust(dist_mat, method="ward.D2")


# Combine scores with clusters (split at 6)
scores <- as.data.frame(pca_res$ind$coord) |>
  rownames_to_column("genre") |>
  mutate(cluster = factor(cutree(hc, k = 6)[genre]))
# Can also be done with the clusters obtained from kmeans and pam:
# or:  mutate(cluster = factor(km$cluster[genre]))
# or:  mutate(cluster = factor(pam_fit$clustering[genre]))

# Have a look at the 'scores' dataframe! Contains PC coordinates AND cluster membership!

# Plot: PCA axes, observations coloured by cluster
ggplot(scores, aes(x = Dim.1, y = Dim.2, colour = cluster, label = genre)) +
  geom_point(size = 2.5) +
  geom_text(size = 4, hjust = -0.1, vjust = 0.5, check_overlap = TRUE) +
  scale_colour_brewer(palette = "Set1") +
  labs(title = "Spotify genres — PCA space with cluster membership",
       x = "PC1 ([Suitable name])",
       y = "PC2 ([Suitable name])") +
  theme_minimal()

# Or use fviz directly with pre-computed clusters
fviz_pca_ind(pca_res,
             col.ind   = factor(cutree(hc, k = 6)),
             palette   = "Set1",
             addEllipses = TRUE,
             label     = "all",
             repel     = TRUE,
             legend.title = "Cluster")
