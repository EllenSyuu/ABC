# Validation status — 2026-10-22

## Reference run (interactive session; not yet re-run from these scripts)

Nine groups pt/pm/pf/lt/lm/lf/ut/um/uf, four chains each, iter=10000,
warmup=5000, thin=5, adapt_delta=.9, max_treedepth=12. Each retained 4000
post-warmup draws across chains. All groups reported zero divergences, depth hits,
and nonconstant diagnostic flags (Rhat >=1.01, bulk/tail ESS <400 or nonfinite).
Constant counts: 10,11,10,5,6,5,2,2,2. The subsequent structural check found zero
unexplained constants in every group. Retained-energy ratios ranged from
0.5572152 to 0.8987252. These are not full-transition E-BFMI because thin=5.

Output contained 168 missing records, all projected3t5 in 2030/2031; no unexpected
missingness. No out-of-range bounds/estimates or reversed intervals were reported.
Four-chain post-processing was subsequently run; valid coverage ended in 2029 for
projected3t5 and 2031 for projected5/projected8. Nine primary/lower-secondary and
ten upper-secondary countries, including IHC only for upper secondary.

## Limits of the evidence

Complete fit files, data, diagnostic tables and the installed abcR source are not
published for independent inspection. Results above are transcribed from the
reference run. The scripts in this repository consolidate, but are not byte-for-byte
copies of, the code used in that session, so their extra input/cache checks still
require a local run.
No predictive accuracy, full country-index mapping, prior sensitivity or UIS
production equivalence has been established. Sampling diagnostics do not validate
model assumptions. Public data are anonymised and noise-perturbed.

## Suggested next acceptance checks

1. Fresh session: check_setup.R; import completed fits; validate/process/plot.
2. Compare regenerated values to prior four-chain CSVs on all country/year keys.
3. Archive the actual environment lock/source commit and generated metadata.
4. Review input transformations and country/survey index mapping.
5. Validate against appropriate held-out data and the intended production workflow.
