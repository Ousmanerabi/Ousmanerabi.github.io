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
      admission_type %in% c("URGENT", "EMERGENCY") ~ "NON_ELECTIVE",
      TRUE ~ "OTHER"
    )
  )


table2 <-
  tbl_summary(
    full_cohort_data,
    include = c(age,),
    by = trt, # split table by group
    missing = "no" # don't list missing data separately
  ) |> 
  add_n() |> # add column with total number of non-missing observations
  add_p() |> # test for a difference between groups
  modify_header(l