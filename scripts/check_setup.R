source("scripts/_common.R")
bundle <- load_inputs()
for (group in names(bundle$inputs)) {
  dat <- prepare_group(bundle$inputs[[group]])
  cat(group, ": countries=", dat$n_country, ", surveys=", dat$n_survey,
      ", latent years=", dat$nyears, "\n", sep = "")
}
rstan::stanc(file = config$model_file)
cat("Input checks and Stan parsing completed; no C++ compile or MCMC performed.\n")
