---
title: "Risk Factors – ITN Guinea DHS 2018"
layout: page
permalink: /projects/itn-ownership-use-guinea-dhs2018/
---

# {{ page.title }}


> **Period:** 2021–2022 · **Role:** Lead Data Analyst · **Country:** Guinea

## Overview
Analysis of the 2018 Guinea Demographic and Health Survey (DHS) to identify determinants of **ownership** and **use** of insecticide-treated nets (ITNs) at both household and individual levels. Understanding the factors influencing household ITN ownership and usage among those with access will enable the Guinea National Malaria Control Programme to design targeted interventions aimed at increasing bed net coverage and utilization.

## Key Highlights
- Main variables: wealth quintiles, education level, urban/rural setting, Age of household head, Age of individual, Sex of household head, Sex of individual, Household size, Number of rooms, Marital status, 
Children under five, Pregnant status, Region.
- Two main outcomes: **ITN ownership** and **ITN use the previous night** (among those with access).
- Accounted for complex survey design: weights, strata, and clusters.

## Methods & Tools
Survey-weighted logistic regression models were implemented in R (`survey`, `srvyr`, `dplyr`, `ggplot2`, `tmap`) to estimate adjusted odds ratios and visualize disparities.

## Deliverables
- Tables and figures for manuscript and policy brief.
- Fully reproducible R scripts (data cleaning, indicator generation, modeling).

## Impact
- Evidence to better target **priority groups** in ITN distribution campaigns.
- Recommendations to tailor behavior change communication messages.

## Links
[![Download Article (PDF)](https://img.shields.io/badge/PDF-Download-red?logo=adobeacrobatreader)](https://link.springer.com/content/pdf/10.1186/s12936-023-04463-z.pdf)
[![View Code on GitHub](https://img.shields.io/badge/View%20Code%20on%20GitHub-181717?logo=github&logoColor=white)](https://github.com/ousmanerabi/Risk_factors_ITN_Guinea_DHS_2018)
