# Country-specific G7 Dirichlet models


# This script fits separate nonlinear Dirichlet regression models for each G7 country.

# The purpose is to compare:
#
#   1. A pooled multi-country G7 model
#   2. Separate country-specific G7 models
#
# Most countries use four penalized-spline macroeconomic predictors. Some specifications are adjusted to improve numerical stability or identifiability.

# Required object:
#   - g7_data

# Created object:
#   - g7_models




# 1. Packages

library(VGAM)
library(dplyr)



# 2. Check required data

if (!exists("g7_data")) {

  stop(
    paste(
      "Object 'g7_data' was not found.",
      "Run R/01_data_preprocessing.R first."
    )
  )
}


# 3. Basic settings

composition_vars <- c(
  "bank",
  "govern",
  "growth",
  "market",
  "other"
)


g7_countries <- c(
  "Canada",
  "France",
  "Germany",
  "Italy",
  "Japan",
  "United Kingdom",
  "United States"
)



# 4. Helper function: safe scaling


# Penalized spline estimation can become unstable when a
# predictor has zero or nearly zero within-country variation.
#
# If the standard deviation is effectively zero, a very small
# sequence is used so that the spline routine does not receive
# an exactly constant predictor.


safe_scale_for_spline <- function(x) {

  x <- as.numeric(x)

  x_sd <- sd(
    x,
    na.rm = TRUE
  )

  x_mean <- mean(
    x,
    na.rm = TRUE
  )

  if (
    !is.finite(x_sd) ||
    is.na(x_sd) ||
    x_sd == 0
  ) {

    return(
      seq(
        -1e-6,
        1e-6,
        length.out = length(x)
      )
    )
  }

  (x - x_mean) / x_sd
}



# 5. Helper function: adjust compositional response

#
# Dirichlet models require strictly positive components.
#
# Small adjustments are therefore applied to move observations
# away from exact zero and one boundaries while preserving the
# sum-to-one constraint.


adjust_composition <- function(
    response_matrix,
    eps = 1e-3,
    delta = 0.002
) {

  response_matrix <- as.matrix(
    response_matrix
  )

  storage.mode(
    response_matrix
  ) <- "double"


  # Protect against small negative numerical values.

  response_matrix[
    response_matrix < 0
  ] <- 0


  # Renormalize each observation.

  response_matrix <-
    response_matrix /
    rowSums(
      response_matrix
    )


  number_components <-
    ncol(
      response_matrix
    )


  # Move exact zeros away from the boundary.

  response_matrix <-
    (
      response_matrix +
      eps
    ) /
    (
      1 +
      number_components * eps
    )


  # Additional shrinkage toward the center of the simplex.

  response_matrix <-
    (
      1 - delta
    ) *
    response_matrix +
    delta *
    (
      1 /
      number_components
    )


  # Final normalization.

  response_matrix <-
    response_matrix /
    rowSums(
      response_matrix
    )


  storage.mode(
    response_matrix
  ) <- "double"


  response_matrix
}



# 6. Prepare common country-specific response

base_response <- as.matrix(
  g7_data[
    ,
    composition_vars
  ]
)


adjusted_response <- adjust_composition(
  base_response,
  eps = 1e-3,
  delta = 0.002
)



# 7. Storage for country-specific models


g7_models <- list()



# Country-specific model specifications


# Canada / France / Germany / United Kingdom
# - Four smooth macroeconomic predictors
# - ps.int = 5
#
# Italy
# - Four smooth macroeconomic predictors
# - ps.int = 4
# - Reduced spline complexity improves numerical stability
#
# Japan
# - Four smooth macroeconomic predictors
# - ps.int = 5
# - Slightly stronger response adjustment
# - Maxit.outer = 400
#
# United States
# - Three smooth macroeconomic predictors
# - usdExchangeRate excluded because of insufficient within-country variation
# - ps.int = 6




# 8. Canada, France, Germany, Italy, United Kingdom


main_countries <- c(
  "Canada",
  "France",
  "Germany",
  "Italy",
  "United Kingdom"
)


