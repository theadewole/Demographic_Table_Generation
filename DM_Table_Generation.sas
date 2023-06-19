/*
File Name: Safety Domain Assessment
Program Developer : Adewole Ogunade
Date: 29-03-2023
Domain: Demography (DM) 
Tasks: 
<-Map the variables that should be present in CRF to have this type of output. 
<-Enlist SDTM variables 
<-Enlist ADaM variables 
<-Header used for writing program to derive this output 
<-Write the program for the report generation 
<-Title and Footnotes 
<-RTF coding to get the required pattern in the output
Application Version: SAS STUDIO
Input
<-Raw Dm Dataset
Output
<-DM.sas		<-DM.Log		<-DM.RTF 
*/

/*Establishing Library*/
LIBNAME mysnip '/home/u63305936/Safety Domain/DM';
RUN;

/*Sorting the dataset*/
PROC SORT DATA=mysnip.dm OUT=DM001  NODUPKEY;
	BY _ALL_;
RUN;

/*creating a new dataset from the existing dataset to remove null Subjid*/
PROC SQL;
	CREATE TABLE DM002 AS
	SELECT *
	FROM DM001
	WHERE Subjid IS NOT NULL;
	QUIT;
RUN;

/*Adding the Age group to the dataset*/
DATA Agegrp;
	LENGTH AgeGrp $ 30.;
	SET DM002;
	IF AGEDRV1N < 65 THEN AgeGrp='<65 Yrs';
	ELSE IF 64 < AGEDRV1N < 74 THEN AgeGrp='≥65 Yrs';
	ELSE IF AGEDRV1N =74 THEN AgeGrp='<75 Yrs';
	ELSE IF AGEDRV1N >= 75 THEN AgeGrp='≥75 Yrs';
RUN;

/*Creating Region column from the country variable*/
DATA regcret;
	SET Agegrp ;
	IF country='USA' THEN Region='North America';
	ELSE IF country='FRA' THEN Region='Europe';
	ELSE IF country='NLD' THEN Region='Europe';
	ELSE IF country= . then Region='others';
RUN;

/******Doubling the dataset to create "Total" labeled as Z****/
DATA Doubling;
	SET regcret;
	OUTPUT;
	TRTM='Z';
	OUTPUT;
RUN;

/*Sorting the dataset*/	
PROC SORT DATA=Doubling  OUT=DM1;
	BY TRTM;
RUN;

									/*Region dataset creation*/
/*Calculating percent and count for the region*/
PROC FREQ DATA=DM1 NOPRINT;
	BY TRTM;
	TABLES Region/OUT=DM2 NOCOL NOROW NOCUM;
RUN;

/*Concatenating the percentage and count column*/
DATA DM3;
	SET DM2;
	NC=PUT(Count,3.0)|| '('||STRIP(PUT(Percent,4.0))||')';
RUN;

/*Sorting the dataset after concatenating*/
PROC SORT DATA=DM3  OUT=DM3_1;
	BY Region;
RUN;

/*Changing context of arrangement by applying transpose*/
PROC  TRANSPOSE DATA=DM3_1 OUT=DM4;
	ID TRTM;
	VAR NC;
	BY Region;
RUN;

/*Creating a new column newvar to accommodate the different regions*/	
DATA DM5;
	LENGTH Newvar $ 30.;
	SET DM4;
	IF Region='Europe' THEN Newvar='Europe';
	ELSE IF Region='North America' THEN Newvar='North America';
	ELSE IF Region='others' THEN Newvar='Others';
	DROP Region _Name_;
RUN;

/*Creating a new dataset 'dummy' having column newvar with variable Region N(%)*/
DATA Dummy;
	LENGTH Newvar $ 30.;
	Newvar='Region N(%)';
RUN;

/*Merging the region dataset and the dummy dataset*/
DATA Region;
	SET Dummy DM5;
	Ord=1;
RUN;

										/*Sex creation*/
/*Calculating percent and count for Sex*/					
PROC FREQ DATA=DM1 NOPRINT;
	BY TRTM;
	TABLE Sex/OUT=Sex1 NOCOL NOROW NOCUM;
