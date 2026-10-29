#!/usr/bin/env bash
# Template SLURM job: one DGREML run per cohort. Adjust resources to your cluster.
# Usage: sbatch --export=COHORT=cohortA slurm/submit_dgreml.sh
#SBATCH --job-name=dgreml
#SBATCH --cpus-per-task=8
#SBATCH --mem=32G
#SBATCH --time=24:00:00
#SBATCH --output=logs/dgreml_%j.out
set -euo pipefail
cd /path/to/dgreml-heritability-am
mkdir -p logs
bash scripts/04_run_dgreml.sh --cohort "${COHORT:?set COHORT}" --pcs "${PCS:-20}"
