
library(sandwich) # 4 covariance ests
library(lmtest)   # Is the model garbage Y/n?

# setwd(dirname(rstudioapi::getActiveDocumentContext()$path))
suppressPackageStartupMessages(library(zoo))

covered <- c("AL","AZ","GA","LA","MS","SC","TX","VA")
partial <- c("CA","FL","NH","NY","NC")

# District-level dataset: enacted 2020 BVAP shares joined to 117th Congress NOMINATE scores
# (generate_dataset_nom.py builds this from data/dataverse_files/ + data/HS117_members.csv)
df <- read.csv("data/datasets/dataset_nom.csv")
df$party <- as.integer(df$party_code == 200) # 1=R, 0=D
df$treated <- as.integer(df$state %in% covered)

primary <- subset(df, !state %in% partial)

# Does BVAP packing predict ideological extremity?
m_nom <- lm(nominate_dim1 ~ blackvap_share * treated + party, data = primary)
# coeftest(m_nom, vcov = vcovCL(m_nom, cluster = ~state))
summary(m_nom)
