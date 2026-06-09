# 

# Init libraries that we will be using
library(DBI)
library(RSQLite)

library(FactoMineR)
library(factoextra)
library(tidyverse)


# Query the valkalkylator database
con <- dbConnect(SQLite(),"data/valkalkylator.sqlite")

# Create sql query
sql_parties <- "
  SELECT
    p.abbreviation,
    p.full_name,
    pr.question_id,
    ROUND(pr.answer * 25.0 / 100.0, 2) AS answer
  FROM party_responses pr
  JOIN parties p ON p.party_id = pr.party_id
  ORDER BY p.abbreviation, pr.question_id
"

party_responses <- dbGetQuery(con, sql_parties) |>
  pivot_wider(names_from = question_id,
              names_prefix = "q",
              values_from = answer)

dbDisconnect(con)

party_responses <- party_responses |>
  column_to_rownames("abbreviation") |>
  select(-full_name)

# Option 1: Cluster in original variable space
party_scaled <- scale(party_responses)
dist_parties <- dist(party_scaled, method = "euclidean")
hc_parties <- hclust(dist_parties, method = "ward.D2")

# Only 9 parties, but try different values of k
fviz_dend(hc_parties, k = 2, cex = 0.8, rect = TRUE,
          main = "Swedish parties — Ward clustering")

# Option 2: Cluster in PCA space (HCPC)
pca_parties <- PCA(party_responses,
  scale.unit = FALSE,
  graph      = FALSE)

# Select number of clusters
hcpc_parties <- HCPC(pca_parties, nb.clust = 2, graph = FALSE)
fviz_cluster(hcpc_parties, repel = TRUE, labelsize = 14,
             main = "Parties in PCA space — HCPC clusters")
# Note: with 2 clusters: the conventional left-right blocks (but note how
# far away the right-wing party 'sd' is from 'c')

# And to get it as a formal list (for subsequent analysis)
hcpc_parties$data.clust |>
  rownames_to_column("party") |>
  select(party, clust) |>
  arrange(clust)
