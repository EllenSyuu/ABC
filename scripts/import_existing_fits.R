# Import the already-completed user runs without sampling.
# IMPORTANT: old fits do not prove the original data/config identity. The user
# explicitly attests that these are the runs described in docs/validation_status.md.
# Example:
# source("scripts/import_existing_fits.R")
# import_existing_fits("results/validation_4chains", attest_same_example = TRUE)
source("scripts/_common.R")
import_existing_fits <- function(source_dir, attest_same_example = FALSE) {
  if (!isTRUE(attest_same_example)) stop("Explicit example-run attestation required; see README.")
  bundle <- load_inputs()
  identity <- list(config = config, data_md5 = md5(config$data_file),
    model_md5 = md5(config$model_file), packages = package_record(),
    R_version = R.version.string, functions = function_record())
  for (i in seq_along(bundle$inputs)) {
    group <- names(bundle$inputs)[i]
    src <- file.path(source_dir, paste0(group,"_fit.rds"))
    dst <- file.path(config$results_dir, paste0(group,"_fit.rds"))
    if (!file.exists(src)) stop("Missing source: ",src)
    if (file.exists(dst)) {
      meta_path <- file.path(config$results_dir, paste0(group,"_meta.rds"))
      if (!file.exists(meta_path) || md5(src) != md5(dst))
        stop("Existing destination differs or lacks metadata: ",dst)
      existing <- readRDS(meta_path)
      dat <- prepare_group(bundle$inputs[[group]])
      key <- c(identity,list(group = group,seed = config$seed + i,stan_data = dat))
      if (!identical(existing$key,key) || existing$fit_md5 != md5(dst))
        stop("Existing metadata/config differs: ",group)
      message("Already imported, unchanged: ",group)
      next
    }
    fit <- readRDS(src)
    dat <- prepare_group(bundle$inputs[[group]])
    if (!inherits(fit,"stanfit") || fit@sim$chains != config$chains) stop("Wrong fit/chains: ",group)
    dims <- fit@par_dims$mu_ct
    if (!identical(as.integer(dims), as.integer(c(dat$n_country,dat$nyears))))
      stop("Model dimensions do not match: ",group)
    check_args <- vapply(fit@stan_args, function(a)
      a$iter == config$iter && a$warmup == config$warmup && a$thin == config$thin, logical(1))
    if (!all(check_args)) stop("Stored sampling settings differ: ",group)
    if (!file.copy(src,dst,overwrite = FALSE)) stop("Copy failed: ",group)
    key <- c(identity,list(group = group,seed = config$seed + i,stan_data = dat))
    saveRDS(list(key = key, fit_md5 = md5(dst), original_stan_args = fit@stan_args,
      provenance = "imported_user_attested_not_independently_verified"),
      file.path(config$results_dir,paste0(group,"_meta.rds")))
  }
  message("Imported fits. Their original provenance is user-attested, not reconstructed.")
}
