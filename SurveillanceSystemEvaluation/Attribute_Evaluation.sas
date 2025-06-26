/********************************************************************************************************
         Narrative: Program for MDRO/CDI Module Attributes Evaluation
Program name: Attribute_Evaluation.sas
Purpose: Evaluate the four of eight (4/8) attributes (timeliness, acceptability, Data Quality, Representativeness)
         for non-required MDRO and denominator data reported to the MDRO/CDI Module. Remaining attributes were analyzed in excel
input: project.labid, project.denomds, project.psannualsurveyallfac 
Output: SAS output with results to be transferred to excel. 
Author name: Carlos R. Alvarez
 
Edit Author/Date: 
**********************************************************************************************************/
libname dtsource 'redacted';
libname project 'redacted/Evaluation Data';


/********STEP 1 - Descriptive Statistics ******/

/*Number of selected labid events by year*/
proc freq data=project.labid;
	tables spcorgtype*year cretot*year;
run;

/*Number of facilities reporting to NHSN*/
proc freq data=project.psannualsurveyallfac;
	tables factype2*surveyyear;
run;

/*********STEP 2 - Evaluation of Surveillance System Attributes************/

/****************************************************************************************Timeliness************************************************************/
data labidtime;	
	set project.labid;
	enter_date = datepart(createdate);
	time2rep = intck('day',specimendate,enter_date);
	Length Cat_t2r $30;

	if time2rep ne . then do;
		if time2rep >90 then cat_t2r = ' 90 days or more';
		else if 46 =< time2rep <= 90 then cat_t2r = ' 46 to 90 days';
		else if 0 =< time2rep < = 45 then Cat_t2r = '1 to 45 days';
		end;
run;

proc print data=labidtime;
	where cat_t2r='';
run;

ods csvall file="D:\LabID Evaluation\timeliness.csv";
/*Number of labid events by reporting time by year*/
proc freq data=labidtime;
	tables year*spcorgtype*cat_t2r / nocol nocum norow nopercent;
run;

proc means data=labidtime;
	class year spcorgtype ;
	var time2rep;
run;
ods csvall close;

/****************************************************************************************Acceptability************************************************************/
/*Create temporary denominator datasets for each year including facilities reporting*/
data ds1;
	set project.denomds;
	length CDArep $25;
	if imported='Y' then CDARep='Yes';
	else if imported='' then CDARep='No/Unk';
run;

proc sort data = ds1; 
	by orgid location factype factype2 year state;
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

/*Match 2019 data to 2020,2021,2022 to determine which orgids continue reporting*/
data match2020 stoprep2020 newrep2020;
	merge ds2019 (in=in1) ds2020 (in=in2); /*Change dataset names to determine what years to compare*/
	by orgid;
	if in1=1 and in2=1 then output match2020;
	else if in1=1 and in2=0 then output stoprep2020;
	else if in1=0 and in2=1 then output newrep2020;
run;

data match2021 stoprep2021 newrep2021;
	merge ds2019 (in=in1) ds2021 (in=in2); /*Change dataset names to determine what years to compare*/
	by orgid;
	if in1=1 and in2=1 then output match2021;
	else if in1=1 and in2=0 then output stoprep2021;
	else if in1=0 and in2=1 then output newrep2021;
run;

data match2022 stoprep2022 newrep2022;
	merge ds2019 (in=in1) ds2022 (in=in2); /*Change dataset names to determine what years to compare*/
	by orgid;
	if in1=1 and in2=1 then output match2022;
	else if in1=1 and in2=0 then output stoprep2022;
	else if in1=0 and in2=1 then output newrep2022;
run;

Title 'Total # of Facilities reporting in 2019';
proc freq data=ds2019;
	tables factype2;
run;

/*Calculate the Type of Facilities stopping reporting*/
Title '2020';
proc freq data=stoprep2020;
	tables factype2;
run;

title '2021';
proc freq data=stoprep2021;
	tables factype2;
run;

title '2022';
proc freq data=stoprep2022;
	tables factype2;
run;

/*Calculate the Type of Facilities starting reporting*/
Title '2020';
proc freq data=newrep2020;
	tables factype2;
