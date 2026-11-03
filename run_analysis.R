# Reproduction workflow for Boehm et al. (2013), AJC 111:1425-1431.
# This script MUST be run locally with a licensed/authorized MIDUS extract.
# No participant-level data should be uploaded to public repositories or AI systems.
# Published paper comparison files are stored separately in reference/.

input <- Sys.getenv("ANALYSIS_DATA", "data/private/analysis_ready.csv")
if (!file.exists(input)) {
  stop(paste0("Local input missing: ", input,
              "\nRead SETUP_DATA.md, then construct the standardized analysis-ready CSV locally. ",
              "No numbers have been fabricated."), call. = FALSE)
}

for (p in c("tables", "figures", "logs")) dir.create(p, showWarnings = FALSE, recursive = TRUE)
d <- read.csv(input, stringsAsFactors = FALSE, check.names = FALSE)
required <- c("optimism", "age", "sex", "race", "education", "income", "months_between",
              "chronic", "bp_meds", "bmi", "smoking", "alcohol", "prudent_diet",
              "exercise", "neg_affect", "lipid_meds", "lipid_dx", "tc", "hdl", "ldl", "tg")
missing_fields <- setdiff(required, names(d))
if (length(missing_fields)) stop("Missing required columns: ", paste(missing_fields, collapse = ", "), call. = FALSE)

# The standardized CSV MUST contain numeric variables with codebook missing values
# already converted to NA. Never blindly replace 8, 9, 98 or 999 for all columns.
for (v in required) {
  if (!is.numeric(d[[v]])) {
    converted <- suppressWarnings(as.numeric(d[[v]]))
    malformed <- !is.na(d[[v]]) & trimws(as.character(d[[v]])) != "" & is.na(converted)
    if (any(malformed)) stop("Column ", v, " has nonnumeric values; check local recoding")
    d[[v]] <- converted
  }
}
if ("id" %in% names(d) && anyDuplicated(d$id)) stop("ID values are not unique. Verify M2ID merge")

# Include variables for sensitivity/secondary models in complete-case definition;
# this is intentionally strict to mimic the paper's sample selection.
n_before <- nrow(d)
d <- d[stats::complete.cases(d[, required]), , drop = FALSE]
if (nrow(d) < 30) stop("Too few complete cases. Check extraction and missing values")
if (any(d$optimism < 6 | d$optimism > 30)) stop("Optimism scale out of 6..30 range")
if (any(!d$sex %in% c(0,1))) stop("Sex must be coded 0=male, 1=female")
if (any(!d$race %in% c(0,1))) stop("Race must be coded 0=white, 1=nonwhite")
if (any(!d$education %in% 1:4)) stop("Education must be coded 1..4")
if (any(!d$smoking %in% 1:3)) stop("Smoking must be coded 1=current/2=past/3=never")
for (v in c("chronic", "bp_meds", "exercise", "lipid_meds", "lipid_dx"))
  if (any(!d[[v]] %in% c(0,1))) stop("Bad binary coding in column ", v)
if (any(d$tc <= 0 | d$hdl <= 0 | d$ldl <= 0 | d$tg <= 0))
  stop("Invalid lipid concentration found; revisit raw missing codes")

# Treatment adjustments described in Methods: applied to uncorrected assay values.
d$tc_adj <- ifelse(d$lipid_meds == 1, d$tc * 1.20, d$tc)
d$ldl_adj <- ifelse(d$lipid_meds == 1, d$ldl * 1.35, d$ldl)
d$tg_adj <- ifelse(d$lipid_meds == 1, d$tg * 1.15, d$tg)
d$hdl_adj <- ifelse(d$lipid_meds == 1, d$hdl * 0.95, d$hdl)
d$log_tg_adj <- log(d$tg_adj)
d$optimism_z <- as.numeric(scale(d$optimism))
d$optimism_group <- cut(d$optimism, breaks = c(5.5, 22.5, 26.5, 30.5),
                         labels = c("Low", "Moderate", "High"), ordered_result = TRUE)
