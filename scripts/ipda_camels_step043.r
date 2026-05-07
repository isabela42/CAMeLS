args <- commandArgs(trailingOnly = TRUE)
input_gene <- args[which(args == "--inputgene") + 1]
input_sgrna <- args[which(args == "--inputsgrna") + 1]
outdir <- args[which(args == "--outdir") + 1]
outstem <- args[which(args == "--outstem") + 1]
functions <- args[which(args == "--function") + 1]

print_help <- function() {
  cat("
Written by Isabela Almeida
Created on May 07, 2026
Last modified on May 07, 2026
Version: 1.0.0

Description: Plot Plasmid representation results from the
CAMeLS pipeline (CRISPR Analysis Method for Library Screens). 

Usage: Rscript ipda_camels_step043.r [options]

Options:
  --input FILE        Input TSV file from camels043_plots_BASH-R_DATE
  --outdir DIR        Output directory
  --outstem STEM      Output file stem (default: 'cellA-replicates')
  --function FILE     Path to R functions file ipda_camels_rfunctions.r
  --help              Show this help message

Example:
  Rscript ipda_camels_step043.r --inputgene /path/from/working/dir/to/camels043_plots_BASH-R_DATE/stem.gene_summary.full.tsv --inputsgrna /path/from/working/dir/to/camels043_plots_BASH-R_DATE/stem.sgrna_summary.full.tsv --outdir /path/from/working/dir/to/camels043_combined-summary_R_DATE/ --outstem FT194-median-riskoc

Pipeline description:

#   010 Quality check sequencing (1FastQC, 2MultiQC)
#   020 Guide representation (1BBDuk - finds 23nt perfect matchs and 21nt 0,2 and 3MM, 2BASH - write to TSV, 3R plot results)
#   030 Count reads from FASTQ files (1MAGeCK - replicate level; 2MAGeCK - combined replicates; 3Bash - summary replicates; 4Bash - summary combined)
#-->040 Statistical test (1MAGeCK; 2Bash summary; 3R plot results)

Please contact Isabela Almeida at mb.isabela42@gmail.com if you encounter any problems.
\n")
}

# Show help if requested or no args
if (length(args) == 0 || "--help" %in% args) {
  print_help()
  quit(save = "no")
}

## Load libraries
library(dplyr)
library(ggplot2)
library(ggrepel)



library(tidyverse)
library(ineq)
library(viridis)
library(Hmisc)
library(ggplot2)
library(dplyr)
library(tidyr)
library(ggbeeswarm)
library(patchwork)

library(tibble)


## Set input/output paths
input_gene <- "/working/lab_julietF/isabelaA/Project_Risk-OC/screens/proliferation-analysis/camels043_plots_BASH-R_06052026165400AEST/IOSE7576-median-riskoc.gene_summary.full.tsv"
input_sgrna <- "/working/lab_julietF/isabelaA/Project_Risk-OC/screens/proliferation-analysis/camels043_plots_BASH-R_06052026165400AEST/IOSE7576-median-riskoc.sgrna_summary.full.tsv"
outdir <- "/working/lab_julietF/isabelaA/Project_Risk-OC/screens/proliferation-analysis/camels043_plots_BASH-R_06052026165400AEST/"
outstem <- "IOSE7576-median-riskoc"
functions <- "/working/lab_julietF/isabelaA/scripts/CAMeLS/scripts/ipda_camels_rfunctions.r"
input_gene <- "/working/lab_julietF/isabelaA/Project_Risk-OC/screens/proliferation-analysis/camels043_plots_BASH-R_06052026165400AEST/FT194-median-riskoc.gene_summary.full.tsv"
input_sgrna <- "/working/lab_julietF/isabelaA/Project_Risk-OC/screens/proliferation-analysis/camels043_plots_BASH-R_06052026165400AEST/FT194-median-riskoc.sgrna_summary.full.tsv"
outdir <- "/working/lab_julietF/isabelaA/Project_Risk-OC/screens/proliferation-analysis/camels043_plots_BASH-R_06052026165400AEST/"
outstem <- "FT194-median-riskoc"

fdr_cutoff <- 0.3
out_volcanogene <- file.path(outdir, paste0(outstem, ".volcano-gene_summary.pdf"))
out_volcanosgrna <- file.path(outdir, paste0(outstem, ".volcano-sgrna_summary.pdf"))

## Import table
df_gene <- read.delim(input_gene, header = TRUE)
df_sgrna <- read.delim(input_sgrna, header = TRUE)

## Select neg/pos fdr
df_gene_plot <- df_gene %>%
  mutate(
    direction = ifelse(pos.fdr <= neg.fdr, "pos", "neg"),
    selected_fdr = ifelse(direction == "pos", pos.fdr, neg.fdr),
    selected_lfc = ifelse(direction == "pos", pos.lfc, neg.lfc),
    minus_log10_fdr = -log10(selected_fdr),
    hit = case_when(
      selected_lfc > 0  & selected_fdr < fdr_cutoff ~ "Positive",
      selected_lfc <= 0 & selected_fdr < fdr_cutoff ~ "Negative",
      TRUE ~ "Not significant"
    ),
    significant = selected_fdr < fdr_cutoff)

ctrls <- c("neg-ctrl", "pos-ctrl")
df_gene_plot$type <- factor(
  df_gene_plot$type,
  levels = c(
    sort(setdiff(unique(df_gene_plot$type), ctrls)),
    ctrls[ctrls %in% df_gene_plot$type]
  )
)

label_df <- df_gene_plot %>%
  filter(hit != "Not significant") %>%
  group_by(type, hit) %>%
  slice_min(selected_fdr, n = 3, with_ties = FALSE) %>%
  ungroup()

#df_geneneg_plot <- df_gene_plot %>%
#  mutate(selection = "Negative", lfc = neg.lfc, fdr = neg.fdr)
#df_genepos_plot <- df_gene_plot %>%
#  mutate(selection = "Positive", lfc = pos.lfc, fdr = pos.fdr)
#df_geneboth_plot <- bind_rows(df_geneneg_plot, df_genepos_plot)
#ggplot(df_geneboth_plot, aes(lfc, -log10(fdr))) +
#  geom_point(aes(color = hit)) +
#  facet_grid(selection ~ type)

df_sgrna_plot <- df_sgrna %>%
  mutate(
    direction = ifelse(high_in_treatment == "True", "Positive", "Negative")
  ) %>%
  group_by(gene_name) %>%
  mutate(
    n_guides = n(),
    n_positive = sum(direction == "Positive"),
    n_negative = sum(direction == "Negative"),
    
    gene_direction = ifelse(n_positive >= n_negative, "Positive", "Negative"),
    
    guide_fraction_consensus = ifelse(
      gene_direction == "Positive",
      n_positive / n_guides,
      n_negative / n_guides
    )
  ) %>%
  ungroup() %>%
  filter(direction == gene_direction) %>%
  mutate(
    size_scale = guide_fraction_consensus,
    alpha_scale = guide_fraction_consensus
  ) %>%
  mutate(
    hit = case_when(
      FDR < fdr_cutoff & LFC > 0 ~ "Positive",
      FDR < fdr_cutoff & LFC <= 0 ~ "Negative",
      TRUE ~ "Not significant"
    )
  )

ctrls <- c("neg-ctrl", "pos-ctrl")
df_sgrna_plot$type <- factor(
  df_sgrna_plot$type,
  levels = c(
    sort(setdiff(unique(df_sgrna_plot$type), ctrls)),
    ctrls[ctrls %in% df_sgrna_plot$type]
  )
)

## Define palette
script_palette <- c(
  "Negative" = "#00AFBB", 
  "Not significant" = "grey", 
  "Positive" = "#bb0c00"
)

## Source functions
source(functions)

## Proportions summary
ctrls <- c("neg-ctrl", "pos-ctrl")
gene_summary <- df_gene_plot %>%
  group_by(type) %>%
  summarise(
    total_genes = n(),
    significant_genes = sum(hit != "Not significant"),
    non_significant_genes = sum(hit == "Not significant"),
    prop_significant = significant_genes / total_genes,
    prop_non_significant = non_significant_genes / total_genes
  ) %>%
  ungroup()

# Per-facet output
gene_summary %>%
  rowwise() %>%
  mutate(
    output = paste0(
      "Facet ", type,
      " - Significant genes: ",
      significant_genes, "/", total_genes,
      " (", round(prop_significant, 3), ")\n",
      "Facet ", type,
      " - Non-significant genes: ",
      non_significant_genes, "/", total_genes,
      " (", round(prop_non_significant, 3), ")\n"
    )
  ) %>%
  pull(output) %>%
  cat(sep = "\n")

# Combined non-control summary
gene_summary_noctrl <- gene_summary %>%
  filter(!type %in% ctrls) %>%
  summarise(
    total_genes = sum(total_genes),
    significant_genes = sum(significant_genes),
    non_significant_genes = sum(non_significant_genes)
  ) %>%
  mutate(
    prop_significant = significant_genes / total_genes,
    prop_non_significant = non_significant_genes / total_genes
  )

cat(
  "\nAll targets - Significant genes: ",
  gene_summary_noctrl$significant_genes, "/",
  gene_summary_noctrl$total_genes,
  " (", round(gene_summary_noctrl$prop_significant, 3), ")\n",
  "All targets - Non-significant genes: ",
  gene_summary_noctrl$non_significant_genes, "/",
  gene_summary_noctrl$total_genes,
  " (", round(gene_summary_noctrl$prop_non_significant, 3), ")\n",
  sep = ""
)

sgrna_summary <- df_sgrna_plot %>%
  group_by(type) %>%
  summarise(
    total_sgrnas = n(),
    significant_sgrnas = sum(hit != "Not significant"),
    non_significant_sgrnas = sum(hit == "Not significant"),
    prop_significant = significant_sgrnas / total_sgrnas,
    prop_non_significant = non_significant_sgrnas / total_sgrnas
  ) %>%
  ungroup()

# Per-facet output
sgrna_summary %>%
  rowwise() %>%
  mutate(
    output = paste0(
      "Facet ", type,
      " - Significant sgRNAs: ",
      significant_sgrnas, "/", total_sgrnas,
      " (", round(prop_significant, 3), ")\n",
      "Facet ", type,
      " - Non-significant sgRNAs: ",
      non_significant_sgrnas, "/", total_sgrnas,
      " (", round(prop_non_significant, 3), ")\n"
    )
  ) %>%
  pull(output) %>%
  cat(sep = "\n")

# Combined non-control summary
sgrna_summary_noctrl <- sgrna_summary %>%
  filter(!type %in% ctrls) %>%
  summarise(
    total_sgrnas = sum(total_sgrnas),
    significant_sgrnas = sum(significant_sgrnas),
    non_significant_sgrnas = sum(non_significant_sgrnas)
  ) %>%
  mutate(
    prop_significant = significant_sgrnas / total_sgrnas,
    prop_non_significant = non_significant_sgrnas / total_sgrnas
  )

cat(
  "\nAll targets - Significant sgRNAs: ",
  sgrna_summary_noctrl$significant_sgrnas, "/",
  sgrna_summary_noctrl$total_sgrnas,
  " (", round(sgrna_summary_noctrl$prop_significant, 3), ")\n",
  "All targets - Non-significant sgRNAs: ",
  sgrna_summary_noctrl$non_significant_sgrnas, "/",
  sgrna_summary_noctrl$total_sgrnas,
  " (", round(sgrna_summary_noctrl$prop_non_significant, 3), ")\n",
  sep = ""
)

## Volcano plot
volcano_gene <- volcano_plot_gene(df_gene_plot, fdr_cutoff, label_df, script_palette)
ggsave(file.path(out_volcanogene),
       plot = volcano_gene, width = 19, height = 4.5 , dpi = 100)
volcano_sgrna <- volcano_plot_guide(df_sgrna_plot, fdr_cutoff, script_palette)
ggsave(file.path(out_volcanosgrna),
       plot = volcano_sgrna, width = 19, height = 4.5 , dpi = 100)