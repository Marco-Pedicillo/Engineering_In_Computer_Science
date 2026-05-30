###################################################
#                  CLINICAL FILE                  #
###################################################

clinical <- read.delim(
  "clinical_lusc.txt",
  header = TRUE,
  sep = "\t",
  quote = "",
  fill = TRUE,
  stringsAsFactors = FALSE
)

write.csv2(
  clinical,
  file = "clinical.csv",
  row.names = FALSE,
  quote = TRUE
)

data_samples_short <- substr(colnames(data), 1, 12)

common_samples <- intersect(
  data_samples_short,
  clinical$submitter_id
)

clinical_common <- clinical[
  clinical$submitter_id %in% common_samples,
]

#+------------------------------------------------+
#+                   HISTOGRAMS                   #
#+------------------------------------------------+

# create output directory
dir.create(
  "clinical_plots",
  showWarnings = FALSE
)

# convert age from days to years
clinical_common$age_years <- round(
  clinical_common$age_at_diagnosis / 365,
  1
)

# remove missing values
age <- clinical_common$age_years[
  !is.na(clinical_common$age_years)
]

# save age histogram
png(
  "clinical_plots/Age_Distribution_Histogram.png",
  width = 1200,
  height = 900,
  res = 150
)

hist(
  age,
  breaks = 8,
  col = "royalblue",
  border = "white",
  main = "Age Distribution of TCGA-LUSC Patients",
  xlab = "Age at Diagnosis (years)",
  ylab = "Number of Patients",
  cex.main = 1.2,
  cex.lab = 1.1
)

dev.off()


#+------------------------------------------------+
#+              GENDER DISTRIBUTION               #
#+------------------------------------------------+

# gender counts
gender_counts <- table(clinical_common$gender)

# save gender barplot
png(
  "clinical_plots/Gender_Distribution_Barplot.png",
  width = 1200,
  height = 900,
  res = 150
)

# create barplot and save bar positions
bp <- barplot(
  gender_counts,
  col = c("pink", "royalblue"),
  border = NA,
  main = "Gender Distribution of TCGA-LUSC Patients",
  ylab = "Number of Patients",
  cex.main = 1.2,
  ylim = c(0, max(gender_counts) * 1.15)
)

# add counts above bars
text(
  x = bp,
  y = gender_counts,
  label = gender_counts,
  pos = 3,
  cex = 1.2
)

dev.off()


rm(data_samples_short, clinical_common, age, gender_counts, common_samples, bp)