d$sex_fac <- factor(d$sex, levels = c(0,1), labels = c("Male", "Female"))
d$race_fac <- factor(d$race, levels = c(0,1), labels = c("White", "Non-white"))
d$education_fac <- factor(d$education)
d$smoking_fac <- factor(d$smoking)
d$chronic_fac <- factor(d$chronic)
d$bp_meds_fac <- factor(d$bp_meds)
d$exercise_fac <- factor(d$exercise)

# Compare important reproducibility checkpoints with published numbers.
groups <- table(d$optimism_group)
check <- c(paste("Source:", input), paste("Original input rows:", n_before),
           paste("Complete-case N:", nrow(d), "(published 990)"),
           paste("Low / Moderate / High:", paste(as.integer(groups), collapse=" / "),
                 "(published 334 / 300 / 356)"),
           sprintf("Optimism mean / SD: %.3f / %.3f (published 23.95 / 4.69)",
                   mean(d$optimism), sd(d$optimism)),
           paste("Lipid-med users:", sum(d$lipid_meds), "(published 284)"),
           "NOTE: If N/checks differ, do not call this an exact replication; re-check documentation, time variables and missing data.")
writeLines(check, "logs/analysis_validation.txt")
if (nrow(d) != 990) warning("Complete-case sample differs from published N=990; see logs/analysis_validation.txt")

# Figure 1 — observed frequency by integer LOT-R score, paper's tertile coloring.
png("figures/Figure1_optimism_frequency.png", width = 1700, height = 950, res = 190)
obs <- as.integer(table(factor(d$optimism, levels = 6:30)))
cols <- ifelse(6:30 <= 22, "black", ifelse(6:30 <= 26, "gray65", "white"))
barplot(obs, names.arg = 6:30, col = cols, border = "black", space = 0.12,
        xlab = "Optimism score (6–30)", ylab = "Frequency",
        main = "Figure 1 reproduction: distribution of optimism scores")
legend("topleft", legend = c("Low: 6–22", "Moderate: 23–26", "High: 27–30"),
       fill = c("black", "gray65", "white"), border = "black", bty = "n")
dev.off()

fmt <- function(z) ifelse(is.na(z), "NA", sprintf("%.2f", z))
# Table 1 — descriptive characteristics by tertiles; p-values from ANOVA/Chi-square.
grp_names <- levels(d$optimism_group)
mean_sd <- function(x) sprintf("%.2f (%.2f)", mean(x), sd(x))
cont <- c("age", "income", "months_between", "bmi", "alcohol", "prudent_diet",
          "neg_affect", "tc_adj", "hdl_adj", "ldl_adj", "tg_adj")
catvars <- c("sex", "race", "education", "chronic", "bp_meds", "smoking", "exercise")
t1 <- list()
for (v in cont) {
  vals <- sapply(grp_names, function(g) mean_sd(d[d$optimism_group == g, v]))
  pv <- summary(aov(d[[v]] ~ d$optimism_group))[[1]][1, "Pr(>F)"]
  t1[[length(t1) + 1L]] <- data.frame(variable = v, type = "Mean (SD)",
    Low = vals[[1]], Moderate = vals[[2]], High = vals[[3]], p_value = pv)
}
for (v in catvars) {
  tab <- table(d[[v]], d$optimism_group)
  p <- tryCatch(suppressWarnings(chisq.test(tab)$p.value), error = function(e) NA_real_)
  for (lev in rownames(tab)) {
    pct <- 100 * tab[lev, ] / colSums(tab)
    t1[[length(t1) + 1L]] <- data.frame(variable = paste0(v, " = ", lev), type = "Column %",
      Low = sprintf("%.2f%%", pct[[1]]), Moderate = sprintf("%.2f%%", pct[[2]]),
      High = sprintf("%.2f%%", pct[[3]]), p_value = p)
  }
}
write.csv(do.call(rbind, t1), "tables/Table1_reproduced.csv", row.names = FALSE)

# Table 2 — Pearson correlations. Continuous codes for binary/ordinal variables
# follow the paper's footnotes (sex 0/1; smoking 1=current,2=past,3=never).
vars2 <- c("age", "sex", "race", "education", "income", "months_between", "chronic",
           "bp_meds", "bmi", "smoking", "alcohol", "prudent_diet", "exercise", "neg_affect")
