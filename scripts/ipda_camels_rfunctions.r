# ============================================================
# FUNCTION: PLOTS
# ============================================================
# Written by Isabela Almeida
# Created on Apr 21, 2026
# Last modified on Apr 24, 2026
# Version: 1.0.0
#
# DESCRIPTION: Plot functions
#
# INPUT: See each plot function for info.
#
# OUTPUT: Plot
#
# USAGE (inside script.R):
#   source("path/to/functions.R")
#   function_plot(df, script_palette)
#
# NOTES:
#   - Designed for CAMeLS pipeline use
#   - Does NOT handle file I/O or argument parsing
#   - Assumes some level of preprocessing is already done
# ============================================================
pca_plot <- function(df, script_palette = NULL) {
  ...
}

# ------------------------------------------------------------
# RANK PLOT
# Description: Rank-abundance curve of counts per condition/sample
# Input: df (condition, sample_label, counts), script_palette
# Output: ggplot object
# Usage: rank_plot(df, script_palette)
# ------------------------------------------------------------

rank_plot <- function(df, script_palette = NULL) {
  rank_df <- df %>%
    group_by(condition) %>%
    arrange(desc(counts)) %>%
    mutate(rank = row_number())
  
  plot <- ggplot(rank_df, aes(x = rank, y = counts, color = sample_label, linetype = sample_label)) +
  geom_line(alpha = 0.7) +
  scale_y_log10() +
  scale_color_manual(values = script_palette) +
  labs(title = "Rank-Abundance Plot",
       x = "Guide Rank",
       y = "Counts (log10)",
       color = "Sample") +
  guides(
    color = guide_legend(title = "Sample"),
    linetype = guide_legend(title = "Sample")
  ) + 
    theme_grey() +
  theme(
      axis.text.x = element_text(size = 12),
      axis.text.y = element_text(size = 12),
      axis.title.x = element_text(size = 12),
      axis.title.y = element_text(size = 12),
      plot.title = element_text(size = 12, face = "bold"),
      legend.title = element_text(size = 12),
      legend.text  = element_text(size = 12)
    )
  return(plot)
}

# ------------------------------------------------------------
# HISTOGRAM
# Description: Distribution of guide counts per sample
# Input: df (counts, sample_label), script_palette
# Output: ggplot object
# Usage: hist_plot(df, script_palette)
# ------------------------------------------------------------

hist_plot <- function(df, script_palette = NULL) {
  plot <- ggplot(df, aes(x = counts, fill = sample_label)) +
  geom_histogram(bins = 50, alpha = 0.7, position = "identity") +
  scale_fill_manual(values = script_palette) +
  scale_x_log10() +
  labs(title = "Distribution of Guide Counts",
       x = "Counts (log10)",
       y = "Frequency") +
  theme_grey() +
  theme(
      axis.text.x = element_text(size = 12),
      axis.text.y = element_text(size = 12),
      axis.title.x = element_text(size = 12),
      axis.title.y = element_text(size = 12),
      plot.title = element_text(size = 12, face = "bold"),
      legend.title = element_text(size = 12),
      legend.text  = element_text(size = 12)
    )
  return(plot)
}

# ------------------------------------------------------------
# LORENZ + GINI
# Description: Inequality of guide distribution per sample
# Input: df (sample_label, counts), script_palette
# Output: ggplot object
# Usage: lorenz_gini_plot(df, script_palette)
# ------------------------------------------------------------

