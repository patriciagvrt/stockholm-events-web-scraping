# Lab Gower and clustering

# First, init the libraries we need:

library(tidyverse)
library(cluster)
library(factoextra)
library(FactoMineR)

# Data preparation! Same as we did for MCA!

# We load the raw data into a data frame
ess <- read_csv("data/ess10_lab.csv")

# If you check it out now, the 'values' are basically just text strings
# so we need to get them into 'factors' instead, ordered as they should be

# Here are our 'trust variables':
trust_vars <- c("trust_parliament", "trust_legal", "trust_police",
  "trust_politicians", "trust_parties",
  "pro_immigration", "religiosity",
  "life_satisfaction", "satis_economy", "satis_government")

# We recode these trust variables and the other ones into factor variables with
# correct levels - and we also remove the idno that we won't need, as well as
# dropping any NA answers
ess <- ess |>
  mutate(
    across(all_of(trust_vars),
           ~ factor(.x, levels = c("low", "medium", "high"), ordered = TRUE)),
    left_right = factor(left_right, levels = c("left", "centre", "right"),
                        ordered = TRUE),
    gender    = factor(gender,    levels = c("male", "female")),
    age_group = factor(age_group, levels = c("18-29", "30-44", "45-59", "60+"),
                       ordered = TRUE),
    education = factor(education, levels = c("low", "medium", "high"),
                       ordered = TRUE),
    cntry     = factor(cntry)
  ) |>
  filter(!is.na(education)) |>
  select(-idno) |> drop_na()

# If you now expand the 'ess' in the Global variables in RStudio (the blue arrow icon)
# you will see that all variables are R 'factor' variables, ordered as they should

# That should be 2175 observations!

# Gower distances
# ===============

# In MCA, we used demographic variables as supplementary. Here we instead include them
# as active variables: distances will thus reflect similarities of these as well
# This is of course the cool thing with Gower: it allows for most variable data types

# As 'ess' looks like now, with all these factors (ordered, nominal), we can use
# it straight off

# Compute gower distances
gower_dist <- daisy(ess, metric = "gower")

# Let's inspect the upper left corner of this matrix (as it is a 2175x2175 matrix)
as.matrix(gower_dist)[1:5, 1:5] |> round(3)

# So cool: we have distances, based on a combination of all these variables

# CHOOSE k
# ========

# Given these Gower-determined distances, we can then do a silhouette plot for
# various values of k (i.e. number of clusters). The code below does this for
# k=1..8. As this is a bit random, we use set.seed() to make sure the random
# numbers are identical (for comparing between us)
set.seed(6031769)

# Instead of doing this with 2175 rows, we just use a sample with 500, so we
# create a smaller version
sil_sample <- ess |> slice_sample(n = 500)
gower_sample <- daisy(sil_sample, metric = "gower")

library(cluster)

# Compute silhouette width for k = 2 to 8 on the sample
sil_widths <- map_dbl(2:8, function(k) {
  pam_k <- pam(gower_sample, k = k, diss = TRUE)
  mean(silhouette(pam_k)[, "sil_width"])
})

# Plot
tibble(k = 2:8, silhouette = sil_widths) |>
  ggplot(aes(x = k, y = silhouette)) +
  geom_line(colour = "steelblue", linewidth = 1.2) +
  geom_point(colour = "steelblue", size = 3) +
  geom_point(data = ~ filter(.x, silhouette == max(silhouette)),
             colour = "red", size = 4) +
  scale_x_continuous(breaks = 2:8) +
  labs(title = "Silhouette width by k — Gower + PAM",
       x = "Number of clusters k",
       y = "Average silhouette width") +
  theme_minimal()

# Looks like k=3 is a suitable one, but k=6 seems like a definite elbow

# Run PAM on full dataset
# Note: diss = TRUE because we pass in a distance matrix (not raw data)

set.seed(6031769)
pam_ess <- pam(gower_dist,
  k    = 6,     # We try with 6 (but maybe also try with 3)
  diss = TRUE)

# Inspect the medoid respondents
# The medoid is the actual most-central respondent in each cluster
# So an actual observation representing the cluster
ess[pam_ess$id.med, ] |> print(width = Inf)

