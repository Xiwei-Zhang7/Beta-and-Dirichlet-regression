# Model selection and nonlinear effects

library(VGAM)
library(splines)

composition_vars <- c(
  "bank",
  "govern",
  "growth",
  "market",
  "other"
)

Y <- as.matrix(
  g7_data[, composition_vars]
)

storage.mode(Y) <- "double"

candidate_variables <- c(
  "headlineInflation_s",
  "policyRate_s",
  "usdExchangeRate_s",
  "realGDP_s"
)

fit_dirichlet_vglm <- function(formula) {

  vglm(
    formula,
    dirichlet(),
    data = g7_data,
    control = vglm.control(
      maxit = 5000,
      trace = FALSE,
      epsilon = 1e-7
    )
  )
}

calculate_bic <- function(model) {

  log_likelihood <-
    as.numeric(logLik(model))

  n_parameters <-
    length(coef(model))

  n_observations <-
    NROW(fitted(model))

  -2 * log_likelihood +
    log(n_observations) * n_parameters
}


# Forward variable selection


selection_start <- vglm(
  I(Y) ~ country,
  dirichlet(),
  data = g7_data
)

selection_full <- vglm(
  I(Y) ~
    country +
    headlineInflation_s +
    policyRate_s +
    usdExchangeRate_s +
    realGDP_s,
  dirichlet(),
  data = g7_data
)

bic_penalty <- log(
  NROW(fitted(selection_full))
)

selection_scope <- list(
  lower = formula(selection_start),
  upper = formula(selection_full)
)

selected_linear_model <- step4vglm(
  selection_start,
  scope = selection_scope,
  direction = "forward",
  k = bic_penalty,
  trace = 0
)

formula(selected_linear_model)


# Final nonlinear pooled model


pooled_spline_model <- vgam(
  I(Y) ~
    country +
    sm.ps(
      headlineInflation_s,
      ps.int = 6
    ) +
    sm.ps(
      policyRate_s,
      ps.int = 6
    ) +
    sm.ps(
      realGDP_s,
      ps.int = 6
    ) +
    sm.ps(
      usdExchangeRate_s,
      ps.int = 6
    ),
  family = dirichlet(),
  data = g7_data,
  control = vgam.control(
    Maxit.outer = 80,
    trace = FALSE
  )
)


# Country-specific policy-rate interaction


pooled_interaction_model <- vgam(
  I(Y) ~
    country +
    country:policyRate +
    sm.ps(
      headlineInflation_s,
      ps.int = 6
    ) +
    sm.ps(
      policyRate_s,
      ps.int = 6
    ) +
    sm.ps(
      realGDP_s,
      ps.int = 6
    ) +
    sm.ps(
      usdExchangeRate_s,
      ps.int = 6
    ),
  family = dirichlet(),
  data = g7_data,
  control = vgam.control(
    Maxit.outer = 80,
    trace = FALSE
  )
)

model_selection_table <- data.frame(
  model = c(
    "Pooled spline",
    "Pooled spline + country-policy interaction"
  ),
  AIC = c(
    AIC(pooled_spline_model),
    AIC(pooled_interaction_model)
  ),
  BIC = c(
    BIC(pooled_spline_model),
    BIC(pooled_interaction_model)
  )
)

print(model_selection_table)
