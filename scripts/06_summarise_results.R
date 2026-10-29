#!/usr/bin/env Rscript
# 06_summarise_results.R
# Purpose : Parse GCTA .hsq files from the DGREML runs into one tidy table.
# Usage   : Rscript scripts/06_summarise_results.R [results_dir]
# Input   : <results_dir>/dgreml/pc<K>/<cohort>/<trait>.hsq and .mgrm.txt
#           config/trait_manifest.tsv (trait_type)
# Output  : <results_dir>/dgreml_summary.tsv
#
# Quantities (G1 = GRM, G2 = DGRM):
#   h2_RM  = sg2 / Vp          variance explained under random mating
#   h2_GPD = delta / Vp        additional variance from directional GPD
#   proportion = h2_GPD / (h2_RM + h2_GPD)
#   Wald z, p : two-sided test of delta = 0 (observed-scale variance and SE)
# For binary traits the liability-scale rows (*_L) are used for h2_RM and h2_GPD.
# No multiple-testing correction is applied here.
suppressPackageStartupMessages(library(data.table))

args        <- commandArgs(trailingOnly = TRUE)
results_dir <- if (length(args) >= 1) args[1] else "results"
manifest    <- fread(Sys.getenv("MANIFEST_TSV", "config/trait_manifest.tsv"))

parse_hsq <- function(file, binary) {
  h <- fread(file, fill = TRUE, sep = "\t", header = TRUE)
  setnames(h, 1:3, c("Source", "Variance", "SE"))
  get <- function(src) h[Source == src, .(est = as.numeric(Variance), se = as.numeric(SE))]
  suffix <- if (binary) "_L" else ""
  g1 <- get(paste0("V(G1)/Vp", suffix)); g2 <- get(paste0("V(G2)/Vp", suffix))
  d  <- get("V(G2)")
  if (nrow(g1) != 1 || nrow(g2) != 1 || nrow(d) != 1) stop("Unexpected .hsq layout: ", file)
  z <- d$est / d$se
  data.table(h2_RM = g1$est, se_h2_RM = g1$se,
             h2_GPD = g2$est, se_h2_GPD = g2$se,
             proportion = g2$est / (g1$est + g2$est),
             z = z, p = 2 * pnorm(-abs(z)))
}

files <- list.files(file.path(results_dir, "dgreml"), pattern = "\\.hsq$",
                    recursive = TRUE, full.names = TRUE)
if (!length(files)) stop("No .hsq files found under ", results_dir)

res <- rbindlist(lapply(files, function(f) {
  parts   <- strsplit(sub("\\.hsq$", "", sub(paste0(".*dgreml/"), "", f)), "/")[[1]]
  pcs     <- as.integer(sub("^pc", "", parts[1])); cohort <- parts[2]; trait <- parts[3]
  # Guard: G1 must be the GRM and G2 the DGRM
  lst <- readLines(sub("\\.hsq$", ".mgrm.txt", f))
  stopifnot(!grepl("\\.gpd$", lst[1]), grepl("\\.gpd$", lst[2]))
  binary <- manifest[trait_id == trait, trait_type] == "binary"
  cbind(data.table(pcs = pcs, cohort = cohort, trait_id = trait), parse_hsq(f, binary))
}), fill = TRUE)

res <- merge(res, manifest[, .(trait_id, label)], by = "trait_id", all.x = TRUE)
setorder(res, pcs, cohort, trait_id)
fwrite(res, file.path(results_dir, "dgreml_summary.tsv"), sep = "\t")
message("Wrote ", nrow(res), " rows to ", file.path(results_dir, "dgreml_summary.tsv"))
