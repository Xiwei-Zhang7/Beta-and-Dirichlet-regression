# Data

The full processed datasets used in this project are not included in this repository due to data access and redistribution restrictions.

The analysis expects the following files to be placed locally in this folder:

```text
g20bis_monthly_topic_proportions.csv
macro_control_vars.xlsx
```

## Main Project Data Files

### `g20bis_monthly_topic_proportions.csv`

This file is a processed monthly topic-proportion dataset constructed from central bank speech texts.

The expected columns are:

```text
country
date
anchor
avg_proportion
```

In this project, topic anchors are grouped into five components:

```text
bank
govern
growth
market
other
```

### `macro_control_vars.xlsx`

This file is a compiled macroeconomic control workbook.

The main sheets used in the analysis are:

```text
realGDP
headlineInflation
usdExchangeRate
policyRate
```

These macroeconomic variables are merged with the topic-proportion data at the country-month level.

## Sample Files

This folder includes small synthetic sample files:

```text
sample_topic_proportions.csv
sample_macro_controls.csv
```

These files are only used to demonstrate the expected data structure. They are not the original project data and should not be used to reproduce the empirical results.

## Reproducibility Note

To reproduce the full analysis, place the full project datasets in this folder using the expected filenames:

```text
data/g20bis_monthly_topic_proportions.csv
data/macro_control_vars.xlsx
```

The R Markdown files should use relative paths such as:

```r
readr::read_csv("data/g20bis_monthly_topic_proportions.csv")
readxl::read_excel("data/macro_control_vars.xlsx", sheet = "realGDP")
```

Do not upload the full processed datasets to a public repository unless redistribution permission is explicitly granted.
