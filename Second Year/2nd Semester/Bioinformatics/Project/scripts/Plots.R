###################################################
#                    PLOTS FILE                   #
###################################################

library(stringr)
library(ggplot2)
library(pheatmap)
library(RColorBrewer)

#+------------------------------------------------+
#+                  VOLCANO PLOT                  +
#+------------------------------------------------+

#Per il volcano dobbiamo sistemare il pval: -Log10(pval_adj) 

#Creo il dataframe per il volcano plot
volcano_df <- data.frame(
  gene = gene,
  logFC = logFC,
  pval_adj = pval_adj
)

#Calcolo -log10 adjusted p-value
volcano_df$neg_log10_pval_adj <- -log10(volcano_df$pval_adj)

#Classifico i geni
volcano_df$direction <- ifelse(
  volcano_df$pval_adj <= thr_pval_adj & volcano_df$logFC >= log2(thr_fc),
  "up",
  ifelse(
    volcano_df$pval_adj <= thr_pval_adj & volcano_df$logFC <= -log2(thr_fc),
    "down",
    "not_significant"
  )
)

#Volcano plot
volcano_plot <- ggplot(volcano_df, aes(x = logFC, y = neg_log10_pval_adj, color = direction)) +
  geom_point(size = 1.2, alpha = 0.7) +
  scale_color_manual(
    values = c(
      "up" = "red",
      "down" = "blue",
      "not_significant" = "grey"
    )
  ) +
  geom_vline(xintercept = c(-log2(thr_fc), log2(thr_fc)), 
             linetype = "dashed", color = "black") +
  geom_hline(yintercept = -log10(thr_pval_adj), 
             linetype = "dashed", color = "black") +
  labs(
    title = "Volcano plot - Tumor vs Normal",
    x = "log2 Fold Change",
    y = "-log10 adjusted p-value",
    color = "Direction"
  ) +
  theme_minimal(base_size = 16) +
  theme(
    plot.title = element_text(
      face = "bold",
      hjust = 0.5,
      size = 18
    ),
    axis.title = element_text(
      size = 15
    ),
    axis.text = element_text(
      size = 12
    ),
    legend.title = element_text(
      size = 14,
      face = "bold"
    ),
    legend.text = element_text(
      size = 12
    )
  )

ggsave("plots/05_volcano_plot.png", volcano_plot, width = 8, height = 6, dpi = 300)


#+------------------------------------------------+
#+            SIGNIFICANT VOLCANO PLOT            +
#+------------------------------------------------+

volcano_sig <- volcano_df[
  volcano_df$pval_adj <= thr_pval_adj &
    abs(volcano_df$logFC) >= log2(thr_fc),
]

volcano_sig_plot <- ggplot(volcano_sig, aes(x = logFC, y = neg_log10_pval_adj, color = direction)) +
  geom_point(size = 1.5, alpha = 0.8) +
  scale_color_manual(
    values = c(
      "up" = "red",
      "down" = "blue"
    )
  ) +
  geom_vline(xintercept = c(-log2(thr_fc), log2(thr_fc)),
             linetype = "dashed", color = "black") +
  geom_hline(yintercept = -log10(thr_pval_adj),
             linetype = "dashed", color = "black") +
  labs(
    title = "Volcano plot restricted to significant DEG",
    x = "log2 Fold Change",
    y = "-log10 adjusted p-value",
    color = "Direction"
  ) +
  theme_minimal(base_size = 16) +
  theme(
    plot.title = element_text(
      face = "bold",
      hjust = 0.5,
      size = 18
    ),
    axis.title = element_text(
      size = 15
    ),
    axis.text = element_text(
      size = 12
    ),
    legend.title = element_text(
      size = 14,
      face = "bold"
    ),
    legend.text = element_text(
      size = 12
    )
  )

ggsave("plots/06_volcano_significant_DEG.png", volcano_sig_plot, width = 8, height = 6, dpi = 300)


#+------------------------------------------------+
#+                    BAR PLOT                    +
#+------------------------------------------------+

deg_counts <- data.frame(
  regulation = c("Upregulated", "Downregulated"),
  count = c(length(up), length(down))
)

png("plots/07_barplot_up_down_DEG.png", width = 900, height = 700)

bp <- barplot(
  deg_counts$count,
  names.arg = deg_counts$regulation,
  main = "Number of differentially expressed genes",
  ylab = "Number of genes",
  col = c("red", "blue"),
  border = "black",
  ylim = c(0, max(deg_counts$count) * 1.15)
)

text(
  x = bp,
  y = deg_counts$count,
  labels = deg_counts$count,
  pos = 3,
  cex = 1.1
)

dev.off()


#+------------------------------------------------+
#+                    PIE CHART                   #
#+------------------------------------------------+

deg_counts <- data.frame(
  regulation = c("Upregulated", "Downregulated"),
  count = c(length(up), length(down))
)

