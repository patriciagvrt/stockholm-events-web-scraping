# ============================================================
# Assignment 2 — Human Freedom Index
#
# Research question:
# What latent dimensions structure human freedom across countries,
# and do countries with similar freedom profiles cluster into
# recognizable geopolitical groupings?
#
# EDA methods: PCA + Clustering (HCPC)
# ============================================================


# ============================================================
# Packages
# ============================================================


install.packages(c("FactoMineR", "factoextra", "tidyverse"))
install.packages(c("tibble", "gridExtra", "grid", "gt"))

library(FactoMineR)   # PCA and HCPC
library(factoextra)   # PCA and cluster visualisations
library(tidyverse)    # data manipulation and plotting
library(tibble)
library(gridExtra)
library(grid)
library(ggplot2)
library(gt)
library(webshot2)
library(tibble)
library(dplyr)

# ============================================================
# Load and inspect the dataset
# ============================================================

hfi <- read.csv("hfi2008_2016.csv", stringsAsFactors = FALSE)

dim(hfi)        # 1458 rows and 123 columns
names(hfi)      # variable names
head(hfi, 3)    # first three rows


# ============================================================
# Filter the dataset to 2016
#
# The analysis focuses on 2016 because it is the most recent
# year in the dataset. This creates a cross-sectional dataset,
# where each row represents one country.
# ============================================================

hfi_2016 <- hfi %>%
  filter(year == 2016)

nrow(hfi_2016)  # 162 countries


# ============================================================
# Select variables for PCA
#
# I use domain-level summary variables instead of the full set
# of detailed indicators. This keeps the analysis easier to
# interpret and reduces problems with missing values.
#
# pf_ = personal freedom
# ef_ = economic freedom
# ============================================================

hfi_pca_data <- hfi_2016 %>%
  select(
    countries,
    region,
    
    # Personal freedom domains
    pf_rol,          # rule of law
    pf_ss,           # security and safety
    pf_movement,     # freedom of movement
    pf_religion,     # freedom of religion
    pf_expression,   # freedom of expression
    pf_identity,     # identity and relationships
    
    # Economic freedom domains
    ef_government,   # size of government
    ef_legal,        # legal system and property rights
    ef_money,        # sound money
    ef_trade,        # freedom to trade internationally
    ef_regulation    # regulation
  )


# ============================================================
# Clean the selected data
# ============================================================

hfi_clean <- hfi_pca_data %>%
  filter(complete.cases(.))

nrow(hfi_clean)  # 161 countries after removing missing values

country_names <- hfi_clean$countries
country_regions <- hfi_clean$region

hfi_num <- hfi_clean %>%
  select(-countries, -region)

rownames(hfi_num) <- country_names

dim(hfi_num)     # 161 countries and 11 variables
head(hfi_num)


# ============================================================
# Run PCA
#
# scale.unit = TRUE standardizes the variables.
# This is important because PCA is sensitive to variable scales.
#
# graph = FALSE prevents automatic graphs from being generated.
# ============================================================

pca_res <- PCA(
  hfi_num,
  scale.unit = TRUE,
  graph = FALSE
)

pca_res$eig       # eigenvalues and explained variance
summary(pca_res)  # PCA summary


# ============================================================
# Scree plot
#
# This plot shows how much variance is explained by each
# principal component.
# ============================================================

fviz_eig(
  pca_res,
  addlabels = TRUE,
  ncp = 10
) +
  ggtitle("Scree Plot — Human Freedom Index (2016)")

# PC1 and PC2 together explain around 64% of the total variance.


# ============================================================
# Variable factor map / Correlation circle
#
# This plot shows how the selected freedom variables relate to
# the first two PCA dimensions.
# ============================================================

fviz_pca_var(
  pca_res,
  col.var = "contrib",
  gradient.cols = c("grey70", "steelblue", "red"),
  repel = TRUE
) +
  ggtitle("Variable Factor Map — Personal vs Economic Freedom")

# Variables pointing in a similar direction tend to vary together
# across countries.


