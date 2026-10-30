# Run scripts from the repository root. No user-specific absolute paths.
required <- c("abcR", "rstan", "StanHeaders", "dplyr", "ggplot2", "posterior",
              "tidybayes", "tidyr", "lubridate")
missing <- required[!vapply(required, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing)) stop("Missing packages: ", paste(missing, collapse = ", "))
if (!file.exists("config/run_config.R")) stop("Set working directory to repository root.")
source("config/run_config.R")
suppressPackageStartupMessages(library(dplyr))
if (as.character(packageVersion("abcR")) != config$expected_abcR_version)
  warning("abcR version differs from user-validated version; inspect internal functions.")
for (folder in c(config$results_dir, config$reports_dir))
  dir.create(folder, recursive = TRUE, showWarnings = FALSE)
md5 <- function(path) unname(tools::md5sum(path))
package_record <- function() {
  setNames(lapply(required, function(x) {
    z <- utils::packageDescription(x)
    z[intersect(names(z), c("Version", "RemoteSha", "RemoteRepo", "RemoteUsername"))]
  }), required)
}
function_record <- function() {
  setNames(lapply(c("mdl_prep", "mdl_joint_prep", "mdl_core", "mdl_process", "init_drift"),
    function(x) paste(deparse(get(x, asNamespace("abcR"))), collapse = "\n")),
    c("mdl_prep", "mdl_joint_prep", "mdl_core", "mdl_process", "init_drift"))
}
load_inputs <- function() {
  if (!file.exists(config$data_file)) stop(
    "Copy the original public ABCtest.rda into data/ABCtest.rda. See data/README.md.")
  env <- new.env(parent = baseenv())
  load(config$data_file, envir = env)
  if (!exists("test.dat", env, inherits = FALSE)) stop("No test.dat in data file.")
  df <- as.data.frame(env$test.dat)
  needed <- c("country", "variable", "sex", "survey", "year", "value", "se",
              "obsage", "recondist", "truage5mlt")
  if (!all(needed %in% names(df))) stop("Missing fields: ",
    paste(setdiff(needed, names(df)), collapse = ", "))
  if (anyNA(df[needed])) stop("Missing input values require explicit review.")
  numeric_fields <- c("year", "value", "se", "obsage", "recondist", "truage5mlt")
  for (field in numeric_fields)
    if (!is.numeric(df[[field]]) || any(!is.finite(df[[field]])))
      stop("Non-finite/non-numeric field: ", field)
  if (any(df$value <= 0 | df$value >= 1)) stop("Raw values must be strictly inside (0,1): qnorm/SE transform.")
  if (any(df$se <= 0)) stop("Non-positive SE requires review.")
  if (any(df$year != floor(df$year))) stop("Years must be integers.")
  if (any(!df$variable %in% c("prim", "lsec", "usec")) ||
      any(!df$sex %in% c("total", "male", "female"))) stop("Unexpected category.")
  # Preserve the original adjustment and row order used in the reference run.
  # This shift cannot accommodate both extremes within one group; fail explicitly.
  caps <- df %>% group_by(country, variable, sex) %>%
    summarise(upper = max(value), lower = min(value), .groups = "drop")
  if (any(caps$upper > config$cap & caps$lower < 1 - config$cap))
    stop("Both cap extremes crossed in one group: upstream shift needs methodological review.")
  caps <- caps %>% mutate(cap_adj = case_when(
    upper > config$cap ~ upper - config$cap,
    lower < 1 - config$cap ~ lower - (1 - config$cap), TRUE ~ 0)) %>%
    select(country, variable, sex, cap_adj)
  observed <- left_join(df, caps, by = c("country", "variable", "sex"))
  spec <- data.frame(group = c("pt","pm","pf","lt","lm","lf","ut","um","uf"),
    variable = rep(c("prim","lsec","usec"), each = 3),
    sex = rep(c("total","male","female"), 3))
  inputs <- setNames(lapply(seq_len(nrow(spec)), function(i)
    filter(observed, variable == spec$variable[i], sex == spec$sex[i])), spec$group)
  if (any(vapply(inputs, nrow, integer(1)) == 0L)) stop("An expected input group is empty.")
  list(observed = observed, inputs = inputs)
}
prepare_group <- function(df) {
  dat <- get("mdl_prep", asNamespace("abcR"))(df)
  dat$nyears <- as.integer(config$latent_end_year - (min(df$year) - 1L))
  if (dat$nyears < max(dat$year) || dat$nyears < 2L) stop("Invalid latent horizon.")
  if (any(!is.finite(dat$value)) || any(!is.finite(dat$se_q2))) stop("Non-finite transformed data.")
  if (any(dat$se_q2 <= 0)) stop("Invalid transformed SE.")
  # Stan assumes survey IDs form consecutive country-specific blocks.
  if (sum(dat$survey_count) != dat$n_survey) stop("Survey counts do not match n_survey.")
  if (!setequal(dat$country, seq_len(dat$n_country)) ||
      !setequal(dat$survey, seq_len(dat$n_survey))) stop("Non-contiguous IDs.")
  for (i in seq_len(dat$n_country)) {
    ends <- cumsum(dat$survey_count)
    start <- if (i == 1L) 1L else ends[i-1L] + 1L
    if (!setequal(unique(dat$survey[dat$country == i]), seq.int(start, ends[i])))
      stop("Survey IDs not arranged by country; stop rather than silently remap.")
  }
  dat
}
expected_constants <- function(dat) c(
  sprintf("late_short2[%d]", sum(dat$haslate2) + 1L),
  sprintf("vlate_short2[%d]", sum(dat$hasvlate2) + 1L),
  sprintf("late[%d]", which(dat$haslate2 == 0)),
  sprintf("vlate[%d]", which(dat$hasvlate2 == 0)),
  sprintf("beta_s[%d]", cumsum(dat$survey_count)[dat$survey_count == 1]))
