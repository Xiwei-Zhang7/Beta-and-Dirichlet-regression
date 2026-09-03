# Country-specific G7 models


library(VGAM)
library(dplyr)

safe_scale <- function(x) {

  x <- as.numeric(x)

  x_sd <- sd(
    x,
    na.rm = TRUE
  )

  x_mean <- mean(
    x,
    na.rm = TRUE
  )

  if (!is.finite(x_sd) || x_sd == 0) {
    return(rep(0, length(x)))
  }

  (x - x_mean) / x_sd
}

# Country-specific model specifications


# Canada / France / Germany / United Kingdom
# - ps.int = 5

# Italy
# - ps.int = 4
# - Reduced spline complexity was used to improve numerical stability.


# Japan
# - ps.int = 5
# - Stronger composition adjustment
# - Maxit.outer = 400
# - A larger outer-iteration limit and slightly stronger response adjustment were required for convergence.


# United States
# - usdExchangeRate excluded
# - Three smooth terms
# - USD exchange rate was excluded because of insufficient within-country variation.
