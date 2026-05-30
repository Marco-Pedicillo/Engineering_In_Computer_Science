###################################################
#                      RESULTS                    #
###################################################

library(stringr)

#+------------------------------------------------+
#+                EXPORTING OUTPUT                +
#+------------------------------------------------+

#Separo gene symbol e Ensembl ID
gene_split <- str_split_fixed(gene, "\\|", 2)

gene_symbol <- gene_split[, 1]
ensembl_id <- gene_split[, 2]

#Definisco direzione up/down/not significant
direction <- rep("not_significant", length(gene))
direction[up] <- "up"
direction[down] <- "down"

#Costruisco tabella risultati completa
results <- data.frame(
  gene = gene_symbol,
  ensembl_id = ensembl_id,
  pval = pval,
  pval_adj = pval_adj,
  logFC = logFC,
  direction = direction
)

#Tengo solo i geni differenzialmente espressi
deg_results <- results[DEG, ]

#Ordino per adjusted p-value
deg_results <- deg_results[order(deg_results$pval_adj), ]

#Esporto risultati DEG
write.csv2(
  deg_results,
  file = "results/LUSC_DEG_results.csv",
  row.names = FALSE,
  quote = FALSE
)


#Lista campioni tumorali
tumor_samples <- data.frame(sample = colnames(dataC))

write.csv2(
  tumor_samples,
  file = "results/LUSC_tumor_samples.csv",
  row.names = FALSE,
  quote = FALSE
)


#Lista campioni normali
normal_samples <- data.frame(sample = colnames(dataN))

write.csv2(
  normal_samples,
  file = "results/LUSC_normal_samples.csv",
  row.names = FALSE,
  quote = FALSE
)


#Matrice di espressione solo dei DEGs
matrix_deg <- common_data[DEG, ]

write.csv2(
  matrix_deg,
  file = "results/LUSC_DEG_matrix.csv",
  quote = FALSE
)





rm(gene_split, results, direction, gene_symbol, ensembl_id, tumor_samples, normal_samples, matrix_deg)