lorenz_gini_plot <- function(df, script_palette = NULL) {
  lorenz_df <- df %>%
    group_by(sample_label) %>%
    do({
      L <- Lc(.$counts)
      tibble(p = L$p, L = L$L)
    })
  
  gini_vals <- df %>%
    group_by(sample_label) %>%
    summarise(Gini = ineq(counts, type = "Gini"))
  
  gini_labels <- gini_vals %>%
    mutate(label = paste0(sample_label, " (Gini=", round(Gini, 3), ")"))
  
  lorenz_df <- lorenz_df %>%
    left_join(gini_labels, by = "sample_label")
  
  plot <- ggplot(lorenz_df, aes(x = p, y = L, color = label, linetype = label)) +
    geom_line(linewidth = 1.2, alpha = 0.7) +
    geom_abline(slope = 1, intercept = 0, linetype = "dashed") +
    scale_color_manual(values = script_palette) +
    scale_linetype_manual(values = rep(1:12, length.out = length(unique(df$sample_label)))) +
    labs(
      title = "Lorenz Curve",
      x = "Cumulative fraction of guides",
      y = "Cumulative fraction of counts",
      color = "Sample"
    ) +
    guides(
      color = guide_legend(title = "Sample"),
      linetype = guide_legend(title = "Sample")
    ) + 
    coord_fixed() +
    theme_grey() +
    theme(
      axis.text.x = element_text(size = 12),
      axis.text.y = element_text(size = 12),
      axis.title.x = element_text(size = 12),
      axis.title.y = element_text(size = 12),
      plot.title = element_text(size = 12, face = "bold"),
      legend.title = element_text(size = 12),
      legend.text  = element_text(size = 12)
    )
  return(plot)
}

# ------------------------------------------------------------
# CORRELATION PLOTS
# Description: Pairwise log-log scatter comparisons
# Input: df, col1, col2, col3, text_title, axis_title
# Output: grid plot (3 panels)
# Usage: correlation_plot(df, "A","B","C","Title","Axis")
# ------------------------------------------------------------

correlation_plot <- function(df, col1, col2, col3, text_title, axis_title){
  df_pairs <- df %>%
    select(target, all_of(c(col1, col2, col3)))
  
  vals <- df_pairs %>%
    select(all_of(c(col1, col2, col3))) %>%
    unlist()
  lims <- range(vals[vals > 0], na.rm = TRUE)
  
  p1 <- ggplot(df_pairs, aes(x = .data[[col1]], y = .data[[col2]])) +
    geom_point(alpha = 0.4, size = 1) +
    scale_x_log10(limits = lims) +
    scale_y_log10(limits = lims) +
    labs(
      title = paste(text_title, "- 1 vs 2"),
      x = paste0(axis_title, " 1"),
      y = paste0(axis_title, " 2")
    ) +
    coord_fixed() +
    theme_grey() +
    theme(
      axis.text.x = element_text(size = 12),
      axis.text.y = element_text(size = 12),
      axis.title.x = element_text(size = 12),
      axis.title.y = element_text(size = 12),
      plot.title = element_text(size = 12, face = "bold"),
      legend.title = element_text(size = 12),
      legend.text  = element_text(size = 12)
    )
  
  p2 <- ggplot(df_pairs, aes(x = .data[[col1]], y = .data[[col3]])) +
    geom_point(alpha = 0.4, size = 1) +
    scale_x_log10(limits = lims) +
    scale_y_log10(limits = lims) +
    labs(
      title = paste(text_title, "- 1 vs 3"),
      x = paste0(axis_title, " 1"),
      y = paste0(axis_title, " 3")
    ) +
    coord_fixed() +
    theme_grey() +
    theme(
      axis.text.x = element_text(size = 12),
      axis.text.y = element_text(size = 12),
      axis.title.x = element_text(size = 12),
      axis.title.y = element_text(size = 12),
      plot.title = element_text(size = 12, face = "bold"),
      legend.title = element_text(size = 12),
      legend.text  = element_text(size = 12)
    )
  
  p3 <- ggplot(df_pairs, aes(x = .data[[col2]], y = .data[[col3]])) +
    geom_point(alpha = 0.4, size = 1) +
    scale_x_log10(limits = lims) +
    scale_y_log10(limits = lims) +
    labs(
      title = paste(text_title, "- 2 vs 3"),
      x = paste0(axis_title, " 2"),
      y = paste0(axis_title, " 3")
    ) +
    coord_fixed() +
    theme_grey() +
    theme(
      axis.text.x = element_text(size = 12),
      axis.text.y = element_text(size = 12),
      axis.title.x = element_text(size = 12),
      axis.title.y = element_text(size = 12),
      plot.title = element_text(size = 12, face = "bold"),
      legend.title = element_text(size = 12),
      legend.text  = element_text(size = 12)
    )
  
  plot <- gridExtra::grid.arrange(p1, p2, p3, ncol = 3)
  return(plot)
}

