# 🧪 City A HCV Data Quality Analysis

This project leverages mock Electronic Lab Reporting (ELR) data to evaluate hepatitis C virus (HCV) testing and reporting quality in a jurisdiction referred to as "City A." The goal was to simulate a real-world epidemiologic surveillance analysis by identifying trends and gaps in data related to disease occurrence and HCV seroconversion.

## 📊 Project Overview

This analysis focused on two primary objectives:
- **HCV Positivity Patterns:** Identifying differences in positive HCV test results across sex, race/ethnicity, and age groups using logistic regression and data visualization (e.g., forest plots).
- **Seroconversion Analysis:** Estimating the average time between a negative and a positive HCV lab result (seroconversion) among eligible individuals during the study period (2022–2024).

## 🧬 Data Description

This project uses a mock dataset simulating ~14,000 ELR records, structured to resemble real-world HCV surveillance data submitted to a public health agency. Key variables include:
- Demographics: Age, sex, race/ethnicity, ZIP code, jurisdiction
- Lab data: Ordered test names, test results, collection dates

The data was designed with:
- ELR completeness variability (`Y`, `N`, and missing values)
- Realistic missingness and variation in patient records

## 📈 Key Findings

- **Higher Odds of Detection** among males and older adults (especially Baby Boomers).
- **Seroconversion Time** was longer in adults aged 50–69 and Hispanic individuals, potentially reflecting delayed follow-up or testing.
- **Surveillance Implication:** Targeted improvements in testing timeliness and data completeness could improve HCV surveillance accuracy and early intervention efforts.

## 📁 Files

- `data/HCV_ELR_MockData_CityA.csv`: Simulated dataset (~14K records)
- `data/HCV_ELR_MockData_CityA.csv`: SAS analysis dataset (~14k records)
- `analysis/CityA_ELR_HCV_analysis.sas`: SAS program to analyze HCV positivity and identify seroconversions
- `slides/City A_HD_HCV_Analysis.pdf`: Summary presentation

## 🧠 Skills Demonstrated

- Public health data cleaning and transformation
- Epidemiologic analysis using SAS (data cleaning, DATA step, PROC MEANS, PROC FREQ, PROC LOGISTIC, PROC SQL)
- Creation of forest plots and summary tables
- Application of surveillance principles to ELR data

## 🔒 Note

- All data used in this repository are simulated and do not represent real individuals. This project was created for portfolio and training purposes only. 
- This project was inspired by a presentation delivered at the 2018 Texas HIV/STD Conference. While the analytic topic and structure were influenced by the presentation, this work was independently developed using **simulated data** and conducted in **SAS**. Additionally, this project includes a **seroconversion analysis**, which was **not part of the original presentation**.

---

📬 For questions or collaboration, feel free to reach out via GitHub or LinkedIn.

