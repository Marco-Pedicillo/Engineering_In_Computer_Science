library(org.Hs.eg.db)
library(AnnotationDbi)

#+------------------------------------------------+
#+               UP GENES MAPPING                 +
#+------------------------------------------------+

up_symbols <- unique(deg_results$gene[deg_results$direction == "up"])

up_entrez <- mapIds(
  org.Hs.eg.db,
  keys = up_symbols,
  column = "ENTREZID",
  keytype = "SYMBOL",
  multiVals = "first"
)

up_entrez <- na.omit(up_entrez)

up_kegg <- data.frame(
  ENTREZ = up_entrez,
  COLOR = "coral"
)

write.table(
  up_kegg,
  file = "kegg_results/KEGG_UP_mapping.txt",
  sep = "\t",
  row.names = FALSE,
  col.names = FALSE,
  quote = FALSE
)

#+------------------------------------------------+
#+              DOWN GENES MAPPING                +
#+------------------------------------------------+

down_symbols <- unique(deg_results$gene[deg_results$direction == "down"])

down_entrez <- mapIds(
  org.Hs.eg.db,
  keys = down_symbols,
  column = "ENTREZID",
  keytype = "SYMBOL",
  multiVals = "first"
)

down_entrez <- na.omit(down_entrez)

down_kegg <- data.frame(
  ENTREZ = down_entrez,
  COLOR = "deepskyblue3"
)

write.table(
  down_kegg,
  file = "kegg_results/KEGG_DOWN_mapping.txt",
  sep = "\t",
  row.names = FALSE,
  col.names = FALSE,
  quote = FALSE
)


rm(up_kegg, up_symbols, up_entrez, down_kegg, down_symbols, down_entrez)