# Re-run with abcR 0.2.0 — 2026-10-26

Full re-run of the anonymised example (`ABCtest.rda`) using only package
functions (`split_abc_groups()` → `abc_run_groups()`), compared with the earlier
four-chain validation run (`ABC_output_4chains_valid.csv`, 2026-10-22).

**Setup:** Ubuntu 24.04, R 4.3.3, rstan 2.32.5 (Stan 2.32.2), packaged
`inst/stan/ABC_indep.stan`. Same settings as the earlier run: 4 chains,
5000 warm-up + 5000 sampling, thin 5, adapt_delta 0.9, max_treedepth 12,
end_year 2031, base seed 20261022 (group i uses seed + i, inits drawn after
`set.seed(seed + i)`). Run time ≈ 2 h on 2 cores.

## Stan data
`mdl_prep(..., end_year = 2031)` returns exactly the saved Stan data of the
earlier run for all 8 groups available (pm, pf, lt, lm, lf, ut, um, uf); in um
and uf one `se_q2` value differs by ≤ 1.1e-16 (floating point across R versions).

## Sampling diagnostics (`abcR_0.2.0_diagnostics.csv`)
All 9 groups pass: 0 divergences, 0 tree-depth hits, max Rhat 1.0099,
min bulk ESS 720, min tail ESS 1324, constants (10, 11, 10, 5, 6, 5, 2, 2, 2) all
explained by the model, same as the earlier run. Retained-draw energy ratios
0.51–0.84 (thin = 5, so not full-transition E-BFMI).

## Agreement with the earlier run (`abcR_0.2.0_vs_previous_4chain.csv`)
- Same 12,432 valid and 168 missing rows; missing keys identical
  (projected3t5 in 2030–2031, as expected).
- Mean |difference| 0.00058; 99.4% of estimates within 0.005; max 0.021.
- Differences are ≤ 3.7% of the 90% interval width (median 0.6%); every earlier
  point estimate lies inside the new 90% interval.
- The largest differences are in the earliest back-cast years (e.g. CFI primary
  male 1982, 18 years before its first survey, interval 0.17–1.00).
- For reference, the earlier 1-chain and 4-chain runs differ by mean 0.0009,
  max 0.013 (fewer draws in the 1-chain run).

Draws are not bit-identical because the Stan/compiler versions differ; the
differences are of Monte Carlo size. Conclusion: the 0.2.0 package reproduces the
earlier results. This is a reproducibility check only; it is not a validation
against UIS published figures, which requires real-country inputs.
