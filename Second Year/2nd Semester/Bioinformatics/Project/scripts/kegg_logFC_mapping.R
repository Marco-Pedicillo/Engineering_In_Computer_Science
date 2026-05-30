library(org.Hs.eg.db)
library(AnnotationDbi)

gene_symbols <- deg_results$gene

entrez_ids <- mapIds(
  org.Hs.eg.db,
  keys = gene_symbols,
  column = "ENTREZID",
  keytype = "SYMBOL",
  multiVals = "first"
)

kegg_fc <- data.frame(
  entrez = entrez_ids,
  logFC = deg_results$logFC
)

kegg_fc <- kegg_fc[!is.na(kegg_fc$entrez), ]

write.table(
  kegg_fc,
  file = "kegg_results/KEGG_logFC_mapping.txt",
  sep = "\t",
  quote = FALSE,
  row.names = FALSE,
  col.names = FALSE
)

rm(gene_symbols, entrez_ids, kegg_fc)