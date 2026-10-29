#!/usr/bin/env bash
# Shared settings, sourced by every script. Copy to config/config.local.sh
# and edit; the local file (if present) overrides the values below.

PROJECT_ROOT="/path/to/project"          # working root (outputs go below it)
GCTA_BIN="gcta64"                        # GCTA executable
DGRM_BIN="/path/to/makeDGRM"             # makeDGRM executable
PLINK_BIN="plink"                        # PLINK 1.9 executable
THREADS=8
N_PCS=20                                 # main analysis; sensitivity uses 0 and 10

HM3_SNPS="/path/to/reference/hapmap3_snps.txt"   # one rsID per line
PHENO_DIR="${PROJECT_ROOT}/phenotypes"           # <cohort>/<pheno_file>

COHORTS_TSV="config/cohorts.tsv"                 # see cohorts_example.tsv
MANIFEST_TSV="config/trait_manifest.tsv"         # see trait_manifest_example.tsv

WORK_DIR="${PROJECT_ROOT}/work"                  # genotypes, GRMs, PCs, covariates
RESULTS_DIR="${PROJECT_ROOT}/results"            # .hsq files and summary tables

# QC thresholds for the HapMap3 genotype set
QC_MAF=0.01
QC_HWE=1e-6
QC_GENO=0.02

[[ -f "$(dirname "${BASH_SOURCE[0]}")/config.local.sh" ]] && \
  source "$(dirname "${BASH_SOURCE[0]}")/config.local.sh"