# ------------------------------------------------------------
# PCC HEATMAP
# Description: Pearson correlation matrix heatmap
# Input: numeric matrix/data.frame
# Output: ggplot object
# Usage: pcc_plot(mat_df)
# ------------------------------------------------------------

pcc_plot <- function(mat_df){
  mat <- as.matrix(mat_df)
  cor_res <- rcorr(mat, type = "pearson")
  R <- cor_res$r
  P <- cor_res$P
  cor_long <- as.data.frame(as.table(R)) %>%
    rename(var1 = Var1, var2 = Var2, r = Freq)
  
  p_long <- as.data.frame(as.table(P)) %>%
    rename(var1 = Var1, var2 = Var2, p = Freq)
  
  plot_df <- cor_long %>%
    left_join(p_long, by = c("var1", "var2")) %>%
    mutate(
      x = as.factor(var1),
      y = as.factor(var2),
      sig = case_when(
        p <= 0.001 ~ "***",
        p <= 0.01  ~ "**",
        p <= 0.05  ~ "*",
        TRUE ~ ""
      )
    )
  
  plot_df <- plot_df %>%
    mutate(
      i = as.integer(x),
      j = as.integer(y)
    ) %>%
    filter(i >= j)
  
  plot <- ggplot(plot_df, aes(x = x, y = y)) +
    geom_point(aes(size = abs(r), fill = r), shape = 21, color = "grey") +
    geom_text(aes(label = round(r,2)), color = "white", size = 2) +
    scale_size(range = c(6, 8)) +
    scale_fill_gradientn(colors = c("#440154", "#3B528B", "#21908C")) +
    guides(
      fill = guide_colourbar(order = 1),
      size = guide_legend(order = 2))+
    labs(title = "Pearson Correlation Coeficient") +
    coord_fixed() +
    theme_grey() +
    theme(
      axis.text.x = element_text(size = 12, angle = 45, hjust = 1),
      axis.text.y = element_text(size = 12),
      axis.title.x = element_blank(),
      axis.title.y = element_blank(),
      plot.title = element_text(size = 12, face = "bold"),
      legend.title = element_text(size = 12),
      legend.text  = element_text(size = 12)
    )
  return(plot)
}

# ------------------------------------------------------------
# BOX PLOT
# Description: Log-scale distribution per group
# Input: df (group, sample_label, counts), script_palette
# Output: ggplot object
# Usage: box_plot(df, script_palette)
# ------------------------------------------------------------

box_plot <- function(df, script_palette = NULL) {
  #merged_df <- df %>%
  #  mutate(group = ifelse(grepl("rep", condition), "Endpoint", "Control")) %>%
  #  mutate(group = factor(group, levels = c("Control", "Endpoint"))) %>%
  #  arrange(group)
  plot <- ggplot(df, aes(x = group, y = counts, fill = sample_label)) +
    geom_boxplot(width = 0.6) +
    scale_y_log10() +
    scale_fill_manual(values = script_palette) +
    labs(
      title = "Boxplot",
      y = "Counts (log10)",
      fill = "Sample"
    ) +
    theme_grey() +
    theme(
      axis.text.x = element_text(size = 12),
      axis.text.y = element_text(size = 12),
      axis.title.x = element_blank(),
      axis.title.y = element_text(size = 12),
      plot.title = element_text(size = 12, face = "bold"),
      legend.title = element_text(size = 12),
      legend.text  = element_text(size = 12)
    )
  return(plot)
}

# ------------------------------------------------------------
# VIOLIN PLOT
# Description: Distribution + median per group
# Input: df (group, sample_label, counts), script_palette
# Output: ggplot object
# Usage: violin_plot(df, script_palette)
# ------------------------------------------------------------

