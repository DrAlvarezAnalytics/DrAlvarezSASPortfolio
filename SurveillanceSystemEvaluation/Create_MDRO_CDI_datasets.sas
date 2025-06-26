/********************************************************************************************************
         Narrative: Dataset creation for Evaluation of MDRO/CDI Module
Program name:Create_MDRO_CDI_datasets.sas
Purpose: Create event and denominator datasets for non-required MDROs reported to the NHSN MDRO/CDI Module.
input: labidevents dataset (Monthly updated on the first of each month), mdro_denom, labidacinetobacter, 
		labidcre, labidvre, labidcephrkleb,psannualsurveyhosp, psannualsurveyirf, psannualsurveyltac
Output: SAS datasets 
Author name: Carlos R. Alvarez
 
Edit Author/Date: 
**********************************************************************************************************/
/*Define libraries*/
libname dtsource 'redacted';
libname project 'redacted/Evaluation Data';


/*********STEP 1 - Create copy Datasets for Analysis***********/

%let oldyear = 2019;
%let rcntyear =2022;


/*Select data for labid events from &oldyear to &rcntyear*/
data project.labid;
	set dtsource.labidevents;
	if spcorgtype not in ('MRSA','CDIF','MSSA');
	where year ge &oldyear and year le &rcntyear;

	if imported='Y' then CDARep='Yes';
	else CDARep='No';

	if spcorgtype in ('CREECOLI','CREKLEB','CREENTERO') then CREtot=1;
	else CREtot=0;

	if factype = 'HOSP-LTAC' then factype2 ='Long Term Acute Care Hospital';
	else if factype ='HOSP-REHAB' then factype2 ='Rehabilitation Facility';
	else if factype ='HOSP-CAH' then factype2 ='Critical Access Care Hospital';
	else factype2 = 'Acute Care Hospital';
run;

/*Select denominator data for &oldyear to &rcntyear from the MDRO_DENOM dataset*/
data project.denomds;	
	set dtsource.mdro_denom;
	if location='FACWIDEIN';
	where year ge &oldyear and year le &rcntyear;
	
	if factype = 'HOSP-LTAC' then factype2 ='Long Term Acute Care Hospital';
	else if factype ='HOSP-REHAB' then factype2 ='Rehabilitation Facility';
	else if factype ='HOSP-CAH' then factype2 ='Critical Access Care Hospital';
	else factype2 = 'Acute Care Hospital';
run;

/*Create temporary denominator datasets for each year including facilities reporting*/
data ds1;
	set project.denomds;
run;

proc sort data = ds1; 
	by orgid location; 
run; 

/*Summarize at the location level*/
proc means data = ds1 NOPRINT;
by orgid location factype factype2 year state;
var numpatdays vre_labid cephrkleb_labid acine_labid crekleb_labid creecoli_labid creentero_labid;
output out = first1 SUM =;
run;

data ds2019 ds2020 ds2021 ds2022;
	set first1;
	if year=2019 then output ds2019;
	else if year=2020 then output ds2020;
	else if year=2021 then output ds2021;
	else output ds2022;
run;


/*Create datasets to identify reporting facilities between &oldyear and &rcntyear from Psannualsurvey datasets*/
data achcah;
	set dtsource.psannualsurveyhosp;
	where surveyYear ge &oldyear and surveyyear le &rcntyear;
	keep orgid state factype factype2 surveyyear completeddate numbeds numpatdays numadmits;
	length factype2 $100;

	if factype ='HOSP-CAH' then factype2 ='Critical Access Hospital';
	else factype2 = 'Acute Care Hospital';

run;

data irf;
	set dtsource.psannualsurveyirf;
	where surveyYear ge &oldyear and surveyyear le &rcntyear;
	keep orgid state factype surveyyear completeddate numbeds numpatdays numadmits;
run;

data list1 dup list2;
	merge achcah (in=in1) irf (in=in2); /*This data step is to identify those facilities reporting only IRF data*/
	by orgid;
	if in1=1 and in2=0 then output list1;
	else if in1=1 and in2=1 then output dup;
	else if in1=0 and in2=1 then output list2;

	keep orgid state factype surveyyear completeddate numbeds numpatdays numadmits;
run;
data list2;
	set list2;
	factype2 ='Rehabilitation Facility';
run;

data ltac;
	set dtsource.psannualsurveyltac;
	where surveyYear ge &oldyear and surveyyear le &rcntyear;
	keep orgid state factype factype2 surveyyear completeddate numbeds numpatdays numadmits;
	factype2 ='Long Term Acute Care Hospital';
run;

data project.psannualsurveyallfac;
	set achcah list2 ltac;
run;

