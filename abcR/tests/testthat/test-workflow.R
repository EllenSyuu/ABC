test_that("packaged Stan model parses with current stanc", {
  expect_true(file.exists(abc_model_file()))
  res <- rstan::stanc(file = abc_model_file())
  expect_true(res$status)
})

test_that("example data splits into nine capped groups", {
  inputs <- split_abc_groups(abc_example_data())
  expect_named(inputs, c("pt", "pm", "pf", "lt", "lm", "lf", "ut", "um", "uf"))
  expect_true(all(vapply(inputs, function(d) "cap_adj" %in% names(d), logical(1))))
  # after the shift no value exceeds the cap
  all_vals <- do.call(rbind, inputs)
  expect_true(all(all_vals$value - all_vals$cap_adj <= 0.98 + 1e-12))
})

test_that("mdl_prep uses the explicit horizon and passes structural checks", {
  inputs <- split_abc_groups(abc_example_data())
  dat <- mdl_prep(inputs$lt, end_year = 2031)
  expect_identical(dat$nyears, as.integer(2031 - (min(inputs$lt$year) - 1)))
  expect_silent(mdl_check_data(dat))
  expect_error(mdl_prep(inputs$lt, end_year = 1990), "earlier than")
  expect_message(mdl_prep(inputs$lt), "end_year")
})

test_that("mdl_prep refuses input without cap_adj", {
  df <- abc_example_data()
  df <- df[df$variable == "prim" & df$sex == "total", ]
  expect_error(mdl_prep(df, end_year = 2031), "cap_adj")
})

test_that("inits are reproducible and one per chain", {
  dat <- mdl_prep(split_abc_groups(abc_example_data())$lt, end_year = 2031)
  a <- mdl_draw_inits(dat, nchains = 4, seed = 1)
  b <- mdl_draw_inits(dat, nchains = 4, seed = 1)
  expect_length(a, 4)
  expect_identical(a, b)
})

test_that("input checks reject impossible values", {
  df <- abc_example_data()
  df$value[1] <- 1
  expect_error(check_abc_input(df), "strictly inside")
})

test_that("compare_uis matches on keys and handles percentages", {
  out <- data.frame(country = "AAA", year = 2020:2021, series = "projected3t5",
                    value = c(0.5, 0.6), lower = c(0.4, 0.5), upper = c(0.6, 0.7),
                    variable = "prim", sex = "total")
  uis <- data.frame(country = "AAA", year = 2020:2021, variable = "prim",
                    sex = "total", value = c(52, 75))
  cmp <- compare_uis(out, uis)
  expect_equal(cmp$overall$n, 2)
  expect_equal(cmp$matched$diff, c(-0.02, -0.15))
  expect_equal(cmp$matched$inside_interval, c(TRUE, FALSE))
})

test_that("read_uis_cr maps labels to level and sex", {
  d <- tempfile(); dir.create(d)
  write.csv(data.frame(
    INDICATOR_ID = c("A", "B", "C", "D"),
    INDICATOR_LABEL_EN = c("Completion rate, primary education, both sexes (%)",
                           "Completion rate, lower secondary education, female (%)",
                           "Completion rate, upper secondary education, male (%)",
                           "Completion rate, primary education, rural, both sexes (%)")),
    file.path(d, "lab.csv"), row.names = FALSE)
  write.csv(data.frame(INDICATOR_ID = c("A", "B", "C", "D"), COUNTRY_ID = "AAA",
                       YEAR = 2020, VALUE = c(80, 60, 40, 10)),
            file.path(d, "dat.csv"), row.names = FALSE)
  r <- read_uis_cr(file.path(d, "dat.csv"), file.path(d, "lab.csv"))
  r <- r[order(r$indicator_id), ]
  expect_equal(r$variable, c("prim", "lsec", "usec"))
  expect_equal(r$sex, c("total", "female", "male"))
  expect_equal(r$uis_value, c(0.8, 0.6, 0.4))
})
