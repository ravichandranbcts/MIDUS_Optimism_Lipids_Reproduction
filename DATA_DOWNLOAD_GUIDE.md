# Official MIDUS II datasets: download and local-use guide

## Sources for the Boehm et al. (2013) reproducibility project

1. **MIDUS II survey (ICPSR 4652)**: https://www.icpsr.umich.edu/web/NACDA/studies/4652
   - Study version currently shown: V8 (2021-09-15).
   - Select the **Data & Documentation** tab and download the aggregated / core MIDUS II survey data relevant to optimism, covariates, and the survey codebook; obtain the associated README, scale documentation, and variable naming conventions.
2. **MIDUS II Biomarker Project (ICPSR 29282)**: https://www.icpsr.umich.edu/web/NACDA/studies/29282
   - Study version currently shown: V11 (2025-06-18), with updates since the 2013 paper.
   - From **Data & Documentation**, select **DS1 Aggregated Data**, not only **DS2 Stacked Medication Data**, plus codebook and blood/urine/saliva, constructed-scale, and data-file documentation. Obtain DS2 if drug-specific sensitivity analyses need medication records.

NACDA describes free public-use access as requiring an ICPSR account, login, and acceptance of the terms before downloading: https://www.icpsr.umich.edu/sites/nacda/posts/shared/how-do-i-access-the-data-is-it-free

## Required download procedure — do this on your own computer

1. Create/sign in to your ICPSR account in a normal browser. Open the two *study-specific* links above (not the general NACDA or ICPSR homepage).
2. Open **Data & Documentation**. Choose an R-ready export if available, otherwise CSV/SPSS/Stata with its codebook. Download the core survey data, biomarker DS1 aggregate, and documentation. Record the date, filenames, study release versions, and any applicable version notes.
3. Extract the ZIPs **locally** into a folder outside your public repository, or into `data/private/` for local execution only. Do not commit data to Git. Verify filenames, M2ID fields and compatible formats against the codebooks.
4. Match respondent records by `M2ID`, not by ordering of rows. Convert source-variable values and missing codes into the standardized fields defined in `config/analysis_ready_schema.csv`, producing `data/private/analysis_ready.csv`.
5. Execute `Rscript R/run_analysis.R` on your own computer and check the generated tables/figures against the article. Keep log files and report any non-reproduced results rather than forcing agreement.

## MIDUS terms and privacy

The official MIDUS data-access policy prohibits **redistributing participant-level data** and **uploading MIDUS data to AI platforms including ChatGPT**. It also specifies noncommercial use and cell suppression for cells smaller than 10 in distributed tabulations. Review and accept all current use conditions yourself before retrieving the data: https://midus.wisc.edu/data-access/

**Never upload the participant-level ICPSR files in this chat or to GitHub.** You can share non-sensitive public documentation, analysis code, and permitted aggregate validation outputs for assistance. When citing data, include ICPSR 04652 and 29282 with their actual release versions.

## Limits of the supplied reproducibility package

This repository includes code and comparison targets, not ICPSR data or independently regenerated paper figures/tables. The published 2013 analysis may rely on earlier versions of both studies; differences should be investigated and documented.
