# Compare ABC estimates with completion rates published by UIS.
#
# 1. Download the latest SDG 4 bulk data from the UIS Bulk Data Download Service
#    (https://databrowser.uis.unesco.org/resources) and unzip it into data/uis/.
#    You need the national data file and the indicator label file
#    (e.g. SDG_DATA_NATIONAL.csv and SDG_LABEL.csv).
# 2. Run the model on REAL country inputs (ISO3 country codes) with the same
#    release horizon. The anonymised ABCtest data cannot be compared: its country
#    codes are scrambled and its values perturbed.
library(abcR)
library(dplyr)

uis <- read_uis_cr("data/uis/SDG_DATA_NATIONAL.csv", "data/uis/SDG_LABEL.csv")
# Check which UIS series were picked up. If both a survey-based and a modelled
# series appear, keep only the modelled one, e.g. label_pattern = "model".
print(distinct(uis, indicator_id, indicator_label, variable, sex))

output <- read.csv("results/abcR_0.2.0/ABC_output.csv")
cmp <- compare_uis(output, uis, series = "projected3t5")

print(cmp$overall)
print(cmp$by_group)
# largest disagreements first
print(head(arrange(cmp$matched, desc(abs_diff)), 20))
write.csv(cmp$matched, "results/abcR_0.2.0/uis_comparison.csv", row.names = FALSE)
