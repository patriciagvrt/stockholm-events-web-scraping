# MCA lab: sample of ESS individual-level responses

# load libraries
library(FactoMineR)
library(factoextra)

ess <- read_csv("data/ess10_lab.csv") |>
  mutate(across(where(is.character), as.factor))

# We remove the idno, overwriting the existing dataframe
ess <- ess |> select(-idno)

# Have a look at the data frame! Click 'ess' in the Global Environment in RStudio
# As you can see, these are not numbers, but instead categories

# Columns from 'trust_parliament' (col 3) to 'satis_government' (col 12) are MCA
# variables
# Supplementary (qualitative) variables:

# cntry (Countries): col 1
# BE BG CH CZ EE FI FR GB GR HR HU IE IS IT LT ME MK NL NO PT SI SK

# left_right: col 12
# left centre right

# gender: col 13
# female male

# age_group: col 14
# 18-29 30-44 45-59 60+

# education: col 15
# low medium high

# So, all other variables that are to be used in the MCA are factors, with several
# levels.
# HOWEVER - when loading this as a csv, R has no idea how to order "high", "low", "medium"!
# So it orders these alphabetically, in the order high, low, medium. WHICH IS INCORRECT!

# For instance, check the levels for this variable
levels(ess$trust_legal)
# [1] "high" "low" medium"
# This is NOT the order we want!

# Thus, when loading a csv with ordered factors/categories, we really need to fix this
# so that the orders are correct.

# In our case, we do like this:
# First, create an array with the names of all factor variables using the low,medium,high values:
trust_vars <- c("trust_parliament", "trust_legal", "trust_police",
  "trust_politicians", "trust_parties",
  "pro_immigration", "religiosity",
  "life_satisfaction", "satis_economy", "satis_government")

# Then we will recode these, making sure that the order is correct:
ess <- ess |>
  mutate(
    across(all_of(trust_vars), ~ factor(.x, levels = c("low","medium","high"), ordered = TRUE)),
    left_right = factor(left_right, levels = c("left","centre","right"), ordered = TRUE),
    gender     = factor(gender, levels = c("male","female")),
    age_group  = factor(age_group, levels = c("18-29","30-44","45-59","60+"), ordered = TRUE),
    education  = factor(education, levels = c("low","medium","high"), ordered = TRUE),
    cntry      = factor(cntry)
  )

# If you now inspect the ess dataframe in RStudio, you will see that the ordering of levels
# are correct

# You can also inspect this with levels():
levels(ess$trust_legal)
# Should give "low" "medium" "high", i.e. correct order
# Compare from above: now the order is correct!

# T H I S   A B O V E   I S   A   C O M M O N   B U G !!!
# #######################################################
# So, make sure your factor variables are ordered correctly!

# Now, when our data is ready, let's do multiple correspondence analysis on this data
mca_res <- MCA(ess,
  quali.sup = c(1, 12, 13, 14, 15),  # idno, cntry, left_right, gender, age, education
  graph    = FALSE)

# We can show a summary, which is a LOT of numbers
summary(mca_res)

# Visualization might be more intuitive
# 1. Variable categories only — the most interpretable starting point
fviz_mca_var(mca_res, repel = TRUE)
# Note that these are not just the variables themselves, but the variables AND
# their different values!

# 2. Individuals only — coloured by a supplementary variable age group
fviz_mca_ind(mca_res,
  geom.ind  = "point",
  col.ind   = ess$age_group,   # colour by age group
  palette   = "jco",
  alpha.ind = 0.4,
  addEllipses = TRUE,
  legend.title = "Age group")

# Change the col.ind, trying the other supplementary variables:
# cntry, left_right, gender, education
# You should then also change the legend.title of course

# Correlation between variables and dimensions (the squared plot)
fviz_mca_var(mca_res,
  choice = "mca.cor",
  repel  = TRUE)
# This shows which variables correlate together. As this is a squared plot,
# this will only be positive directions (1st quadrant)

# 4. Biplot — variable categories + individual points together
fviz_mca_biplot(mca_res,
  geom.ind = "point",
  alpha.ind = 0.2,
  repel    = TRUE)
# This gets pretty messy, but yeah, biplots work here as well