RUN;

/*Concatenating the percentage and count column*/
DATA sex2;
	SET sex1;
	NC=PUT(Count,3.0)||'('||STRIP(PUT(Percent,4.0))||')';
RUN;

/*Sorting the dataset after concatenating*/
PROC SORT DATA=sex2  OUT=sex2_1;
	BY sex;
RUN;

/*Changing context of arrangement by applying transpose*/	
PROC  TRANSPOSE DATA=sex2_1 OUT=sex3;
	ID TRTM;
	VAR NC;
	BY sex;
RUN;

/*Creating a new column newvar to accommodate the sex types*/		
DATA sex4;
	LENGTH Newvar $ 30.;
	SET sex3;
	IF sex='F' THEN Newvar='Women';
	ELSE IF sex='M' THEN Newvar='Male';
	ELSE IF sex='U' THEN Newvar='Undisclosed';
	DROP sex _Name_;
RUN;

/*Creating a new dataset 'dummy' having column newvar with variable Sex N(%)*/
DATA Dummy1;
	LENGTH Newvar $ 30.;
	Newvar='Sex N(%)';
RUN;

/*Merging the sex dataset and the dummy dataset*/
DATA Sex;
	SET Dummy1 sex4;
	Ord=2;
RUN;

								/*Race and Ethnic*/
/*Calculating percent and count for the race and country*/
PROC FREQ DATA=DM1 NOPRINT;
	BY TRTM;
	TABLE Race*Ethnic/OUT=Race1 NOCOL NOROW NOCUM;
RUN;

/*Concatenating the percentage and count column, race and ethnic*/
DATA Race2;
	SET race1;
	Race_Ethnic=CATX(' ',Race,Ethnic);
	NC=PUT(Count,3.0)|| '('||STRIP(PUT(Percent,4.0))||')';
RUN;

/*Sorting the dataset after concatenating*/
PROC SORT DATA=race2  OUT=race2_1;
	BY Race_Ethnic;
RUN;
	
/*Changing context of arrangement by applying transpose*/
PROC  TRANSPOSE DATA=race2_1 OUT=race3;
	ID TRTM;
	VAR NC;
	BY Race_Ethnic;
RUN;

/*Creating a new column newvar to accommodate the different races and ethnic*/		
DATA race4;
	LENGTH Newvar $ 30.;
	SET race3;
	IF Race_Ethnic='BLACK ASIAN' THEN Newvar='Asian';
	ELSE IF Race_Ethnic='OTHER NOT HISPANIC OR LATINO' THEN Newvar='Black or African American';
	ELSE IF Race_Ethnic='WHITE HISPANIC OR LATINO' THEN Newvar='Hispanic or Latino';
	ELSE IF Race_Ethnic='WHITE NOT HISPANIC OR LATINO' THEN Newvar='White or Caucassian';
	DROP Race_Ethnic _Name_;
RUN;

/*Creating a new dataset 'dummy' having column newvar with variable Race/Ethnicity-N(%)*/
DATA Dummy4;
	LENGTH Newvar $ 30.;
	Newvar='Race/Ethnicity-N(%)';
RUN;

/*Merging the region dataset and the dummy dataset*/
DATA Race;
	SET Dummy4 Race4;
	Ord=3;
RUN;

									/*Age(Years) dataset creation*/
/*Sorting the dataset which contains the doubling variable*/									
PROC SORT DATA=DM1    OUT=Age;
	BY TRTM;
RUN;

/*Applying proc summary to specify some statistical analysis*/
PROC SUMMARY DATA=Age;
	BY TRTM;
	VAR AGEDRV1N;
	OUTPUT OUT=Age1 
	n=_n 
	MEAN=_mean
	STD=_sd
	MEDIAN=_Median
	Q1=_Q1
	Q3=_Q3
	MIN=_Min
	Max=_Max;
RUN;

