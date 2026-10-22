# Optional: run only in the confirmed working environment. Does not install/update packages.
source("scripts/_common.R")
if (!requireNamespace("renv", quietly = TRUE)) stop("Install renv separately if an exact lockfile is required.")
# This directory's real dependency resolution is recorded, not fabricated from a chat transcript.
renv::snapshot(packages = required, lockfile = "renv.lock", prompt = FALSE)
