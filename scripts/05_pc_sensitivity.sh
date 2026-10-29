#!/usr/bin/env bash
# 05_pc_sensitivity.sh
# Purpose : Repeat the DGREML analysis with 0 and 10 principal components
#           (the 20-PC run from 04 is the main analysis).
# Usage   : bash scripts/05_pc_sensitivity.sh
# Output  : $RESULTS_DIR/dgreml/pc0/..., pc10/...
set -euo pipefail
for k in 0 10; do bash scripts/04_run_dgreml.sh --pcs "$k"; done
