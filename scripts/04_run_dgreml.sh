#!/usr/bin/env bash
# 04_run_dgreml.sh
# Purpose : Fit the DGREML model for every cohort x trait combination.
#           Model: y ~ N(Xb, sg2*G + delta*D + se2*I)
# Usage   : bash scripts/04_run_dgreml.sh [--pcs K] [--cohort ID] [--trait ID]
#           K defaults to $N_PCS (main analysis). Use 0 or 10 for sensitivity.
# Input   : GRM lists (02), covariates (03), trait manifest, phenotype files
# Output  : $RESULTS_DIR/dgreml/pc<K>/<cohort>/<trait>.hsq (+ .log, .mgrm.txt)
set -euo pipefail
source config/config.sh; source scripts/lib.sh

pcs=$N_PCS; only_cohort=""; only_trait=""
while [[ $# -gt 0 ]]; do
  case $1 in
    --pcs) pcs=$2; shift 2;;
    --cohort) only_cohort=$2; shift 2;;
    --trait) only_trait=$2; shift 2;;
    *) echo "Unknown argument: $1" >&2; exit 1;;
  esac
done

read_tsv_rows "$COHORTS_TSV" | cut -f1 | while read -r cohort; do
  [[ -n "$only_cohort" && "$cohort" != "$only_cohort" ]] && continue
  grm_list="${WORK_DIR}/${cohort}/grm/mgrm.txt"
  cov="${WORK_DIR}/${cohort}/covar/sex.covar"
  qcov="-"; [[ "$pcs" -gt 0 ]] && qcov="${WORK_DIR}/${cohort}/covar/pc${pcs}.qcovar"
  out_dir="${RESULTS_DIR}/dgreml/pc${pcs}/${cohort}"; mkdir -p "$out_dir"

  read_tsv_rows "$MANIFEST_TSV" | while IFS=$'\t' read -r trait label pheno type prev; do
    [[ -n "$only_trait" && "$trait" != "$only_trait" ]] && continue
    if [[ -s "${out_dir}/${trait}.hsq" ]]; then echo "skip ${cohort}/${trait} (done)"; continue; fi
    cp "$grm_list" "${out_dir}/${trait}.mgrm.txt"      # record G/D order with the result
    run_reml "$grm_list" "${PHENO_DIR}/${cohort}/${pheno}" "$type" "$prev" \
             "$qcov" "$cov" "${out_dir}/${trait}" || echo "FAILED ${cohort}/${trait}" >&2
  done
done
