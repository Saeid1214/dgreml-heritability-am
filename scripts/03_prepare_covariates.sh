#!/usr/bin/env bash
# 03_prepare_covariates.sh
# Purpose : Write covariate files for each cohort: sex (discrete) and the
#           first K principal components (quantitative), K = 20 and 10.
#           K = 0 uses sex only.
# Usage   : bash scripts/03_prepare_covariates.sh
# Input   : $WORK_DIR/<cohort>/grm/<cohort>_gcta.eigenvec, genotype .fam
# Output  : $WORK_DIR/<cohort>/covar/sex.covar, pc10.qcovar, pc20.qcovar
set -euo pipefail
source config/config.sh; source scripts/lib.sh

read_tsv_rows "$COHORTS_TSV" | cut -f1 | while read -r cohort; do
  out="${WORK_DIR}/${cohort}/covar"; mkdir -p "$out"
  eig="${WORK_DIR}/${cohort}/grm/${cohort}_gcta.eigenvec"
  fam="${WORK_DIR}/${cohort}/geno/${cohort}_qc.fam"
  awk '{print $1, $2, $5}' "$fam" > "${out}/sex.covar"
  for k in 10 20; do
    cut -d' ' -f1-$((k + 2)) "$eig" > "${out}/pc${k}.qcovar"
  done
done
