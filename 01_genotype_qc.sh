#!/usr/bin/env bash
# 01_genotype_qc.sh
# Purpose : Build one HapMap3 genotype set per cohort for GRM/DGRM construction.
# Steps   : per chromosome, keep HapMap3 SNPs and unrelated individuals of
#           European ancestry with MAF/HWE/missingness filters; then merge
#           chromosomes into a single PLINK fileset.
# Usage   : bash scripts/01_genotype_qc.sh
# Input   : config/cohorts.tsv (cohort_id, genotype_pattern with {chr}, keep_file)
# Output  : $WORK_DIR/<cohort>/geno/<cohort>_qc.{bed,bim,fam}
set -euo pipefail
source config/config.sh; source scripts/lib.sh

read_tsv_rows "$COHORTS_TSV" | while IFS=$'\t' read -r cohort pattern keep; do
  out="${WORK_DIR}/${cohort}/geno"; mkdir -p "$out"
  : > "${out}/merge_list.txt"
  for chr in $(seq 1 22); do
    "$PLINK_BIN" --bfile "${pattern//\{chr\}/$chr}" \
      --extract "$HM3_SNPS" --keep "$keep" \
      --maf "$QC_MAF" --hwe "$QC_HWE" --geno "$QC_GENO" \
      --make-bed --out "${out}/chr${chr}"
    echo "${out}/chr${chr}" >> "${out}/merge_list.txt"
  done
  "$PLINK_BIN" --merge-list "${out}/merge_list.txt" --make-bed --out "${out}/${cohort}_qc"
  echo "[${cohort}] QC done: $(wc -l < "${out}/${cohort}_qc.bim") SNPs, $(wc -l < "${out}/${cohort}_qc.fam") individuals"
done
