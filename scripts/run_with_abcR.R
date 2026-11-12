# Full ABC run using only abcR >= 0.2.0 functions. Run from a fresh R session
# in the repository root:  source("scripts/run_with_abcR.R")
# Install the package first:  install.packages("abcR", repos = NULL, type = "source")
#   (or devtools::install("abcR")).
library(abcR)

end_year   <- 2031      # last latent year; projected3t5 then ends in 2029
output_dir <- "results/abcR_0.2.0"   # fits + metadata; reruns resume from here

inputs <- split_abc_groups(abc_example_data(), cap = 0.98)
# For real data replace abc_example_data() with your own data frame, e.g.
#   inputs <- split_abc_groups(readRDS("data/my_input.rds"))

model <- mdl_compile()  # packaged modern-syntax Stan model
run <- abc_run_groups(inputs, model = model, end_year = end_year,
                      chains = 4, warmup = 5000, iter = 5000, thin = 5,
                      seed = 20261022, cores = 4, output_dir = output_dir)

print(run$diagnostics)   # every row should have pass == TRUE
write.csv(run$diagnostics, file.path(output_dir, "diagnostics.csv"), row.names = FALSE)
write.csv(run$output, file.path(output_dir, "ABC_output.csv"), row.names = FALSE)
