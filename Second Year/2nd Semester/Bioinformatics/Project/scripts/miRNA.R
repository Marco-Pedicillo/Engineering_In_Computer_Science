###################################################
#          miRNA-TARGET ENRICHMENT INPUT          #
###################################################

#+------------------------------------------------+
#+                  DIRECTORIES                   #
#+------------------------------------------------+

dir_mirna <- "mirna_results/"

if (!dir.exists(dir_mirna)) {
  dir.create(dir_mirna)
}

#+------------------------------------------------+
#+              GENE LISTS FOR MIENTURNET         #
#+------------------------------------------------+

up_genes_mirna <- unique(deg_results$gene[deg_results$direction == "up"])
down_genes_mirna <- unique(deg_results$gene[deg_results$direction == "down"])

up_genes_mirna <- up_genes_mirna[!is.na(up_genes_mirna) & up_genes_mirna != ""]
down_genes_mirna <- down_genes_mirna[!is.na(down_genes_mirna) & down_genes_mirna != ""]

write.table(
  up_genes_mirna,
  file = paste0(dir_mirna, "LUSC_UP_genes_for_MIENTURNET.txt"),
  quote = FALSE,
  row.names = FALSE,
  col.names = FALSE
)

write.table(
  down_genes_mirna,
  file = paste0(dir_mirna, "LUSC_DOWN_genes_for_MIENTURNET.txt"),
  quote = FALSE,
  row.names = FALSE,
  col.names = FALSE
)

rm(up_genes_mirna, down_genes_mirna, dir_mirna)