/*====================================================================
project:       qcheck examples
Author:        Laura Moreno Herrera / Adriana Castillo Castillo
Dependencies:  SAR Stats Team World Bank 
----------------------------------------------------------------------
Creation Date:    Feb 2023
Modification Date:   April 2023
Do-file version:    01       
Output:             dta
====================================================================*/
version 10
drop _all

*====================================================================*
*##glo qcheckpath "<add your path>"
discard
adopath ++ "${qcheckpath}"
global qcheckout "${qcheckpath}\exampleout"
/*---------------------------------------------------------------------
*        1: Data: Household survey
*---------------------------------------------------------------------

local files : dir "${qcheckpath}\datatest" files "XXX_*.dta"
foreach file in `files' {
  use "${qcheckpath}\datatest\\`file'", clear
  qui des, varlist
	local Allvars="`r(varlist)'"
*-----------------------------------------------------------
*## BASIC		
			qchecksum `Allvars' [aw=weight], file("`filename'") out(${qcheckout})		
*-----------------------------------------------------------
*## CATEG	
			qcheckcat age male urban hsize school literacy educy educat4 [aw=weight], file("`filename'") out(${qcheckout})
		
}
 
*---------------------------------------------------------------------*/
*        1: Data: Household survey version 2
*---------------------------------------------------------------------
local files : dir "${qcheckpath}\datatest" files "XXX_*.dta"
foreach file in `files' {
  use "${qcheckpath}\datatest\\`file'", clear
  cap drop year
  qui des, varlist
	local Allvars="`r(varlist)'"
		
	*-----------------------------------------------------------
	*## BASIC		
	qcheck `Allvars' [aw=weight], out(${qcheckout}) report(basic) 
	**same results with: qchecksum `Allvars' [aw=weight], out(${qcheckout})
	
	*-----------------------------------------------------------
	*## CATEG	
	qcheck age male urban hsize school literacy educy educat4 [aw=weight], out(${qcheckout}) report(categoric) 
	**same results with: qcheckcat age male urban hsize school literacy educy educat4 [aw=weight], file("`filename'") out(${qcheckout})

	*-----------------------------------------------------------
	*## STATIC	
	*qcheck `Allvars' [aw=weight], file("`filename'") out(${qcheckout}) report(static) input(${qcheckpath}/qcheck_NNN.xlsx) restore
	**same results with: qcheckstatuc `Allvars' [aw=weight], file("`filename'") out(${qcheckout}) report(static) input(${qcheckpath}\qcheck_NNN.xlsx) restore

}
	

*---------------------------------------------------------------------*/
*        2: Data: WB Open Data
*---------------------------------------------------------------------
*ssc install wbopendata
	wbopendata, indicator(ag.agr.trac.no;si.pov.dday; ny.gdp.pcap.pp.kd) clear long 
	keep if year==2015
	sort year countrycode
	
	local filename="testwbopen"
	di "`filename'"
	qui des, varlist
	local Allvars=r(varlist)
	
	*-----------------------------------------------------------
	*## BASIC		
	qcheck `Allvars' , out(${qcheckout}) report(basic) 
	**same results with: qchecksum `Allvars' [aw=weight], out(${qcheckout})
	
	*-----------------------------------------------------------
	*## CATEG	
	*qcheck `Allvars' , out(${qcheckout}) report(categoric) 
	qcheck region , out(${qcheckout}) report(categoric) 
	**same results with: qcheckcat `Allvars' [aw=weight], file("`filename'") out(${qcheckout})

	*-----------------------------------------------------------
	*## STATIC	
	*qcheck `Allvars' , file("`filename'") out(${qcheckout}) report(static) input(${qcheckpath}\qcheck_WBOpenData.xlsx) restore
	**same results with: qcheckstatuc `Allvars' [aw=weight], file("`filename'") out(${qcheckout}) report(static) input(${qcheckpath}\qcheck_NNN.xlsx) restore

	
*---------------------------------------------------------------------*/
*        3: Data: US Census
*---------------------------------------------------------------------
    sysuse census.dta, clear 
	
	local filename= "census.dta"
	di "`filename'"
	qui des, varlist
	local Allvars=r(varlist)

	*medage
	*-----------------------------------------------------------
	*## BASIC		
	qcheck medage, out(${qcheckout}) report(basic) 
	
	*-----------------------------------------------------------
	*## CATEG	
	qcheck region , out(${qcheckout}) report(categoric) 

	*-----------------------------------------------------------
	*## STATIC	
	*qcheck medage , file("`filename'") out(${qcheckout}) report(static) input(${qcheckpath}\qcheck_USCensus.xlsx) restore

*---------------------------------------------------------------------*/
*        4: Data: City Temperature 
*---------------------------------------------------------------------
	sysuse citytemp.dta, clear 
	
	local filename= r(filename) 
	di "`filename'"
	qui des, varlist
	local Allvars=r(varlist)

	*-----------------------------------------------------------
	*## BASIC		
	qcheck heatdd, out(${qcheckout}) report(basic) 
	
	*-----------------------------------------------------------
	*## CATEG	
	qcheck division , out(${qcheckout}) report(categoric) 

	*-----------------------------------------------------------
	*## STATIC	
	qcheck heatdd , file("`filename'") out(${qcheckout}) report(static) input(${qcheckpath}\qcheck_CityTemperature.xlsx) restore


*---------------------------------------------------------------------
*        5: Data: Votes
*---------------------------------------------------------------------
	sysuse voter.dta, clear 
	
	local filename= r(filename) 
	di "`filename'"
	qui des, varlist
	local Allvars=r(varlist)

	*-----------------------------------------------------------
	*## BASIC		
	qcheck pop, out(${qcheckout}) report(basic) 
	
	*-----------------------------------------------------------
	*## CATEG	
	qcheck candidat , out(${qcheckout}) report(categoric) 

	*-----------------------------------------------------------
	*## STATIC	
	*qcheck pop , file("`filename'") out(${qcheckout}) report(static) input(${qcheckpath}\qcheck_CityVoter.xlsx) restore

exit

