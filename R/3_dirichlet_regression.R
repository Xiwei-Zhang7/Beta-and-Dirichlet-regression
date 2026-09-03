# Dirichlet regression

library(DirichletReg)
library(dplyr)

composition_vars <- c(
  "bank",
  "govern",
  "growth",
  "market",
  "other"
)

dirichlet_data <- analysis_data

Y_matrix <- data.matrix(
  dirichlet_data[, composition_vars]
)

dirichlet_data$Y <- DR_data(
  Y_matrix,
  base = 5
)

predictor_vars <- c(
  "realGDP",
  "headlineInflation",
  "usdExchangeRate",
  "policyRate"
)

dirichlet_data[predictor_vars] <-
  lapply(
    dirichlet_data[predictor_vars],
    function(x) as.numeric(scale(x))
  )


# Baseline model

dirichlet_baseline <- DirichReg(
  Y ~
    realGDP +
    headlineInflation +
    usdExchangeRate +
    policyRate | 1,
  data = dirichlet_data,
  model = "alternative",
  control = list(
    iterlim = 10000,
    tol1 = 1e-6,
    tol2 = 1e-12
  )
)

summary(dirichlet_baseline)


# COVID-period model

dirichlet_data <- dirichlet_data %>%
  mutate(
    event_covid = as.integer(
      date_m >= as.Date("2020-03-01") &
      date_m <= as.Date("2021-12-01")
    )
  )

dirichlet_covid <- DirichReg(
  Y ~
    realGDP +
    headlineInflation +
    usdExchangeRate +
    policyRate +
    event_covid | 1,
  data = dirichlet_data,
  model = "alternative",
  control = list(
    iterlim = 5000,
    tol1 = 1e-6,
    tol2 = 1e-12
  )
)

summary(dirichlet_covid)


# Likelihood-ratio comparison

anova(
  dirichlet_baseline,
  dirichlet_covid
)
