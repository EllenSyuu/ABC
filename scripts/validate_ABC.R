# Read-only with respect to fits: no compilation or sampling.
source("scripts/_common.R")
bundle <- load_inputs()
summaries <- lapply(names(bundle$inputs), function(group) {
  path <- file.path(config$results_dir, paste0(group, "_fit.rds"))
  if (!file.exists(path)) stop("Missing fit: ", path)
  fit <- load_checked_fit(group, bundle$inputs[[group]])
  check_fit(fit, prepare_group(bundle$inputs[[group]]), group)
})
validation_table <- bind_rows(summaries)
write.csv(validation_table, file.path(config$reports_dir, "validation_summary.csv"), row.names = FALSE)
print(validation_table)