run;
Title '2021';
proc freq data=newrep2021;
	tables factype2;
run;
title '2022';
proc freq data=newrep2022;
	tables factype2;
run;
/****************************************************************************************Data Quality************************************************************/
/* Create a table with the list of required variables */
proc sql;
  create table reqvar as 
  select year, patid, gender, dob, specimendate, spcorgtype, outpatient, specimensource, location, carbatest, cretot
  from project.labid
  where outpatient='N' and Year=2021; /*Change year and outpatient variable for each year of interest*/
quit;

/*Create a Missing Data Report*/
proc format;
value nm
	low-high ='1'
	other ='0';
value $ch
	''='0'
	other='1';
run;

ods listing close;
ods output onewayfreqs=tables (keep=table frequency percent f_:);

proc freq data=reqvar;
	tables _all_ / missing;
	format _numeric_ nm. _character_ $ch.;
run;
	 
ods output close;
ods listing;

data report;
 length var $32;
 do until (last.table);
	set tables;
	by table notsorted;
	array names(*) f_: ;
	select (names(_n_));
		when ('0') do; miss = frequency; p_miss = percent; 
		end;
		when ('1') do; ok = frequency; p_ok = percent; 
		end;
	end;
end;

 miss + 0;
 pmiss + 0;
 ok + 0;
 p_ok + 0;
 var = scan (table, -1);
 format miss ok comma7. p_: 5.1;
 label miss = 'N_MISSING' ok = 'N_OK' p_miss = '%_MISSING' p_ok = '%_OK' var = 'VARIABLE';
 keep var miss ok p_:;
run;

Title "Summary of Missing and Non-Missing Values for Required Variables";
proc print data=report label;
run;
title;

proc freq data=reqvar;
	where cretot=1;
	tables carbaTest;
run;

/*Calculate the Percentage of events reported manually or through CDA*/
proc freq data=project.labid;
	tables CDARep*year;
run;

proc freq data=project.labid;
	tables CDARep*factype2;
run;

/*Calculate the percentage of facilities reporting manually or through CDA*/
data imported; 
	set project.denomds;
	keep orgid location CDARep factype factype2 year state imported acine_labid cdif_labid cephrkleb_labid creecoli_labid creentero_labid crekleb_labid mrsa_labid vre_labid CREall_labid multrep
	noEventLabID_ACINE noEventLabID_CEPHRKLEB noEventLabID_CREECOLI noEventLabID_CREENTERO noEventLabID_CREKLEB noEventLabID_VRE noEventLabID_MRSA;

	CREall_labid=sum(creecoli_labid, creentero_labid, crekleb_labid);
	
	if sum(acine_labid, cephrkleb_labid, CREall_labid, vre_labid) > 1 then Multrep =1;
	else multrep=0;

	if imported='Y' then CDARep='Y';
	else CDARep='N';
run;

data nrmdro;	
	set imported;
	if  acine_labid > 1 or cephrkleb_labid > 1 or CREall_labid > 1 or vre_labid > 1 or noEventLabID_ACINE ne '' or noEventLabID_CEPHRKLEB ne '' 
	or noEventLabID_CREECOLI ne '' or noEventLabID_CREENTERO ne '' or noEventLabID_CREKLEB ne '' or noEventLabID_VRE ne '';
run;

data cda nocda;
	set nrmdro;

	if cdarep='Y' then output cda;
	else output nocda;
run;

proc sql;
	select count(distinct orgid)
	from cda
	where year=2019 and multrep=1;
	
	select count(distinct orgid)
	from cda
	where year=2020 and multrep=1;

	select count(distinct orgid)
	from cda
	where year=2021 and multrep=1;

	select count(distinct orgid)
	from cda
	where year=2022 and multrep=1;
quit;

proc sort data=nrmdro;
	by orgid location factype factype2 year state cdarep;
run;

/*Summarize at the facility level*/
proc means data =nrmdro NOPRINT;
by orgid location factype factype2 year state cdarep;
var acine_labid cdif_labid cephrkleb_labid creecoli_labid creentero_labid crekleb_labid mrsa_labid vre_labid CREall_labid multrep;
output out = nrmdro_1 SUM =;
run;