/*Concatenating Q1&Q3,minimum & maximum, and applying format to the statistics*/
DATA Age2 (DROP=_:);
	SET Age1;
	N=PUT(_n,3.0);
	Mean=PUT(_Mean,4.1);
	SD=PUT(_Sd,4.1);
	Median=PUT(_Median,4.1);
	Q1_Q3=STRIP(PUT(_Q1,3.0))||','||STRIP(PUT(_Q3,3.0));
	mnmx=STRIP(PUT(_Min,3.0))||','||STRIP(PUT(_Max,3.0));
RUN;

/*Changing context of arrangement by applying transpose*/
PROC TRANSPOSE DATA= Age2   OUT=Age3;
	ID TRTM;
	VAR N Mean SD Median  Q1_Q3 mnmx;
RUN;

/*Creating a new column newvar to accommodate the different statistics*/
DATA Age4;
LENGTH Newvar $ 30.;
	SET age3;
	IF _name_='N' THEN Newvar=' N';
	ELSE IF _name_='Mean' THEN Newvar=' Mean';
	ELSE IF _name_='SD' THEN Newvar=' SD';
	ELSE IF _name_='Median' THEN Newvar=' Median';
	ELSE IF _name_='mnmx' THEN Newvar=' Min,Max';
	ELSE IF _name_='Q1_Q3' THEN Newvar=' Q1,Q3';
	DROP _name_;
RUN;

/*Creating a new dataset 'dummy' having column newvar with variable Baseline Age-Years*/
DATA dummy2;
	LENGTH Newvar $ 30.;
	Newvar='Baseline Age-Years';
RUN;

/*Merging the Age dataset and the dummy dataset*/
DATA Years;
	SET dummy2 age4;
	ord=4;
RUN;

								/*Age group*/
/*Calculating percent and count for the Age group*/
PROC FREQ DATA=DM1 NOPRINT;
	BY TRTM;
	TABLE Agegrp/OUT=Agegrp1 NOCOL NOROW NOCUM;
RUN;

/*Concatenating the percentage and count column*/
DATA Agegrp2;
	SET Agegrp1;
	NC=PUT(Count,3.0)||'('||STRIP(PUT(Percent,3.0))||')';
RUN;

/*Sorting the dataset after concatenating*/
PROC SORT DATA=Agegrp2  OUT=Agegrp2_1;
	BY Agegrp;
RUN;

/*Changing context of arrangement by applying transpose*/	
PROC  TRANSPOSE DATA=Agegrp2_1 OUT=Agegrp3;
	ID TRTM;
	VAR NC;
	BY Agegrp;
RUN;
	
/*Creating a new column newvar to accommodate the different Age Groups*/	
DATA Agegrp4;
	LENGTH Newvar $ 30.;
	SET Agegrp3;
	IF Agegrp='<65 Yrs' THEN Newvar='<65 Years';
	ELSE IF Agegrp='≥65 Yrs' THEN Newvar="(*ESC*){UNICODE 2265}"||'65 Years';
	ELSE IF Agegrp='<75 Yrs' THEN Newvar='<75 Years';
	ELSE IF Agegrp='≥75 Yrs' THEN Newvar="(*ESC*){UNICODE 2265}"||'75 Years';
	DROP  Agegrp _Name_;	
RUN;

/*Creating a new dataset 'dummy' having column newvar with variable Baseline Age Group N(%)*/
DATA Dummy19;
	LENGTH Newvar $ 30.;
	Newvar='Baseline Age Group N(%)';
RUN;

/*Merging the Age group dataset and the dummy dataset*/
DATA Agegrp;
	SET Dummy19 Agegrp4;
	Ord=5;
RUN;

							/*BSA creation*/
/*Sorting the dataset which contains the doubling variable*/						
PROC SORT DATA=DM1    OUT=BSA1;
	BY TRTM;
RUN;

/*Applying proc summary to specify some statistical analysis*/
PROC SUMMARY DATA=BSA1;
	BY TRTM;
	VAR BSA_1N;
	OUTPUT OUT=BSA2 
	n=_n 
	MEAN=_mean
	STD=_sd
	MEDIAN=_Median
	Q1=_Q1
	Q3=_Q3
	MIN=_Min
	Max=_Max;
RUN;

