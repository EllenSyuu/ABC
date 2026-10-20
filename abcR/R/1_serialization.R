# qs2 migration by EllenSyuu, 2026-10-20. Distributed under GPL-3.
# Internal reader: never interpret legacy qs bytes as qs2.
read_prepped_survey <- function(path) {
  if (!file.exists(path)) {
    legacy_path <- sub("\\.qs2$", ".qs", path)
    if (file.exists(legacy_path)) {
      stop(
        "Legacy qs file found: ", legacy_path,
        ". Convert it with qs::qread() and qs2::qs_save() in an environment ",
        "where qs works. Renaming the file is not a conversion. ",
        "See the repository README.",
        call. = FALSE
      )
    }
    stop("Preprocessed survey file not found: ", path, call. = FALSE)
  }
  qs2::qs_read(path, validate_checksum = TRUE)
}
