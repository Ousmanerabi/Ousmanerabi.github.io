### Logistic regression

## Summarize baseline characteristics by early IAC exposure status

# create a vector to include the covariate
library(gtsummary)

# explanatory_vars <- c("wealth", "sex", "urb", "Num_childre", "region", "rooms", "hh_size", "Edu", "head_age", "Marital")
# 
# for(i in 1:length(explanatory_vars)){
#   col = explanatory_vars[i]
#   tbl <- svytable(~HH_at_least_one + col, design_sample_hh)
#   t = summary(tbl, statistic="Chisq")
#   t = plyr::ldply(t)
# }

final_cohort_v2 <- final_cohort %>%
  dplyr::mutate(
    ethnicity_grp = dplyr::case_when(
      ethnicity %in% c("ASIAN") ~ "ASIAN",
      ethnicity %in% c("BLACK", "BLACK/AFRICAN AMERICAN") ~ "BLACK",
      ethnicity %in% c("WHITE") ~ "WHITE",
      TRUE ~ "OTHER"
    ),
    insurance_grp= dplyr::case_when(
      insurance %in% c("Government", "Medicaid", "Medicare")~"Public",
      insurance %in% c("Self Pay") ~ "Uninsured",
      TRUE~"Private"
    ),
    adm_type_grp = case_when(
      admission_type == "ELECTIVE" ~ "ELECTIVE",
      admission_type %in% c("URGENT", "EMERGENCY") ~ "NON ELECTIVE",
      TRUE ~ "OTHER"
    ),
    first_careunit_exclu = ifelse(first_careunit=="CSRU", 1, 0),
    icu_type = case_when(
      first_careunit == "MICU" ~ "MICU",
      first_careunit %in% c("SICU", "TSICU") ~ "SURGICAL",
      first_careunit == "CCU" ~ "CARDIAC",
      TRUE ~ "OTHER"
    ),
    iac_exposed_re = ifelse(iac_exposed==0, "No-IAC", "IAC")
  )

# Excluded the patients admitted in CSRU – Cardiac Surgery Recovery Unit

final_cohort_v3 = final_cohort_v2 %>%
  dplyr::filter(first_careunit_exclu == 0,
                vaso_24h==0) %>%
  dplyr::select(subject_id, hadm_id, icustay_id, intime, outtime, icu_los_hours,
                age, mv_start, death_28d, iac_exposed, vaso_24h, gender,
                insurance_grp, icu_type, charlson_score, adm_type_grp,iac_exposed_re, ethnicity_grp) %>%
  dplyr::mutate(
    dplyr::across(
      c(death_28d, iac_exposed_re, vaso_24h, gender, insurance_grp, icu_type, adm_type_grp,
        ethnicity_grp),
      as.factor
    )
  )

table2 <-
  tbl_summary(
    final_cohort_v3,
    include = c(age,gender, insurance_grp, icu_type, charlson_score, adm_type_grp, death_28d,
                ethnicity_grp),
    by = iac_exposed_re, # split table by group
    missing = "no" # don't list missing data separately
  ,
  label = list(age = "Age (years)", gender="Sex",
               charlson_idex="Charlson comorbidity index",
               icu_type="ICU type",
               #vaso_24h="Vasopressor use (first 24h)",
               ethnicity_grp = "Ethnic group",
               insurance_grp = "Insurance",
               adm_type_grp = "Admission type",
               death_28d = "28-day mortality"
               )) |> 
  add_n() |> # add column with total number of non-missing observations
  add_p() |> # test for a difference between groups
  modify_header(label = "**Variable**") |> # update the column header
  bold_labels() 

##


tab1_smd <- final_cohort_v3 %>% dplyr::select(age, gender,charlson_score,
                                              icu_type,
                            insurance_grp, adm_type_grp, death_28d, iac_exposed_re,
                            ethnicity_grp) %>%
  tbl_summary(
    by = iac_exposed_re,
    label = list(age = "Age (years)", 
                 gender="Sex",
                 charlson_idex="Charlson comorbidity index",
                 icu_type="ICU type",
                 #vaso_24h="Vasopressor use (first 24h)",
                 insurance_grp = "Insurance",
                 adm_type_grp = "Admission type",
                 ethnicity_grp = "Ethnic group",
                 death_28d = "28-day mortality"),
    statistic = list(
      all_continuous() ~ "{median} ({p25}, {p75})",
      all_categorical() ~ "{n} ({p}%)"
    ),
    missing = "no"
  ) %>%
  add_difference(
    test = list(
      all_continuous() ~ "smd",
      all_categorical() ~ "smd"
    )
  ) %>%
  modify_header(
    estimate ~ "**SMD**"
  ) %>%
  bold_labels()

