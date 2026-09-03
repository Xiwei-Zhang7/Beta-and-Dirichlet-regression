# Compositional Modeling of Central Bank Communications

**Beta Regression, Dirichlet Regression, Penalized Smoothing, and G7 Country-Specific Modeling in R**

This repository contains an applied statistical modeling project on proportional and compositional data. The project studies how central-bank communication topics vary with macroeconomic conditions using monthly country-level topic proportions and macroeconomic indicators.

The analysis progresses from a single-response **Beta regression** baseline to joint **Dirichlet regression**, nonlinear **penalized-spline models**, and finally pooled versus country-specific modeling for the G7.

---

## Project Overview

Central-bank speeches can be represented as topic proportions. In this project, the response for each country-month is summarized by five topic components:

- `bank`
- `govern`
- `growth`
- `market`
- `other`

These components form a composition:

\[
y_{bank} + y_{govern} + y_{growth} + y_{market} + y_{other} = 1.
\]

This creates two important statistical issues:

1. each response component is bounded between 0 and 1;
2. the five components are dependent because they must sum to one.

A standard Gaussian linear model is therefore not well suited to the response structure.

The project compares methods designed specifically for proportional and compositional data.

---

## Research Question

The main research question is:

> How should central-bank topic shares be modeled when the outcome is either a single proportion or an entire multicomponent composition?

The analysis also investigates:

- whether macroeconomic variables are associated with changes in topic allocation;
- whether the COVID period represents a meaningful structural shift;
- whether nonlinear macroeconomic effects improve model fit;
- whether separate country-specific G7 models better describe national dynamics than a shared pooled model.

---

## Data

The empirical analysis combines two main sources of information.

### Topic Composition

Monthly topic proportions constructed from central-bank speech data are aggregated into five components:

```text
bank
govern
growth
market
other
```

The data are organized at the country-month level.

### Macroeconomic Variables

The main explanatory variables are:

```text
realGDP
headlineInflation
usdExchangeRate
policyRate
```

Quarterly real GDP is converted to monthly frequency before being merged with the remaining monthly macroeconomic variables.

The resulting modeling data set links the five-part topic composition with macroeconomic conditions for each country and month.

---

## Analysis Workflow

```text
Central-bank speech topic data
                │
                ▼
Construct five-part monthly composition
                │
                ▼
Macroeconomic data preprocessing
                │
                ▼
Country-month data integration
                │
                ▼
Beta regression baseline
                │
                ▼
Dirichlet regression
                │
                ▼
COVID-period model comparison
                │
                ▼
BIC-based model selection
                │
                ▼
Nonlinear penalized smoothing
                │
                ▼
Pooled G7 model
                │
                ▼
Country-specific G7 models
                │
                ▼
MAE / RMSE model evaluation
```

---

## Methodology

### 1. Data Preprocessing

The preprocessing pipeline:

- maps country codes to country names;
- aggregates topic shares to the country-month level;
- constructs the five-part composition;
- converts quarterly real GDP to monthly frequency;
- reads inflation, exchange-rate, and policy-rate data;
- merges topic and macroeconomic data;
- removes incomplete observations;
- normalizes compositional responses;
- applies small boundary adjustments to zero-valued components;
- standardizes predictors for nonlinear modeling.

The main processed objects are created in:

```text
R/1_data_preprocessing.R
```

---

### 2. Beta Regression Baseline

Beta regression is first used to model the `bank` topic share as a single continuous proportion.

The model uses macroeconomic predictors including:

\[
\text{realGDP},
\quad
\text{headlineInflation},
\quad
\text{usdExchangeRate},
\quad
\text{policyRate}.
\]

This provides a useful baseline for bounded proportional responses.

However, modeling only the `bank` component ignores the dependence among the remaining topic shares.

This motivates the transition to Dirichlet regression.

Implementation:

```text
R/2_beta_regression.R
```

---

### 3. Dirichlet Regression

Dirichlet regression models all five topic components jointly.

The response is

\[
\mathbf{Y}
=
(Y_{bank},
Y_{govern},
Y_{growth},
Y_{market},
Y_{other}),
\]

subject to

\[
\sum_{j=1}^{5}Y_j = 1.
\]

The baseline model uses:

