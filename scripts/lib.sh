#!/usr/bin/env bash
# Shared helpers. Source after config/config.sh.
#
# run_reml <grm_list> <pheno> <trait_type> <prevalence> <qcovar|-> <covar|-> <out_prefix>
#   Fits y ~ N(Xb, sg2*G + delta*D + se2*I) with GCTA REML.
#   - the GRM list must contain G first and D second (G1 = RM, G2 = GPD)
#   - --reml-no-constrain lets delta take negative values
#   - binary traits: Fisher scoring (--reml-alg 1) and liability-scale
#     transformation (--prevalence); continuous traits: default AI-REML

read_tsv_rows() {  # print data rows of a TSV (skip header, blank and # lines)
  tail -n +2 "$1" | grep -v '^\s*$' | grep -v '^#'
}

run_reml() {
  local grm_list=$1 pheno=$2 type=$3 prev=$4 qcov=$5 cov=$6 out=$7
  local args=(--reml --mgrm "$grm_list" --pheno "$pheno"
              --reml-no-constrain --reml-maxit 200
              --thread-num "$THREADS" --out "$out")
  [[ "$qcov" != "-" ]] && args+=(--qcovar "$qcov")
  [[ "$cov"  != "-" ]] && args+=(--covar "$cov")
  if [[ "$type" == "binary" ]]; then
    args+=(--reml-alg 1 --prevalence "$prev")
  fi
  "$GCTA_BIN" "${args[@]}"
}