# ============================================================
# Contribution plots
#
# These plots show which variables contribute the most to PC1
# and PC2.
# ============================================================

fviz_contrib(
  pca_res,
  choice = "var",
  axes = 1,
  top = 11
) +
  ggtitle("Contributions to PC1")

# PC1 shows the variables that explain the main difference
# between countries.


fviz_contrib(
  pca_res,
  choice = "var",
  axes = 2,
  top = 11
) +
  ggtitle("Contributions to PC2")

# PC2 shows the variables that explain the second main difference
# between countries.


# ============================================================
# Country map / Individuals factor map
#
# This plot shows where each country is located in the PCA space.
# Countries close to each other have similar freedom profiles.
# ============================================================

fviz_pca_ind(
  pca_res,
  label = "all",
  repel = TRUE,
  col.ind = "cos2",
  gradient.cols = c("grey70", "steelblue", "red")
) +
  ggtitle("Countries in PCA Space (2016)")

# This map helps identify countries with similar or distinct
# freedom profiles.


# ============================================================
# PCA map colored by region
#
# This plot shows whether countries from the same geographical
# region appear close to each other in the PCA space.
#
# Region is used only for interpretation. It was not used as an
# active variable in the PCA.
# ============================================================

region_factor <- as.factor(country_regions)

fviz_pca_ind(
  pca_res,
  label = "none",
  habillage = region_factor
) +
  ggtitle("Countries by Region in PCA Space")

# This plot helps identify possible geographical or geopolitical
# patterns in countries' freedom profiles.


# ============================================================
# PCA biplot
#
# This plot shows countries and variables in the same PCA space.
# Countries located in the direction of a variable tend to have
# higher values for that variable.
# ============================================================

fviz_pca_biplot(
  pca_res,
  label = "var",
  col.ind = "steelblue",
  col.var = "red",
  repel = TRUE
) +
  ggtitle("PCA Biplot — Human Freedom Index")


# ============================================================
# Loadings
#
# Loadings show how strongly each variable is associated with
# each PCA dimension.
# ============================================================

loadings <- as.data.frame(pca_res$var$coord)

print(round(loadings, 3))

loadings$freedom_type <- ifelse(
  grepl("^pf_", rownames(loadings)),
  "Personal Freedom",
  "Economic Freedom"
)

print(loadings[, c("Dim.1", "Dim.2", "freedom_type")])

# Variables with higher loadings are more useful for interpreting
# what each PCA dimension represents.







# ============================================================
# Clustering with HCPC
#
# HCPC groups countries based on their position in the PCA space.
# Countries in the same cluster have similar freedom profiles.
# ============================================================

set.seed(123)

hcpc_res <- HCPC(
  pca_res,
  nb.clust = -1,
  graph = FALSE
)


# ============================================================
# Cluster plot
#
# This plot shows the country clusters in the PCA space.
# ============================================================

fviz_cluster(
  hcpc_res,
  repel = TRUE,
  show.clust.cent = TRUE
) +
  ggtitle("Country Clusters — Human Freedom Index")
fviz_cluster(
  hcpc_res,
  geom = "point",
  show.clust.cent = TRUE
) +
  ggtitle("Country Clusters — Human Freedom Index")

# ============================================================
# Summary table for the report using gt
#
# This table summarizes the main interpretation of each cluster.
# It is saved as a PNG file to include in the report.
# ============================================================

cluster_summary_table <- tibble(
  Cluster = c(1, 2, 3, 4),
  N = c(25, 32, 60, 44),
  `Freedom profile` = c(
    "Lowest freedom profile: weak rule of law, movement, identity, legal system, and trade freedom.",
    "Intermediate profile: stronger economic indicators, but weaker personal and civil freedoms.",
    "Mixed profile: stronger movement, religion, expression, and identity, but weaker legal institutions.",
    "Highest freedom profile: strong scores across most personal and economic freedom domains."
  ),
  `Main regional pattern` = c(
    "Sub-Saharan Africa; Middle East & North Africa; South Asia.",
    "Middle East & North Africa; South Asia; Caucasus & Central Asia.",
    "Latin America & Caribbean; Sub-Saharan Africa; Eastern Europe.",
    "Western Europe; Eastern Europe; East Asia; North America; Oceania."
  ),
  `Example countries` = c(
    "Syria, Iran, Iraq, Venezuela, Zimbabwe.",
    "China, Russia, Qatar, Saudi Arabia, UAE.",
    "Brazil, Mexico, South Africa, Argentina, Ukraine.",
    "Sweden, Norway, Canada, Japan, New Zealand."
  )
)

