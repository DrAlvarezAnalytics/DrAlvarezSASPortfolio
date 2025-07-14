/***************************************************************************************************************
****************************************************************************************************************
*** Author: Carlos R. Alvarez 
*** Create Date: July 2025
*** Purpose: This SAS program examines adverse event reports related to measles-containing vaccines (MMR, MMRV) from 2014–2024 
***          to identify patterns by age group, severity, and symptom clusters, 
***          and to explore potential safety signals in passive surveillance data.
*** Modified by:
*** Modify Date: 
*** Peer Review:
*** Peer Review Start Date:
*** OS: Windows 10 Pro 64-bit
*** Software: SAS 9.4
*** Program: VAERS_AE_SAS_analysis.sas
*** Note: The input dataset was created from the publicly available VAERS (Vaccine Adverse Event Reporting System) files, 
***       integrating VAERSDATA, VAERSVAX, and VAERSSYMPTOMS tables for the years 2014 to 2024. 
***       Data were managed and merged using SQLiteStudio prior to statistical analysis in SAS.
**************************************************************************************************************/

/*Define Library*/
libname vaers '/home/cralvarezhdz0/VAERS_Project';

/*Import dataset for analysis*/
proc import datafile='/home/cralvarezhdz0/VAERS_Project/mmwrvaersalldata.csv'
			out=mmwralldata
			DBMS=csv replace;
			GETNAMES=yes;
run;

ods pdf file='/home/cralvarezhdz0/VAERS_Project/VAERS_MMR_Safety_Analysis_Output.pdf' style=statistical;
/*Data Exploration and Quality Control*/
proc contents data=work.mmwralldata varnum;
run;

*Create flag variables for seriousness and year_group/modify age_yrs to create whole numbers;
data vaers_analysis;
    set work.mmwralldata;
    Length Age_group $30;
    
    *Seriousness;
    if died = 'Y' or hospital = 'Y' or er_visit = 'Y' or disable = 'Y' or l_threat = 'Y' then
        seriousness = 1;
    else seriousness = 0;
    
    *Year Group;
    year_group = year(recvdate);
    
    *Convert Age to whole numbers;
    Age = floor(age_yrs);
    
    *Create Age Group;
    if age =. then Age_Group="Missing";
    else if age < 1 then age_group = "<1 year";
    else if 1 <= age < 5 then age_group = "1-4 years";
    else if 5 <= age < 18 then age_group = "5-17 years";
    else if 18 <= age < 65 then age_group = "18-64 years";
    else if age >= 65 then age_group = "65+ years";
run;
    
*Checks for outliers or implausible values, Visual review of distribution;
proc univariate data=work.vaers_analysis;
	var age;
	histogram age/ normal;
	inset n mean median std min max;
	Title 'Age Distribution of MMR/MMRV VAERS Reports (2014-2024)';
run;

*Identify missing or miscoded categories, spot patterns in serious vs non-serious events;
proc freq data=work.vaers_analysis;
	tables sex seriousness year_group / missing nocum;
	title'Frequency of MMR/MMRV Reports by Sex, Seriousness, and Year';
run;

*Check for missingnes;
proc freq data=vaers_analysis;
    tables age sex seriousness / missing;
    title "Missing Data Check";
run;

*Create a Symptoms dataset for analysis;
data symptom_long;
    set vaers_analysis(keep=vaers_id age_group sex seriousness symptom1-symptom5);
    length symptom $200;

    array sym(*) symptom1-symptom5;

    do i = 1 to dim(sym);
        if sym(i) ne "" and sym(i) ne " " then do;
            symptom = sym(i);
            output; /* Create one row per symptom */
        end;
    end;

    drop i symptom1-symptom5;
   
run;

*Remove non-clinical terms from top symptom list;
data symptoms2;
	set symptom_long;
	
	if upcase(symptom) in ("NO ADVERSE EVENT", 
         "PRODUCT STORAGE ERROR", 
         "INCORRECT PRODUCT STORAGE","EXPIRED PRODUCT ADMINISTERED",
         "EXTRA DOSE ADMINISTERED") then delete; 
run;

/*Primary Descriptive Analysis*/

*Seriousness Comparison by Age and Sex;
proc freq data=vaers_analysis;
    tables seriousness*age_group / chisq norow nocol;
    title "Serious vs Non-Serious MMR/MMRV Adverse Events by Age Group";
run;

proc freq data=vaers_analysis;
    tables seriousness*sex / chisq norow nocol;
    title "Serious vs Non-Serious MMR/MMRV Adverse Events by Sex";
run;

*Yearly Trend Analysis;
proc freq data=vaers_analysis;
    tables year_group*seriousness / chisq norow nocol;
    title "Trend in Serious vs Non-Serious MMR/MMRV Events by Year";
run;

proc sgplot data=vaers_analysis;
    vbar year_group / group=seriousness groupdisplay=stack stat=freq;
    title "Yearly Trend of Serious vs Non-Serious MMR/MMRV Reports";
run;

*Create a list with the Top 10 most reported symptoms;
title 'Count of Top 10 Reported Symptoms';
proc sql outobs=10;
    create table top10_symptoms as
    select symptom, 
           count(*) as count
    from symptoms2
    group by symptom
    order by count desc;
    
    select * from top10_symptoms;
quit;

*Calculate Predictors of Seriousness;
proc logistic data=work.vaers_analysis;
	class sex(Ref="U") age_group(Ref="<1 year")/ param=reference;
	model seriousness (Event="1") = sex age_group;
	oddsratio sex;
	oddsratio age_group;
	Title'Logistic Regression: Predictors of Serious Adverse Events (MMR/MMRV)';
run;

*Create data for forest plot;
ods output OddsRatios=or_results;
proc logistic data=vaers_analysis descending;
    class sex(ref="F") age_group(ref="<1 year") / param=ref;
    model seriousness(event='1') = sex age_group;
run;

*Prepare data for forest plot;
data forest_data;
    set or_results;
    label = catx(": ", Effect, Level);  /* Create labels like Sex: M */
    logOR = log(OddsRatioEst);
run;

*Plot the forest plot;
proc sgplot data=forest_data noautolegend;
    scatter y=label x=OddsRatioEst / 
        xerrorlower=LowerCL xerrorupper=UpperCL 
        datalabel=OddsRatioEst
        markerattrs=(symbol=diamondfilled size=10);
    refline 1 / axis=x lineattrs=(pattern=shortdash);
    xaxis type=log label="Odds Ratio (Log Scale)";
    yaxis discreteorder=data label="Predictors";
    title "Forest Plot of Odds Ratios: Predictors of Serious Adverse Events";
run;
ods pdf close;