### Logistic regression

final_cohort_v3$ethnicity_grp <- relevel(
  final_cohort_v3$ethnicity_grp,
  ref = "WHITE"
)

final_cohort_v3 = final_cohort_v3 %>%
  dplyr::mutate(age10=age/10)

fit <- glm(death_28d~iac_exposed_re+age10+gender+charlson_score+icu_type+insurance_grp+adm_type_grp+ethnicity_grp, family = binomial, data = final_cohort_v3)

### Display the model fit
summary(fit)

## Odds ratio
questionr::odds.ratio(fit)

## Forest plot

ggstats::ggcoef_model(fit, exponentiate = TRUE,
                      variable_labels = c(age10 = "Age (per 10 years)",
                                          iac_exposed_re="Exposure",
                                          gender="Sex",
                                          charlson_idex="Charlson comorbidity index",
                                          icu_type="ICU type",
                                          #vaso_24h="Vasopressor use (first 24h)",
                                          insurance_grp = "Insurance",
                                          adm_type_grp = "Admission type",
                                          ethnicity_grp = "Ethnic group"),
                      no_reference_row = broom.helpers::all_categorical(),
                      categorical_terms_pattern = "{level}/{reference_level}")


### Propensity score matching

final_cohort_v3$iac_exposed_re <- relevel(as.factor(final_cohort_v3$iac_exposed_re), ref = "No-IAC")


library(MatchIt)


match_obj_1 <- matchit(
  iac_exposed_re ~ age + gender + charlson_score + icu_type +
    insurance_grp + adm_type_grp + ethnicity_grp,
  data = final_cohort_v3,
  method   = "nearest",
  distance = "glm",
  ratio    = 1,
  replace  = FALSE,
  caliper  = 0.2
)

summary(match_obj_1)

matched_data <- match.data(match_obj_1)

matched_data <- matched_data %>%
  dplyr::mutate(age10 = age / 10)


fit_ps_adj <- glm(
  death_28d ~ iac_exposed_re + age10,
  family = binomial,
  data = matched_data
)
summary(fit_ps_adj)


### Love plot

install.packages("cobalt")
library(cobalt)

bt <- bal.tab(match_obj_1, un = TRUE, disp.v.ratio = FALSE, binary = "std")

bal <- bt$Balance %>%
  tibble::rownames_to_column("term") %>%
  # optionnel: si jamais "distance" apparaît, on l'enlève
  filter(!is.na(term), term != "", term != "distance", term != "(Intercept)") %>%
  transmute(
    term,
    smd_pre  = Diff.Un,
    smd_post = Diff.Adj,
    # ---- variable "mère" ----
    base_key = case_when(
      term %in% c("age", "charlson_score") ~ term,              # continues
      grepl("_", term) ~ sub("_(?!.*_).*", "", term, perl=TRUE), # avant le dernier "_"
      TRUE ~ term
    ),
    base_var = recode(base_key,
                      age           = "Age (years)",
                      gender        = "Sex",
                      charlson_score= "Charlson score",
                      icu_type      = "ICU type",
                      insurance_grp = "Insurance",
                      adm_type_grp  = "Admission type",
                      ethnicity_grp = "Ethnic group",
                      .default      = base_key
    )
  ) %>%
  group_by(base_var) %>%
  summarise(
    smd_pre  = max(abs(smd_pre),  na.rm = TRUE),
    smd_post = max(abs(smd_post), na.rm = TRUE),
    .groups = "drop"
  ) %>%
  pivot_longer(c(smd_pre, smd_post), names_to="sample", values_to="smd") %>%
  mutate(sample = recode(sample,
                         smd_pre  = "Before matching",
                         smd_post = "After matching"))

# Ordre: du pire au meilleur AVANT matching
order_levels <- bal %>%
  dplyr::filter(sample == "Before matching") %>%
  dplyr::arrange(smd) %>%
  pull(base_var)

bal <- bal %>%
  dplyr::mutate(base_var = factor(base_var, levels = rev(order_levels)))

