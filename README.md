# Modeling Proportions and Compositions with Beta and Dirichlet Regression

This repository contains the R code for a final-year statistics project on **Beta regression** and **Dirichlet regression**. The project studies how proportional and compositional responses should be modeled when the outcome is bounded and when several components are constrained to sum to one.

The empirical application uses monthly country-level topic proportions constructed from central bank speeches. The response is a five-part topic composition:

- `bank`
- `govern`
- `growth`
- `market`
- `other`

The main explanatory variables are macroeconomic covariates observed at the same country-month level:

- real GDP
- headline inflation
- USD exchange rate
- policy rate
- COVID-period indicator

## Research Question

The main question is:

> How should topic shares be modeled when the response is either a single proportion or a full composition?

A standard Gaussian linear model is not ideal for this setting because the response is bounded and often heteroskedastic. When the response is a full composition, the components are also dependent because they must sum to one. This motivates two likelihood-based approaches:

- **Beta regression** for a single continuous proportion in `(0, 1)`;
- **Dirichlet regression** for a multicomponent response on the simplex.

## Methodology

The project includes the following steps:

1. **Data preparation**
   - Aggregate topic shares to the country-month level.
   - Construct a five-anchor composition: `bank`, `govern`, `growth`, `market`, and `other`.
   - Merge topic shares with macroeconomic covariates.
   - Adjust zero values to satisfy the support requirements of Beta and Dirichlet models.

2. **Baseline Beta regression**
   - Model the `bank` topic share as a single proportion.
   - Use a logit mean model with macroeconomic covariates.

3. **Baseline Dirichlet regression**
   - Model the full five-part topic composition jointly.
   - Use the alternative parameterization with `other` as the reference component.
   - Interpret coefficients on the baseline log-ratio scale.

4. **COVID model comparison**
   - Compare a macro-only Dirichlet model with a macro + COVID model.
   - Use likelihood-ratio testing to assess whether the COVID indicator improves model fit.

5. **Nonlinear smoothing and model selection**
   - Use spline-based and penalized-smoothing extensions to relax purely linear effects.
   - Compare candidate specifications using AIC and BIC.
   - Retain smooth macroeconomic effects when they improve model fit.

6. **G7 multi-country versus single-country comparison**
   - Compare a shared G7 model against separate country-specific models.
   - Evaluate fit using MAE and RMSE across the five composition components.

## Key Results

The simplified Beta regression example is useful for modeling one topic share, but it ignores the dependence among the remaining shares. Dirichlet regression is more appropriate when the goal is to model the full topic allocation jointly.

The baseline Dirichlet model suggests that macroeconomic covariates affect topic components differently. For example, policy rate is associated with changes in expected topic shares relative to the reference component.

Adding a COVID-period indicator improves model fit and captures a structural shift in topic allocation during the pandemic period.

The final nonlinear Dirichlet models show that purely linear specifications are too restrictive for this dataset. Penalized smoothing provides a more flexible way to model nonlinear macroeconomic effects while controlling excessive wiggliness.

For the G7 comparison, separate country-specific models achieve lower MAE and RMSE than the shared multi-country model for every G7 country. This suggests that country-specific modeling provides a better description of national topic-composition dynamics.

## Repository Structure

```text
.
├── README.md
├── .gitignore
├── G7 model.Rmd
├── New table.Rmd
├── g7_multi_single_compare.Rmd
└── data/
    ├── README.md
    ├── sample_topic_proportions.csv
    └── sample_macro_controls.csv
