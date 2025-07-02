# Claims-Based Adherence Analysis

This project uses simulated pharmacy claims data to evaluate medication adherence among patients prescribed oral antihypertensive medications. The analysis calculates key adherence metrics (PDC and MPR) and explores demographic differences in adherence, including racial and ethnic disparities.

## 📊 Project Overview

- **Type:** Real-World Evidence (RWE) / Claims-based analysis  
- **Dataset:** Simulated patient-level pharmacy claims (951 patients)  
- **Tools Used:**  
  - SAS (data manipulation, statistical analysis)  
  - Tableau Public (data visualization)  

## 🎯 Objectives

- Compute **Proportion of Days Covered (PDC)** and **Medication Possession Ratio (MPR)**
- Identify patients who are adherent (PDC ≥ 80%)
- Analyze adherence rates across:
  - Age
  - Sex
  - Payer type
  - Race/Ethnicity
- Use logistic regression to identify predictors of non-adherence

## 📁 Files
- `data/AxMed_Claims_Mock_Dataset.csv`: Simulated dataset
- `data/AxMed_Claims_Analysis_Dataset.xls`: Excel analysis dataset (Used for Tableau Dashboard)
- `analysis/AxMed_Claims_Analysis.sas`: SAS program to calculate PDC, MPR and adherence
- `Reporting/AxMed_Claims_Analysis_Output.pdf`: SAS program Output
- `Reporting/AxMed_Claims_SAP.pdf`: Fictional Organization Statistical Analysis Plan (SAP)

## 🧠 Skills Demonstrated

- **Pharmacy Claims Data Analysis**: Interpreted and manipulated longitudinal prescription fill data to calculate patient-level adherence metrics (PDC, MPR).
- **SAS Programming**: Utilized SAS for data cleaning, summary statistics, conditional logic, and logistic regression modeling.
- **Real-World Evidence (RWE) Methodology**: Applied RWE concepts to assess real-world medication use and adherence patterns across demographic subgroups.
- **Health Equity Analysis**: Stratified adherence outcomes by race/ethnicity and payer type to evaluate disparities in access or engagement.
- **Data Simulation**: Generated a synthetic but realistic dataset to mimic claims-based structures used in public health and pharma settings.
- **Data Visualization**: Created interactive dashboards in Tableau Public to communicate adherence patterns and subgroup comparisons effectively.
- **Documentation & Reporting**: Developed a Statistical Analysis Plan (SAP) and exported results to structured PDF output for stakeholders.



