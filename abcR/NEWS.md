# abcR 0.2.0

## Runs on current R / Stan

* Survey serialisation uses **qs2** instead of the archived **qs** package
  (`read_prepped_survey()` refuses legacy `.qs` files instead of misreading them).
* The ABC independent model now ships with the package (`inst/stan/ABC_indep.stan`,
  path via `abc_model_file()`), written with `array[]` declarations so it compiles
  under Stan >= 2.33, where the old `int x[n]` syntax was removed. The statistical
  model is unchanged.
* `mdl_compile()` compiles the packaged model by default and also accepts a file
  path or Stan code (the old `mdl_compile(readLines(file))` call still works).

## Reproducibility fixes

* `mdl_prep()` gains `end_year`. Previously the latent horizon was
  `year(Sys.Date()) + 5`, so the same data gave models of different size depending
  on the day it was run. Without `end_year` the old behaviour is kept, with a message.
* `mdl_core()` / `mdl_run()` now support several chains in one call (previously
  only one init list was passed, so `nchains > 1` failed), draw initial values
  from a stated seed (`init_seed`, new `mdl_draw_inits()`), and expose `seed`,
  `cores`, `adapt_delta`, `max_treedepth` and `refresh`. Defaults reproduce the old
  settings (seed 2019, adapt_delta 0.9, max_treedepth 12). The inits used are kept
  in `attr(fit, "abc_init")`.

## New workflow functions (previously typed in the console)

* `abc_example_data()` - the public anonymised test data (`inst/extdata`).
* `add_cap_adj()` - the cap adjustment from the upstream example script, which
  `mdl_prep()`/`mdl_process()` require but the package never created; it stops if
  a group crosses both caps.
* `split_abc_groups()` - input checks, cap adjustment and the nine level/sex groups.
* `check_abc_input()`, `mdl_check_data()` - input and Stan-data checks, including
  the survey-block ordering the Stan model relies on.
* `mdl_diagnose()`, `mdl_expected_constants()` - Rhat, bulk/tail ESS, divergences,
  tree-depth hits, and a check that zero-variance quantities are exactly the ones
  fixed by the model.
* `abc_run_groups()` - prepare, sample, process and diagnose all groups, with
  saved fits and safe resume.
* `read_uis_cr()`, `compare_uis()` - compare estimates with completion rates from a
  UIS bulk data download. `compare_runs()` - compare two runs.

## Bug fixes

* `get_nsvar()`, `test_abc2()`, `mdl_test()`, `test_cov()` called `pivot_wider()`
  / `replace_na()` without importing them and failed at run time.
* `posterior` is now declared in Imports; unused `readr` removed.
  `R CMD check` passes with no warnings or notes.