cluster_table_gt <- cluster_summary_table %>%
  gt::gt() %>%
  gt::tab_header(
    title = gt::md("**Table 1. Summary of country clusters based on HCPC**")
  ) %>%
  gt::cols_label(
    Cluster = "Cluster",
    N = "N",
    `Freedom profile` = "Freedom profile",
    `Main regional pattern` = "Main regional pattern",
    `Example countries` = "Example countries"
  ) %>%
  gt::cols_width(
    Cluster ~ gt::px(70),
    N ~ gt::px(60),
    `Freedom profile` ~ gt::px(340),
    `Main regional pattern` ~ gt::px(330),
    `Example countries` ~ gt::px(300)
  ) %>%
  gt::tab_options(
    table.width = gt::px(1150),
    table.font.size = gt::px(13),
    data_row.padding = gt::px(12),
    column_labels.font.weight = "bold",
    column_labels.background.color = "grey85",
    heading.title.font.size = gt::px(18),
    heading.align = "left"
  )

# Show table in RStudio Viewer
cluster_table_gt


# ============================================================
# Save gt table


gt::gtsave(
  data = cluster_table_gt,
  filename = "cluster_summary_table_HCPC.png",
  expand = 10,
  vwidth = 1300,
  vheight = 750
)









# ============================================================
# Cluster membership
#
# This table shows which countries belong to each cluster.
# Region is added only to help interpret possible geopolitical
# patterns.
# ============================================================

cluster_data <- hcpc_res$data.clust %>%
  rownames_to_column("country") %>%
  left_join(
    hfi_clean %>% select(countries, region),
    by = c("country" = "countries")
  ) %>%
  select(country, region, clust) %>%
  arrange(clust)

print(cluster_data)


# ============================================================
# Number of countries per cluster
# ============================================================

cluster_count <- cluster_data %>%
  count(clust)

print(cluster_count)


# ============================================================
# Cluster profiles
#
# This table shows the average score of each selected freedom
# variable by cluster. It helps describe what each cluster means.
# ============================================================

cluster_means <- hfi_clean %>%
  mutate(clust = hcpc_res$data.clust$clust) %>%
  group_by(clust) %>%
  summarise(
    across(
      where(is.numeric),
      ~ round(mean(.x, na.rm = TRUE), 2)
    )
  )

print(cluster_means)


# ============================================================
# Regional distribution by cluster
#
# This table shows whether clusters are related to geographical
# or geopolitical regions.
# ============================================================

cluster_region_distribution <- cluster_data %>%
  count(clust, region) %>%
  group_by(clust) %>%
  mutate(percent = round(100 * n / sum(n), 1)) %>%
  arrange(clust, desc(n))

print(cluster_region_distribution, n = 50)





















# ============================================================
# Save selected graphs
#
# Purpose:
# Saving figures makes it easier to include them in the final paper.
# ============================================================

p_var <- fviz_pca_var(
  pca_res,
  col.var = "contrib",
  gradient.cols = c("grey70", "steelblue", "red"),
  repel = TRUE
) +
  ggtitle("Variable Factor Map — Personal vs Economic Freedom")

ggsave(
  filename = "variable_factor_map.png",
  plot = p_var,
  width = 8,
  height = 6,
  dpi = 300
)

p_cluster <- fviz_cluster(
  hcpc_res,
  repel = TRUE,
  show.clust.cent = TRUE
) +
  ggtitle("Country Clusters — Human Freedom Index")

ggsave(
  filename = "country_clusters.png",
  plot = p_cluster,
  width = 8,
  height = 6,
  dpi = 300
)









