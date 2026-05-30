###################################################
#              PRE-PROCESSING FILE                #
###################################################

library(stringr)

#+------------------------------------------------+
#+                 IMPORT DATA                    +
#+------------------------------------------------+

#Leggo solo le prime 5 righe del file per capire la struttura delle colonne
tmp <- read.table(
  "matrix_RNAseq_LUSC.txt",
  header = T,
  sep = "\t",
  check.names = F,
  row.names = 1,
  quote = "",
  nrows = 5
)

#Determino il tipo classe di ogni colonna
colClasses <- sapply(tmp, class)

#Leggo l'intero dataset usando i tipi di colonna già identificati
data <- read.table(
  "matrix_RNAseq_LUSC.txt",
  header = T,
  sep = "\t",
  check.names = F,
  row.names = 1,
  quote = "",
  colClasses = colClasses
)


#+------------------------------------------------+
#+        MATCHED PATIENTS CASE vs CONTROL        +
#+------------------------------------------------+

#Estraggo i nomi dei campioni (colons) e dei geni (rows)
pz <- colnames(data)
gene <- row.names(data)

#Seleziono i campioni tumorali e normali 
pzC <- grep("^TCGA-[^-]+-[^-]+-0[0-9A-Z]", pz, value = TRUE)  
pzN <- grep("^TCGA-[^-]+-[^-]+-1[0-9A-Z]", pz, value = TRUE)

#Rimuovo duplicati a livello di paziente (primi 3 campi del barcode TCGA)
#Mantengo solo la prima occorrenza per ogni paziente
pzC <- pzC[!duplicated(str_extract(pzC, "^TCGA-[^-]+-[^-]+"))]
pzN <- pzN[!duplicated(str_extract(pzN, "^TCGA-[^-]+-[^-]+"))]

#Estraggo gli ID paziente (senza il tipo di campione) e trovo quelli presenti sia in tumor che in normal
common_pz <- intersect(str_extract(pzC, "^TCGA-[^-]+-[^-]+"), str_extract(pzN, "^TCGA-[^-]+-[^-]+"))

pzN_com <- sapply(common_pz, function(x){grep(x, pzN, value = TRUE)})
pzC_com <- sapply(common_pz, function(x){grep(x, pzC, value = TRUE)})

dataN <- data[,pzN_com]
dataC <- data[,pzC_com]

#Creo la matrice finale contenente solo i campioni matched (tumor + normal)
common_data <- cbind(dataC, dataN) 

rm(tmp, colClasses, pzC_com, pzN_com)


#+------------------------------------------------+
#+                 PRE-PROCESSING                 +
#+------------------------------------------------+

#Applico la trasformazione log2(data + 1) per rendere la distribuzione più simmetrica
common_data <- log2(common_data + 1)
dataN <- log2(dataN + 1)
dataC <- log2(dataC + 1)

#Calcolo l'IQR per ogni gene, per misurare la variabilità tra i campioni
iqr_values <- apply(common_data, 1, IQR)

#Calcolo il 20° percentile della distribuzione degli IQR.
#Nel nostro dataset il valore della soglia è 0, quindi verranno rimossi solo i geni con variabilità nulla.
threshold <- quantile(iqr_values, 0.2)


png("plots/01_IQR_before_filtering.png", width = 1200, height = 1000, res = 180)

#Istogramma degli IQR (vediamo che la frequenza su 0 è elevata)
hist(
  iqr_values,
  breaks = 50,
  main = "IQR distribution of genes",
  xlab = "IQR",
  ylab = "Frequency",
  col = "lightblue",
  border = "black",
  cex.main = 1.4,
  cex.lab = 1.4,
  cex.axis = 1.2
)

#Aggiungo la soglia del 20° percentile
abline(v = threshold, col = "red", lwd = 2, lty = 2)

dev.off()

#Elimino i geni con IQR minore o uguale alla soglia.
#Poiché threshold = 0, vengono rimossi solo i geni con IQR = 0.
ind <- which(iqr_values <= threshold)

dataC <- dataC[-ind, ]
dataN <- dataN[-ind, ]
common_data <- common_data[-ind, ]
gene <- gene[-ind]
iqr_values <- iqr_values[-ind]


png("plots/02_IQR_after_filtering.png", width = 1200, height = 1000, res = 180)

#Istogramma degli IQR modificati
hist(
  iqr_values,
  breaks = 50,
  main = "IQR distribution after removal of genes with IQR = 0",
  xlab = "IQR",
  ylab = "Frequency",
  col = "lightblue",
  border = "black",
  cex.main = 1.4,
  cex.lab = 1.4,
  cex.axis = 1.2
)

dev.off()





rm(pz, pzC, pzN, ind)