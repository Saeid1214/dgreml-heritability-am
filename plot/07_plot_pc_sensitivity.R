#!/usr/bin/env Rscript
# 07_plot_pc_sensitivity.R
# Purpose : Compare the proportion of SNP-based heritability attributable to
#           GPD across 0, 10 and 20 principal components.
# Usage   : Rscript plots/07_plot_pc_sensitivity.R [results_dir]
# Input   : <results_dir>/dgreml_summary.tsv (from 06)
# Output  : <results_dir>/pc_sensitivity.pdf
suppressPackageStartupMessages({ library(data.table); library(ggplot2) })
args <- commandArgs(trailingOnly = TRUE)
results_dir <- if (length(args) >= 1) args[1] else "results"

d <- fread(file.path(results_dir, "dgreml_summary.tsv"))
d[, pcs := factor(pcs, levels = c(0, 10, 20), labels = c("0 PCs", "10 PCs", "20 PCs"))]

p <- ggplot(d, aes(x = proportion, y = reorder(label, proportion), colour = pcs)) +
  geom_vline(xintercept = 0, linetype = "dashed", colour = "grey60") +
  geom_point(position = position_dodge(width = 0.6), size = 2) +
  facet_wrap(~cohort) +
  scale_colour_manual(values = c("#9ecae1", "#4292c6", "#08306b"), name = NULL) +
  labs(x = "Proportion of SNP-based heritability attributable to GPD", y = NULL) +
  theme_minimal(base_size = 11) + theme(legend.position = "top")

ggsave(file.path(results_dir, "pc_sensitivity.pdf"), p, width = 8, height = 6)
message("Saved ", file.path(results_dir, "pc_sensitivity.pdf"))
