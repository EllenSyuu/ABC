# Comparison with published UIS figures. Added in abcR 0.2.0 (EllenSyuu fork).
# Distributed under GPL-3.

#' Read completion rates from a UIS bulk data download.
#'
#' Reads the national-data and label CSV files of a UIS Bulk Data Download
#' Service (BDDS) SDG 4 release and keeps the completion-rate indicators,
#' mapped to the \code{variable}/\code{sex} coding used by abcR. Column names
#' are matched case-insensitively (\code{INDICATOR_ID}, \code{COUNTRY_ID},
#' \code{YEAR}, \code{VALUE}; labels: \code{INDICATOR_ID},
#' \code{INDICATOR_LABEL_EN}).
#'
#' Indicators are selected from their English labels: the label must match
#' \code{label_pattern} and name exactly one level (primary / lower secondary /
#' upper secondary) and one sex (female / male / both sexes). Always inspect the
#' \code{indicator_label} column of the result: UIS releases may contain more than
#' one completion-rate series (e.g. survey-based and model-based), and only the
#' one produced by the ABC model is a like-for-like comparison. Use
#' \code{label_pattern} or \code{indicator_ids} to restrict the selection.
#'
#' @param data_file Path to the national data CSV (e.g. \code{SDG_DATA_NATIONAL.csv}).
#' @param label_file Path to the indicator label CSV (e.g. \code{SDG_LABEL.csv}).
#' @param label_pattern Regular expression (case-insensitive) a label must match.
#' @param indicator_ids Optional character vector restricting indicator ids.
#'
#' @return Data frame with \code{country} (ISO3), \code{year}, \code{variable},
#'   \code{sex}, \code{uis_value} (proportion, 0-1), \code{indicator_id},
#'   \code{indicator_label}.
#' @export
read_uis_cr <- function(data_file, label_file, label_pattern = "completion rate",
                        indicator_ids = NULL) {
  lower_names <- function(x) { names(x) <- tolower(names(x)); x }
  labels <- lower_names(utils::read.csv(label_file, stringsAsFactors = FALSE,
                                        check.names = FALSE, encoding = "UTF-8"))
  lab_col <- intersect(c("indicator_label_en", "indicator_label", "label"), names(labels))[1]
  if (is.na(lab_col) || !"indicator_id" %in% names(labels))
    stop("Label file needs INDICATOR_ID and INDICATOR_LABEL_EN columns.", call. = FALSE)
  lab <- data.frame(indicator_id = labels$indicator_id,
                    indicator_label = labels[[lab_col]], stringsAsFactors = FALSE)
  lab <- lab[grepl(label_pattern, lab$indicator_label, ignore.case = TRUE), ]
  if (!is.null(indicator_ids)) lab <- lab[lab$indicator_id %in% indicator_ids, ]
  lab$variable <- uis_match_one(lab$indicator_label, c(
    prim = "\\bprimary", lsec = "lower secondary", usec = "upper secondary"))
  lab$sex <- uis_match_one(lab$indicator_label, c(
    female = "\\bfemale", male = "\\bmale", total = "both sexes"))
  lab <- lab[!is.na(lab$variable) & !is.na(lab$sex), ]
  # Exclude labels that carry further breakdowns (location, wealth, ...).
  extra <- "rural|urban|quintile|wealth|adjusted|parity|location|disabilit"
  lab <- lab[!grepl(extra, lab$indicator_label, ignore.case = TRUE), ]
  if (!nrow(lab)) stop("No completion-rate indicators matched.", call. = FALSE)
  dup <- duplicated(lab[c("variable", "sex")]) | duplicated(lab[c("variable", "sex")], fromLast = TRUE)
  if (any(dup)) {
    warning("More than one indicator per level/sex matched; narrow with ",
            "`label_pattern` or `indicator_ids`:\n",
            paste(lab$indicator_id[dup], lab$indicator_label[dup], sep = ": ", collapse = "\n"),
            call. = FALSE)
  }
  dat <- lower_names(utils::read.csv(data_file, stringsAsFactors = FALSE,
                                     check.names = FALSE))
  need <- c("indicator_id", "country_id", "year", "value")
  if (!all(need %in% names(dat)))
    stop("Data file needs columns: ", paste(toupper(need), collapse = ", "), call. = FALSE)
  dat <- dat[dat$indicator_id %in% lab$indicator_id, need]
  out <- merge(dat, lab, by = "indicator_id")
  data.frame(country = out$country_id, year = as.integer(out$year),
             variable = out$variable, sex = out$sex,
             uis_value = as.numeric(out$value) / 100,
             indicator_id = out$indicator_id, indicator_label = out$indicator_label,
             stringsAsFactors = FALSE)
}

