###################################################
#       LUNG EPITHELIAL IDENTITY ANALYSIS         #
#     Loss of normal lung functions in LUSC        #
###################################################

library(ggplot2)
library(stringr)
library(pheatmap)

#+------------------------------------------------+
#+                  DIRECTORIES                   #
#+------------------------------------------------+

dir_lung_plots <- "lung_identity_plots/"
dir_lung_results <- "lung_identity_results/"

if (!dir.exists(dir_lung_plots)) {
  dir.create(dir_lung_plots)
}

if (!dir.exists(dir_lung_results)) {
  dir.create(dir_lung_results)
}


#+------------------------------------------------+
#+              LUNG EPITHELIAL GENES             #
#+------------------------------------------------+

gene_split <- str_split_fixed(gene, "\\|", 2)
gene_symbol <- gene_split[, 1]

lung_identity_genes <- c(
  "SCGB1A1",
  "MUC1",
  "FOXJ1",
  "PIGR",
  "SFTPA1",
  "SFTPA2",
  "SFTPB",
  "SFTPC"
)

lung_idx <- match(lung_identity_genes, gene_symbol)
lung_idx <- lung_idx[!is.na(lung_idx)]

lung_genes_found <- gene_symbol[lung_idx]


#+------------------------------------------------+
#+              SUMMARY TABLE                     #
#+------------------------------------------------+

lung_summary <- data.frame(
  gene = lung_genes_found,
  full_id = gene[lung_idx],
  logFC = logFC[lung_idx],
  pval = pval[lung_idx],
  pval_adj = pval_adj[lung_idx],
  direction = ifelse(
    logFC[lung_idx] > 0,
    "up",
    "down"
  )
)

write.csv2(
  lung_summary,
  file = paste0(
    dir_lung_results,
    "LUSC_lung_epithelial_identity_genes.csv"
  ),
  row.names = FALSE,
  quote = FALSE
)


#+------------------------------------------------+
#+              BOXPLOTS TUMOR VS NORMAL          #
#+------------------------------------------------+

for (i in seq_along(lung_idx)) {
  
  idx <- lung_idx[i]
  g <- gene_symbol[idx]
  
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
  
  box_df$group <- factor(
    box_df$group,
    levels = c("Normal", "Tumor")
  )
  
  p_gene <- pval_adj[idx]
  
  boxplot_gene <- ggplot(
    box_df,
    aes(x = group, y = expression, fill = group)
  ) +
    geom_boxplot(
      notch = TRUE,
      width = 0.5,
      alpha = 0.8,
      whisker.linetype = "dashed",
      staplewidth = 0.5,
      outlier.shape = 21,
      outlier.size = 2,
      outlier.fill = "white",
      outlier.colour = "black"
    ) +
    scale_fill_manual(
      values = c(
        "Normal" = "royalblue",
        "Tumor" = "red"
      )
    ) +
    labs(
      title = paste("Expression of", g),
      subtitle = paste("Adjusted p-value =", format.pval(p_gene, digits = 3)),
      x = "",
      y = "log2 expression"
    ) +
    theme_classic(base_size = 14) +
    theme(
      legend.position = "none",
      plot.title = element_text(face = "bold", hjust = 0.5),
      plot.subtitle = element_text(hjust = 0.5)
    )
  
  ggsave(
    filename = paste0(
      dir_lung_plots,
      "boxplot_",
      g,
      "_Tumor_vs_Normal.png"
    ),
    plot = boxplot_gene,
    width = 5,
    height = 5,
    dpi = 300
  )
}


#+------------------------------------------------+
#+              VOLCANO HIGHLIGHT                 #
#+------------------------------------------------+

volcano_df_lung <- data.frame(
  gene_symbol = gene_symbol,
  gene_full = gene,
  logFC = logFC,
  pval_adj = pval_adj
)

volcano_df_lung$neg_log10_pval_adj <- -log10(volcano_df_lung$pval_adj)

volcano_df_lung$direction <- ifelse(
  volcano_df_lung$pval_adj <= thr_pval_adj &
    volcano_df_lung$logFC >= log2(thr_fc),
  "up",
  ifelse(
    volcano_df_lung$pval_adj <= thr_pval_adj &
      volcano_df_lung$logFC <= -log2(thr_fc),
    "down",
    "not_significant"
  )
)

