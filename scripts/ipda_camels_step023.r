args <- commandArgs(trailingOnly = TRUE)
input_table <- args[which(args == "--input") + 1]
outdir <- args[which(args == "--outdir") + 1]
outstem <- args[which(args == "--outstem") + 1]
functions <- args[which(args == "--function") + 1]

print_help <- function() {
  cat("
Written by Isabela Almeida
Created on Apr 15, 2026
Last modified on Apr 24, 2026
Version: 1.0.0

Description: Plot Plasmid representation results from the
CAMeLS pipeline (CRISPR Analysis Method for Library Screens). 

Usage: Rscript ipda_camels_step023.r [options]

Options:
  --input FILE        Input TSV file from camels022_guide-rep_BASH_DATE
  --outdir DIR        Output directory
  --outstem STEM      Output file stem (default: 'plasmid-rep')
  --help              Show this help message

Example:
  Rscript ipda_camels_step023.r --input /path/from/working/dir/to/camels022_guide-rep_BASH_DATE/guide-representation_riskoc_per-target.tsv --outdir /path/from/working/dir/to/camels023_guide-rep-plots_R_DATE/ --outstem guide-rep

Pipeline description:

#   010 Quality check sequencing (1FastQC, 2MultiQC)
#-->020 Guide representation (1BBDuk - finds 23nt perfect matchs and 21nt 0,2 and 3MM, 2BASH - write to TSV, 3R plot results)
#   030 Count reads from FASTQ files (1MAGeCK - replicate level; 2MAGeCK - combined replicates; 3Bash - summary replicates; 4Bash - summary combined)
#   040 Statistical test (1MAGeCK; 2Bash summary)
#   050 Plot results (1MAGeCK)

Please contact Isabela Almeida at mb.isabela42@gmail.com if you encounter any problems.
\n")
}

# Show help if requested or no args
if (length(args) == 0 || "--help" %in% args) {
  print_help()
  quit(save = "no")
}

## Load libraries
library(tidyverse)
library(ineq)
library(viridis)
library(Hmisc)
library(ggplot2)
library(dplyr)
library(tidyr)
library(ggbeeswarm)
library(patchwork)

## Set input/output paths
out_rankplot <- file.path(outdir, paste0(outstem, ".rankabundance.pdf"))
out_histplot <- file.path(outdir, paste0(outstem, ".histogram.pdf"))
out_lorenzgini <- file.path(outdir, paste0(outstem, ".lorenzcurvegini.pdf"))
out_correlation <- file.path(outdir, paste0(outstem, ".correlation.pdf"))
out_pcc <- file.path(outdir, paste0(outstem, ".pcc.pdf"))
out_boxplot <- file.path(outdir, paste0(outstem, ".boxplot.pdf"))
out_violin <- file.path(outdir, paste0(outstem, ".violin.pdf"))
out_pca <- file.path(outdir, paste0(outstem, ".pca.pdf"))

## Import table
df <- read.delim(input_table, header = TRUE,
                 col.names = c("target",
                               "rep1_counts","rep1_perc","rep2_counts",
                               "rep2_perc","rep3_counts","rep3_perc"))

## Convert to long format (counts only)
df_long <- df %>%
  pivot_longer(
    cols = -target,
    names_to = c("condition", ".value"),
    names_pattern = "(rep\\d+)_(counts|perc)"
  ) %>%
  mutate(
    sample_label = condition,
    group = condition
  )

## Convert to matrix for PCC
mat <- df %>%
  select(matches("^rep(?!.*perc)", perl = TRUE)) %>%
  as.matrix()

## Define palette
script_palette <- c(
  "rep1" = "#CAE2BC",
  "rep2" = "#C7CCB9",
  "rep3" = "#B0BC98"
)

## Source functions
source(functions)

## Rank-abundance plot
rank <- rank_plot(df_long, script_palette)
print(rank)
ggsave(file.path(out_rankplot),
       plot = rank, width = 5.5, height = 4.5, dpi = 100)

## Histogram (log counts)
hist <- hist_plot(df_long, script_palette)
print(hist)
ggsave(file.path(out_histplot),
       plot = hist, width = 5.5, height = 4.5, dpi = 100)

## Lorenz curve + Gini coefficient
lorenz <- lorenz_gini_plot(df_long, script_palette)
print(lorenz)
ggsave(file.path(out_lorenzgini),
       plot = lorenz, width = 6, height = 4.5, dpi = 100)

## Replicate correlation scatter plot
correl <- correlation_plot(df, "rep1_counts", "rep2_counts", "rep3_counts", "Guide rep", "Guide rep")
print(correl)
ggsave(file.path(out_correlation),
       plot = correl, width = 5.5, height = 9, dpi = 100)

## Pearson correlation coefficient (PCC)
pcc <- pcc_plot(mat)
print(pcc)
ggsave(file.path(out_pcc),
       plot = pcc, width = 6, height = 4.5, dpi = 100)

## Boxplot
boxplot <- box_plot(df_long, script_palette)
print(boxplot)
ggsave(file.path(out_boxplot),
       plot = boxplot, width = 6, height = 4.5, dpi = 100)

## Violin
violin <- violin_plot(df_long, script_palette)
print(violin)
ggsave(file.path(out_violin),
      plot = violin, width = 6, height = 4.5, dpi = 100)

## PCA
pca <- pca_plot(df_long, script_palette)
print(pca)
ggsave(file.path(out_pca),
       plot = pca, width = 6, height = 4.5, dpi = 100)