# And explore the sizes of each cluster:
table(cluster = pam_ess$clustering)

# Plot the silhouette for the selected k
fviz_silhouette(silhouette(pam_ess)) +
  labs(title = "Silhouette plot — PAM k=6, Gower distance")

# So some of these clusters are problematic - also issues with k=3

# Add the cluster data to the original data and profile each cluster
ess_clustered <- ess |>
  mutate(cluster = factor(pam_ess$clustering))

# If you now check this new 'ess_clustered' dataframe, you will see that it has
# 16 variables! The new one represents the cluster id (1-6), a new variable
# that you can use and say things about

# For instance, you can now use it to get summary statistics about each cluster
# Such as proportion of parliament trust level per cluster:
ess_clustered |>
  group_by(cluster, trust_parliament) |>
  summarise(n = n(), .groups = "drop") |>
  group_by(cluster) |>
  mutate(pct = round(100 * n / sum(n), 1)) |>
  select(-n) |>
  pivot_wider(names_from   = trust_parliament,
    values_from  = pct,
    names_prefix = "trust_parl_",
    values_fill  = 0)          # replace NA with 0

# You can also explore all these trust variables in one table:
# Full profile: mean/modal response per cluster for all active variables
ess_clustered |>
  group_by(cluster) |>
  summarise(
    n = n(),
    across(all_of(trust_vars),
           ~ names(sort(table(.x), decreasing = TRUE))[1],  # modal category
           .names = "{.col}_mode"),
    top_country = names(sort(table(cntry), decreasing = TRUE))[1]
  )
# As such, you see that cluster 1 contains countries characterized by high trust
# across sections, cluster 6 has low trust, and others are in-between


# COMBINING MCA AND GOWER RESULTS
# ===============================

# Just as we can combine PCA and clustering, we can equally combine MCA and
# clustering! Let us re-run the MCA on the same subset (or at least those
# that didn't drop due to drop_na)

mca_res <- MCA(ess,
  quali.sup = c(1, 12, 13, 14, 15),  # idno, cntry, left_right, gender, age, education
  graph    = FALSE)

# Where do the Gower clusters sit in the MCA space?
# Let's extract individual MCA scores
mca_scores <- as.data.frame(mca_res$ind$coord) |>
  rename(mca_dim1 = `Dim 1`, mca_dim2 = `Dim 2`) |>
  mutate(row = row_number())

# Combine with Gower clusters
comparison <- ess_clustered |>
  mutate(row = row_number()) |>
  left_join(mca_scores, by = "row")

# Check comparison: the left_join is like SQL LEFT JOIN: supplementing
# with the data from mca_scores so they appear as new columns

# Visualise MCA individual map by Gower cluster (each cluster colored differently)
ggplot(comparison, aes(x = mca_dim1, y = mca_dim2, colour = cluster)) +
  geom_point(alpha = 0.3, size = 1.2) +
  stat_ellipse(linewidth = 1.0) +
  scale_colour_brewer(palette = "Set1") +
  labs(title  = "MCA individual map — coloured by Gower cluster",
       x      = "MCA Dim1",
       y      = "MCA Dim2",
       colour = "Gower cluster") +
  theme_minimal()

# Country distribution across Gower clusters
# This creates a column bar chart where you can see how cluster members are spread
# across countries (same colors as above)
comparison |>
  count(cluster, cntry) |>
  group_by(cntry) |>
  mutate(pct = round(100 * n / sum(n), 1)) |>
  filter(n > 5) |>
  ggplot(aes(x = cntry, y = pct, fill = cluster)) +
  geom_col() +
  coord_flip() +
  scale_fill_brewer(palette = "Set1") +
  labs(title = "Gower cluster distribution by country",
       x = NULL, y = "% of respondents", fill = "Cluster") +
  theme_minimal()

# So given this data, You could state that Iceland (IS) seems to contain the 
# fewest type 6 individuals, whereas North Macedonia (MK) has the most type 6
# individuals!
# Switzerland (CH) has a very large share (>50%) of type 1 individuals, i.e. those
# representing high trust across many institutions