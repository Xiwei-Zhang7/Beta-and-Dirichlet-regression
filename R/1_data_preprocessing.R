# Data preprocessing


library(dplyr)
library(tidyr)
library(readr)
library(readxl)
library(lubridate)
library(stringr)
library(purrr)
library(zoo)

# 1. Country-code mapping

code_to_country <- c(
  AR = "Argentina",
  AU = "Australia",
  BR = "Brazil",
  CA = "Canada",
  CN = "China",
  DE = "Germany",
  FR = "France",
  GB = "United Kingdom",
  ID = "Indonesia",
  IN = "India",
  IT = "Italy",
  JP = "Japan",
  KR = "Korea, Republic of",
  MX = "Mexico",
  RU = "Russian Federation",
  SA = "Saudi Arabia",
  TR = "Turkey",
  US = "United States",
  ZA = "South Africa",
  XM = "Other_ECB"
)

# 2. Build five-part topic composition

topic_data <- read_csv(
  "data/g20bis_monthly_topic_proportions.csv",
  show_col_types = FALSE
) %>%
  mutate(
    date = as.Date(date),
    date_m = floor_date(date, "month"),
    anchor5 = if_else(
      anchor %in% c("market", "bank", "growth", "govern"),
      anchor,
      "other"
    ),
    avg_proportion = as.numeric(avg_proportion)
  ) %>%
  group_by(country, date_m, anchor5) %>%
  summarise(
    avg_proportion = sum(avg_proportion, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  pivot_wider(
    names_from = anchor5,
    values_from = avg_proportion,
    values_fill = 0
  ) %>%
  filter(date_m >= as.Date("2010-01-01"))

# 3. Convert quarterly GDP to monthly

real_gdp_monthly <- read_excel(
  "data/macro_control_vars.xlsx",
  sheet = "realGDP"
) %>%
  rename(date = 1) %>%
  pivot_longer(
    -date,
    names_to = "series",
    values_to = "realGDP"
  ) %>%
  mutate(
    date = as.Date(date),
    code = str_extract(series, "[A-Z]{2,3}$"),
    country = recode(code, !!!code_to_country),
    quarter = as.yearqtr(date),
    quarter_start = as.Date(quarter, frac = 0)
  ) %>%
  filter(!is.na(country)) %>%
  group_by(country, quarter, quarter_start) %>%
  summarise(
    realGDP = mean(realGDP, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(
    date_m = map(
      quarter_start,
      ~ seq(.x, by = "1 month", length.out = 3)
    )
  ) %>%
  unnest(date_m) %>%
  select(country, date_m, realGDP)


# 4. Read monthly macroeconomic variables

read_monthly_sheet <- function(sheet_name) {

  read_excel(
    "data/macro_control_vars.xlsx",
    sheet = sheet_name
  ) %>%
    rename(date = 1) %>%
    pivot_longer(
      -date,
      names_to = "series",
      values_to = "value"
    ) %>%
    mutate(
      date = as.Date(date),
      date_m = floor_date(date, "month"),
      code = str_extract(series, "[A-Z]{2,3}$"),
      country = recode(code, !!!code_to_country)
    ) %>%
    filter(!is.na(country)) %>%
    group_by(country, date_m) %>%
    summarise(
      value = mean(value, na.rm = TRUE),
      .groups = "drop"
    ) %>%
    rename(!!sheet_name := value)
}

macro_data <- real_gdp_monthly %>%
  full_join(
    read_monthly_sheet("headlineInflation"),
    by = c("country", "date_m")
  ) %>%
  full_join(
    read_monthly_sheet("usdExchangeRate"),
    by = c("country", "date_m")
  ) %>%
  full_join(
    read_monthly_sheet("policyRate"),
    by = c("country", "date_m")
  )


# 5. Merge topic and macroeconomic data

analysis_data <- inner_join(
  topic_data,
  macro_data,
  by = c("country", "date_m")
) %>%
  arrange(country, date_m) %>%
  select(
    country,
    date_m,
    bank,
    govern,
    growth,
    market,
    other,
    realGDP,
    headlineInflation,
    usdExchangeRate,
    policyRate
  ) %>%
  na.omit()


# 6. Composition adjustment

composition_vars <- c(
  "bank",
  "govern",
  "growth",
  "market",
  "other"
)

analysis_data[composition_vars] <-
  lapply(
    analysis_data[composition_vars],
    as.numeric
  )

composition_sum <- rowSums(
  analysis_data[, composition_vars]
)

analysis_data[, composition_vars] <-
  analysis_data[, composition_vars] / composition_sum

eps <- 1e-3
K <- length(composition_vars)

analysis_data[, composition_vars] <-
  (analysis_data[, composition_vars] + eps) /
  (1 + K * eps)

delta <- 0.002

analysis_data[, composition_vars] <-
  (1 - delta) *
  analysis_data[, composition_vars] +
  delta * (1 / K)

# 7. G7 analysis sample

g7_countries <- c(
  "Canada",
  "France",
  "Germany",
  "Italy",
  "Japan",
  "United Kingdom",
  "United States"
)

g7_data <- analysis_data %>%
  filter(
    country %in% g7_countries,
    date_m >= as.Date("2014-01-01"),
    date_m <= as.Date("2024-01-01")
  ) %>%
  mutate(
    country = factor(country),
    headlineInflation_s =
      as.numeric(scale(headlineInflation)),
    policyRate_s =
      as.numeric(scale(policyRate)),
    usdExchangeRate_s =
      as.numeric(scale(usdExchangeRate)),
    realGDP_s =
      as.numeric(scale(realGDP))
  )
