genclustering <- function(filename, isfile=TRUE, ...) {
  if (isfile) {
    slmed = read.table(filename, header=TRUE)
  } else {
    slmed = filename
  }
  slmat = as.matrix(slmed[, c(-1, -2)])
  slmat_log = log2(slmat + 1)

  if (ncol(slmat_log) > 1) {
    pheatmap(cor(slmat_log))
  } else {
    print('Skip Clustering plot as there is only one sample.')
  }
}