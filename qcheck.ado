*!v 0.1 <30Nov2016> <Laura Moreno> <Andres Castaneda>
*=====================================================================
*	qcheck: Program to check the quality of the data
*	Reference: 
*-------------------------------------------------------------------
*Created for datalib/LAC:		15Jul2013	(Santiago Garriga & Andres Castaneda) 
*Adapted for datalibweb:		8/1/2016	(Laura Moreno) 
*Last Modifications: 7Oct2019   Sandra Segovia / Laura Moreno
*Last Modifications: 20Dec2019   Sandra Segovia / Laura Moreno / Jayne Jungsun
*Last Modifications: 02Jan2020   Laura Moreno / Jayne Jungsun
*Version not using datalibweb/datalib:  Adriana Casillo / Laura Moreno
*version:		01 
*Dependencies: 	WORLD BANK - LCSPP
*=====================================================================

cap program drop qcheck
program define qcheck, rclass

syntax varlist								///
		[if] [in]							///
		[aweight fweight pweight]			///
		[,	Report(string)  File(string) Out(string) INput(string) restore]

		*input(): this is required when the option"static" is chosen. 
		*Select file that has the test you want to perform. 
*---------------------------------
*	Validation     
*---------------------------------
if !inlist("`report'","basic", "categoric", "static") {
	noi di as error "Report must be one of the following: basic, categoric, static"
	error 1
}
*---------------------------------
*		Update Static Analysis  test         
*---------------------------------
cap which unique
if _rc ssc describe unique

cap which missings
if _rc ssc install missings

cap which labelrename
if _rc net install dm0012, from(http://www.stata-journal.com/software/sj5-2/)

cap which filelist
if _rc ssc install filelist

cap which apoverty
if _rc ssc install apoverty

cap which ainequal
if _rc ssc install ainequal


*---------------------------------------------
* Weights treatment
loc weight "[`weight' `exp']"
*---------------------------------------------

*---------------------------------
*		Dynamic Analysis          
*---------------------------------
	if ("`report'"=="basic") {
		di "Report type: `report'"
		qchecksum `varlist' `weight', file("`file'") out(`out')	
		noi di  _col(10) as result "Basic analysis was performed"
	}
*---------------------------------
*		Categorical Analysis          
*---------------------------------
	if ("`report'"=="categoric") {
		di "Report type: `report'"
		qcheckcat `varlist' `weight', file("`file'") out(`out')	
		noi di  _col(10) as result "Categoric analysis was performed"
	}
*---------------------------------
*		Static Analysis          
*---------------------------------
	if ("`report'"=="static") {
		di "Report type: `report'"		
		qcheckstatic `varlist' `weight', file("`file'") out(`out') input(`input') `restore'
	} 
	
	
end



****************************************************************************************************************