/*Create facility level datasets for each year*/
data repdata2019 repdata2020 repdata2021 repdata2022;
	set nrmdro_1;
	
	if year=2019 then output repdata2019;
	else if year=2020 then output repdata2020;
	else if year=2021 then output repdata2021;
	else if year=2022 then output repdata2022;
run;

/*Calculate number of facilities reporting for multiple or single organisms through CDA by year*/
Title1 '2019';
/*multiple*/
title2 'multi';
proc freq data=repdata2019;
	where multrep >= 1;
	tables cdarep;
run;
title2;
/*single*/
title3 'Single';
proc freq data=repdata2019;
	where multrep < 1;
	tables cdarep;
run;
title1 '2020';
/*multiple*/
title2 'multi';
proc freq data=repdata2020;
	where multrep >= 1;
	tables cdarep;
run;
title2;
/*single*/
title3 'Single';
proc freq data=repdata2020;
	where multrep < 1;
	tables cdarep;
run;
Title1 '2021';
/*Multiple*/
title2 'multi';
proc freq data=repdata2021;
	where multrep >= 1;
	tables cdarep;
run;
title2;
/*Single*/
title3 'Single';
proc freq data=repdata2021;
	where multrep < 1;
	tables cdarep;
run;
Title1 '2022';
/*Multiple*/
title2 'multi';
proc freq data=repdata2022;
	where multrep >= 1;
	tables cdarep;
run;
title2;
/*Single*/
title3 'Single';
proc freq data=repdata2022;
	where multrep < 1;
	tables cdarep;
run;
title;

/*Calculate Percentage of consistent reporters for each year of the study period (Consisten Reporter = data for 12 months of data)*/
/*Acinetobacter*/
proc freq data=project.acine1;	
	tables _freq_*year / norow nocum;
run;

/*CRE*/
proc freq data=project.cre1;
	tables _freq_*year / norow nocum;
run; 

/*VRE*/
proc freq data=project.vre1;
	tables _freq_*year / norow nocum;
run; 

/*Ceph-R Klebsiella*/
proc freq data=project.cephrkleb1;
	tables _freq_*year / norow nocum;
run;
 
/*Calculate proportion of Non-Required MDROs by Facilit Type each year*/
proc freq data=project.labid;
	tables factype2*spcorgtype*year /nopercent norow;
run;

proc freq data=project.labid;
	where cretot=1;
	tables cretot*factype2*year/ norow nocum nopercent;
run;

/****************************************************************************************Representativeness************************************************************/
/*Calculate the number of facilities reporting non-Req MDROs by year*/
proc sql;
	select count(distinct orgid)
	from repdata2019;

	select count(distinct orgid)
	from repdata2020;

	select count(distinct orgid)
	from repdata2021;

	select count(distinct orgid)
	from repdata2022;
quit;

/*Calculate the distribution of facilities reporting by state (mandate vs. No Mandate)*/
data imported_2; 
	set project.denomds;
	keep orgid location factype factype2 year state acine_labid cdif_labid cephrkleb_labid creecoli_labid creentero_labid crekleb_labid mrsa_labid vre_labid CREall_labid;

	CREall_labid=sum(creecoli_labid, creentero_labid, crekleb_labid);
run;

proc sort data=imported_2;
	by orgid location factype factype2 year state;
run;

/*Summarize at the facility level*/
proc means data =imported_2 NOPRINT;
by orgid location factype factype2 year state;
var acine_labid cdif_labid cephrkleb_labid creecoli_labid creentero_labid crekleb_labid mrsa_labid vre_labid CREall_labid;
output out = imp_3 SUM =;
run;

/*Merge facility level dataset to state reporting mandate dataset*/
proc sort data=imp_3;
	by state;
run;

proc sort data=project.mandate_table;
	by state; 
run;

data imp_4;
	merge imp_3 project.mandate_table;
	by state;
run;