for (cty in main_countries) {

  cat(
    "\n========================================\n"
  )

  cat(
    "Fitting country-specific model:",
    cty,
    "\n"
  )

  cat(
    "========================================\n"
  )



  # Extract country observations


  country_index <- which(
    g7_data$country == cty
  )


  country_order <- order(
    g7_data$date_m[
      country_index
    ]
  )


  ordered_index <-
    country_index[
      country_order
    ]


  country_data <- g7_data[
    ordered_index,
    ,
    drop = FALSE
  ]


  country_response <-
    adjusted_response[
      ordered_index,
      ,
      drop = FALSE
    ]


  # Country-specific scaling


  country_data$headlineInflation_sc <-
    safe_scale_for_spline(
      country_data$headlineInflation
    )


  country_data$policyRate_sc <-
    safe_scale_for_spline(
      country_data$policyRate
    )


  country_data$realGDP_sc <-
    safe_scale_for_spline(
      country_data$realGDP
    )


  country_data$usdExchangeRate_sc <-
    safe_scale_for_spline(
      country_data$usdExchangeRate
    )


  # Spline complexity


  spline_intervals <- if (
    cty == "Italy"
  ) {
    4
  } else {
    5
  }



  # Fit model
  

  country_model <- try(

    vgam(

      country_response ~

        sm.ps(
          headlineInflation_sc,
          ps.int = spline_intervals
        ) +

        sm.ps(
          policyRate_sc,
          ps.int = spline_intervals
        ) +

        sm.ps(
          realGDP_sc,
          ps.int = spline_intervals
        ) +

        sm.ps(
          usdExchangeRate_sc,
          ps.int = spline_intervals
        ),

      family = dirichlet(),

      data = country_data,

      control = vgam.control(
        Maxit.outer = 200,
        trace = FALSE
      )
    ),

    silent = TRUE
  )


 
  # Store model
  

  g7_models[
    [cty]
  ] <- country_model


 
  # Report fitting status


  if (
    inherits(
      country_model,
      "try-error"
    )
  ) {

    cat(
      "FAILED:",
      cty,
      "\n"
    )

  } else {

    cat(
      "SUCCESS:",
      cty,
      "| ps.int =",
      spline_intervals,
      "\n"
    )
  }
}



# 9. Japan

#
# Japan required a slightly stronger response adjustment and a larger outer-iteration limit to obtain stable convergence.

cty <- "Japan"


cat(
  "\n========================================\n"
)

cat(
  "Fitting country-specific model:",
  cty,
  "\n"
)

cat(
  "Special convergence specification\n"
)

cat(
  "========================================\n"
)



# Extract Japan observations

japan_index <- which(
  g7_data$country == cty
)


japan_order <- order(
  g7_data$date_m[
    japan_index
  ]
)


japan_index <-
  japan_index[
    japan_order
  ]


japan_data <- g7_data[
  japan_index,
  ,
  drop = FALSE
]



# Japan-specific response adjustment


japan_response <- as.matrix(
  japan_data[
    ,
    composition_vars
  ]
)


japan_response <- adjust_composition(

  japan_response,

  eps = 2e-3,

  delta = 0.003
)



# Japan-specific scaling


japan_data$headlineInflation_sc <-
  safe_scale_for_spline(
    japan_data$headlineInflation
  )


japan_data$policyRate_sc <-
  safe_scale_for_spline(
    japan_data$policyRate
  )


japan_data$realGDP_sc <-
  safe_scale_for_spline(
    japan_data$realGDP
  )


japan_data$usdExchangeRate_sc <-
  safe_scale_for_spline(
    japan_data$usdExchangeRate
  )



# Fit Japan model

japan_model <- try(

  vgam(

    japan_response ~

      sm.ps(
        headlineInflation_sc,
        ps.int = 5
      ) +

      sm.ps(
        policyRate_sc,
        ps.int = 5
      ) +

      sm.ps(
        realGDP_sc,
        ps.int = 5
      ) +

      sm.ps(
        usdExchangeRate_sc,
        ps.int = 5
      ),

    family = dirichlet(),

    data = japan_data,

    control = vgam.control(
      Maxit.outer = 400,
      trace = FALSE
    )
  ),

  silent = TRUE
)


g7_models[
  ["Japan"]
] <- japan_model


if (
  inherits(
    japan_model,
    "try-error"
  )
) {

  cat(
    "FAILED: Japan\n"
  )

} else {

  cat(
    paste(
      "SUCCESS: Japan",
      "| ps.int = 5",
      "| Maxit.outer = 400\n"
    )
  )
}



# 10. United States

# usdExchangeRate is excluded from the country-specific US specification because it provides insufficient within-country variation for stable identification.


cty <- "United States"


cat(
  "\n========================================\n"
)

cat(
  "Fitting country-specific model:",
  cty,
  "\n"
)

cat(
  "USD exchange rate excluded\n"
)

cat(
  "========================================\n"
)


# Extract US observations


us_index <- which(
  g7_data$country == cty
)


us_order <- order(
  g7_data$date_m[
    us_index
  ]
)


