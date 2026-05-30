###################################################
#                 BIOMARKERS FILE                 #
###################################################

library(ggplot2)
library(stringr)

#+------------------------------------------------+
#+                  DIRECTORIES                   +
#+------------------------------------------------+

dir_biomarkers <- "biomarkers_plot/"

if (!dir.exists(dir_biomarkers)) {
  dir.create(dir_biomarkers)
}


#+------------------------------------------------+
#+              SELECTED BIOMARKERS               +
#+------------------------------------------------+

biomarker_genes <- c("SFTPC", "CDC20", "AGER", "SLC2A1")

gene_split <- str_split_fixed(gene, "\\|", 2)
gene_symbol <- gene_split[, 1]

biomarker_idx <- match(biomarker_genes, gene_symbol)

biomarker_idx <- biomarker_idx[!is.na(biomarker_idx)]
biomarker_genes <- gene_symbol[biomarker_idx]


#+------------------------------------------------+
#+               VOLCANO DATAFRAME                +
#+------------------------------------------------+

volcano_df <- data.frame(
  gene_symbol = gene_symbol,
  gene_full = gene,
  logFC = logFC,
  pval_adj = pval_adj
)

volcano_df$neg_log10_pval_adj <- -log10(volcano_df$pval_adj)

volcano_df$direction <- ifelse(
  volcano_df$pval_adj <= thr_pval_adj & volcano_df$logFC >= log2(thr_fc),
  "up",
  ifelse(
    volcano_df$pval_adj <= thr_pval_adj & volcano_df$logFC <= -log2(thr_fc),
    "down",
    "not_significant"
  )
)


#+------------------------------------------------+
#+       VOLCANO PLOTS WITH HIGHLIGHTED GENE      +
#+------------------------------------------------+

for (g in biomarker_genes) {
  
  volcano_gene <- ggplot(
    volcano_df,
    aes(x = logFC, y = neg_log10_pval_adj, color = direction)
  ) +
    geom_point(size = 1.1, alpha = 0.6) +
    scale_color_manual(
      values = c(
        "up" = "red",
        "down" = "blue",
        "not_significant" = "grey"
      )
    ) +
    geom_point(
      data = volcano_df[volcano_df$gene_symbol == g, ],
      aes(x = logFC, y = neg_log10_pval_adj),
      color = "purple",
      size = 4
    ) +
    geom_text(
      data = volcano_df[volcano_df$gene_symbol == g, ],
      aes(label = gene_symbol),
      color = "black",
      vjust = -1,
      size = 4
    ) +
    geom_vline(
      xintercept = c(-log2(thr_fc), log2(thr_fc)),
      linetype = "dashed",
      color = "black"
    ) +
    geom_hline(
      yintercept = -log10(thr_pval_adj),
      linetype = "dashed",
      color = "black"
    ) +
    labs(
      title = paste("Volcano plot - highlighted biomarker:", g),
      x = "log2 Fold Change",
      y = "-log10 adjusted p-value",
      color = "Direction"
    ) +
    theme_minimal()
  
  ggsave(
    filename = paste0(dir_biomarkers, "volcano_", g, ".png"),
    plot = volcano_gene,
    width = 8,
    height = 6,
    dpi = 300
  )
}


#+------------------------------------------------+
#+              BIOMARKER BOXPLOTS                +
#+------------------------------------------------+

for (i in seq_along(biomarker_idx)) {
  
  idx <- biomarker_idx[i]
  g <- gene_symbol[idx]
  p_gene <- pval_adj[idx]
  
  box_df <- data.frame(
    expression = c(
      as.numeric(dataN[idx, ]),
      as.numeric(dataC[idx, ])
    ),
    group = c(
      rep("Normal", ncol(dataN)),
      rep("Tumor", ncol(dataC))
    )
  )
  
  box_df$group <- factor(box_df$group, levels = c("Normal", "Tumor"))
  
  boxplot_gene <- ggplot(box_df, aes(x = group, y = expression, fill = group)) +
    geom_boxplot(
      notch = TRUE,
      width = 0.45,
      alpha = 0.8,
      whisker.linetype = "dashed",
      staplewidth = 0.5,
      outlier.shape = 21,
      outlier.size = 2,
      outlier.fill = "white",
      outlier.colour = "black"
    ) +
    scale_fill_manual(
      values = c("Normal" = "royalblue", "Tumor" = "red")
    ) +
    labs(
      title = paste("Expression of", g),
      subtitle = paste("Adjusted p-value =", format.pval(p_gene, digits = 3)),
      x = "TCGA samples",
      y = "log2 expression"
    ) +
    theme_classic(base_size = 14) +
    theme(
      legend.position = "none",
      plot.title = element_text(face = "bold", hjust = 0.5),
      plot.subtitle = element_text(hjust = 0.5)
    )
  
  ggsave(
    filename = paste0(dir_biomarkers, "boxplot_", g, ".png"),
    plot = boxplot_gene,
    width = 5,
    height = 5,
    dpi = 300
  )
}


#+------------------------------------------------+
#+              BIOMARKER SUMMARY                 +
#+------------------------------------------------+

biomarker_summary <- data.frame(
  gene = gene_symbol[biomarker_idx],
  full_id = gene[biomarker_idx],
  logFC = logFC[biomarker_idx],
  pval_adj = pval_adj[biomarker_idx],
  direction = volcano_df$direction[biomarker_idx]
)

write.csv2(
  biomarker_summary,
  file = paste0(dir_biomarkers, "LUSC_biomarker_summary.csv"),
  row.names = FALSE,
  quote = FALSE
)


#+------------------------------------------------+
#+                  CLEAN DATA                    +
#+------------------------------------------------+

rm(box_df, boxplot_gene, volcano_gene, volcano_df, biomarker_idx, biomarker_genes, gene_split, 
   gene_symbol, p_gene, g, idx, i, dir_biomarkers)