/*Create datasets for each year with unique facilities reporting at least one of the non-req MDROs*/
proc sql;
	create table uniquefac2019 as
	select distinct orgid, location, factype, factype2, year, state, acine_labid, cephrkleb_labid, creall_labid, vre_labid, mandate_cre, mandate_vre, mandate_mdraci, mandate_cephrkleb
	from imp_4
	where year=2019 and (acine_labid > 0 or cephrkleb_labid > 0 or creall_labid > 0 or vre_labid > 0);

	create table uniquefac2020 as
	select distinct orgid, location, factype, factype2, year, state, acine_labid, cephrkleb_labid, creall_labid, vre_labid, mandate_cre, mandate_vre, mandate_mdraci, mandate_cephrkleb
	from imp_4
	where year=2020 and (acine_labid > 0 or cephrkleb_labid > 0 or creall_labid > 0 or vre_labid > 0);
	
	create table uniquefac2021 as
	select distinct orgid, location, factype, factype2, year, state, acine_labid, cephrkleb_labid, creall_labid, vre_labid, mandate_cre, mandate_vre, mandate_mdraci, mandate_cephrkleb
	from imp_4
	where year=2021 and (acine_labid > 0 or cephrkleb_labid > 0 or creall_labid > 0 or vre_labid > 0);

	create table uniquefac2022 as
	select distinct orgid, location, factype, factype2, year, state, acine_labid, cephrkleb_labid, creall_labid, vre_labid, mandate_cre, mandate_vre, mandate_mdraci, mandate_cephrkleb
	from imp_4
	where year=2022 and (acine_labid > 0 or cephrkleb_labid > 0 or creall_labid > 0 or vre_labid > 0);

quit;

/*CRE*/
ods csvall file='D:\LabID Evaluation\Deliverables\Evaluation_Analysis\CRE_mand_tables.csv';

title 'State mandate for CRE 2019';
proc freq data=uniquefac2019;
	where Mandate_CRE='Y' and creall_labid > 0;
	tables state;
run;
title 'State non-mandate for CRE 2019';
proc freq data=uniquefac2019;
	where (Mandate_CRE='N' or mandate_cre='U') and creall_labid > 0;
	tables state;
run;
title 'State mandate for CRE 2020';
proc freq data=uniquefac2020;
	where Mandate_CRE='Y' and creall_labid > 0;
	tables state;
run;
title 'State non-mandate for CRE 2020';
proc freq data=uniquefac2020;
	where (Mandate_CRE='N' or mandate_cre='U') and creall_labid > 0;
	tables state;
run;
title 'State mandate for CRE 2021';
proc freq data=uniquefac2021;
	where Mandate_CRE='Y' and creall_labid > 0;
	tables state;
run;
title 'State non-mandate for CRE 2021';
proc freq data=uniquefac2021;
	where (Mandate_CRE='N' or mandate_cre='U') and creall_labid > 0;
	tables state;
run;
title 'State mandate for CRE 2022';
proc freq data=uniquefac2022;
	where Mandate_CRE='Y' and creall_labid > 0;
	tables state;
run;
title 'State non-mandate for CRE 2022';
proc freq data=uniquefac2022;
	where (Mandate_CRE='N' or mandate_cre='U') and creall_labid > 0;
	tables state;
run;

/*VRE*/
ods csvall file='D:\LabID Evaluation\Deliverables\Evaluation_Analysis\VRE_mand_tables.csv';

title 'State mandate for VRE 2019';
proc freq data=uniquefac2019;
	where Mandate_VRE='Y' and vre_labid > 0;
	tables state;
run;
title 'State non-mandate for VRE 2019';
proc freq data=uniquefac2019;
	where (Mandate_VRE='N' or mandate_vre='U') and vre_labid > 0;
	tables state;
run;
title 'State mandate for VRE 2020';
proc freq data=uniquefac2020;
	where Mandate_VRE='Y' and vre_labid > 0;
	tables state;
run;
title 'State non-mandate for VRE 2020';
proc freq data=uniquefac2020;
	where (Mandate_VRE='N' or mandate_vre='U') and vre_labid > 0;
	tables state;
run;
title 'State mandate for VRE 2021';
proc freq data=uniquefac2021;
	where Mandate_VRE='Y' and vre_labid > 0;
	tables state;
run;
title 'State non-mandate for VRE 2021';
proc freq data=uniquefac2021;
	where (Mandate_VRE='N' or mandate_vre='U') and vre_labid > 0;
	tables state;
