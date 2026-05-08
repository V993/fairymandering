

library(sandwich) # 4 covariance ests
library(lmtest) # Is the model garbage Y/n?

# setwd(dirname(rstudioapi::getActiveDocumentContext()$path))
suppressPackageStartupMessages(library(zoo)) # Not sure what that's all about

covered <- c("AL","AZ","GA","LA","MS","SC","TX","VA")
partial <- c("CA","FL","NH","NY","NC")

# Load organized DiD dataset (with all states summary stats precomputed by ALARM, thanks ALARM)
df <- read.csv("data/datasets/dataset_DiD.csv")
df$decade <- as.character(df$decade)
df$post <- as.integer(df$decade == "2020")
df$treated <- as.integer(df$state %in% covered)

# It looks like removing the partially covered states from assessmet doesn't change much:
primary <- subset(df, !state %in% partial)
# primary <- na.omit(primary[, c("state","post","treated","egap_zscore")])

m1 <- lm(egap_zscore ~ post * treated, data = df)
coeftest(m1, vcov = vcovCL(m1, cluster = ~state))
summary(m1)

# Minority packing: max Black VAP z-score vs. neutral simulations
m2 <- lm(bvap_zscore ~ post * treated, data = df)
coeftest(m2, vcov = vcovCL(m2, cluster = ~state))
summary(m2)