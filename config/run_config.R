# Explicit configuration; do not use Sys.Date() to choose model dimensions.
config <- list(
  data_file = "data/ABCtest.rda",
  model_file = "models/ABC_indep_modern.stan",
  results_dir = "results/reproduction",
  reports_dir = "reports/generated",
  latent_end_year = 2031L,
  plot_end_year = 2021L,
  cap = 0.98,
  chains = 4L,
  warmup = 5000L,
  iter = 10000L,
  thin = 5L,
  seed = 20261022L,
  cores = 1L,
  adapt_delta = 0.9,
  max_treedepth = 12L,
  rhat_limit = 1.01,
  ess_limit = 400,
  expected_abcR_version = "0.1.0.9000"
)
