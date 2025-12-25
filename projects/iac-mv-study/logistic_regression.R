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

fit <- glm(death_28d~iac_exposed_re+age+gender+charlson_score+icu_type+insurance_grp+adm_type_grp+ethnicity_grp, family = binomial, data = final_cohort_v3)

### Display the model fit
summary(fit)

## Odds ratio
questionr::odds.ratio(fit)

## Forest plot