# calculate percentages
deg_counts$percent <- round(
  deg_counts$count / sum(deg_counts$count) * 100,
  1
)

# labels: Up 45.3%, Down 54.7%
deg_counts$label <- paste0(
  ifelse(deg_counts$regulation == "Upregulated", "Up", "Down"),
  "\n",
  deg_counts$percent,
  "%"
)

png(
  "plots/07_piechart_up_down_DEG.png",
  width = 1200,
  height = 1000,
  res = 180
)

pie(
  deg_counts$count,
  labels = deg_counts$label,
  col = c("coral", "deepskyblue3"),
  border = "white",
  main = "Differentially Expressed Genes",
  cex = 1.3,
  cex.main = 1.4
)

dev.off()


#+------------------------------------------------+
#+       BOXPLOT SELECTED DIFFERENTIAL GENE       +
#+------------------------------------------------+

#Scelgo un gene con alto fold-change (non banale)
selected_gene <- DEG[which.max(abs(logFC[DEG]))]

selected_gene_name <- gene[selected_gene]
p_gene <- pval_adj[selected_gene]

#Creo dataframe
box_df <- data.frame(
  expression = c(as.numeric(dataN[selected_gene, ]),
                 as.numeric(dataC[selected_gene, ])),
  group = c(rep("Normal", ncol(dataN)),
            rep("Tumor", ncol(dataC)))
)

#Ordine corretto
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
    title = paste("Expression of", selected_gene_name),
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

ggsave("plots/08_boxplot_selected_gene.png", boxplot_gene, width = 7, height = 6, dpi = 300)


#+------------------------------------------------+
#+              SELECTED VOLCANO PLOT             +
#+------------------------------------------------+

selected_gene_name <- gene[selected_gene]

selected_volcano_plot <- ggplot(volcano_df, aes(x = logFC, y = neg_log10_pval_adj, color = direction)) +
  geom_point(size = 1.2, alpha = 0.6) +
  scale_color_manual(
    values = c(
      "up" = "red",
      "down" = "blue",
      "not_significant" = "grey"
    )
  ) +
  geom_point(
    data = volcano_df[volcano_df$gene == selected_gene_name, ],
    aes(x = logFC, y = neg_log10_pval_adj),
    color = "purple",
    size = 4
  ) +
  geom_vline(xintercept = c(-log2(thr_fc), log2(thr_fc)),
             linetype = "dashed", color = "black") +
  geom_hline(yintercept = -log10(thr_pval_adj),
             linetype = "dashed", color = "black") +
  labs(
    title = paste("Volcano plot with highlighted gene:", selected_gene_name),
    x = "log2 Fold Change",
    y = "-log10 adjusted p-value",
    color = "Direction"
  ) +
  theme_minimal()

ggsave("plots/09_volcano_selected_gene.png", selected_volcano_plot, width = 8, height = 6, dpi = 300)


#+------------------------------------------------+
#+                  HEAT MAP                      +
#+------------------------------------------------+

#Matrice solo dei geni differenzialmente espressi
deg_data <- common_data[DEG, ]

#Annotazione colonne: Tumor / Normal
annotation_col <- data.frame(
  Condition = c(
    rep("Tumor", ncol(dataC)),
    rep("Normal", ncol(dataN))
  )
)

rownames(annotation_col) <- colnames(common_data)

#Annotazione righe: Up / Down
gene_direction <- rep(NA, nrow(common_data))
gene_direction[up] <- "up"
gene_direction[down] <- "down"

annotation_row <- data.frame(
  Direction = gene_direction[DEG]
)

rownames(annotation_row) <- rownames(deg_data)

#Colori annotazioni
annotation_colors <- list(
  Condition = c(
    Tumor = "red",
    Normal = "lightblue"
  ),
  Direction = c(
    up = "coral",
    down = "green3"
  )
)

#Heatmap
pheatmap(
  deg_data,
  scale = "row",
  border_color = NA,
  cluster_rows = TRUE,
  cluster_cols = TRUE,
  clustering_distance_rows = "correlation",
  clustering_distance_cols = "correlation",
  clustering_method = "average",
  annotation_col = annotation_col,
  annotation_row = annotation_row,
  annotation_colors = annotation_colors,
  show_rownames = FALSE,
  show_colnames = FALSE,
  cutree_rows = 2,
  cutree_cols = 2,
  color = colorRampPalette(c("yellow","yellow2", "yellow3", "black","purple3", "purple2","purple"))(100),
  main = "Heatmap of Differentially Expressed Genes",
  filename = "plots/10_heatmap_DEG.png",
  width = 10,
  height = 10
)





rm(annotation_col, annotation_colors, annotation_row, box_df, deg_counts, deg_data, 
   volcano_df, volcano_sig, gene_direction, p_gene, bp, boxplot_gene, selected_volcano_plot, 
   volcano_plot, volcano_sig_plot)