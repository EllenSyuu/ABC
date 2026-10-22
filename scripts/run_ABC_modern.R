# Fresh session, repository root: source("scripts/run_ABC_modern.R")
source("scripts/_common.R")
bundle <- load_inputs()
functions <- function_record()
identity <- list(config = config, data_md5 = md5(config$data_file),
  model_md5 = md5(config$model_file), packages = package_record(),
  R_version = R.version.string, functions = functions)
writeLines(capture.output(sessionInfo()), file.path(config$reports_dir, "sessionInfo.txt"))
saveRDS(identity, file.path(config$results_dir, "run_identity.rds"))
writeLines(unlist(Map(function(n, x) c(paste0("# ",n), x, ""), names(functions), functions)),
  file.path(config$reports_dir, "abcR_functions.txt"))
model <- NULL
summaries <- list()
init_fun <- get("init_drift", asNamespace("abcR"))
for (i in seq_along(bundle$inputs)) {
  group <- names(bundle$inputs)[i]
  df <- bundle$inputs[[group]]
  dat <- prepare_group(df)
  key <- c(identity, list(group = group, seed = config$seed + i, stan_data = dat))
  fit_path <- file.path(config$results_dir, paste0(group,"_fit.rds"))
  meta_path <- file.path(config$results_dir, paste0(group,"_meta.rds"))
  if (file.exists(fit_path)) {
    if (!file.exists(meta_path)) stop("Cached fit lacks metadata: ", group)
    meta <- readRDS(meta_path)
    if (!identical(meta$key, key) || !identical(meta$fit_md5, md5(fit_path)))
      stop("Cache mismatch for ",group,". Use a new results_dir; do not overwrite old runs.")
    message("Reading cached fit: ", group, " [",meta$provenance,"]")
    fit <- readRDS(fit_path)
  } else {
    if (is.null(model)) model <- rstan::stan_model(file = config$model_file, verbose = TRUE)
    set.seed(config$seed + i)
    inits <- lapply(seq_len(config$chains), function(j)
      init_fun(dat$n_country, dat$nyears, !is.null(dat$mprop)))
    message("Sampling group: ",group)
    fit <- rstan::sampling(model, data = dat, chains = config$chains,
      chain_id = seq_len(config$chains), cores = config$cores,
      seed = config$seed + i, init = inits, warmup = config$warmup,
      iter = config$iter, thin = config$thin,
      control = list(adapt_delta = config$adapt_delta, max_treedepth = config$max_treedepth),
      refresh = 500)
    saveRDS(fit, fit_path)
    saveRDS(list(key = key, fit_md5 = md5(fit_path), init = inits,
      provenance = "generated_by_this_workflow"), meta_path)
  }
  summaries[[group]] <- check_fit(fit, dat, group)
  write.csv(bind_rows(summaries), file.path(config$reports_dir,"validation_summary.csv"), row.names = FALSE)
  rm(fit); gc(verbose = FALSE)
}
print(bind_rows(summaries))
source("scripts/process_results.R")
source("scripts/plot_results.R")
message("Finished. Read reports/generated/validation_summary.csv and coverage.csv.")
