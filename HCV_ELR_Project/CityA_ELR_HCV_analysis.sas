/***************************************************************************************************************
****************************************************************************************************************
*** Author: Carlos R. Alvarez 
*** Create Date: June 2025
*** Purpose: This SAS program creates a SAS dataset including mock HCV laboratory reports received by fictional City A Health Deparment
			 This program also creates:
			 -An analysis to assess HCV occurrence and rates in City A. 
			 -An odd ratio analysis in HCV occurence by age, race and sex in City A.
			 -Identifies seroconversion rates within the surveillance period (2022-2024)	 
*** Modified by:
*** Modify Date: 
*** Peer Review:
*** Peer Review Start Date:
*** OS: Windows 10 Pro 64-bit
*** Software: SAS 9.4
*** Program: CityA_ELR_HCV_analysis.sas
*** Note: The input dataset for this analysis was generated using commercially-available generative AI models (Chatgpt 4o)
**************************************************************************************************************/

/*define library*/
libname elrhcv '/home/cralvarezhdz0/ELR Data HCV';

/*Import CSV file downloaded from City A Surveillance System*/
proc import datafile='/home/cralvarezhdz0/ELR Data HCV/HCV_ELR_MockData_CityA.csv' out=elrhcv.dataHCV
			DBMS=csv replace;
			GETNAMES=yes;
run;


/*Explore data variables to identify outliers, missing data*/
proc univariate data=elrhcv.datahcv;
	var date_specimen_collected event_date patient_dob date_received_by_Public_Health date_created;
run;

/*Create a new dataset to only include does laboratory records for Hepatitis C with a patient DOB, and categorize Detected vs Not-Detected*/
data work.hcv2ds;
	set elrhcv.datahcv;
	Length HCVRes $100;
	
	/*keep only HCV related lab records*/
	if index(strip(upcase(resulted_test_name)), "HCV") > 0 or 
       index(strip(upcase(resulted_test_name)), "HEP C") > 0 or
       index(strip(upcase(resulted_test_name)), "HEPATITIS C") > 0;
    
    /*During initial review, some lab records did not include Patient's date of Birth. 
	It was determined that those records will be deleted since verification is not possible.*/
	if patient_dob=. then delete;
	
	  /*categorize Detected vs Not-Detected*/  
	 
      if coded_result in('1A','1a','1b','2A OR 2C','2b','3a','DETECTED','Detected','GENOTYPE 1a','GENOTYPE 1b','GENOTYPE 2b',	
      'GENOTYPE 3a','GENOTYPE 6a','High Pos','Low Pos','POSITIVE','Positive','REACTIVE','Reactive','Reactive (qu','positive',	
      'reactive') then HCVRes='Detected';
      
      else HCVRes='Not-Detected';
      
      /*Categorize those lab records with a numeric result but not coded result. All Numeric results indicate a presence of HCV virus*/
      if coded_result='' and numeric_results ne '' then HCVRes='Detected';
      
      label HCVRes='HCV Result';
run;

/*Create analysis variables (Age at testing, year of lab result, etc)*/
data datahcv1;
	set work.hcv2ds;
	Length age_group $20;
	
	/*Calculate Age at Reporting (Lab_creation_date minus DOB divided by 365.25)*/
	Age_at_Reporting = floor((date_specimen_collected - patient_dob)/365.25);
	
	/*Calculate Year of Reporting*/
	Collection_Year= year(date_specimen_collected);	
	
	/*Group Ages into 4 different groups relevant to HCV historical burden*/
	  
    	if Age_at_Reporting <= 29 then age_group = "0-29";
    	else if 30 <= Age_at_Reporting <= 49 then age_group = "30–49";
    	else if 50 <= Age_at_Reporting <= 69 then age_group = "50–69";
    	else if Age_at_Reporting >= 70 then age_group = "70 + years";
    	
	/*Calculate a Baby Boomer vs not Baby Boomer Category*/
		if   1945 <= year(patient_dob) <= 1965 then BBoom='Yes';
		else BBoom='No';
	
	label BBoom='Baby Boomer';
run;

/************************************************************Analysis*************************************************************/
/*Create an analysis-ready temporary dataset*/
data work.HCV1ds label;
	set datahcv1;
run;

/*******************************Descriptive Statistics on lab records*******************************/
/*Calculate percentage of lab records reported electronically*/
proc freq data=hcv1ds;
	tables elr_indicator;
run;

/*Calcuate number of lab records reported by year*/
proc freq data=work.hcv1ds;
	tables collection_year*hcvres;
run;

proc sgplot data=work.hcv1ds;
	styleattrs datacolors=(gray royalblue);
    vbar collection_year / group=hcvres
                        stat=freq
                        groupdisplay=cluster
                        datalabel;
    xaxis label="Collection Year";
    yaxis label="Number of reported HCV lab records";
    title "HCV Lab Records Reported by Detection Status, 2022-2024";
run;

/*Calculate the proportion of HCV labs reported by Age Group*/
proc freq data=work.hcv1ds;
	tables age_group*hcvres;
	where hcvres='Detected';
run;

proc sgplot data=work.hcv1ds;
	where hcvres='Detected';
	styleattrs datacolors=(gray royalblue);
    vbar collection_year / group=age_group
                        stat=percent
                        groupdisplay=cluster
                        datalabel;
    xaxis label="Collection Year";
    yaxis label="Percent of reported positive HCV lab records";
    title "Positive HCV Lab Records Reported by age Group, 2022-2024";
run;

/*Calculate the proportion of HCV labs reported by Baby Boomer Category*/
proc freq data=work.hcv1ds;
	tables bboom*hcvres;
	where hcvres='Detected';
run;

