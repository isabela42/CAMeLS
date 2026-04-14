args <- commandArgs(trailingOnly = TRUE)

print_help <- function() {
  cat("
Written by Isabela Almeida
Created on Apr 15, 2026
Last modified on Apr 15, 2026
Version: 1.0.0

Description: Plot Plasmid representation results from the
CAMeLS pipeline (CRISPR Analysis Method for Library Screens). 

Usage: Rscript ipda_camels_step023.r [options]

Options:
  --input FILE        Input TSV file from camels022_plasmid-rep_BASH_DATE
  --outdir DIR        Output directory
  --outstem STEM      Output file stem (default: 'plasmid-rep')
  --help              Show this help message

Example:
  Rscript ipda_camels_step023.r --input /path/from/working/dir/to/camels022_plasmid-rep_BASH_DATE/plasmid-representation_riskoc_per-target.tsv --outdir /path/from/working/dir/to/camels023_plasmid-rep-plots_R_DATE/ --outstem plasmid-rep

Pipeline description:

#   010 Quality check sequencing (1FastQC, 2MultiQC)
#-->020 Plasmid-representation (1BBDuk - finds 23nt perfect matchs and 21nt 0,2 and 3MM, 2BASH - write to TSV, 3R plot results)
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

## Set input/output paths
input_table <- args[which(args == "--input") + 1]
outdir <- args[which(args == "--outdir") + 1]
outstem <- args[which(args == "--outstem") + 1]
out_rankplot <- file.path(outdir, paste0(outstem, ".rankabundance.pdf"))
out_histplot <- file.path(outdir, paste0(outstem, ".histogram.pdf"))
out_lorenzgini <- file.path(outdir, paste0(outstem, ".lorenzcurvegini.pdf"))
out_correlation <- file.path(outdir, paste0(outstem, ".correlation.pdf"))
  
## Import table
df <- read.delim(input_table, header = TRUE,
                 col.names = c("target",
                               "rep1_counts","rep1_perc","rep2_counts",
                               "rep2_perc","rep3_counts","rep3_perc"))

## Convert to long format (counts only)
df_long <- df %>%
  pivot_longer(
    cols = -target,
    names_to = c("replicate", ".value"),
    names_pattern = "(rep\\d+)_(counts|perc)"
  )

## Rank-abundance plot
rank_df <- df_long %>%
  group_by(replicate) %>%
  arrange(desc(counts)) %>%
  mutate(rank = row_number())

rank <- ggplot(rank_df, aes(x = rank, y = counts, color = replicate)) +
  geom_line() +
  scale_y_log10() +
  labs(title = "Rank-Abundance Plot",
       x = "Guide Rank",
       y = "Counts (log10)") +
  theme_grey() +
  theme(
    axis.text.x = element_text(size = 20),
    axis.text.y = element_text(size = 20),
    axis.title.x = element_text(size = 23),
    axis.title.y = element_text(size = 23),
    plot.title = element_text(size = 25, face = "bold"),
    legend.title = element_text(size = 18),
    legend.text  = element_text(size = 15)
  )
  
print(rank)
ggsave(file.path(out_rankplot),
       plot = rank, width = 20, height = 20, dpi = 100)

## Histogram (log counts)
hist <- ggplot(df_long, aes(x = counts, fill = replicate)) +
  geom_histogram(bins = 50, alpha = 0.6, position = "identity") +
  scale_x_log10() +
  labs(title = "Distribution of Guide Counts",
       x = "Counts (log10)",
       y = "Frequency") +
  theme_grey() +
  theme(
    axis.text.x = element_text(size = 20),
    axis.text.y = element_text(size = 20),
    axis.title.x = element_text(size = 23),
    axis.title.y = element_text(size = 23),
    plot.title = element_text(size = 25, face = "bold"),
    legend.title = element_text(size = 18),
    legend.text  = element_text(size = 15)
  )

print(hist)
ggsave(file.path(out_histplot),
       plot = hist, width = 20, height = 20, dpi = 100)

## Lorenz curve + Gini coefficient
lorenz_df <- df_long %>%
  group_by(replicate) %>%
  do({
    L <- Lc(.$counts)
    tibble(p = L$p, L = L$L)
  })

gini_vals <- df_long %>%
  group_by(replicate) %>%
  summarise(Gini = ineq(counts, type = "Gini"))

gini_labels <- gini_vals %>%
  mutate(label = paste0(replicate, " (Gini=", round(Gini, 3), ")"))

lorenz_df <- lorenz_df %>%
  left_join(gini_labels, by = "replicate")

lorenz <- ggplot(lorenz_df, aes(x = p, y = L, color = label, linetype = replicate)) +
  geom_line(linewidth = 1.2, alpha = 0.7) +
  geom_abline(slope = 1, intercept = 0, linetype = "dashed") +
  labs(
    title = "Lorenz Curve",
    x = "Cumulative fraction of guides",
    y = "Cumulative fraction of counts",
    color = "Replicate"
  ) +
  theme_grey() +
  theme(
    axis.text.x = element_text(size = 20),
    axis.text.y = element_text(size = 20),
    axis.title.x = element_text(size = 23),
    axis.title.y = element_text(size = 23),
    plot.title = element_text(size = 25, face = "bold"),
    legend.title = element_text(size = 18),
    legend.text  = element_text(size = 15)
  )

print(lorenz)
ggsave(file.path(out_lorenzgini),
       plot = lorenz, width = 20, height = 20, dpi = 100)


## Replicate correlation scatter plot
df_pairs <- df %>%
  select(target, rep1_counts, rep2_counts, rep3_counts)

p1 <- ggplot(df_pairs, aes(rep1_counts, rep2_counts)) +
  geom_point(alpha = 0.4, size = 1) +
  scale_x_log10() + scale_y_log10() +
  ggtitle("rep1 vs rep2") +
  theme_grey() +
  theme(
    axis.text.x = element_text(size = 20),
    axis.text.y = element_text(size = 20),
    axis.title.x = element_text(size = 23),
    axis.title.y = element_text(size = 23),
    plot.title = element_text(size = 25, face = "bold"),
    legend.title = element_text(size = 18),
    legend.text  = element_text(size = 15)
  )

p2 <- ggplot(df_pairs, aes(rep1_counts, rep3_counts)) +
  geom_point(alpha = 0.4, size = 1) +
  scale_x_log10() + scale_y_log10() +
  ggtitle("rep1 vs rep3") +
  theme_grey() +
  theme(
    axis.text.x = element_text(size = 20),
    axis.text.y = element_text(size = 20),
    axis.title.x = element_text(size = 23),
    axis.title.y = element_text(size = 23),
    plot.title = element_text(size = 25, face = "bold"),
    legend.title = element_text(size = 18),
    legend.text  = element_text(size = 15)
  )

p3 <- ggplot(df_pairs, aes(rep2_counts, rep3_counts)) +
  geom_point(alpha = 0.4, size = 1) +
  scale_x_log10() + scale_y_log10() +
  ggtitle("rep2 vs rep3") +
  theme_grey() +
  theme(
    axis.text.x = element_text(size = 20),
    axis.text.y = element_text(size = 20),
    axis.title.x = element_text(size = 23),
    axis.title.y = element_text(size = 23),
    plot.title = element_text(size = 25, face = "bold"),
    legend.title = element_text(size = 18),
    legend.text  = element_text(size = 15)
  )

correl <- gridExtra::grid.arrange(p1, p2, p3, ncol = 3)

print(correl)
ggsave(file.path(out_correlation),
       plot = correl, width = 20, height = 20, dpi = 100)