/*Concatenating Q1&Q3,minimum & maximum, and applying format to the statistics*/
DATA BSA3 (DROP=_:);
	SET BSA2;
	N=PUT(_n,3.0);
	Mean=PUT(_Mean,4.1);
	SD=PUT(_Sd,4.1);
	Median=PUT(_Median,4.1);
	Q1_Q3=PUT(_Q1,3.0)||','||STRIP(PUT(_Q3,3.0));
	mnmx=PUT(_Min,3.0)||','||STRIP(PUT(_Max,3.0));
RUN;

/*Changing context of arrangement by applying transpose*/
PROC TRANSPOSE DATA= BSA3  OUT=BSA4;
	ID TRTM;
	VAR N Mean SD Median  Q1_Q3 mnmx;
RUN;

/*Creating a new column newvar to accommodate the different statistics*/
DATA BSA5;
LENGTH Newvar $ 30.;
	SET BSA4;
	IF _name_='N' THEN Newvar=' N';
	ELSE IF _name_='Mean' THEN Newvar=' Mean';
	ELSE IF _name_='SD' THEN Newvar=' SD';
	ELSE IF _name_='Median' THEN Newvar=' Median';
	ELSE IF _name_='mnmx' THEN Newvar=' Min,Max';
	ELSE IF _name_='Q1_Q3' THEN Newvar=' Q1,Q3';
	DROP _name_;
RUN;

/*Creating a new dataset 'dummy' having column newvar with variable Baseline BSA m"||"^{super 2}*/
DATA dummy3;
	LENGTH Newvar $ 30.;
	Newvar="Baseline BSA m"||"^{super 2}";
RUN;

/*Merging the BSA dataset and the dummy dataset*/
DATA BSA;
	SET dummy3 BSA5;
	ord=6;
RUN;     
                                                                                                                                                                                           
/*Merging all createe dataset together*/
DATA Demo_All;
	SET region sex race years agegrp bsa;
RUN;

/*****Generating RTF file for Demographic***/
ODS escapechar="^";
ODS LISTING CLOSE;  
ODS RTF FILE='/home/u63305936/My Log/Demographic.RTF';
/*Generating Report: Applying font type, size*/
OPTIONS NOCENTER NODATE NONUMBER;
PROC  REPORT DATA=Demo_All NOWD HEADLINE HEADSKIP SPLIT='*'
	STYLE(report)={cellpadding=1pt cellspacing=0pt just=c frame=above asis=on rules=groups}
	STYLE(header)={font=('Courier New',9pt,normal) just=C asis=Off background=white fontweight=bold borderbottomwidth=2 bordertopwidth=2}
	STYLE(column)={font=('Courier New',9pt,normal) asis=on}
	STYLE(lines) ={font=('Courier New',9pt,normal) asis=on} ;
	COLUMN ('TREATMENT' ord Newvar A B C D Z);
	DEFINE Ord/ORDER NOPRINT;
	BREAK AFTER ord/SKIP;
	DEFINE Newvar/'' ;
	DEFINE A/'Trt A' STYLE(Column)={Just=c asis=on Cellwidth=10.7%} FLOW; 
	DEFINE B/'Trt B' STYLE(Column)={Just=c asis=on Cellwidth=10.7%} FLOW;
	DEFINE C/'Trt C' STYLE(Column)={Just=c asis=on Cellwidth=10.7%} FLOW;
	DEFINE D/'Trt D' STYLE(Column)={Just=c asis=on Cellwidth=10.7%} FLOW;
	DEFINE Z/'Total' STYLE(Column)={Just=c asis=on Cellwidth=10.7%} FLOW;
	COMPUTE AFTER _Page_/LEFT;
/*Applying Title and Footnotes*/
	LINE @1 1 *'-';
	LINE@1 "*Note";
	LINE@1 "SD: Standard Deviation  Min:Minimum  Max:Maximum Q1:First Quartile  Q3:Third Quartile";
	ENDCOMP;
	TITLE1 Font='Courier New' Height=9pt Justify=c "Demographic and Baseline Characteristics";
	FOOTNOTE1 Font='Courier New' Height=9pt Justify=l "Safety Domain Assessment (Descriptive)";
	RUN;
ODS RTF CLOSE;