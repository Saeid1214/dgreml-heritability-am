# dgreml-heritability-am

A methods pipeline for estimating how much of SNP-based heritability is
attributable to directional gametic phase disequilibrium (GPD), a genomic
signature of assortative mating (AM), using disequilibrium GREML (DGREML;
Zhang et al. 2025).

> **Scope.** The underlying cohort data are confidential and access-restricted.
> This repository documents the analysis workflow. All paths, cohort names and
> trait identifiers are placeholders. It is not designed to reproduce published
> numbers without access to the data.

## Model

For each trait, in each cohort, GCTA REML fits

    y ~ N(Xb,  sg2 * G  +  delta * D  +  se2 * I)

| Term | Meaning |
|---|---|
| `G` | genomic relationship matrix (GRM) |
| `D` | disequilibrium GRM (DGRM): between-chromosome covariance among SNPs, computed with `makeDGRM` |
| `sg2` | additive genetic variance expected under random mating |
| `delta` | additional variance attributable to directional GPD (may be negative) |

Reported quantities (Vp = total phenotypic variance):

- `h2_RM  = sg2 / Vp`
- `h2_GPD = delta / Vp`
- `proportion = h2_GPD / (h2_RM + h2_GPD)`
- two-sided Wald test of `delta = 0`

Binary traits are analysed with Fisher scoring and reported on the liability
scale (population prevalence from the manifest). Continuous traits use the
default AI-REML algorithm. Covariates are sex and the first 20 principal
components; 0 and 10 PCs are run as sensitivity analyses.

## Workflow

```
01_genotype_qc.sh          HapMap3 SNPs, unrelated Europeans, MAF/HWE/missingness
02_make_grm_dgrm.sh        GCTA GRM + PCA; makeDGRM GRM and DGRM; GRM list (G, then D)
03_prepare_covariates.sh   sex and PC covariate files (10 and 20 PCs)
04_run_dgreml.sh           cohort x trait loop (--pcs, --cohort, --trait optional)
05_pc_sensitivity.sh       repeats 04 with 0 and 10 PCs
06_summarise_results.R     parses .hsq files into one tidy table
plots/07_plot_pc_sensitivity.R   proportion by trait across PC settings
slurm/submit_dgreml.sh     template job script
```

Each step reads the shared settings in `config/config.sh`.

## Setup

1. Install GCTA (>= 1.94) and `makeDGRM`
   ([Zenodo record 14429245](https://zenodo.org/records/14429245)), plus PLINK 1.9 and R.
   `conda env create -f environment.yml` covers PLINK and R.
2. Copy `config/config.sh` to `config/config.local.sh` and set paths.
3. Copy the two `*_example.tsv` files in `config/` to `cohorts.tsv` and
   `trait_manifest.tsv` and fill them in.
   - `cohorts.tsv`: cohort ID, per-chromosome genotype prefix with `{chr}`, keep-file of unrelated European individuals.
   - `trait_manifest.tsv`: trait ID, label, phenotype file (GCTA format: FID IID value; binary traits coded 0/1), `binary`/`continuous`, prevalence.

## Run

```bash
bash scripts/01_genotype_qc.sh
bash scripts/02_make_grm_dgrm.sh
bash scripts/03_prepare_covariates.sh
bash scripts/04_run_dgreml.sh            # main analysis (20 PCs)
bash scripts/05_pc_sensitivity.sh        # 0 and 10 PCs
Rscript scripts/06_summarise_results.R results
Rscript plots/07_plot_pc_sensitivity.R results
```

Completed runs are skipped on re-run, so the loop can be resumed.

## Notes

- **GRM order matters.** GCTA labels components by their position in the GRM list. Step 02 writes `G` first and `D` second; step 04 stores a copy of the list with every result, and step 06 refuses to summarise a result if the order is wrong.
- **Negative `delta` is allowed** (`--reml-no-constrain`), so estimates are not truncated at zero.
- **No multiple-testing correction** is applied in the summary table.
- Principal components are computed per cohort from that cohort's GCTA GRM.
- Step 02 copies the GCTA `grm.N.bin` next to the `makeDGRM` outputs if `makeDGRM` does not write one, because `--mgrm` expects it. Both sets use the same SNPs and individuals (checked by comparing `.grm.id` files).

## References

- Zhang Y, et al. The contribution of gametic phase disequilibrium to the heritability of complex traits. *Nature Genetics* 57, 1418–1425 (2025). doi:10.1038/s41588-025-02192-4
- Yang J, et al. GCTA: a tool for genome-wide complex trait analysis. *Am J Hum Genet* 88, 76–82 (2011).

## License

MIT, see `LICENSE`.