```text
realGDP
headlineInflation
usdExchangeRate
policyRate
```

with `other` serving as the reference component in the alternative Dirichlet parameterization.

This allows macroeconomic variables to affect different parts of the topic composition differently.

Implementation:

```text
R/3_dirichlet_regression.R
```

---

### 4. COVID-Period Model Comparison

A COVID-period indicator is added to the baseline Dirichlet specification.

The macro-only model is compared against the macro + COVID model using a likelihood-ratio test.

The purpose is to evaluate whether the pandemic period represents an additional structural shift in central-bank topic allocation after controlling for macroeconomic conditions.

---

### 5. Model Selection

Model selection is performed using information criteria, with particular emphasis on **BIC**.

The analysis considers:

- forward variable selection;
- alternative linear specifications;
- nonlinear spline representations;
- penalized smooth macroeconomic effects.

BIC is emphasized because it imposes a stronger complexity penalty and helps balance model fit against unnecessary flexibility.

Implementation:

```text
R/4_model_selection.R
```

---

### 6. Nonlinear Modeling

Purely linear macroeconomic effects can be too restrictive.

The project therefore uses penalized spline terms to allow flexible nonlinear relationships while controlling excessive wiggliness.

The pooled nonlinear G7 model includes smooth effects for macroeconomic variables and country effects.

A country-by-policy-rate interaction is also investigated to allow monetary-policy relationships to differ across countries.

---

## G7 Country-Specific Modeling

The second major stage of the project compares a pooled G7 specification against separate models for:

```text
Canada
France
Germany
Italy
Japan
United Kingdom
United States
```

The country-specific analysis is particularly useful because the same numerical specification is not equally appropriate for every country.

### Final Country-Specific Specifications

| Country | Smooth Terms | `ps.int` | Special Treatment |
|---|---:|---:|---|
| Canada | 4 | 5 | Standard specification |
| France | 4 | 5 | Standard specification |
| Germany | 4 | 5 | Standard specification |
| Italy | 4 | 4 | Reduced spline complexity for numerical stability |
| Japan | 4 | 5 | Stronger response adjustment and `Maxit.outer = 400` |
| United Kingdom | 4 | 5 | Standard specification |
| United States | 3 | 6 | USD exchange rate excluded |

These adjustments illustrate practical issues that arise in applied statistical modeling, including:

- numerical convergence;
- spline complexity;
- limited within-country predictor variation;
- predictor identifiability;
- model flexibility versus computational feasibility.

Implementation:

```text
R/5_g7_models.R
```

---

## Model Evaluation

The pooled and country-specific models are evaluated using:

### Mean Absolute Error

\[
MAE
=
\frac{1}{n}
\sum_{i=1}^{n}
|y_i-\hat{y}_i|
\]

### Root Mean Squared Error

\[
RMSE
=
\sqrt{
\frac{1}{n}
\sum_{i=1}^{n}
(y_i-\hat{y}_i)^2
}
\]

Performance is evaluated both:

- across the complete five-part composition;
- separately for each topic component.

The evaluation workflow also generates country-level comparison plots showing:

```text
Observed
vs.
Pooled G7 model
vs.
Country-specific model
```

Implementation:

```text
R/6_model_evaluation.R
```

---

## Key Findings

### Composition-Aware Modeling

Beta regression provides a useful model for a single bounded topic share, but it does not account for the dependence created by the full five-part composition.

Dirichlet regression provides a more appropriate framework when all topic shares are modeled jointly.

### Macroeconomic Effects

The Dirichlet models indicate that macroeconomic variables are associated with systematic reallocations across topic components rather than affecting every topic in the same way.

### COVID Structural Effect

Adding a COVID-period indicator improves the likelihood-based specification, indicating that the pandemic period contains additional information about changes in topic allocation beyond the included macroeconomic controls.

### Nonlinear Relationships

Penalized smoothing provides additional flexibility relative to purely linear specifications and allows nonlinear macroeconomic relationships to be modeled while controlling excessive curve complexity.

### Country Heterogeneity

The G7 analysis shows substantial country-level heterogeneity.

Separate country-specific models provide greater flexibility for capturing national topic-composition dynamics, while also introducing additional computational and convergence challenges.

---