violin_plot <- function(df, script_palette = NULL) {
  #merged_df <- df %>%
  #  mutate(group = ifelse(grepl("rep", condition), "Endpoint", "Control")) %>%
  #  mutate(group = factor(group, levels = c("Control", "Endpoint"))) %>%
  #  arrange(group)
  plot <- ggplot(df, aes(x = group, y = counts, fill = sample_label, group = sample_label)) +
    geom_violin(trim = FALSE, alpha = 0.25, position = position_dodge(width = 0.8)) +
    geom_boxplot(width = 0.15, outlier.shape = NA, position = position_dodge(width = 0.8)) +
    stat_summary(fun = median, geom = "point", size = 2, color = "#36454F", position = position_dodge(width = 0.8)) +
    stat_summary(fun.data = "median_hilow", fun.args = list(conf.int = 0.5),
                 geom = "errorbar", width = 0.1, color = "#36454F", position = position_dodge(width = 0.8)) +
    scale_y_log10() +
    scale_fill_manual(values = script_palette) +
    labs(
      title = "Violin",
      y = "Counts (log10)",
      fill = "Sample"
    ) +
    theme_grey() +
    theme(
      axis.text.x = element_text(size = 12),
      axis.text.y = element_text(size = 12),
      axis.title.x = element_blank(),
      axis.title.y = element_text(size = 12),
      plot.title = element_text(size = 12, face = "bold"),
      legend.title = element_text(size = 12),
      legend.text  = element_text(size = 12)
    )
  return(plot)
}     

# ------------------------------------------------------------
# PCA
# Description: PCA + variance explained
# Input: df (target, sample_label, counts), script_palette
# Output: patchwork (PCA + variance)
# Usage: pca_plot(df, script_palette)
# ------------------------------------------------------------

pca_plot <- function(df, script_palette = NULL) {
  df <- df %>%
    mutate(counts = replace_na(counts, 0))
  df_wide <- df %>%
    select(target, sample_label, counts) %>%
    pivot_wider(
      names_from = sample_label,
      values_from = counts,
      values_fill = 0
    )
  mat <- df_wide %>%
    column_to_rownames("target") %>%
    as.matrix()
  storage.mode(mat) <- "numeric"
  mat_log <- log10(mat + 1)
  row_var <- apply(mat_log, 1, var, na.rm = TRUE)
  col_var <- apply(mat_log, 2, var, na.rm = TRUE)
  mat_log <- mat_log[row_var > 0 & !is.na(row_var),
                     col_var > 0 & !is.na(col_var)]
  if (nrow(mat_log) < 2 || ncol(mat_log) < 2) {
    stop("Not enough variation after filtering to run PCA")
  }
  pca <- prcomp(t(mat_log), scale. = TRUE)
  pca_df <- as.data.frame(pca$x) %>%
    mutate(sample_label = rownames(.))
  var_df <- data.frame(
    PC = paste0("PC", seq_along(pca$sdev)),
    variance = (pca$sdev^2) / sum(pca$sdev^2)
  ) %>%
    mutate(cumvar = cumsum(variance)) %>%
    filter(!is.na(PC))
  p_pca <- ggplot(pca_df, aes(x = PC1, y = PC2, color = sample_label)) +
    geom_point(size = 3) +
    scale_color_manual(values = script_palette) +
    labs(
      title = "PCA",
      x = paste0("PC1 (", round(var_df$variance[1] * 100, 1), "%)"),
      y = paste0("PC2 (", round(var_df$variance[2] * 100, 1), "%)"),
      color = "Sample"
    ) +
    theme_grey() +
    theme(
      axis.text.x = element_text(size = 12),
      axis.text.y = element_text(size = 12),
      axis.title.x = element_text(size = 12),
      axis.title.y = element_text(size = 12),
      plot.title = element_text(size = 12, face = "bold"),
      legend.title = element_text(size = 12),
      legend.text  = element_text(size = 12)
    )
  max_pc <- min(10, nrow(var_df))
  p_var <- ggplot(var_df[1:max_pc, ], aes(x = PC, y = variance, group = 1)) +
    geom_line(linewidth = 1) +
    geom_point(size = 2) +
    labs(
      title = "Variance Explained",
      x = "Principal Component",
      y = "Variance"
    ) +
    theme_grey() +
    theme(
      axis.text.x = element_text(size = 12, angle = 45, hjust = 1),
      axis.text.y = element_text(size = 12),
      axis.title.x = element_text(size = 12),
      axis.title.y = element_text(size = 12),
      plot.title = element_text(size = 12, face = "bold")
    )
  plot <- p_pca / p_var
  return(plot)
}