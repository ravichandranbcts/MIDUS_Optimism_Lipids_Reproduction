# Preparing the MIDUS data for an actual reproduction

**These steps must be performed locally. Do NOT upload MIDUS files to a public AI service or GitHub.**

1. Obtain the survey datasets (ICPSR 4652) and the biomarker project (ICPSR 29282) from the official ICPSR study pages. Record the exact study version and download date. The current 2025 biomarker revision has new variables and corrected value labels, so it may not be identical to what was available to the 2013 researchers.
2. Read the study codebooks and documentation. Survey-scale variable `B1SORIEN` is documented as MIDUS II overall Life Orientation Test optimism, but **confirm the scoring, imputation/missing codes and sample-specific validity** with the exact study release you use. The 6-item composite ranges from 6 to 30, with higher values representing optimism.
3. Identify each relevant variable from `config/analysis_ready_schema.csv` using the codebooks; create standardized columns with the EXACT names in that file. Recode original missing categories before analysis. Do not treat values like 8/98/999 as NA without checking the field-specific codebook: some are valid in other fields.
4. Merge relevant files by `M2ID`, verify M2ID uniqueness by project and validate family IDs when present. Include only the appropriate longitudinal MIDUS II participants. Ensure that the 2013 paper's N=990 can be obtained by applying appropriate complete-case restrictions; do not select an arbitrary 990 rows to force a match.
5. Construct scales and recodes: sex 0=male/1=female, race 0=white/1=nonwhite, education 1=<HS/2=HS/3=some college/4=college+, smoking 1=current/2=past/3=never, chronic and medication 0/1, exercise 0/1; income thousands of US dollars; dates expressed as time between psychosocial and clinical assessments in months; diet index 0–7; negative affect 1–5. See paper Methods for definitions.
6. Verify the covariate sample includes all variables, even those only used in secondary analyses. The published sample of 990 is explicitly complete-case on all primary confounders AND pathways. Keep a flow log with counts at each exclusion step.
7. Ensure lipid values are original **uncorrected** mg/dL figures in `analysis_ready.csv`. The R script applies paper's correction to people using lipid medication: total cholesterol ×1.20, LDL ×1.35, triglycerides ×1.15, HDL ×0.95. The precise interpretation of medication adjustment and any LDL computation should be checked against the paper and the raw documentation.
8. Save a CSV as `data/private/analysis_ready.csv` using UTF-8, header row, one row per person. All 21 required columns must be present. Optional `family_id` supports clustered GEE check. The file must remain local and untracked.
9. Execute `Rscript R/run_analysis.R`; read `logs/analysis_validation.txt`, then compare numeric outputs with paper reference files. Report differences transparently.

## How to check what the input schema requires
Open `config/analysis_ready_schema.csv`. Most raw ICPSR variable codes have deliberately NOT been guessed: guessing silently produces invalid scientific results. Some standard variable names are derived constructs, which require more than renaming a single source column.

## Determining reproducibility
Success means independently rerunning Figure 1, Tables 1–5, and sensitivity checks on the genuine source data, with close agreement in sample n, scaling, coefficient size, standard errors, odds ratios, and other reported diagnostics. If that has not been achieved, label the project **partial reproduction/incomplete numerical verification**.