/*Create Denominator Data for each Non-Req MDRO from individual labid datasets*/
data acinedenom;
	set dtsource.labidacinetobacter;
	if year ge &oldyear and year le &rcntyear;
	where location='FACWIDEIN' and acine_labidplan=1;
run;

/*Summarize at the location level*/
proc means data = acinedenom NOPRINT;
by orgid location year state factype;
var numpatdays numadms numtotpatdays numTotAdm ACINE_labidCount;
output out = project.acine1 SUM =;
run;

data nonconsacine;
	set project.acine1;
	if _freq_ < 12 and year=2022;
run;

data acinedenom2022;
	set acinedenom;
	where year=2022;
run;

data monthnoncons;
	merge acinedenom2022 (in=in1) nonconsacine (in=in2); /*Change dataset names to determine what years to compare*/
	by orgid;
	if in1=1 and in2=1 then output ;
run;
proc sort data=monthnoncons;
	by month;
	run;

proc freq data=monthnoncons;
	tables month;
run;

data vredenom;
	set dtsource.labidvre;
	if year ge &oldyear and year le &rcntyear;
	where location='FACWIDEIN' and vre_labidplan=1;
run;

/*Summarize at the location level*/
proc means data = vredenom NOPRINT;
by orgid location year state factype;
var numpatdays numadms numtotpatdays numTotAdm VRE_labIDcount;
output out = project.vre1 SUM =;
run;

data nonconsvre;
	set project.vre1;
	if _freq_ < 12 and year=2022;
run;

data vredenom2022;
	set vredenom;
	where year=2022;
run;

data monthnonconsvre;
	merge vredenom2022 (in=in1) nonconsvre (in=in2); /*Change dataset names to determine what years to compare*/
	by orgid;
	if in1=1 and in2=1 then output ;
run;

proc freq data=monthnonconsvre;
	tables month;
run;

data credenom;
	set dtsource.labidcre;
	if year ge &oldyear and year le &rcntyear;
	where location='FACWIDEIN';
	CRETot_labidCount=sum(CREECOLI_labidCount, CREENTERO_labidCount, CREKLEB_labidCount);
run;

/*Summarize at the location level*/
proc means data = credenom NOPRINT;
by orgid location year state factype;
var numpatdays numadms numtotpatdays numTotAdm CREECOLI_labidCount CREENTERO_labidCount CREKLEB_labidCount;
output out = project.cre1 SUM =;
run;

data nonconscre;
	set project.cre1;
	if _freq_ < 12 and year=2022;
run;

data credenom2022;
	set credenom;
	where year=2022;
run;

data monthnonconscre;
	merge credenom2022 (in=in1) nonconscre (in=in2); /*Change dataset names to determine what years to compare*/
	by orgid;
	if in1=1 and in2=1 then output ;
run;

proc means data = monthnonconscre NOPRINT;
by orgid month;
var numpatdays numadms numtotpatdays numTotAdm CREECOLI_labidCount CREENTERO_labidCount CREKLEB_labidCount;
output out = monthnonconscre2 SUM =;
run;


proc sort data=monthnonconscre;
	by month;
	run;

proc freq data=monthnonconscre2;
	tables month;
run;


data cephrklebdenom;
	set dtsource.labidcephrkleb;
	if year ge &oldyear and year le &rcntyear;
	where location='FACWIDEIN' and cephrkleb_labidplan=1;
run;

/*Summarize at the location level*/
proc means data = cephrklebdenom NOPRINT;
by orgid location year state factype;
var numpatdays numadms numtotpatdays numTotAdm CEPHRKLEB_labidCount;
output out = project.cephrkleb1 SUM =;
run;


data nonconscephr;
	set project.cephrkleb1;
	if _freq_ < 12 and year=2022;
run;

data cphrdenom2022;
	set cephrklebdenom;
	where year=2022;
run;

data monthnonconscphr;
	merge cphrdenom2022 (in=in1) nonconscephr (in=in2); /*Change dataset names to determine what years to compare*/
	by orgid;
	if in1=1 and in2=1 then output ;
run;

proc freq data=monthnonconscphr;
	tables month;
run;


/*Join tables for all non-Req MDRO*/
data allfac;
	set acine1 cre1 vre1 cephrkleb1;
run;

proc sort data=allfac;
	by orgid year state;
run;

/*Summarize at the facility level*/
proc means data = allfac NOPRINT;
by orgid location year state factype;
var numpatdays numadms numtotpatdays numTotAdm ACINE_labidCount cretot CEPHRKLEB_labidCount VRE_labIDcount;
output out = allfac1 SUM =;
run;

data allfactot;
	set allfac1;
	drop _freq_ _type_;
run;

proc freq data=allfactot;
	tables year;
run;

/*Create Mandate table for each state*/
proc import datafile='redacted\mandate_table.xlsx'
		out=project.mandate_table
		DBMS=excel
		replace;
run;
	
