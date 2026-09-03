# Beta regression baseline

library(betareg)
library(dplyr)

beta_data <- analysis_data %>%
  filter(country == "Canada")

eps_beta <- 1e-4

beta_data <- beta_data %>%
  mutate(
    bank_beta =
      (bank + eps_beta) /
      (1 + 2 * eps_beta)
  )

beta_model <- betareg(
  bank_beta ~
    realGDP +
    headlineInflation +
    usdExchangeRate +
    policyRate,
  data = beta_data,
  link = "logit"
)

summary(beta_model)