uis_match_one <- function(x, patterns) {
  hits <- vapply(patterns, function(p) grepl(p, x, ignore.case = TRUE), logical(length(x)))
  hits <- matrix(hits, nrow = length(x))
  res <- rep(NA_character_, length(x))
  one <- rowSums(hits) == 1
  res[one] <- names(patterns)[max.col(hits[one, , drop = FALSE])]
  res
}

#' Compare ABC estimates with published UIS values.
#'
#' Joins model output (from \code{\link{mdl_process}}) to published values on
#' country, year, level and sex, and reports differences and whether the
#' published value lies inside the model's 90\% interval.
#'
#' Agreement is expected only if the model was run on the same input data and
#' settings as the UIS production run for that release. With the anonymised
#' example data (\code{\link{abc_example_data}}) no meaningful comparison is
#' possible: country codes are scrambled and values perturbed.
#'
#' @param output Model output with \code{country, year, series, value, lower,
#'   upper, variable, sex}.
#' @param uis Published values with \code{country, year, variable, sex} and a
#'   value column (\code{uis_value}, or \code{value}). Values above 1 are treated
#'   as percentages.
#' @param series Model series corresponding to the published indicator
#'   (\code{"projected3t5"} is the SDG 4.1.2 completion rate).
#'
#' @return A list: \code{matched} (row-level comparison), \code{by_group}
#'   (summary per level/sex), \code{unmatched_uis} (published rows with no model
#'   estimate) and \code{overall}.
#' @export
compare_uis <- function(output, uis, series = "projected3t5") {
  if (!"uis_value" %in% names(uis)) {
    if (!"value" %in% names(uis)) stop("`uis` needs a `uis_value` or `value` column.", call. = FALSE)
    uis$uis_value <- uis$value
  }
  if (any(uis$uis_value > 1, na.rm = TRUE)) uis$uis_value <- uis$uis_value / 100
  keys <- c("country", "year", "variable", "sex")
  uis <- uis[!is.na(uis$uis_value), c(keys, "uis_value")]
  uis$year <- as.integer(uis$year)
  if (anyDuplicated(uis[keys])) stop("`uis` has duplicate country/year/level/sex rows.", call. = FALSE)
  est <- output[output$series == series & is.finite(output$value), ]
  est$year <- as.integer(est$year)
  est <- est[c(keys, "value", "lower", "upper")]
  names(est)[names(est) == "value"] <- "model_value"
  matched <- inner_join(est, uis, by = keys) %>%
    mutate(diff = model_value - uis_value,
           abs_diff = abs(diff),
           inside_interval = uis_value >= lower & uis_value <= upper)
  summarise_cmp <- function(d) d %>% summarise(
    n = n(), countries = n_distinct(country),
    mean_diff = mean(diff), mean_abs_diff = mean(abs_diff),
    median_abs_diff = stats::median(abs_diff), max_abs_diff = max(abs_diff),
    share_within_0.01 = mean(abs_diff <= 0.01),
    share_inside_90 = mean(inside_interval), .groups = "drop")
  list(matched = matched,
       by_group = summarise_cmp(group_by(matched, variable, sex)),
       unmatched_uis = anti_join(uis, est, by = keys) %>%
         semi_join(distinct(est, country), by = "country"),
       overall = summarise_cmp(matched))
}

#' Compare two sets of ABC outputs (reproducibility check).
#'
#' Used to check that a re-run reproduces an earlier run. With different seeds,
#' Stan versions or compilers the draws differ, so estimates should agree within
#' Monte Carlo error rather than exactly.
#'
#' @param new,old Outputs of \code{\link{mdl_process}}.
#' @return Data frame of matched rows with differences in value and bounds.
#' @export
compare_runs <- function(new, old) {
  keys <- c("country", "year", "series", "variable", "sex")
  new <- new[is.finite(new$value), ]; old <- old[is.finite(old$value), ]
  old$year <- as.integer(old$year); new$year <- as.integer(new$year)
  inner_join(new[c(keys, "value", "lower", "upper")],
             old[c(keys, "value", "lower", "upper")],
             by = keys, suffix = c("_new", "_old")) %>%
    mutate(d_value = value_new - value_old,
           d_lower = lower_new - lower_old,
           d_upper = upper_new - upper_old)
}
