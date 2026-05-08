

library(sandwich) # 4 covariance ests
library(lmtest) # Is the model garbage Y/n?

suppressPackageStartupMessages(library(zoo)) # Not sure what that's all about

covered <- c("AL","AZ","GA","LA","MS","SC","TX","VA")
partial <- c("CA","FL","NH","NY","NC")

# Load organized DiD dataset (with all states summary stats precomputed by ALARM)
df <- read.csv("data/datasets/dataset_DiD.csv")
df$decade <- as.character(df$decade)
df$post <- as.integer(df$decade == "2020")
df$treated <- as.integer(df$state %in% covered)

# It looks like removing the partially covered states from assessmet doesn't change much:
# primary <- subset(df, !state %in% partial)

# Stack egap and bvap z-scores into long format with a 'racial' indicator
# racial = 1 for the bvap (racial-packing) outcome, 0 for the egap (partisan) outcome
egap_long  <- data.frame(state = df$state, post = df$post,
                         treated = df$treated, racial = 0L,
                         y = df$egap_zscore)
bvap_long  <- data.frame(state = df$state, post = df$post,
                         treated = df$treated, racial = 1L,
                         y = df$bvap_zscore)
long <- rbind(egap_long, bvap_long)

# Triple-difference: does Shelby hit racial packing differently from partisan packing in covered states? The post:treated:racial coefficient is the answer.
m3 <- lm(y ~ post * treated * racial, data = long)
# coeftest(m3, vcov = vcovCL(m3, cluster = ~state))
summary(m3)
