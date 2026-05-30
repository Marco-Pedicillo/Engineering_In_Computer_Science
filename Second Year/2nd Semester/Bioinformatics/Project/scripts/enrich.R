###################################################
#              FUNCTIONAL ENRICHMENT              #
#                 UP vs DOWN DEG                  #
###################################################

library(enrichR)
library(ggplot2)
library(forcats)
library(stringr)

#+------------------------------------------------+
#+                  DIRECTORIES                   +
#+------------------------------------------------+

dir_plots <- "enrich_plots/"
dir_results <- "enrich_results/"

if (!dir.exists(dir_plots)) {
  dir.create(dir_plots)
}

if (!dir.exists(dir_results)) {
  dir.create(dir_results)
}


#+------------------------------------------------+
#+                 INPUT GENE LISTS               +
#+------------------------------------------------+

up_genes <- unique(deg_results$gene[deg_results$direction == "up"])
down_genes <- unique(deg_results$gene[deg_results$direction == "down"])

up_genes <- up_genes[!is.na(up_genes) & up_genes != ""]
down_genes <- down_genes[!is.na(down_genes) & down_genes != ""]

write.table(up_genes, paste0(dir_results, "LUSC_UP_gene_list_for_enrichR.txt"),
            quote = FALSE, row.names = FALSE, col.names = FALSE)

write.table(down_genes, paste0(dir_results, "LUSC_DOWN_gene_list_for_enrichR.txt"),
            quote = FALSE, row.names = FALSE, col.names = FALSE)


#+------------------------------------------------+
#+                 ENRICHR DATABASES              +
#+------------------------------------------------+

available_dbs <- listEnrichrDbs()

available_dbs[grep(
  "DisGeNET|KEGG|GO_Biological|GO_Molecular|TRANSFAC",
  available_dbs$libraryName
), ]

dbs <- c(
  "DisGeNET",
  "KEGG_2026",
  "GO_Biological_Process_2026",
  "GO_Molecular_Function_2026",
  "TRANSFAC_and_JASPAR_PWMs"
)

top_term <- 20

thresholds <- c(
  "DisGeNET" = 0.05,
  "KEGG_2026" = 0.05,
  "GO_Biological_Process_2026" = 0.01,
  "GO_Molecular_Function_2026" = 0.05,
  "TRANSFAC_and_JASPAR_PWMs" = 0.05
)


#+------------------------------------------------+
#+              ENRICHMENT FUNCTION               +
#+------------------------------------------------+

run_enrichment <- function(gene_list, label) {
  
  enrich_results <- enrichr(gene_list, dbs)
  enrichment_processed <- list()
  
  for (db in names(enrich_results)) {
    
    annotation <- enrich_results[[db]]
    
    if (nrow(annotation) == 0) {
      next
    }
    
    annotation <- annotation[order(annotation$Adjusted.P.value), ]
    
    annotation$Gene_count <- sapply(annotation$Genes, function(x) {
      length(unlist(strsplit(x, ";")))
    })
    
    annotation$Gene_ratio <- sapply(annotation$Overlap, function(x) {
      count <- as.numeric(strsplit(x, "/")[[1]][1])
      total <- as.numeric(strsplit(x, "/")[[1]][2])
      count / total
    })
    
    thr <- thresholds[db]
    
    annotation_sig <- annotation[annotation$Adjusted.P.value < thr, ]
    
    enrichment_processed[[db]] <- annotation_sig
    
    write.csv2(
      annotation_sig[, c(
        "Term",
        "Overlap",
        "P.value",
        "Adjusted.P.value",
        "Gene_count",
        "Gene_ratio",
        "Genes"
      )],
      file = paste0(
        dir_results,
        "LUSC_",
        label,
        "_",
        db,
        "_enrichment_adj_pval_",
        thr,
        ".csv"
      ),
      row.names = FALSE,
      quote = FALSE
    )
    
    if (nrow(annotation_sig) == 0) {
      next
    }
    
    if (nrow(annotation_sig) >= top_term) {
      annotation_top <- annotation_sig[1:top_term, ]
    } else {
      annotation_top <- annotation_sig
    }
    
    dotplot_enrich <- ggplot(
      annotation_top,
      aes(
        x = Gene_count,
        y = fct_reorder(Term, Gene_count)
      )
    ) +
      geom_point(aes(size = Gene_ratio, color = Adjusted.P.value)) +
      scale_color_gradient(low = "red", high = "blue") +
      scale_y_discrete(labels = function(x) str_wrap(x, width = 45)) +
      labs(
        title = paste("Enrichment dotplot -", label, "-", db),
        x = "Gene count",
        y = NULL,
        color = "Adjusted p-value",
        size = "Gene ratio"
      ) +
      theme_bw(base_size = 11)
    
    ggsave(
      filename = paste0(
        dir_plots,
        "LUSC_",
        label,
        "_",
        db,
        "_dotplot.png"
      ),
      plot = dotplot_enrich,
      width = 7,
      height = 7,
      dpi = 300
    )
  }
  
  return(enrichment_processed)
}


#+------------------------------------------------+
#+                RUN ENRICHMENT                  +
#+------------------------------------------------+

enrichment_UP <- run_enrichment(up_genes, "UP")
enrichment_DOWN <- run_enrichment(down_genes, "DOWN")


#+------------------------------------------------+
#+                  CLEAN DATA                    +
#+------------------------------------------------+

rm(available_dbs, dbs, thresholds, up_genes, down_genes, dir_plots, dir_results, top_term, 
   run_enrichment)