## G7 Observed vs. Fitted Comparison

The following result file compares the observed five-part topic composition against both the pooled G7 model and the country-specific models for all seven G7 countries:

**[View G7 Observed vs. Pooled vs. Country-Specific Comparison](results/figures/G7_5anchor_observed_multi_single_clean.pdf)**

The PDF contains one page for each G7 country and five panels per country:

```text
bank
govern
growth
market
other
```

Each panel compares:

```text
Observed
Multi-country
Single-country
```

This visualization provides a direct comparison of how the shared and country-specific models track the observed topic-composition dynamics.

---

## Repository Structure

```text
.
├── README.md
├── run_analysis.R
├── .gitignore
│
├── R/
│   ├── 1_data_preprocessing.R
│   ├── 2_beta_regression.R
│   ├── 3_dirichlet_regression.R
│   ├── 4_model_selection.R
│   ├── 5_g7_models.R
│   └── 6_model_evaluation.R
│
├── data/
│   ├── README.md
│   ├── sample_topic_proportions.csv
│   └── sample_macro_controls.csv
│
├── results/
│   ├── figures/
│   │   └── G7_5anchor_observed_multi_single_clean.pdf
│   └── tables/
│
├── presentation/
│   └── beta_dirichlet_project_presentation.pdf
│
└── archive/
    ├── exploratory_modeling.Rmd
    ├── original_g7_model.Rmd
    └── original_g7_comparison.Rmd
```

The original exploratory R Markdown files are retained in `archive/` for transparency, while the main analysis has been reorganized into modular R scripts.

---

## Running the Analysis

The complete workflow is organized through:

```text
run_analysis.R
```

From the repository root, run:

```r
source("run_analysis.R")
```

The runner executes:

```r
source("R/1_data_preprocessing.R")
source("R/2_beta_regression.R")
source("R/3_dirichlet_regression.R")
source("R/4_model_selection.R")
source("R/5_g7_models.R")
source("R/6_model_evaluation.R")
```

The workflow is intentionally sequential because later stages depend on objects created by earlier scripts.

---

## Main R Packages

The analysis uses packages including:

```text
dplyr
tidyr
readr
readxl
lubridate
stringr
purrr
zoo
betareg
DirichletReg
VGAM
splines
ggplot2
```

---

## Data Availability and Reproducibility

The complete processed project data are not included in this public repository because of data-access and redistribution restrictions.

The full analysis expects:

```text
data/g20bis_monthly_topic_proportions.csv
data/macro_control_vars.xlsx
```

Small synthetic sample files are included to document the expected data structure:

```text
data/sample_topic_proportions.csv
data/sample_macro_controls.csv
```

These sample files are intended for structural demonstration only and do **not** reproduce the empirical results reported in the project.

The full data should not be uploaded publicly unless redistribution permission is available.

Additional information is provided in:

```text
data/README.md
```

---

## Skills Demonstrated

This project demonstrates experience with:

- R programming
- statistical data analysis
- data cleaning and transformation
- multi-source data integration
- country-month panel construction
- proportional-response modeling
- compositional data analysis
- Beta regression
- Dirichlet regression
- maximum-likelihood modeling
- likelihood-ratio testing
- AIC and BIC model comparison
- forward model selection
- nonlinear regression
- natural splines
- penalized smoothing
- country effects and interactions
- model diagnostics
- numerical convergence troubleshooting
- predictor-identifiability assessment
- MAE and RMSE model evaluation
- observed-versus-fitted visualization
- reproducible analytical workflow design

---

## Project Presentation

A presentation deck summarizing the project motivation, methodology, model development, empirical findings, nonlinear modeling, and G7 analysis is included here:

**[Project Presentation](presentation/beta_dirichlet_project_presentation.pdf)**

---

## Archive

The `archive/` directory contains the original R Markdown development files:

```text
exploratory_modeling.Rmd
original_g7_model.Rmd
original_g7_comparison.Rmd
```

These files preserve the exploratory modeling process and earlier analysis workflow.

The primary portfolio-facing implementation is now contained in the modular scripts under `R/`.

---

## Author

**Xiwei Zhang**

Statistical modeling project focused on proportional and compositional responses, nonlinear regression, model selection, and country-specific quantitative analysis.
