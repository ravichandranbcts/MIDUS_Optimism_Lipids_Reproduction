# Reproducibility study: Optimism and Lipids in Midlife (Boehm et al., 2013)

**Status: research-based reproduction package; numerical replication pending local MIDUS data and variable mapping.** The published values in `reference/` are **transcribed comparison targets, not independently reproduced results**. No claims of an exact reproduction should be made until the scripts are run and the outputs checked.

## Paper
Boehm JK, Williams DR, Rimm EB, Ryff C, Kubzansky LD. (2013). *Relation between Optimism and Lipids in Midlife.* American Journal of Cardiology, 111(10), 1425-1431. DOI: 10.1016/j.amjcard.2013.01.292. Full text: https://pmc.ncbi.nlm.nih.gov/articles/PMC3644345/

## Research question
Whether greater dispositional optimism is associated with a healthier serum lipid profile among MIDUS II participants. The published analytic sample is N=990. The paper contains **Figure 1 and Tables 1–5**, in addition to sensitivity/secondary analyses described in text.

## Data and use restrictions — READ FIRST
- MIDUS II Core/Social/Psychological data: https://www.icpsr.umich.edu/web/NACDA/studies/4652
- MIDUS II Biomarker Project: https://www.icpsr.umich.edu/web/NACDA/studies/29282
- Public-use data may be obtainable from ICPSR, but **MIDUS forbids redistribution**. MIDUS conditions updated March 16, 2026 also prohibit uploading public-use MIDUS files to AI platforms. **Do not upload MIDUS data to ChatGPT or the public GitHub classroom repository.** See https://midus.wisc.edu/data-access/ and the ICPSR study terms.
- Download and process MIDUS data **locally** using the rules presented by ICPSR. Only submit code, methodological notes, the original published comparison statistics, and non-disclosive output after checking the data use terms.

For precise local download instructions, see `DATA_DOWNLOAD_GUIDE.md`.

## Folder layout
```
README.md                  Setup, sources, commands, disclosure
PROJECT_REPORT.Rmd         Project draft in reproducible R Markdown
SETUP_DATA.md              Detailed steps for constructing the input
DATA_DOWNLOAD_GUIDE.md      Official study links, login instructions and data-use restrictions
R/run_analysis.R           Creates Figure 1, Tables 1–5, secondary/sensitivity outputs
R/toy_example.R            Simulated demonstration; no MIDUS observations
config/analysis_ready_schema.csv   Required variables and coding rules
reference/                Published, transcribed results for comparison only
figures/                   Generated locally, not included
 tables/                   Generated locally, not included
 data/private/             Your local data (ignored by Git)
```

## Local prerequisites
Install R (recommended R 4.3+) and RStudio. The main analysis requires only base R; rendering the report additionally requires `rmarkdown` and its dependencies. Optional clustered-model sensitivity requires `geepack`.

## Run instructions
1. Download ICPSR 4652 and 29282 **to your own computer** after reading and accepting the terms.
2. Use the codebooks to identify source column names and original missing-value codes. Join relevant MIDUS II data **by M2ID** (never row order); exclude cases according to the article's eligibility and complete-case criteria.
3. Construct `data/private/analysis_ready.csv`, matching every field and coding convention in `config/analysis_ready_schema.csv`. See `SETUP_DATA.md` for cautions and metadata verification.
4. Run from the repository's top-level folder:
   ```sh
   Rscript R/run_analysis.R
   Rscript -e 'rmarkdown::render("PROJECT_REPORT.Rmd")'
   ```
5. Examine `logs/analysis_validation.txt`; the paper's complete-case analytic n=990 and optimism group counts 334/300/356 are **targets**, not hardcoded filters. Compare outputs in `tables/` with `reference/`.
6. Inspect values, assess differences due to treatment correction, missing-value codes, categorical recodes, dates, multiple observations/family clusters, and version updates. Update the reproducibility status only after successfully running the actual data.

### What is implemented?
- Figure 1: optimism score distribution, paper-defined low/medium/high groups.
- Table 1: descriptive participant characteristics by optimism, ANOVA/chi-squared p-values.
- Table 2: correlations between optimism and covariates.
- Table 3: linear regressions of four lipid measures with demographic and demographic+health models.
- Table 4: coefficient attenuation after adding candidate behavior pathways and BMI.
- Table 5: logistic regressions for high-risk lipid status.
- Secondary analyses: raw vs medication-corrected lipids; no-medication sample; medication covariate; negative-affect adjustment; race interaction; optional family-cluster GEE.

### Important limitations
The original researchers used SAS 9.2 and did not publish an executable end-to-end analysis script in the article. Constructing all recoded variables, particularly the prudent-diet index, medication status, chronic condition indicator, the months between assessments and accurate complete-case selection requires careful work with ICPSR codebooks. This package **does not** automatically discover, download or impute those survey-specific mappings. `run_analysis.R` expects a verified analysis-ready CSV and intentionally fails with a clear error when it is missing. It does not fake or estimate missing results.

## Citations
- Boehm JK et al. (2013), DOI 10.1016/j.amjcard.2013.01.292, PMC3644345.
- MIDUS II, ICPSR 4652, DOI 10.3886/ICPSR04652.v8.
- MIDUS II Biomarker, ICPSR 29282, DOI 10.3886/ICPSR29282.v11 (current public landing page; study version may differ from 2013).
- MIDUS data policy, https://midus.wisc.edu/data-access/.