ggplot2::ggplot(bal, aes(x = smd, y = base_var, shape = sample, color=sample)) +
  geom_point(size = 3) +
  geom_vline(xintercept = 0.1, linetype = "dashed") +
  labs(
    x = "Absolute Standardized Mean Difference (|SMD|)",
    y = "",
    title = "Covariate balance before and after propensity score matching",
    subtitle = "Acceptable balance threshold: |SMD| < 0.10"
  ) +
  theme_minimal(base_size = 14)


##
# ============================================================
# IPTW (Inverse Probability of Treatment Weighting) - ATE
# ============================================================

library(dplyr)
library(WeightIt)
library(cobalt)
library(survey)
library(broom)

# -----------------------------
# 0) Check exposure coding
# -----------------------------
final_cohort_v3 <- final_cohort_v3 %>%
  mutate(
    iac_exposed_re = factor(iac_exposed_re)
  )

# Met "No-IAC" comme référence (important pour l'interprétation)
final_cohort_v3$iac_exposed_re <- relevel(final_cohort_v3$iac_exposed_re, ref = "No-IAC")

table(final_cohort_v3$iac_exposed_re, useNA = "ifany")

# -----------------------------
# 1) Fit propensity score weights (ATE)
# -----------------------------
w_out <- weightit(
  iac_exposed_re ~ age + gender + charlson_score + icu_type +
    insurance_grp + adm_type_grp + ethnicity_grp,
  data     = final_cohort_v3,
  method   = "ps",     # PS via logistic regression
  estimand = "ATE"     # ATE weights
)

summary(w_out)

# Extract weights
final_cohort_v3$w_iptw <- w_out$weights

# -----------------------------
# 2) Diagnostics: weights
# -----------------------------
summary(final_cohort_v3$w_iptw)
quantile(final_cohort_v3$w_iptw, probs = c(.01, .05, .1, .5, .9, .95, .99), na.rm = TRUE)

# Quick plot
hist(final_cohort_v3$w_iptw, breaks = 50, main = "IPTW weights distribution", xlab = "Weight")

# Optionnel: truncation (souvent utile si poids extrêmes)
# Ici exemple 1st-99th percentile
w_lo <- quantile(final_cohort_v3$w_iptw, 0.01, na.rm = TRUE)
w_hi <- quantile(final_cohort_v3$w_iptw, 0.99, na.rm = TRUE)

final_cohort_v3 <- final_cohort_v3 %>%
  mutate(
    w_iptw_trunc = pmin(pmax(w_iptw, w_lo), w_hi)
  )

# -----------------------------
# 3) Balance diagnostics post-weighting (SMD)
# -----------------------------
# Table de balance
bt_w <- bal.tab(w_out, un = TRUE, disp.v.ratio = FALSE, binary = "std")
bt_w

# Love plot agrégé (1 ligne par variable) - cobalt >= 4
love.plot(
  w_out,
  stats = "mean.diffs",
  abs = TRUE,
  threshold = 0.10,
  var.order = "unadjusted",
  drop.distance = TRUE,
  sample.names = c("Before weighting", "After weighting"),
  aggregate = "max"
)

# -----------------------------
# 4) Weighted outcome model (logistic) with robust SE
# -----------------------------
# Survey design object (robust SE via sandwich)
des <- svydesign(
  ids     = ~1,
  weights = ~w_iptw_trunc,  # utilise w_iptw si tu ne veux pas truncation
  data    = final_cohort_v3
)

fit_iptw <- svyglm(
  death_28d ~ iac_exposed_re + age + gender + charlson_score + icu_type +
    insurance_grp + adm_type_grp + ethnicity_grp,
  design = des,
  family = quasibinomial()
)

summary(fit_iptw)

# OR + CI
or_tab <- broom::tidy(fit_iptw, conf.int = TRUE, exponentiate = TRUE)
or_tab

# Extraire seulement l'effet IAC (IAC vs No-IAC)
or_tab %>% filter(grepl("^iac_exposed_re", term))

# -----------------------------
# 5) Option: weighted marginal effect (unadjusted outcome model)
#     (souvent présenté comme estimand après équilibrage)
# -----------------------------
fit_iptw_marginal <- svyglm(
  death_28d ~ iac_exposed_re,
  design = des,
  family = quasibinomial()
)

broom::tidy(fit_iptw_marginal, conf.int = TRUE, exponentiate = TRUE)
