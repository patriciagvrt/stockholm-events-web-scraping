# DAY 3 - PCA analysis
# Code for replicating PCA analyses shown in the lectures

# First, install the necessary packages for PCA/factor analysis
# install.packages(c("FactoMineR","factoextra","tidyverse"))

# Init libraries that we will be using
library(DBI)
library(RSQLite)

library(FactoMineR)
library(factoextra)
library(tidyverse)

# We want to explore the various genres and their various average properties in tracks

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

# You should now have the genre_profiles in your Global environment. Feel free to
# click and explore: making sure that the data is there. And to check what the
# variables in this data frame are called
# Specifically: note that the first column contains the names of the genres,
# and this is not something we want to use as input for the PCA

# We want to use these genre names as row names, so we need to set that first in the data frame
genre_profiles <- genre_profiles |> column_to_rownames("genre")

# If you now click and explore this data frame, you will see that the column 'genre' is now
# gone and its content is instead used as row names

# Then, let's do a PCA analysis of this data
# All the 9 columns in the data frame are variables, so we don't have to specify
# a quali.sup column
pca_res <- PCA(
  genre_profiles,
  scale.unit = TRUE,
  graph = FALSE
)
# A few comments on the above
# scale.unit = TRUE : this means that the answers for each variable are normalized
# so that the mean value for each variable is zero (0) and the variance of each
# variable is 1. This is to guarantee that each variable has the same "importance"
# irrespective of the value span of variables.
# graph = FALSE : when set to TRUE, this will result in a simple variable
# factor map. We will use the more advanced ways to plot this later on, so we
# can set this to FALSE here.


# Finally, inspect the results
summary(pca_res)

# The above displays a lot of info here!
# Check the first Eigenvalues section
# The first 2 dimensions capture 61% of variance, adding the 3rd capptures 78%
# quite good.

# Scree plot — variance explained per component
fviz_eig(pca_res, addlabels = TRUE, ncp = 9)

# Variable factor map (correlation circle)
fviz_pca_var(
  pca_res,
  col.var = "contrib",
  gradient.cols = c("grey70", "steelblue", "red"),
  repel = TRUE,
  arrowsize=1
)+
  theme(
    axis.line = element_line(linewidth=0.8)
  )

# Individual factor map (genre points, labelled)
# Make sure to Zoom this display in RStudio - it is a bit messy!
fviz_pca_ind(pca_res,
  label = "all",
  repel = TRUE
)

# Contribution plot: which variables drive PC1?
fviz_contrib(pca_res, choice = "var", axes = 1)

# Contribution plot: which variables drive PC2?
fviz_contrib(pca_res, choice = "var", axes = 2)

# Biplot — observations and variables together
fviz_pca_biplot(pca_res,
  label    = "all", # Can also set to "var" to only view the variables
  col.ind  = "steelblue",
  col.var  = "red",
  repel    = TRUE
)


# FactoMineR has a dedicated function that clusters directly in PCA space
# It runs hierarchical clustering on the PC scores and then
# consolidates with k-means — the best of both approaches
# Here, first create the cluster object
hcpc_res <- HCPC(pca_res,
  nb.clust = -1,   # -1 = choose automatically from dendrogram
  graph    = FALSE
)

# Then visualize:
# Plot: individuals coloured by cluster
# Use 'labelsize' argument if too cluttered
fviz_cluster(hcpc_res,
  repel       = TRUE,
  show.clust.cent = TRUE,
  main = "Genres — clusters in PCA space"
)

# Which genres are in each cluster?
hcpc_res$data.clust |>
  rownames_to_column("genre") |>
  select(genre, clust) |>
  arrange(clust)
# note there are actually 4 clusters!
# Genre 'comedy' is very high up on the 2nd dimension
# Very opposite of black metal
