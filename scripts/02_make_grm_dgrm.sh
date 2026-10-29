#!/usr/bin/env bash
# 02_make_grm_dgrm.sh
# Purpose : For each cohort, compute
#           (a) a standard GRM with GCTA (used for PCA),
#           (b) the GRM and the between-chromosome disequilibrium GRM (DGRM)
#               with makeDGRM (Zhang et al. 2025), used in the REML models,
#           (c) the top principal components from the GCTA GRM.
# Usage   : bash scripts/02_make_grm_dgrm.sh
# Input   : $WORK_DIR/<cohort>/geno/<cohort>_qc.*
# Output  : $WORK_DIR/<cohort>/grm/
#             <cohort>_gcta.grm.*          GCTA GRM (PCA input)
#             <cohort>.grm.*, <cohort>.gpd.grm.*   makeDGRM GRM and DGRM
#             <cohort>_gcta.eigenvec       PCs
#             mgrm.txt                     GRM list for GCTA --mgrm (G first, D second)
set -euo pipefail
source config/config.sh; source scripts/lib.sh

read_tsv_rows "$COHORTS_TSV" | cut -f1 | while read -r cohort; do
  bfile="${WORK_DIR}/${cohort}/geno/${cohort}_qc"
  out="${WORK_DIR}/${cohort}/grm"; mkdir -p "$out"

  "$GCTA_BIN" --bfile "$bfile" --make-grm --thread-num "$THREADS" --out "${out}/${cohort}_gcta"
  "$GCTA_BIN" --grm "${out}/${cohort}_gcta" --pca 20 --thread-num "$THREADS" --out "${out}/${cohort}_gcta"

  "$DGRM_BIN" --bfile "$bfile" --nthreads "$THREADS" --out "${out}/${cohort}"

  # The two GRMs must describe the same individuals in the same order.
  cmp "${out}/${cohort}.grm.id" "${out}/${cohort}.gpd.grm.id"

  # GCTA --mgrm expects a *.grm.N.bin next to each GRM. If makeDGRM did not
  # write one, reuse the GCTA file (same SNP set, same individuals).
  cmp "${out}/${cohort}.grm.id" "${out}/${cohort}_gcta.grm.id"
  for p in "${cohort}" "${cohort}.gpd"; do
    [[ -f "${out}/${p}.grm.N.bin" ]] || cp "${out}/${cohort}_gcta.grm.N.bin" "${out}/${p}.grm.N.bin"
  done

  # Order matters: G1 = GRM (random-mating component), G2 = DGRM (GPD component)
  printf '%s\n%s\n' "${out}/${cohort}" "${out}/${cohort}.gpd" > "${out}/mgrm.txt"
done