volcano_lung_plot <- ggplot(
  volcano_df_lung,
  aes(x = logFC, y = neg_log10_pval_adj, color = direction)
) +
  geom_point(size = 1.1, alpha = 0.6) +
  scale_color_manual(
    values = c(
      "up" = "red",
      "down" = "royalblue",
      "not_significant" = "grey"
    )
  ) +
  geom_point(
    data = volcano_df_lung[volcano_df_lung$gene_symbol %in% lung_genes_found, ],
    aes(x = logFC, y = neg_log10_pval_adj),
    color = "purple",
    size = 4
  ) +
  geom_text(
    data = volcano_df_lung[volcano_df_lung$gene_symbol %in% lung_genes_found, ],
    aes(label = gene_symbol),
    color = "black",
    vjust = -1,
    size = 3.5
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
    title = "Volcano plot highlighting normal lung identity genes",
    x = "log2 Fold Change",
    y = "-log10 adjusted p-value",
    color = "Direction"
  ) +
  theme_minimal(base_size = 13)

ggsave(
  filename = paste0(
    dir_lung_plots,
    "volcano_lung_epithelial_identity_genes.png"
  ),
  plot = volcano_lung_plot,
  width = 8,
  height = 6,
  dpi = 300
)


#+------------------------------------------------+
#+              LUNG IDENTITY SCORE               #
#+------------------------------------------------+

lung_identity_score <- data.frame(
  sample = colnames(common_data),
  condition = c(
    rep("Tumor", ncol(dataC)),
    rep("Normal", ncol(dataN))
  ),
  lung_identity_score = colMeans(common_data[lung_idx, ], na.rm = TRUE)
)

lung_identity_score$condition <- factor(
  lung_identity_score$condition,
  levels = c("Normal", "Tumor")
)

write.csv2(
  lung_identity_score,
  file = paste0(
    dir_lung_results,
    "LUSC_lung_identity_score.csv"
  ),
  row.names = FALSE,
  quote = FALSE
)

score_pval <- t.test(
  lung_identity_score$lung_identity_score[
    lung_identity_score$condition == "Tumor"
  ],
  lung_identity_score$lung_identity_score[
    lung_identity_score$condition == "Normal"
  ],
  paired = TRUE
)$p.value

score_plot <- ggplot(
  lung_identity_score,
  aes(x = condition, y = lung_identity_score, fill = condition)
) +
  geom_boxplot(
    notch = TRUE,
    width = 0.5,
    alpha = 0.8,
    whisker.linetype = "dashed",
    staplewidth = 0.5,
    outlier.shape = 21,
    outlier.size = 2,
    outlier.fill = "white",
    outlier.colour = "black"
  ) +
  scale_fill_manual(
    values = c(
      "Normal" = "royalblue",
      "Tumor" = "red"
    )
  ) +
  labs(
    title = "Normal lung epithelial identity score",
    subtitle = paste("Paired t-test p-value =", format.pval(score_pval, digits = 3)),
    x = "",
    y = "Mean log2 expression"
  ) +
  theme_classic(base_size = 14) +
  theme(
    legend.position = "none",
    plot.title = element_text(face = "bold", hjust = 0.5),
    plot.subtitle = element_text(hjust = 0.5)
  )

ggsave(
  filename = paste0(
    dir_lung_plots,
    "boxplot_lung_identity_score_Tumor_vs_Normal.png"
  ),
  plot = score_plot,
  width = 5,
  height = 5,
  dpi = 300
)


#+------------------------------------------------+
#+                  CLEAN DATA                    #
#+------------------------------------------------+

rm(
  gene_split,
  gene_symbol,
  lung_identity_genes,
  lung_idx,
  lung_genes_found,
  lung_summary,
  box_df,
  boxplot_gene,
  p_gene,
  i,
  idx,
  g,
  lung_data,
  annotation_col,
  annotation_colors,
  volcano_df_lung,
  volcano_lung_plot,
  lung_identity_score,
  score_pval,
  score_plot,
  dir_lung_plots,
  dir_lung_results
)