source("scripts/_common.R")
bundle <- load_inputs()
path <- file.path(config$reports_dir, "ABC_output_4chains_valid.csv")
if (!file.exists(path)) stop("Run scripts/process_results.R first.")
out <- read.csv(path, stringsAsFactors = FALSE)
fig_dir <- file.path(config$reports_dir, "figures")
dir.create(fig_dir, recursive = TRUE, showWarnings = FALSE)
countries <- sort(unique(bundle$observed$country))
labels <- c(prim = "Primary", lsec = "Lower Secondary", usec = "Upper Secondary",
            female = "Female", male = "Male", total = "Total")
for (i in seq_along(countries)) {
  target <- countries[i]
  pred <- out %>% filter(country == target, year <= config$plot_end_year) %>%
    mutate(variable = factor(variable, levels = c("prim","lsec","usec")),
           sex = factor(sex, levels = c("female","male","total")))
  obs <- bundle$observed %>% filter(country == target, year <= config$plot_end_year) %>%
    mutate(variable = factor(variable, levels = c("prim","lsec","usec")),
           sex = factor(sex, levels = c("female","male","total")), survey = factor(survey))
  plot <- ggplot2::ggplot(mapping = ggplot2::aes(x = year, y = value)) +
    ggplot2::geom_ribbon(data = filter(pred, series == "projected8"),
      ggplot2::aes(ymin = lower, ymax = upper), fill = "grey60", alpha = .25) +
    ggplot2::geom_line(data = filter(pred, series == "projected8"), colour = "grey45", linetype = "dotted") +
    ggplot2::geom_ribbon(data = filter(pred, series == "projected3t5"),
      ggplot2::aes(ymin = lower, ymax = upper), fill = "blue", alpha = .12) +
    ggplot2::geom_line(data = filter(pred, series == "projected3t5"), colour = "blue") +
    ggplot2::geom_line(data = obs, ggplot2::aes(group = survey, colour = survey), linewidth = .2) +
    ggplot2::geom_point(data = obs, ggplot2::aes(shape = survey, colour = survey), size = 1) +
    ggplot2::scale_shape_manual(values = rep(0:25, length.out = nlevels(obs$survey))) +
    ggplot2::scale_y_continuous(breaks = seq(0,1,.25)) +
    ggplot2::coord_cartesian(ylim = c(0,1)) +
    ggplot2::facet_grid(variable ~ sex, labeller = ggplot2::labeller(
      variable = ggplot2::as_labeller(labels), sex = ggplot2::as_labeller(labels))) +
    ggplot2::labs(title = paste("Anonymised country:",target), x = "Year", y = "Completion rate",
      colour = "Survey", shape = "Survey",
      subtitle = "Blue: projected3t5; grey dotted: projected8; shaded: 90% posterior intervals",
      caption = "Public anonymised, noise-perturbed example data; not official country estimates.") +
    ggplot2::theme_bw() + ggplot2::theme(legend.position = "bottom")
  ggplot2::ggsave(file.path(fig_dir, sprintf("country_%02d.png",i)), plot,
                 width = 12, height = 9, dpi = 180)
}
write.csv(data.frame(file = sprintf("country_%02d.png",seq_along(countries)), country = countries),
  file.path(fig_dir,"index.csv"), row.names = FALSE)
