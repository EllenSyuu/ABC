# Reuses saved fits. No sampling. Does not replace upstream mdl_process().
source("scripts/_common.R")
bundle <- load_inputs()
outputs <- lapply(names(bundle$inputs), function(group) {
  path <- file.path(config$results_dir, paste0(group, "_fit.rds"))
  if (!file.exists(path)) stop("Missing fit: ", path)
  fit <- load_checked_fit(group, bundle$inputs[[group]])
  # recover_types() uses the original labelled inputs; do not substitute numeric IDs.
  abcR::mdl_process(bundle$inputs[[group]], fit)
})
checked <- audit_output(bind_rows(outputs), bundle$observed)
saveRDS(checked$full, file.path(config$results_dir, "ABC_output_4chains_full.rds"))
for (name in c("valid", "missing")) {
  clean <- checked[[name]] %>% select(-expected_missing, -actual_missing)
  write.csv(clean, file.path(config$reports_dir, paste0("ABC_output_4chains_",name,".csv")), row.names = FALSE)
}
write.csv(checked$coverage, file.path(config$reports_dir, "coverage.csv"), row.names = FALSE)
print(checked$coverage)