run;
title 'State mandate for VRE 2022';
proc freq data=uniquefac2022;
	where Mandate_VRE='Y' and vre_labid > 0;
	tables state;
run;
title 'State non-mandate for VRE 2022';
proc freq data=uniquefac2022;
	where (Mandate_VRE='N' or mandate_vre='U') and vre_labid > 0;
	tables state;
run;

/*MDR-Acinetobacter*/
ods csvall file='D:\LabID Evaluation\Deliverables\Evaluation_Analysis\MDRACINE_mand_tables.csv';

title 'State mandate for MDR-Acinetobacter 2019';
proc freq data=uniquefac2019;
	where mandate_mdraci='Y' and acine_labid > 0;
	tables state;
run;
title 'State non-mandate for MDR-Acinetobacter 2019';
proc freq data=uniquefac2019;
	where (mandate_mdraci='N' or mandate_mdraci='U') and acine_labid > 0;
	tables state;
run;
title 'State mandate for MDR-Acinetobacter 2020';
proc freq data=uniquefac2020;
	where mandate_mdraci='Y' and acine_labid > 0;
	tables state;
run;
title 'State non-mandate for MDR-Acinetobacter 2020';
proc freq data=uniquefac2020;
where (mandate_mdraci='N' or mandate_mdraci='U') and acine_labid > 0;
	tables state;
run;
title 'State mandate for MDR-Acinetobacter 2021';
proc freq data=uniquefac2021;
	where mandate_mdraci='Y' and acine_labid > 0;
	tables state;
run;
title 'State non-mandate for MDR-Acinetobacter 2021';
proc freq data=uniquefac2021;
	where (mandate_mdraci='N' or mandate_mdraci='U') and acine_labid > 0;
	tables state;
run;
title 'State mandate for MDR-Acinetobacter 2022';
proc freq data=uniquefac2022;
where mandate_mdraci='Y' and acine_labid > 0;
	tables state;
run;
title 'State non-mandate for MDR-Acinetobacter 2022';
proc freq data=uniquefac2022;
	where (mandate_mdraci='N' or mandate_mdraci='U') and acine_labid > 0;
	tables state;
run;

/*CephR-Klebsiella*/
ods csvall file='D:\LabID Evaluation\Deliverables\Evaluation_Analysis\CephRKleb_mand_tables.csv';

title 'State mandate for CephR-Klebsiella 2019';
proc freq data=uniquefac2019;
	where mandate_cephrkleb='Y' and cephrkleb_labid > 0;
	tables state;
run;
title 'State non-mandate for CephR-Klebsiella 2019';
proc freq data=uniquefac2019;
	where (mandate_cephrkleb='N' or mandate_cephrkleb='U') and cephrkleb_labid > 0;
	tables state;
run;
title 'State mandate for CephR-Klebsiella 2020';
proc freq data=uniquefac2020;
	where mandate_cephrkleb='Y' and cephrkleb_labid > 0;
	tables state;
run;
title 'State non-mandate for CephR-Klebsiella 2020';
proc freq data=uniquefac2020;
	where (mandate_cephrkleb='N' or mandate_cephrkleb='U') and cephrkleb_labid > 0;
	tables state;
run;
title 'State mandate for CephR-Klebsiella 2021';
proc freq data=uniquefac2021;
	where mandate_cephrkleb='Y' and cephrkleb_labid > 0;
	tables state;
run;
title 'State non-mandate for CephR-Klebsiella 2021';
proc freq data=uniquefac2021;
	where (mandate_cephrkleb='N' or mandate_cephrkleb='U') and cephrkleb_labid > 0;
	tables state;
run;
title 'State mandate for CephR-Klebsiella 2022';
proc freq data=uniquefac2022;
	where mandate_cephrkleb='Y' and cephrkleb_labid > 0;
	tables state;
run;
title 'State non-mandate for CephR-Klebsiella 2022';
proc freq data=uniquefac2022;
	where (mandate_cephrkleb='N' or mandate_cephrkleb='U') and cephrkleb_labid > 0;
	tables state;
run;
ods csvall close;