proc sgplot data=work.hcv1ds;
	where hcvres='Detected';
	styleattrs datacolors=(gray royalblue);
    vbar collection_year / group=bboom
                        stat=percent
                        groupdisplay=cluster
                        datalabel;
    xaxis label="Collection Year";
    yaxis label="Percent of reported positive HCV lab records" values=(0 to 0.5 by 0.1);
    title "Positive HCV Lab Records Reported by Baby Boomer Category, 2022-2024";
run;

/*Calculate the proportion of HCV labs reported by Race/Ethnicity*/

*Calculate Positive Labs by Rac/Ethnicity;
proc sql;
    create table pos_by_race as
    select race_ethnicity,
           count(*) as n_pos
    from hcv1ds
    where hcvres = "Detected"
    group by race_ethnicity;
quit;

*Calculate total Positive Labs;
proc sql;
    create table total_pos as
    select sum(n_pos) as total_pos
    from pos_by_race;
quit;

*Calculate Percent by Race;
data percent_pos_by_race;
    if _n_ = 1 then set total_pos;
    set pos_by_race;
    percent = (n_pos / total_pos) * 100;
run;

Proc Gchart data=percent_pos_by_race;
	pie race_ethnicity / sumvar=n_pos
                         percent=inside
                         value=outside
                         slice=outside
                         coutline=black;
    format percent 5.1;
    title "Distribution of Positive HCV Labs by Race/Ethnicity, 2022-2024";
run;

/*Calculate the proportion of HCV labs reported by Sex */
proc freq data=work.hcv1ds;
	tables patient_current_Gender*hcvres;
	where hcvres='Detected';
run;

proc sgplot data=work.hcv1ds;
	where hcvres='Detected';
	styleattrs datacolors=(gray royalblue);
    vbar collection_year / group=patient_current_gender
                        stat=percent
                        groupdisplay=cluster
                        datalabel;
    xaxis label="Collection Year";
    yaxis label="Percent of reported positive HCV lab records" values=(0 to 0.5 by 0.1);
    title "Positive HCV Lab Records Reported by Gender, 2022-2024";
run;

/* Calculate Odds Ratio of a HCV positive Event by Sex and Race/Ethnicity*/
ods output OddsRatios=or_combined;
proc logistic data=hcv1ds descending;
    class patient_current_gender (ref="F") race_ethnicity (ref="Black") bboom (ref="No") / param=ref;
    model hcvres(event='Detected') = patient_current_gender race_ethnicity bboom;
    
    label Patient_current_gender='Sex' race_ethnicity='Race/Ethnicity' bboom='Baby Boomer';
    title "Odds of Positive HCV Lab by Sex, Race, and Baby Boomer (Ref: Female, Black, Not Baby Boomer)";
run;

data forest_data label;
    set or_combined;
    label = catx(": ", Effect, Level);  /* e.g., Sex: M */
    format OddsRatioEst LowerCL UpperCL 4.2;
    
    /* Create CI label as: 1.52 [1.20–1.93] */
    labelCI = cats(put(OddsRatioEst, 4.2), ' [', put(LowerCL, 4.2), '–', put(UpperCL, 4.2), ']');
run;

proc sgplot data=forest_data noautolegend;
    scatter y=label x=OddsRatioEst / 
        xerrorlower=LowerCL xerrorupper=UpperCL 
        datalabel=LabelCI
        datalabelattrs=(size=8 weight=bold color=black)
        markerattrs=(symbol=diamondfilled size=10 color=black);
    refline 1 / axis=x lineattrs=(pattern=shortdash color=gray);
    xaxis type=log label="Odds Ratio (log scale)" min=0.1 max=10;
    yaxis discreteorder=data label="Group Comparison";
    title "Odds of Positive HCV Lab by Sex, Race and Age Cohort (Forest Plot)";
run;


/*Identify Individuals that seroconverted during surveillance years*/
proc sort data=hcv1ds out=serohcv;
    by patient_local_id date_specimen_collected;
run;

data seroconverters;
    set serohcv;
    by patient_local_id;

    retain ever_notd ever_det first_neg_date first_pos_date;
    format first_neg_date first_pos_date mmddyy10.;

    if first.patient_local_id then do;
        ever_notd = 0;
        ever_det = 0;
        first_neg_date = .;
        first_pos_date = .;
    end;

    if hcvres = 'Not-Detected' and ever_notd = 0 then do;
        ever_notd = 1;
        first_neg_date = date_specimen_collected;
    end;

    if hcvres = 'Detected' and ever_notd = 1 and ever_det = 0 then do;
        ever_det = 1;
        first_pos_date = date_specimen_collected;
    end;

    if last.patient_local_id and ever_det = 1 then do;
        days_to_seroconversion = first_pos_date - first_neg_date;
        output;
    end;
run;

/*Calculate the number and percent of seroconverters by different demographic groups*/
proc freq data=seroconverters;
	tables patient_current_gender race_ethnicity age_group;
run;

/*Calculate the mean seroconversion time (in days) by different demographic groups*/
title "Time to HCV Seroconversion (Days)";
proc means data=seroconverters n mean median min max; 
    var days_to_seroconversion;   
run;

title "Time to HCV Seroconversion (Days) by Sex";
proc means data=seroconverters n mean median min max;
	class patient_current_gender; 
    var days_to_seroconversion;   
run;

title "Time to HCV Seroconversion (Days) by Race";
proc means data=seroconverters n mean median min max;
	class race_ethnicity; 
    var days_to_seroconversion;   
run;

title "Time to HCV Seroconversion (Days) by Age Group";
proc means data=seroconverters n mean median min max;
	class age_group; 
    var days_to_seroconversion;  
run;
title "Time to HCV Seroconversion (Days) by Baby Boomer Category";
  proc means data=seroconverters n mean median min max;
	class bboom; 
    var days_to_seroconversion;
run;