check_fit <- function(fit, dat, group) {
  if (!inherits(fit, "stanfit") || fit@mode != 0L) stop("Not a sampled stanfit.")
  ds <- posterior::summarise_draws(posterior::as_draws_array(as.array(fit)),
    "mean", "sd", "rhat", "ess_bulk", "ess_tail", "mcse_mean")
  constants <- ds %>% filter(is.finite(sd), sd == 0)
  unexplained <- constants %>% filter(!variable %in% expected_constants(dat) | mean != 0)
  flags <- ds %>% filter(!(is.finite(sd) & sd == 0)) %>% filter(
    !is.finite(rhat) | rhat >= config$rhat_limit |
    !is.finite(ess_bulk) | ess_bulk < config$ess_limit |
    !is.finite(ess_tail) | ess_tail < config$ess_limit)
  sp <- rstan::get_sampler_params(fit, inc_warmup = FALSE)
  bfmi <- vapply(sp, function(x) mean(diff(x[,"energy__"])^2)/var(x[,"energy__"]), numeric(1))
  actual_thin <- vapply(fit@stan_args, function(x) as.integer(x$thin), integer(1))
  divergences <- sum(vapply(sp, function(x) sum(x[,"divergent__"]), numeric(1)))
  depth <- sum(vapply(sp, function(x) sum(x[,"treedepth__"] >= config$max_treedepth), numeric(1)))
  summary <- data.frame(group = group, chains = length(sp), divergences = divergences,
    treedepth_hits = depth, constant_quantities = nrow(constants),
    unexplained_constants = nrow(unexplained), flagged_quantities = nrow(flags),
    min_energy_ratio_retained = min(bfmi),
    full_transition_energy_available = all(actual_thin == 1L),
    numerical_screen_pass = length(sp) == config$chains && divergences == 0 && depth == 0 &&
      nrow(flags) == 0 && nrow(unexplained) == 0)
  for (x in c("diagnostics", "constants", "flagged")) {
    obj <- switch(x, diagnostics = ds, constants = constants, flagged = flags)
    write.csv(as.data.frame(obj), file.path(config$reports_dir, paste0(group,"_",x,".csv")), row.names = FALSE)
  }
  write.csv(data.frame(chain = seq_along(bfmi), energy_ratio_retained = bfmi,
    thin = actual_thin), file.path(config$reports_dir, paste0(group,"_energy.csv")), row.names = FALSE)
  summary
}
audit_output <- function(out, observed) {
  keys <- c("country", "variable", "sex", "year", "series")
  if (anyDuplicated(out[keys])) stop("Duplicate output keys.")
  actual_keys <- distinct(out, country, variable, sex)
  source_keys <- distinct(observed, country, variable, sex)
  if (nrow(anti_join(actual_keys, source_keys, by = c("country","variable","sex"))) ||
      nrow(anti_join(source_keys, actual_keys, by = c("country","variable","sex"))))
    stop("Output country/category labels differ from input.")
  out <- out %>% mutate(expected_missing = series == "projected3t5" &
    year > config$latent_end_year - 2L,
    actual_missing = !is.finite(value) | !is.finite(lower) | !is.finite(upper))
  if (any(out$expected_missing != out$actual_missing)) stop("Unexpected missingness pattern.")
  valid <- filter(out, !actual_missing)
  if (any(valid$value < 0 | valid$value > 1 | valid$lower < 0 |
          valid$upper > 1 | valid$lower > valid$upper)) stop("Invalid output ranges.")
  # Confirm each country/category/series has every expected year, not just valid endpoints.
  start <- observed %>% group_by(variable, sex) %>% summarise(start = min(year), .groups = "drop")
  coverage <- valid %>% group_by(country, variable, sex, series) %>%
    summarise(first_year = min(year), last_year = max(year), n_years = n_distinct(year), .groups = "drop") %>%
    left_join(start, by = c("variable","sex")) %>%
    mutate(expected_end = config$latent_end_year - ifelse(series == "projected3t5", 2L, 0L))
  if (any(coverage$first_year != coverage$start | coverage$last_year != coverage$expected_end |
      coverage$n_years != coverage$expected_end - coverage$start + 1L)) stop("Incomplete year coverage.")
  list(full = out, valid = valid, missing = filter(out, actual_missing), coverage = coverage)
}

load_checked_fit <- function(group, df) {
  path <- file.path(config$results_dir,paste0(group,"_fit.rds"))
  meta_path <- file.path(config$results_dir,paste0(group,"_meta.rds"))
  if (!file.exists(path) || !file.exists(meta_path)) stop("Missing fit/metadata: ",group)
  meta <- readRDS(meta_path)
  key <- meta$key
  if (meta$fit_md5 != md5(path) || !identical(key$config,config) ||
      key$data_md5 != md5(config$data_file) || key$model_md5 != md5(config$model_file) ||
      !identical(key$stan_data,prepare_group(df)) ||
      !identical(key$packages,package_record()) ||
      !identical(key$functions,function_record()) || key$R_version != R.version.string)
    stop("Fit/data/model/environment/config mismatch: ",group,
         ". Keep the original run; select a separate results directory for changes.")
  readRDS(path)
}
