# 🧪 Vaccine Safety Signal Analysis Using VAERS (2014–2024)

Analyzing 2014–2024 VAERS reports for measles-containing vaccines (MMR, MMRV) to identify adverse event patterns by age, severity, and symptom clusters. 
This project demonstrates real-world data integration and passive safety surveillance using structured SQL queries, and statistical modeling for signal detection.

## 📌 Objectives

- Integrate and manage multi-year VAERS datasets using SQLite
- Filter and analyze adverse event reports involving MMR/MMRV vaccines
- Characterize adverse event patterns by age group and seriousness
- Identify common symptom clusters across age categories
- Detect potential safety signals through descriptive statistics and modeling

## 🧰 Tools & Technologies

- **SQLiteStudio** – Data wrangling, joins, filtering, and preparation
- **SAS** – Descriptive analysis and logistic regression

## 📊 Key Deliverables

| Component | Description |
|----------|-------------|
| `VAERS_MMR_SQLScript` | SQL queries Extract, filter, and join VAERS Data/Symptom/Vax tables for MMR/MMRV |
| `mmrvaersalldata.csv` | Structured dataset with 2014–2024 MMR/MMRV reports |
| `VAERS_Analysis.sas` | SAS program for VAERS Project analysis|
| `VAERS_MMR_Safety_Analysis_Output.pdf` | Descriptive Statistics, Symptoms Analysis, Logistic Regression SAS Output |
| `VAERS_MMR_Safety_Analysis_Summary.pdf` | Summary/Interpretation document for VAERS MMR/MMRV project |

## 🔐 Notes

- This analysis uses publicly available de-identified data from the [VAERS database](https://vaers.hhs.gov/data/datasets.html).
- No patient identifiers or sensitive data were accessed.
- This project is for educational and portfolio purposes.
