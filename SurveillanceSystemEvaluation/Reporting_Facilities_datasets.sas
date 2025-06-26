/********************************************************************************************************
         Narrative: Dataset creation for Evaluation of MDRO/CDI Module
Program name:Reporting_Facilities_datasets.sas
Purpose: Create datasets including facilities reporting data to the NHSN MDRO/CDI Module.
input: PSAnnualSurvey Datasets: sannualsurveyhosp, psannualsurveyirf, psannualsurveyltac, psannualsurveyltac,
       denomds
Output: SAS datasets 
Author name: Carlos R. Alvarez
 
Edit Author/Date: 
**********************************************************************************************************/
/*Define libraries*/

libname dtsource 'redacted';
libname project 'redacted\Evaluation Data';

/******************************************Create datasets to identify reporting facilities between 2019 and 2022 from the PSAnnualSurvey Datasets*************************************/
data achcah;
	set dtsource.psannualsurveyhosp;
	where surveyYear ge 2019 and surveyYear le 2022;
	keep orgid state surveyyear completeddate numbeds numpatdays numadmits;
run;

data irf;
	set dtsource.psannualsurveyirf;
	where surveyYear ge 2019 and surveyYear le 2022;
	keep orgid state surveyyear completeddate numbeds numpatdays numadmits;
run;

data list1 dup list2;
	merge achcah (in=in1) irf (in=in2); /*This data step is to identify those facilities reporting only IRF data*/
	by orgid;
	if in1=1 and in2=0 then output list1;
	else if in1=1 and in2=1 then output dup;
	else if in1=0 and in2=1 then output list2;

	keep orgid state surveyyear completeddate numbeds numpatdays numadmits;
run;

data ltac;
	set dtsource.psannualsurveyltac;
	where surveyYear ge 2019 and surveyYear le 2022;
	keep orgid state surveyyear completeddate numbeds numpatdays numadmits;
run;

data allfacsurv;
	set achcah list2 ltac;
run;

proc freq data=allfacsurv;
	tables surveyYear;
run;


/******************************************Create temporary denominator datasets for each year including facilities reporting from the MDRO_DENOM dataset*************************************/
data ds1;
	set project.denomds;
	noEventLabID_CREtot = s4
run;

proc sort data = ds1; 
	by orgid location; 
run; 

data ds2019 ds2020 ds2021 ds2022;
	set first1;
	if year=2019 then output ds2019;
	else if year=2020 then output ds2020;
	else if year=2021 then output ds2021;
	else output ds2022;
run;

data dsacine19 dscre;
	set ds2019;
	where noEventLabID_ACINE ne '';
run;

data dscephrkleb;
	set ds1;
	where noEventLabID_CEPHRKLEB ne '';
run;

/*Summarize at the location level*/
proc means data = ds1 NOPRINT;
by orgid location year state;
var numpatdays vre_labid cephrkleb_labid acine_labid crekleb_labid creecoli_labid creentero_labid;
output out = first1 SUM =;
run;

proc freq data=ds2019;
	tables year;
run;

proc freq data=ds2020;
	tables year;
run;

proc freq data=ds2021;
	tables year;
run;

proc freq data=ds2022;
	tables year;
run;