t2 <- do.call(rbind, lapply(vars2, function(v) {
  z <- cor.test(d$optimism, d[[v]], method = "pearson")
  data.frame(characteristic = v, r = unname(z$estimate), p_value = z$p.value)
}))
write.csv(t2, "tables/Table2_reproduced.csv", row.names = FALSE)

# Main analysis formulas: baseline and adjustment for chronic conditions and BP meds.
demographics <- "optimism_z + age + sex_fac + race_fac + education_fac + income + months_between"
health <- " + chronic_fac + bp_meds_fac"
get_optimism <- function(model, logistic = FALSE) {
  sm <- coef(summary(model))
  if (!"optimism_z" %in% rownames(sm)) stop("No optimism_z estimate in model")
  est <- sm["optimism_z", "Estimate"]
  se <- sm["optimism_z", "Std. Error"]
  if (logistic) {
    # Wald 95% confidence intervals, similar to SAS default report conventions.
    c(estimate = exp(est), se = se, lower = exp(est - 1.96*se),
      upper = exp(est + 1.96*se), p = sm["optimism_z", ncol(sm)])
  } else {
    ci <- confint(model, parm = "optimism_z", level = .95)
    c(estimate = est, se = se, lower = ci[1], upper = ci[2],
      p = sm["optimism_z", ncol(sm)])
  }
}
model_spec <- list("Model 1" = demographics, "Model 2" = paste0(demographics, health))
outcomes <- c("Total cholesterol" = "tc_adj", "HDL cholesterol" = "hdl_adj",
              "LDL cholesterol" = "ldl_adj", "Log triglycerides" = "log_tg_adj")
t3 <- list()
for (out in names(outcomes)) for (spec in names(model_spec)) {
  fit <- lm(as.formula(paste(outcomes[[out]], "~", model_spec[[spec]])), data=d)
  cfs <- get_optimism(fit)
  t3[[length(t3)+1L]] <- data.frame(measure=out, model=spec,
                                    estimate=cfs["estimate"], std_error=cfs["se"],
                                    lower95=cfs["lower"], upper95=cfs["upper"], p=cfs["p"])
}
write.csv(do.call(rbind, t3), "tables/Table3_reproduced.csv", row.names=FALSE)

# Table 4 — attenuation of optimism coefficient from Model 1 when candidate
# health-behavior pathways are considered singly and together.
paths <- list("Demographics" = "", "Plus prudent diet" = "prudent_diet",
              "Plus exercise" = "exercise_fac", "Plus smoking" = "smoking_fac",
              "Plus alcohol" = "alcohol", "Plus BMI" = "bmi",
              "Plus all pathways" = "prudent_diet + exercise_fac + smoking_fac + alcohol + bmi")
t4 <- list()
for (out in c("HDL cholesterol", "Log triglycerides")) {
  initial <- NULL
  for (p in names(paths)) {
    terms <- demographics
    if (nzchar(paths[[p]])) terms <- paste0(terms, " + ", paths[[p]])
    fit <- lm(as.formula(paste(outcomes[[out]], "~", terms)), data=d)
    est <- get_optimism(fit)
    if (is.null(initial)) initial <- est["estimate"]
    pct <- if (p == "Demographics" || initial == 0) NA_real_ else
      100 * (est["estimate"] / initial - 1)
    t4[[length(t4)+1L]] <- data.frame(outcome=out, model=p,
                  estimate=est["estimate"], std_error=est["se"], change_pct=pct)
  }
}
write.csv(do.call(rbind, t4), "tables/Table4_reproduced.csv", row.names=FALSE)

# Table 5 — adverse risk status on raw lipids; lipid medication OR diagnosis OR
# conventional cutpoint. Sex-specific HDL cutpoints are explicitly applied.
d$bad_tc <- as.integer(d$lipid_meds == 1 | d$lipid_dx == 1 | d$tc >= 240)
d$bad_hdl <- as.integer(d$lipid_meds == 1 | d$lipid_dx == 1 |
                        (d$sex == 0 & d$hdl < 40) | (d$sex == 1 & d$hdl < 50))
