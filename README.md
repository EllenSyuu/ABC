# ABC completion-rate model: reproduction workflow

Reproducible execution and sampling diagnostics for the public Adjusted Bayesian
Completion Rates (ABC/ABCR) example, associated with SDG 4.1.2.

This is an **overlay/workflow**, not a new statistical model, an R package, or a
validated replacement for the current UIS production pipeline. Original model
and abcR authors: Bilal Barakat and Ameer Dharamshi; upstream repository:
https://github.com/AmeerD/ABC. Preserve upstream attribution and GPL-3 licensing.
The model blob used here is recorded in `docs/upstream_model.json`.

## What is included

- Original Stan model and an array-syntax-only modernised copy.
- Scripts that create all objects in a fresh R session; no Console history needed.
- Nine education-level/sex groups, four chains per group, fixed seeds and horizon.
- Resume checks based on configuration, model/data MD5, package/function records
  and saved-fit MD5. A mismatch stops execution; choose a new results directory.
- Rank-normalised Rhat, bulk/tail ESS, HMC count checks, explained-constant checks.
- Retained-energy ratios explicitly labelled as limited when thinning is used.
- Upstream post-processing, boundary/range/key checks, separate missing-data output,
  and country figures generated specifically from the four-chain fits.

## Files you must supply

1. Installed, working `abcR`, RStan and other dependencies in `_common.R`.
2. Original public `data/ABCtest.rda` from your existing upstream checkout.
   The ZIP does not include this dataset or abcR source.
3. Optionally the already-completed `*_fit.rds` files to avoid re-running MCMC.

Merge these files into the **repository root**, not `abcR/R/`. Keep existing
`abcR/`, `data/`, `docs/`, original `scripts/ABCtest.R`, and upstream LICENSE.
This README is suitable as the root README of your reproduction fork. If you want
to retain the upstream root README unchanged, save this as REPRODUCTION.md and link it.
Keep a copy before replacing an existing README; do not delete unrelated files.

## Working environment reported by the user

Windows 11; R 4.6.1; abcR 0.1.0.9000; rstan 2.39.0.9000;
StanHeaders 2.39.1; posterior 1.7.0; dplyr 1.2.1; ggplot2 4.0.3;
tidybayes 3.0.7; tidyr 1.3.2; lubridate 1.9.5.
This is an environment record, **not a dependency lockfile**. Do not update a
working environment just to run this bundle. Generate `renv.lock` locally with
`scripts/snapshot_environment.R` if renv is available. Save abcR's RemoteSha or its
source checkout: a development version number alone does not identify its code.
No installation commands execute automatically. The structural checks are conservative:
an unsupported input stops for review rather than implying the model is unusable.

## Run from a fresh R session

Set RStudio working directory to this repository root using Session > Set Working
Directory > Choose Directory. First:

```r
source("scripts/check_setup.R")
```

### Option A: reuse your completed four-chain runs (recommended here)

Keep your old `results/validation_4chains/` folder in this project. Import only if
these are the exact anonymised-example runs discussed in the validation record:

```r
source("scripts/import_existing_fits.R")
import_existing_fits("results/validation_4chains", attest_same_example = TRUE)
source("scripts/validate_ABC.R")
source("scripts/process_results.R")
source("scripts/plot_results.R")
```

Import checks dimensions and sampling settings, but cannot reconstruct which input
bytes produced a historical fit. Provenance remains explicitly user-attested. It
does not upgrade the old runs into independently verified fresh-session evidence.
Do not import unrelated fits just because dimensions happen to match.

### Option B: execute a new, self-recording run

```r
source("scripts/run_ABC_modern.R")
```

This compiles once and samples nine groups. Four chains run sequentially by default.
After interruption rerun the same command. An already-saved fit must have matching
metadata and MD5. Change results_dir/reports_dir for a genuinely different run.

### Rebuild outputs without sampling

```r
source("scripts/validate_ABC.R")
source("scripts/process_results.R")
source("scripts/plot_results.R")
```

## Configuration and year coverage

Edit `config/run_config.R` before starting a new run. The default matches the user's
completed validation: 5000 warmup + 5000 sampling transitions, thin=5, four chains,
adapt_delta=0.9, max_treedepth=12, latent end year 2031. Seeds are explicitly stored.
Upstream preparation uses Sys.Date() for its horizon; this workflow overrides the
returned nyears before initialisation and sampling.

Upstream `mdl_process()` uses lead(mu_ct,1) and lead(mu_ct,2). Therefore the default
valid projected3t5 series ends in 2029; projected5/projected8 end in 2031. Missing
2030/2031 projected3t5 records are retained separately, not filled with zero and not
silently discarded. For projected3t5 through year T, the latent horizon must extend
to T+2. Extending that horizon is a new model run, not a post-processing repair.
Future years are model extrapolations, not new observed data. Figures default to 2021.

The upstream function applies pnorm, restores cap_adj, clips to [0,1], averages
three age-specific draws for projected3t5, and calls point_interval(.width=0.9).
This bundle preserves that implementation instead of reinterpreting its interval
or point-estimate defaults. Exact defaults remain tied to the installed tidybayes
version. Output estimates are rounded to four decimals by upstream code.
Country/category membership checks do not independently prove every index mapping;
full mapping and methodological parity with production remain review items.

## Results

- `results/reproduction/`: complete fits, metadata and full output RDS; local only.
- `reports/generated/`: actual newly computed diagnostics, valid/missing CSVs,
  coverage, environment/function records and four-chain figures; ignored by default.
- `reports/user_reported/`: explicitly labelled summary transcribed from the user's
  completed run; not generated by executing this newly assembled bundle.

For GitHub, inspect and copy selected generated small reports into
`reports/reviewed/`, which is not ignored. Never commit raw fits by accident.
Expected example counts per sex: primary/lower secondary each 9 countries x 48
valid projected3t5 years = 432 rows; upper secondary 10 x 48 = 480. Other series
have 50 years per country. IHC has upper-secondary data only.

## Acceptance scope

Numerical screening is necessary, not sufficient. The user's completed runs had
zero divergence/depth counts and no nonconstant Rhat >=1.01 or ESS <400 flags.
Constants were explained by model constraints; 168 missing output records were
exactly expected terminal records. Energy ratios were calculated after thin=5,
so full-transition E-BFMI has not been established by those ratios.
For full-transition diagnostics, use thin=1 in a separate new run if required;
do not rerun merely to inflate evidence.

Remaining work before production: verify preprocessing including SE transformation
and cap rules, complete index-mapping/methodology review, posterior predictive and
held-out validation using appropriate data, compare production version/settings,
and agree the intended release horizon. Input checks fail on unsupported cases
rather than silently changing the upstream statistical method.

## Validation of this code bundle

The earlier workflow was executed on the user's machine. This newly assembled
bundle has been structurally inspected and its modern model mechanically compared
with the original; it has **not been run end-to-end here**, because this environment
has no R installation or ABCtest.rda. Run check_setup.R and the import/output route
in your working environment. Do not describe this bundle as fully validated until
that fresh-session run succeeds. See docs/validation_status.md.

## Reference

Dharamshi et al. (2022), A Bayesian model for estimating Sustainable Development
Goal indicator 4.1.2: School completion rates. JRSS Series C, 71(5), 1822-1864.
https://doi.org/10.1111/rssc.12595

Code is distributed under GPL-3; see LICENSE.md and NOTICE.md.
