###################################################
#                   MAIN FILE                     #
###################################################

rm(list = ls())

#+------------------------------------------------+
#+                 RUN PIPELINE                   +
#+------------------------------------------------+

source("scripts/Pre_Processing.R")
source("scripts/Filtering.R")
source("scripts/Plots.R")
source("scripts/Results.R")

source("scripts/enrich.R")
source("scripts/biomarkers.R")
source("scripts/Clinical.R")
source("scripts/Lung_Epithelial_Identity_Analysis.R")

#+------------------------------------------------+
#+                  SAVE DATA                     +
#+------------------------------------------------+

save.image(file = "LUSC.RData")