d$bad_ldl <- as.integer(d$lipid_meds == 1 | d$lipid_dx == 1 | d$ldl >= 160)
d$bad_tg <- as.integer(d$lipid_meds == 1 | d$lipid_dx == 1 | d$tg >= 200)
risk_outcomes <- c("Total cholesterol"="bad_tc", "HDL cholesterol"="bad_hdl",
                   "LDL cholesterol"="bad_ldl", "Triglycerides"="bad_tg")
t5 <- list()
for (out in names(risk_outcomes)) for (spec in names(model_spec)) {
  fit <- glm(as.formula(paste(risk_outcomes[[out]], "~", model_spec[[spec]])),
             data = d, family=binomial(link="logit"))
  cfs <- get_optimism(fit, logistic=TRUE)
  t5[[length(t5)+1L]] <- data.frame(measure=out, model=spec,
    odds_ratio=cfs["estimate"], lower95=cfs["lower"], upper95=cfs["upper"], p=cfs["p"])
}
write.csv(do.call(rbind, t5), "tables/Table5_reproduced.csv", row.names=FALSE)

# Secondary and sensitivity analyses (reported narratively in the original paper).
# Results can differ with codebook treatment of dates, medicines, chronic conditions.
sens <- list()
for (out in c("HDL cholesterol", "Log triglycerides")) {
  raw <- if (out == "HDL cholesterol") "hdl" else "log(tg)"
  adjust <- outcomes[[out]]
  fits <- list("Corrected main model" = lm(as.formula(paste(adjust, "~", demographics)), d),
               "Original uncorrected lipids" = lm(as.formula(paste(raw, "~", demographics)), d),
               "Exclude lipid-med users" = lm(as.formula(paste(raw, "~", demographics)),
                                              d[d$lipid_meds == 0, , drop=FALSE]),
               "Add lipid medicine covariate" = lm(as.formula(paste(raw,"~", demographics,
                                                       "+ factor(lipid_meds)")), d),
               "Add negative affect" = lm(as.formula(paste(adjust,"~", demographics,
                                                  "+ neg_affect")), d),
               "Race interaction" = lm(as.formula(paste(adjust,"~", demographics,
                                                  "+ optimism_z:race_fac")), d))
  for (nm in names(fits)) {
    est <- get_optimism(fits[[nm]])
    sens[[length(sens)+1L]] <- data.frame(measure=out, analysis=nm,
      estimate=est["estimate"], lower95=est["lower"], upper95=est["upper"], p=est["p"])
  }
}
write.csv(do.call(rbind, sens), "tables/Secondary_sensitivity_analyses.csv", row.names=FALSE)

# Optional GEE family-cluster analysis. Requires true family IDs: never infer from
# adjacent rows or create fake clusters. Can be skipped without invalid main outputs.
if ("family_id" %in% names(d) && all(!is.na(d$family_id)) &&
    requireNamespace("geepack", quietly=TRUE)) {
  # geeglm requires clusters in adjacent rows. Working correlation = independence;
  # robust SE accounts for observed group clustering (family/twin pairs).
  d <- d[order(d$family_id), , drop=FALSE]
  gee <- list()
  for (out in names(outcomes)) {
    fit <- geepack::geeglm(as.formula(paste(outcomes[[out]], "~", demographics)),
                           id = d$family_id, data = d, corstr = "independence")
    sm <- summary(fit)$coefficients
    gee[[length(gee)+1L]] <- data.frame(measure=out,
       estimate=sm["optimism_z", "Estimate"], robust_se=sm["optimism_z", "Std.err"])
  }
  write.csv(do.call(rbind, gee), "tables/GEE_optional.csv", row.names=FALSE)
}

writeLines(c(paste("R version:", R.version.string),
             capture.output(sessionInfo())), "logs/session_info.txt")
cat(paste(check, collapse="\n"), "\n")
cat("Wrote Figure 1, Tables 1–5, secondary analyses and validation logs.\n")
