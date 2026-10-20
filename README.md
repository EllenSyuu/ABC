> **Maintained fork of [AmeerD/ABC](https://github.com/AmeerD/ABC).**
> Original ABC methodology and software credit remain with the original authors.
> Changes by EllenSyuu (2026-10-20): migrate abcR's survey serialization dependency
> from qs to qs2, add explicit legacy-file diagnostics and regression tests.
> This derivative remains licensed under GPL-3.

## qs2 migration in this fork

Install this migration branch in R:

```r
install.packages("remotes")
remotes::install_github(
  "EllenSyuu/ABC", subdir = "abcR",
  ref = "fix/qs2-migration", upgrade = "never"
)
library(abcR)
```

The package now imports qs2 instead of qs. `agg_survey("example", ...)`
reads `data/example_prepped.qs2` relative to the working directory.
Save newly prepared surveys with:

```r
qs2::qs_save(prepped_data, "data/example_prepped.qs2")
```

### Existing .qs files

qs and qs2 formats are incompatible. Do not rename a .qs file to .qs2.
In a separate environment where the original qs package works, convert each file:

```r
old_data <- qs::qread("data/example_prepped.qs")
qs2::qs_save(old_data, "data/example_prepped.qs2")
new_data <- qs2::qs_read("data/example_prepped.qs2", validate_checksum = TRUE)
stopifnot(identical(old_data, new_data))
```

Retain the original files until conversion is verified. This fork does not require
qs for installation and does not silently read legacy files. External pipelines
that create `*_prepped.qs` must also update their writers. The supplied
`data/ABCtest.rda` uses R's own format and does not require conversion.

### Validation status

The migration changes file input, not statistical formulas or Stan models.
Regression tests in `abcR/tests/qs2-serialization.R` cover object preservation,
missing inputs, legacy-file diagnostics, file precedence and invalid input.

**Not yet runtime-validated:** the editing environment has no R executable.
Package installation, regression tests, R CMD check and end-to-end model
equivalence have not been run. This is a development branch, not a validated
release. After installing, run:

```r
source("abcR/tests/qs2-serialization.R") # from a local checkout's root
```

Original project documentation and paper attribution follow below.

---

# Adjusted Bayesian Completion Rates (ABC)

Sustainable Development Goal 4 Indicator 4.1.2, completion rates for primary, lower secondary, and upper secondary education, is defined as the "percentage of a cohort of children or young people aged 3-5 years above the intended age for the last grade of each level of education who have completed that grade." ([UIS](https://unstats.un.org/sdgs/metadata/files/Metadata-04-01-02.pdf)). Unlike enrolment, estimates of school completion rates require the use of household surveys, such as those perfomed by UNICEF Multiple Indicator Cluster Surveys ([MICS](https://mics.unicef.org/)) and The Demographic and Health Surveys Program ([DHS](https://dhsprogram.com/)). In our 2021 paper, [Adjusted Bayesian Completion Rates (ABC) Estimation](https://osf.io/preprints/socarxiv/at368/), we introduce the ABC model to produce the first complete set of estimates for Indicator 4.1.2 for 153 countries. The model estimates a latent random walk corresponding to the true completion rates while adjusting for a suite of topical data challenges including gaps between survey waves, conflicting estimates, age-misreporting, and delayed completion. Further model details can be found in the paper or by directly viewing the [model](https://github.com/AmeerD/ABC/tree/main/models/ABC_indep.stan). 

The purpose of this repository is to consolidate the school completion rate analysis pipeline and make it accessible to the public. We have collected all relevant functions and prepared the `abcR` package. It provides the necessary tools to excute the ABC model, and is divided into the following sections:
* Auxiliary functions used either throughout the pipeline, or in the raw data formatting and pre-processing.
* Modelling functions that prepare the cleaned raw data for model execution as well as model execution functions.
* Post-processing functions to digest the Stan output.
* Extraction functions to retrieve quantities of interest.
* Testing functions to assess performance.
* Aggregation functions to combine country level output into region or income group level output.
* Plotting functions for various visualisations.

In addition to the `abcR` package, the ABC Stan file is provided along with a sample dataset and test script to guide users in how to use the provided functions. For a more involved example, the [drake](https://github.com/ropensci/drake) plans used in the actual modelling pipeline are provided [here](https://github.com/AmeerD/ABC/tree/main/scripts/sample_plans.R).

## Package Installation

To install the `abcR` package, execute the following in R:
```r
remotes::install_github("EllenSyuu/ABC", subdir="abcR", ref="fix/qs2-migration")
library(abcR)
```

## Sample Data

We provide a sample dataset in the [data](https://github.com/AmeerD/ABC/tree/main/data) folder to illustrate the mechanisms of the model. Note that due to data sharing policies, the presented data contains ten anonymised countries and random noise has been added to all observed values. The magnitude of this error exceeds the sampling variation for a great majority of the data points. Readers may experiment with this data using the ABCtest.R script in the [scripts](https://github.com/AmeerD/ABC/tree/main/scripts) folder. 
