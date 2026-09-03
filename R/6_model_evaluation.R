# Model evaluation

# This script compares:
#
# 1. The pooled G7 Dirichlet model
# 2. The country-specific G7 models
#
# Performance is evaluated using MAE and RMSE across the five-component topic composition:
# bank, govern, growth, market, other
# Required objects:
#   - g7_data
#   - pooled_interaction_model
#   - g7_models
#
# These objects are created by the earlier scripts in the analysis pipeline.




# 1. Packages

library(dplyr)
library(tidyr)
library(ggplot2)



# 2. Check required objects

required_objects <- c(
  "g7_data",
  "pooled_interaction_model",
  "g7_models"
)

missing_objects <- required_objects[
  !vapply(
    required_objects,
    exists,
    logical(1),
    inherits = TRUE
  )
]

if (length(missing_objects) > 0) {

  stop(
    paste(
      "Missing required objects:",
      paste(missing_objects, collapse = ", "),
      "\nRun scripts 01-05 before running model evaluation."
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


# 4. Create output directories

dir.create(
  "results",
  showWarnings = FALSE
)

dir.create(
  "results/tables",
  recursive = TRUE,
  showWarnings = FALSE
)

dir.create(
  "results/figures",
  recursive = TRUE,
  showWarnings = FALSE
)


# 5. Evaluation functions

mae <- function(observed, predicted) {

  mean(
    abs(observed - predicted),
    na.rm = TRUE
  )
}


rmse <- function(observed, predicted) {

  sqrt(
    mean(
      (observed - predicted)^2,
      na.rm = TRUE
    )
  )
}



# 6. Helper function for fitted values

extract_fitted_matrix <- function(
    model,
    suffix,
    component_names = composition_vars
) {

  fitted_matrix <- as.matrix(
    fitted(model)
  )

  # Confirm that the fitted matrix contains the expected
  # compositional components.

  if (!all(component_names %in% colnames(fitted_matrix))) {

    stop(
      "Fitted model does not contain all expected composition components."
    )
  }

  fitted_data <- as.data.frame(
    fitted_matrix[
      ,
      component_names,
      drop = FALSE
    ]
  )

  names(fitted_data) <- paste0(
    component_names,
    suffix
  )

  fitted_data
}



# 7. Pooled-model fitted values


pooled_fit <- extract_fitted_matrix(
  pooled_interaction_model,
  suffix = "_pooled"
)


if (nrow(pooled_fit) != nrow(g7_data)) {

  stop(
    "Number of pooled fitted observations does not match g7_data."
  )
}


pooled_fitted_data <- g7_data %>%

  mutate(
    row_id = seq_len(n())
  ) %>%

  bind_cols(
    pooled_fit
  ) %>%

  select(
    row_id,
    country,
    date_m,
    all_of(composition_vars),
    ends_with("_pooled")
  )



# 8. Country-specific fitted values


single_fitted_list <- list()


for (cty in g7_countries) {

  cat(
    "\nExtracting fitted values:",
    cty,
    "\n"
  )

  # Identify observations for this country.

  idx <- which(
    g7_data$country == cty
  )

  if (length(idx) == 0) {

    warning(
      paste(
        "No observations found for",
        cty
      )
    )

    next
  }

  # Match the same ordering used during model fitting.

  ord <- order(
    g7_data$date_m[idx]
  )

  country_data <- g7_data[
    idx[ord],
    ,
    drop = FALSE
  ]

  # Confirm that a model exists.

  if (!cty %in% names(g7_models)) {

    warning(
      paste(
        "No country-specific model found for",
        cty
      )
    )

    next
  }

  country_model <- g7_models[[cty]]

  # Skip failed models.

  if (
    inherits(country_model, "try-error") ||
    is.null(country_model)
  ) {

    warning(
      paste(
        "Country-specific model failed for",
        cty
      )
    )

    next
  }

  country_fit <- extract_fitted_matrix(
    country_model,
    suffix = "_single"
  )

  if (
    nrow(country_fit) !=
    nrow(country_data)
  ) {

    warning(
      paste(
        "Fitted-value length mismatch for",
        cty
      )
    )

    next
  }

  country_result <- country_data %>%

    select(
      country,
      date_m,
      all_of(composition_vars)
    ) %>%

    bind_cols(
      country_fit
    )

  single_fitted_list[[cty]] <-
    country_result
}



# 9. Combine country-specific fitted values


single_fitted_data <- bind_rows(
  single_fitted_list
)


if (nrow(single_fitted_data) == 0) {

  stop(
    "No valid country-specific fitted values were produced."
  )
}


# 10. Merge pooled and country-specific predictions


comparison_data <- pooled_fitted_data %>%

  select(
    country,
    date_m,
    all_of(composition_vars),
    ends_with("_pooled")
  ) %>%

  left_join(

    single_fitted_data %>%
      select(
        country,
        date_m,
        ends_with("_single")
      ),

    by = c(
      "country",
      "date_m"
    )

  ) %>%

  arrange(
    country,
    date_m
  )



# 11. Country-level composition performance
#
# All five composition components are evaluated jointly.
# Each country receives:
#
# pooled_MAE
# pooled_RMSE
# single_MAE
# single_RMSE
#
# ------------------------------------------------------------

g7_performance <- bind_rows(

  lapply(
    g7_countries,
    function(cty) {

      country_data <-
        comparison_data %>%
        filter(
          country == cty
        )

      if (nrow(country_data) == 0) {

        return(NULL)
      }

      observed_matrix <- as.matrix(
        country_data[
          ,
          composition_vars
        ]
      )

      pooled_matrix <- as.matrix(
        country_data[
          ,
          paste0(
            composition_vars,
            "_pooled"
          )
        ]
      )

      single_matrix <- as.matrix(
        country_data[
          ,
          paste0(
            composition_vars,
            "_single"
          )
        ]
      )

      observed_vector <-
        as.vector(
          observed_matrix
        )

      pooled_vector <-
        as.vector(
          pooled_matrix
        )

      single_vector <-
        as.vector(
          single_matrix
        )

      data.frame(

        country = cty,

        pooled_MAE =
          mae(
            observed_vector,
            pooled_vector
          ),

        pooled_RMSE =
          rmse(
            observed_vector,
            pooled_vector
          ),

        single_MAE =
          mae(
            observed_vector,
            single_vector
          ),

        single_RMSE =
          rmse(
            observed_vector,
            single_vector
          )
      )
    }
  )
)


# 12. Add improvement statistics


g7_performance <- g7_performance %>%

  mutate(

    MAE_improvement =
      pooled_MAE -
      single_MAE,

    RMSE_improvement =
      pooled_RMSE -
      single_RMSE,

    MAE_improvement_pct =
      100 *
      (
        pooled_MAE -
        single_MAE
      ) /
      pooled_MAE,

    RMSE_improvement_pct =
      100 *
      (
        pooled_RMSE -
        single_RMSE
      ) /
      pooled_RMSE

  ) %>%

  mutate(

    across(
      where(is.numeric),
      ~ round(.x, 4)
    )

  ) %>%

  arrange(
    country
  )


cat(
  "\n========================================\n"
)

cat(
  "G7 pooled vs country-specific models\n"
)

cat(
  "========================================\n\n"
)

print(
  g7_performance
)



# 13. Save country-level performance table


write.csv(
  g7_performance,
  "results/tables/g7_model_performance.csv",
  row.names = FALSE
)



# 14. Component-level performance
# This evaluates bank, govern, growth, market, and other separately for each country.


component_performance_list <- list()


for (cty in g7_countries) {

  country_data <- comparison_data %>%

    filter(
      country == cty
    )

  if (nrow(country_data) == 0) {

    next
  }

  for (component in composition_vars) {

    observed_values <-
      country_data[
        [component]
      ]

    pooled_values <-
      country_data[
        [paste0(
          component,
          "_pooled"
        )]
      ]

    single_values <-
      country_data[
        [paste0(
          component,
          "_single"
        )]
      ]

    component_result <- data.frame(

      country = cty,

      component = component,

      pooled_MAE =
        mae(
          observed_values,
          pooled_values
        ),

      pooled_RMSE =
        rmse(
          observed_values,
          pooled_values
        ),

      single_MAE =
        mae(
          observed_values,
          single_values
        ),

      single_RMSE =
        rmse(
          observed_values,
          single_values
        )
    )

    component_performance_list[
      [paste(
        cty,
        component,
        sep = "_"
      )]
    ] <- component_result
  }
}


g7_component_performance <-
  bind_rows(
    component_performance_list
  ) %>%

  mutate(

    MAE_improvement =
      pooled_MAE -
      single_MAE,

    RMSE_improvement =
      pooled_RMSE -
      single_RMSE

  ) %>%

  mutate(

    across(
      where(is.numeric),
      ~ round(.x, 4)
    )

  )


print(
  g7_component_performance
)


# 15. Save component-level performance


write.csv(
  g7_component_performance,
  "results/tables/g7_component_performance.csv",
  row.names = FALSE
)


# 16. Convert comparison data to long format


build_plot_data <- function(
    country_name,
    data = comparison_data
) {

  country_data <- data %>%

    filter(
      country == country_name
    ) %>%

    arrange(
      date_m
    )


  # Observed values

  observed_long <- country_data %>%

    select(
      country,
      date_m,
      all_of(
        composition_vars
      )
    ) %>%

    pivot_longer(

      cols =
        all_of(
          composition_vars
        ),

      names_to =
        "component",

      values_to =
        "proportion"

    ) %>%

    mutate(
      model = "Observed"
    )


  # Pooled model

  pooled_long <- country_data %>%

    select(
      country,
      date_m,
      all_of(
        paste0(
          composition_vars,
          "_pooled"
        )
      )
    ) %>%

    rename_with(
      ~ sub(
        "_pooled$",
        "",
        .x
      )
    ) %>%

    pivot_longer(

      cols =
        all_of(
          composition_vars
        ),

      names_to =
        "component",

      values_to =
        "proportion"

    ) %>%

    mutate(
      model =
        "Pooled G7"
    )


  # Country-specific model

  single_long <- country_data %>%

    select(
      country,
      date_m,
      all_of(
        paste0(
          composition_vars,
          "_single"
        )
      )
    ) %>%

    rename_with(
      ~ sub(
        "_single$",
        "",
        .x
      )
    ) %>%

    pivot_longer(

      cols =
        all_of(
          composition_vars
        ),

      names_to =
        "component",

      values_to =
        "proportion"

    ) %>%

    mutate(
      model =
        "Country-specific"
    )


  bind_rows(

    observed_long,
    pooled_long,
    single_long

  ) %>%

    mutate(

      component = factor(
        component,
        levels =
          composition_vars
      ),

      model = factor(

        model,

        levels = c(
          "Observed",
          "Pooled G7",
          "Country-specific"
        )
      )
    )
}



# 17. Plot function


plot_country_comparison <- function(
    country_name
) {

  plot_data <-
    build_plot_data(
      country_name
    )

  ggplot(
    plot_data,
    aes(
      x = date_m,
      y = proportion,
      linetype = model,
      linewidth = model
    )
  ) +

    geom_line() +

    facet_wrap(
      ~ component,
      ncol = 2,
      scales = "free_y"
    ) +

    scale_linetype_manual(

      values = c(
        "Observed" = "dotted",
        "Pooled G7" = "solid",
        "Country-specific" = "longdash"
      )

    ) +

    scale_linewidth_manual(

      values = c(
        "Observed" = 0.5,
        "Pooled G7" = 0.9,
        "Country-specific" = 0.9
      )

    ) +

    labs(

      title = paste(
        "Observed vs Fitted Topic Composition -",
        country_name
      ),

      x = "Date",

      y = "Proportion",

      linetype = NULL,

      linewidth = NULL
    ) +

    theme_bw() +

    theme(

      plot.title = element_text(
        hjust = 0.5,
        face = "bold",
        size = 14
      ),

      strip.text = element_text(
        face = "bold"
      ),

      legend.position = "top"
    )
}



# 18. Generate and save G7 comparison figures


for (cty in g7_countries) {

  if (
    !cty %in%
    unique(
      comparison_data$country
    )
  ) {

    next
  }

  country_plot <-
    plot_country_comparison(
      cty
    )

  print(
    country_plot
  )


  # Create a safe file name.

  file_name <- tolower(
    gsub(
      " ",
      "_",
      cty
    )
  )


  ggsave(

    filename = paste0(
      "results/figures/",
      file_name,
      "_model_comparison.png"
    ),

    plot =
      country_plot,

    width = 11,

    height = 8,

    dpi = 300
  )
}



# 19. Overall pooled vs country-specific performance


observed_all <- as.vector(

  as.matrix(
    comparison_data[
      ,
      composition_vars
    ]
  )
)


pooled_all <- as.vector(

  as.matrix(
    comparison_data[
      ,
      paste0(
        composition_vars,
        "_pooled"
      )
    ]
  )
)


single_all <- as.vector(

  as.matrix(
    comparison_data[
      ,
      paste0(
        composition_vars,
        "_single"
      )
    ]
  )
)


overall_performance <- data.frame(

  model = c(
    "Pooled G7",
    "Country-specific"
  ),

  MAE = c(

    mae(
      observed_all,
      pooled_all
    ),

    mae(
      observed_all,
      single_all
    )
  ),

  RMSE = c(

    rmse(
      observed_all,
      pooled_all
    ),

    rmse(
      observed_all,
      single_all
    )
  )

) %>%

  mutate(

    across(
      where(is.numeric),
      ~ round(.x, 4)
    )

  )


cat(
  "\n========================================\n"
)

cat(
  "Overall G7 performance\n"
)

cat(
  "========================================\n\n"
)

print(
  overall_performance
)



# 20. Save overall performance


write.csv(
  overall_performance,
  "results/tables/g7_overall_performance.csv",
  row.names = FALSE
)


# 21. Completion message


cat(
  "\nModel evaluation completed successfully.\n"
)

cat(
  "\nSaved tables:\n",
  "- results/tables/g7_model_performance.csv\n",
  "- results/tables/g7_component_performance.csv\n",
  "- results/tables/g7_overall_performance.csv\n"
)

cat(
  "\nSaved figures:\n",
  "- results/figures/*_model_comparison.png\n"
)