us_index <-
  us_index[
    us_order
  ]


us_data <- g7_data[
  us_index,
  ,
  drop = FALSE
]


us_response <-
  adjusted_response[
    us_index,
    ,
    drop = FALSE
  ]


# US-specific scaling

us_data$headlineInflation_sc <-
  safe_scale_for_spline(
    us_data$headlineInflation
  )


us_data$policyRate_sc <-
  safe_scale_for_spline(
    us_data$policyRate
  )


us_data$realGDP_sc <-
  safe_scale_for_spline(
    us_data$realGDP
  )


# Fit US model

us_model <- try(

  vgam(

    us_response ~

      sm.ps(
        headlineInflation_sc,
        ps.int = 6
      ) +

      sm.ps(
        policyRate_sc,
        ps.int = 6
      ) +

      sm.ps(
        realGDP_sc,
        ps.int = 6
      ),

    family = dirichlet(),

    data = us_data,

    control = vgam.control(
      Maxit.outer = 200,
      trace = FALSE
    )
  ),

  silent = TRUE
)


g7_models[
  ["United States"]
] <- us_model


if (
  inherits(
    us_model,
    "try-error"
  )
) {

  cat(
    "FAILED: United States\n"
  )

} else {

  cat(
    paste(
      "SUCCESS: United States",
      "| ps.int = 6",
      "| usdExchangeRate excluded\n"
    )
  )
}


# 11. Check successful models


successful_models <- vapply(

  g7_models,

  function(model) {

    !inherits(
      model,
      "try-error"
    ) &&
      !is.null(
        model
      )
  },

  logical(1)
)


successful_countries <-
  names(
    g7_models
  )[
    successful_models
  ]


failed_countries <-
  names(
    g7_models
  )[
    !successful_models
  ]


cat(
  "\n========================================\n"
)

cat(
  "Country-specific model fitting summary\n"
)

cat(
  "========================================\n"
)


cat(
  "\nSuccessful models:\n"
)


print(
  successful_countries
)


if (
  length(
    failed_countries
  ) > 0
) {

  cat(
    "\nFailed models:\n"
  )

  print(
    failed_countries
  )
}


# 12. Model specification summary


g7_model_specifications <- data.frame(

  country = g7_countries,

  smooth_terms = c(
    4,
    4,
    4,
    4,
    4,
    4,
    3
  ),

  ps_int = c(
    5,
    5,
    5,
    4,
    5,
    5,
    6
  ),

  special_adjustment = c(

    "Standard specification",

    "Standard specification",

    "Standard specification",

    "Reduced spline complexity for stability",

    paste(
      "Stronger response adjustment;",
      "Maxit.outer = 400"
    ),

    "Standard specification",

    "usdExchangeRate excluded"
  ),

  stringsAsFactors = FALSE
)


print(
  g7_model_specifications
)


# 13. AIC/BIC summary
#
# AIC and BIC are reported for each successfully fitted country-specific model.
#
# These values are useful for comparing alternative models within the same country. They should not be interpreted as direct model rankings across countries with different data.


if (
  length(
    successful_countries
  ) > 0
) {

  g7_information_criteria <- data.frame(

    country =
      successful_countries,

    AIC =
      sapply(

        g7_models[
          successful_countries
        ],

        AIC
      ),

    BIC =
      sapply(

        g7_models[
          successful_countries
        ],

        BIC
      ),

    stringsAsFactors = FALSE
  )


  g7_information_criteria <-
    g7_information_criteria %>%

    mutate(

      AIC = round(
        AIC,
        2
      ),

      BIC = round(
        BIC,
        2
      )
    )


  cat(
    "\n========================================\n"
  )

  cat(
    "Country-specific AIC/BIC\n"
  )

  cat(
    "========================================\n\n"
  )


  print(
    g7_information_criteria
  )
}



# 14. Save model specification table

dir.create(
  "results/tables",
  recursive = TRUE,
  showWarnings = FALSE
)


write.csv(

  g7_model_specifications,

  "results/tables/g7_model_specifications.csv",

  row.names = FALSE
)


if (
  exists(
    "g7_information_criteria"
  )
) {

  write.csv(

    g7_information_criteria,

    "results/tables/g7_information_criteria.csv",

    row.names = FALSE
  )
}


# 15. Completion message

cat(
  "\nCountry-specific G7 modeling completed.\n"
)


cat(
  "\nCreated object:\n",
  "- g7_models\n"
)


cat(
  "\nSaved tables:\n",
  "- results/tables/g7_model_specifications.csv\n",
  "- results/tables/g7_information_criteria.csv\n"
)
