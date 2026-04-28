args <- commandArgs(trailingOnly = TRUE)
input_table <- args[which(args == "--input") + 1]
outdir <- args[which(args == "--outdir") + 1]
outstem <- args[which(args == "--outstem") + 1]
functions <- args[which(args == "--function") + 1]

print_help <- function() {
  cat("
Written by Isabela Almeida
Created on Apr 28, 2026
Last modified on Apr 29, 2026
Version: 1.0.0

Description: Plot Plasmid representation results from the
CAMeLS pipeline (CRISPR Analysis Method for Library Screens). 

Usage: Rscript ipda_camels_step034.r [options]

Options:
  --input FILE        Input TSV file from camels034_combined-summary_BASH-R_DATE
  --outdir DIR        Output directory
  --outstem STEM      Output file stem (default: 'cellA-replicates')
  --function FILE     Path to R functions file ipda_camels_rfunctions.r
  --help              Show this help message

Example:
  Rscript ipda_camels_step034.r --input /path/from/working/dir/to/camels034_combined-summary_BASH-R_DATE/stem_per-target.tsv --outdir /path/from/working/dir/to/camels034_combined-summary_R_DATE/ --outstem FT194-median-riskoc

Pipeline description:

#   010 Quality check sequencing (1FastQC, 2MultiQC)
#   020 Guide representation (1BBDuk - finds 23nt perfect matchs and 21nt 0,2 and 3MM, 2BASH - write to TSV, 3R plot results)
#-->030 Count reads from FASTQ files (1MAGeCK - replicate level; 2MAGeCK - combined replicates; 3Bash - summary replicates; 4Bash - summary combined)
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
out_rankplot <- file.path(outdir, paste0(outstem, ".rankabundance-combined.pdf"))
out_raw_rankplot <- file.path(outdir, paste0(outstem, ".rankabundance-raw.pdf"))
out_norm_rankplot <- file.path(outdir, paste0(outstem, ".rankabundance-norm.pdf"))
out_histplot <- file.path(outdir, paste0(outstem, ".histogram-combined.pdf"))
out_raw_histplot <- file.path(outdir, paste0(outstem, ".histogram-raw.pdf"))
out_norm_histplot <- file.path(outdir, paste0(outstem, ".histogram-norm.pdf"))
out_lorenzgini <- file.path(outdir, paste0(outstem, ".lorenzcurvegini-combined.pdf"))
out_raw_lorenzgini <- file.path(outdir, paste0(outstem, ".lorenzcurvegini-raw.pdf"))
out_norm_lorenzgini <- file.path(outdir, paste0(outstem, ".lorenzcurvegini-norm.pdf"))
out_correlation <- file.path(outdir, paste0(outstem, ".correlation-combined.pdf"))
out_raw_correlation <- file.path(outdir, paste0(outstem, ".correlation-raw.pdf"))
out_norm_correlation <- file.path(outdir, paste0(outstem, ".correlation-norm.pdf"))
out_pcc <- file.path(outdir, paste0(outstem, ".pcc-combined.pdf"))
out_raw_pcc <- file.path(outdir, paste0(outstem, ".pcc-raw.pdf"))
out_norm_pcc <- file.path(outdir, paste0(outstem, ".pcc-norm.pdf"))
out_boxplot <- file.path(outdir, paste0(outstem, ".boxplot-combined.pdf"))
out_raw_boxplot <- file.path(outdir, paste0(outstem, ".boxplot-raw.pdf"))
out_norm_boxplot <- file.path(outdir, paste0(outstem, ".boxplot-norm.pdf"))
out_violin <- file.path(outdir, paste0(outstem, ".violin-combined.pdf"))
out_raw_violin <- file.path(outdir, paste0(outstem, ".violin-raw.pdf"))
out_norm_violin <- file.path(outdir, paste0(outstem, ".violin-norm.pdf"))
out_pca <- file.path(outdir, paste0(outstem, ".pca-combined.pdf"))
out_raw_pca <- file.path(outdir, paste0(outstem, ".pca-raw.pdf"))
out_norm_pca <- file.path(outdir, paste0(outstem, ".pca-norm.pdf"))

## Import table
df <- read.delim(input_table, header = TRUE,
                 col.names = c("target",
                               "end_counts","ctrl_counts",
                               "normend_counts","normctrl_counts"))

## Convert to long format (counts only)
df_long <- df %>%
  pivot_longer(
    cols = -target,
    names_to = c("norm", "condition", ".value"),
    names_pattern = "(norm)?((?:end|ctrl)\\d+)_(counts)"
  ) %>%
  mutate(
    norm = ifelse(is.na(norm) | norm == "", "raw", "norm"),
    condition = gsub("^end", "endpoint", condition),
    group = ifelse(grepl("ctrl", condition), "Control", "Endpoint"),
    replicate = gsub("[a-zA-Z]+", "", condition),
    sample_label = paste(
      ifelse(norm == "raw", "Raw", "Norm"),
      ifelse(group == "Control", "Ctrl", "End"),
      replicate,
      sep = " "
    )
  )

## Split raw and normalized counts
raw_df <- df_long %>% filter(norm == "raw")
norm_df <- df_long %>% filter(norm == "norm")
mat_norm <- df %>%
  select(matches("^(normend|normctrl)")) %>%
  as.matrix()
mat_raw <- df %>%
  select(matches("^(end|ctrl)")) %>%
  as.matrix()

## Define palette
script_palette <- c(
  "Raw Ctrl" = "#C7CCB9",
  "Raw End" = "#A9B2C6",
  "Norm Ctrl" = "#55674E",
  "Norm End" = "#5C76A3"
)

## Source functions
source(functions)

## Rank-abundance plot
rank_raw_plot <- rank_plot(raw_df, script_palette, 500)
rank_norm_plot <- rank_plot(norm_df, script_palette, 500)
rank <- gridExtra::grid.arrange(rank_raw_plot, rank_norm_plot, ncol = 2)
print(rank)
ggsave(file.path(out_rankplot),
       plot = rank, width = 11, height = 4.5, dpi = 100)
ggsave(file.path(out_raw_rankplot),
       plot = rank_raw_plot, width = 5.5, height = 4.5, dpi = 100)
ggsave(file.path(out_norm_rankplot),
       plot = rank_norm_plot, width = 5.5, height = 4.5, dpi = 100)

## Histogram (log counts)
hist_raw_plot <- hist_plot(raw_df, script_palette, 500)
hist_norm_plot <- hist_plot(norm_df, script_palette, 500)
hist <- gridExtra::grid.arrange(hist_raw_plot, hist_norm_plot, ncol = 2)
print(hist)
ggsave(file.path(out_histplot),
       plot = hist, width = 11, height = 4.5, dpi = 100)
ggsave(file.path(out_raw_histplot),
       plot = hist_raw_plot, width = 5.5, height = 4.5, dpi = 100)
ggsave(file.path(out_norm_histplot),
       plot = hist_norm_plot, width = 5.5, height = 4.5, dpi = 100)

## Lorenz curve + Gini coefficient
lorenz_raw_plot <- lorenz_gini_plot(raw_df, script_palette)
lorenz_norm_plot <- lorenz_gini_plot(norm_df, script_palette)
lorenz <- gridExtra::grid.arrange(lorenz_raw_plot, lorenz_norm_plot, ncol = 2)
print(lorenz)
ggsave(file.path(out_lorenzgini),
       plot = lorenz, width = 12, height = 4.5, dpi = 100)
ggsave(file.path(out_raw_lorenzgini),
       plot = lorenz_raw_plot, width = 6, height = 4.5, dpi = 100)
ggsave(file.path(out_norm_lorenzgini),
       plot = lorenz_norm_plot, width = 6, height = 4.5, dpi = 100)

## Replicate correlation scatter plot
correl_raw_plot <- correlation2_plot(df, "end_counts", "ctrl_counts", "Raw endpoints", "end")
correl_norm_plot <- correlation2_plot(df, "normend_counts", "normctrl_counts", "Normalized endpoints", "end")
correl <- gridExtra::grid.arrange(correl_raw_plot, correl_norm_plot, ncol = 1)
print(correl)
ggsave(file.path(out_correlation),
       plot = correl, width = 22, height = 9, dpi = 100)
ggsave(file.path(out_raw_correlation),
       plot = correl_raw_plot, width = 11, height = 9, dpi = 100)
ggsave(file.path(out_norm_correlation),
       plot = correl_norm_plot, width = 11, height = 9, dpi = 100)

## Pearson correlation coefficient (PCC)
pcc_raw_plot <- pcc_plot(mat_raw)
pcc_norm_plot <- pcc_plot(mat_norm)
pcc <- gridExtra::grid.arrange(pcc_raw_plot, pcc_norm_plot, ncol = 2)
print(pcc)
ggsave(file.path(out_pcc),
       plot = pcc, width = 12, height = 4.5, dpi = 100)
ggsave(file.path(out_raw_pcc),
       plot = pcc_raw_plot, width = 6, height = 4.5, dpi = 100)
ggsave(file.path(out_norm_pcc),
       plot = pcc_norm_plot, width = 6, height = 4.5, dpi = 100)

## Boxplot
boxplot_raw_plot <- box_plot(raw_df, script_palette)
boxplot_norm_plot <- box_plot(norm_df, script_palette)
boxplot <- gridExtra::grid.arrange(boxplot_raw_plot, boxplot_norm_plot, ncol = 2)
print(boxplot)
ggsave(file.path(out_boxplot),
       plot = boxplot, width = 12, height = 4.5, dpi = 100)
ggsave(file.path(out_raw_boxplot),
       plot = boxplot_raw_plot, width = 6, height = 4.5, dpi = 100)
ggsave(file.path(out_norm_boxplot),
       plot = boxplot_norm_plot, width = 6, height = 4.5, dpi = 100)

## Violin
violin_raw_plot <- violin_plot(raw_df, script_palette)
violin_norm_plot <- violin_plot(norm_df, script_palette)
violin <- gridExtra::grid.arrange(violin_raw_plot, violin_norm_plot, ncol = 2)
print(violin)
ggsave(file.path(out_violin),
      plot = violin, width = 12, height = 4.5, dpi = 100)
ggsave(file.path(out_raw_violin),
      plot = violin_raw_plot, width = 6, height = 4.5, dpi = 100)
ggsave(file.path(out_norm_violin),
      plot = violin_norm_plot, width = 6, height = 4.5, dpi = 100)

## PCA
pca_raw_plot <- pca_plot(raw_df, script_palette)
pca_norm_plot <- pca_plot(norm_df, script_palette)
pca <- gridExtra::grid.arrange(pca_raw_plot, pca_norm_plot, ncol = 2)
print(pca)
ggsave(file.path(out_pca),
       plot = pca, width = 12, height = 4.5, dpi = 100)
ggsave(file.path(out_raw_pca),
       plot = pca_raw_plot, width = 6, height = 4.5, dpi = 100)
ggsave(file.path(out_norm_pca),
       plot = pca_norm_plot, width = 6, height = 4.5, dpi = 100)