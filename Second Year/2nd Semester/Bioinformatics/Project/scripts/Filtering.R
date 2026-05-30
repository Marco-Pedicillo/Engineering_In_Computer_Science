###################################################
#                 FILTERING FILE                  #
###################################################

library(stringr)

#+------------------------------------------------+
#+                    LOG-FC                      +
#+------------------------------------------------+

#Calcolo logFC con rowmeans
logFC <- rowMeans(dataC, na.rm = T) - rowMeans(dataN, na.rm = T)

#Soglie di fold-change
thr_fc <- 2.5

png("plots/03_logFC_distribution.png", width = 1200, height = 1000, res = 180)

#Istogramma del logFC
hist(
  logFC,
  breaks = 50,
  main = "Log2 Fold Change Distribution",
  xlab = "log2FC Tumor vs Normal",
  ylab = "Frequency",
  col = "lightgreen",
  border = "black",
  cex.main = 1.4,
  cex.lab = 1.4,
  cex.axis = 1.2
)

#Linea a zero: separa downregulated(sx) e upregulated(dx)
abline(v = 0, col = "red", lwd = 2)

abline(v = c(-log2(thr_fc), log2(thr_fc)), col = "blue", lwd = 2, lty = 2)

dev.off()


#+------------------------------------------------+
#+                    P-VALUE                     +
#+------------------------------------------------+

#Calcolo p-value
pval <- apply(common_data, 1, function(x){
  res <- t.test(
    x[1:ncol(dataC)],
    x[(ncol(dataC) + 1):(ncol(dataC) + ncol(dataN))],
    paired = TRUE
  )
  res$p.value
})

#Correggo i p-value per test multipli usando FDR.
#Questo riduce il rischio di falsi positivi dovuti al grande numero di geni testati.
#P=0.95x0.95x0.95... = 0.80, quindi rischio del 20% invece che 5%(con 0.95)
pval_adj <- p.adjust(pval, method = "fdr")

#Sistemo eventuali adjusted p-value uguali a 0
pval_adj[pval_adj == 0] <- min(pval_adj[pval_adj > 0])


png("plots/04_adjusted_pvalue_distribution.png", width = 1200, height = 1000, res = 180)

hist(
  pval_adj,
  breaks = 50,
  main = "Adjusted p-value Distribution",
  xlab = "Adjusted p-value (FDR)",
  ylab = "Frequency",
  col = "lightpink",
  border = "black",
  cex.main = 1.4,
  cex.lab = 1.4,
  cex.axis = 1.2
)

abline(v = 0.05, col = "red", lwd = 2, lty = 2)

dev.off()


#+------------------------------------------------+
#+                      DEG                       +
#+------------------------------------------------+

#Seleziono i geni significativi
thr_pval_adj <- 0.05

DEG <- which(
  abs(logFC) >= log2(thr_fc) &
    pval_adj <= thr_pval_adj
)

up <- which(
  logFC >= log2(thr_fc) &
    pval_adj <= thr_pval_adj
)

down <- which(
  logFC <= -log2(thr_fc) &
    pval_adj <= thr_pval_adj
)





rm(iqr_values, threshold)