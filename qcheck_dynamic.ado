/* *===========================================================================
	_dyncheck: Program to check the quality of the data over time
	Reference: 
-------------------------------------------------------------------
Created datalib/lac: 		15Jul2013	(Santiago Garriga & Andres Castaneda) 
Adapted datalibweb:			01Aug2016 	Laura Moreno Herrera
							20Nov2013	(Santiago Garriga & Andres Castaneda) 
Adapted for review:			06Oct2017	(Jayne Jungsun Yoo)
version:		01 
Dependencies: 	WORLD BANK - LCSPP
*===========================================================================*/

#delimit cr	 
discard
cap program drop qcheck_dynamic
program define qcheck_dynamic, rclass

syntax [anything]								///
		[if] [in]	,			 				///
			[ 									///
			COUNTries(string)					///
			Years(numlist)						///
			VARiables(string)					///
				VERMast(passthru)				///
				VERAlt(passthru)				///
				module(string)					///
				type(passthru)					///	
				survey(passthru)				///
				logfile							///
				replace							///
				path(string)					///
				outfile(string)					///
				CASEs(string)					///
				Weight(string)					///
				VARCtgs(string)					///
				VARWelfare(string)				///
				Sources(numlist)				///
				Format(string)					///
				fileserver          			///
			]

/*-----------------------------------------------------
		0. Check for errors and defaults
-----------------------------------------------------*/
qui {


if ("`bins'"=="") local bins=1
* programs
cap which distinct 
if (_rc > 0 ) ssc install distinct
* file to save categorical analysis
clear all


tempname pic
postfile `pic' str10 source str10 veralt str10 vermast str10 project str30 survey str30 year str30 acronym str30 country str30 type str30 nature str30 variable str244 description str30 module str30 analysis str30 case double value  using "`povcheck'", replace			

tempname cat
postfile `cat' str10 source str10 acronym str10 year str30 veralt str30 survey str30 vermast str30 type str30 module str30 case str30 variable str30 valuelabel double value  using "`catcheck'", replace			
	
*qui dis as error "`sources'"

/*-----------------------------------------------------
		1. Dynamic Analysis
-----------------------------------------------------*/
glo saveresultsbas=0
glo saveresultspov=0
glo saveresultsinq=0
glo saveresultscat=0


foreach source of local sources {

	/*if (`source'==.)	{				
		qui disp in red "No source assigned"
			continue 
		}  // close if _rc
	*/
	if (`source'==2)	{			
	
	* Set years
	foreach year of local years { 
	noi di "`country' - `year'"
	*************************************************
	
			if ("`source'"=="current") {
				use `database2qcheck', clear
				
				*local noteend`country'`year' "Variable -weighttype- not found for `country' `year' `veralt_p' `vermast_p'. Analitycal weight is assumed "
			}
			
			if ("`source'"=="datalibweb") {
				if ("`type'"=="type(sedlac)") local mod "mod(all)"
<<<<<<< HEAD
			cap datalibweb, country(`country') year(`year') `survey' `period' `type' `mod' clear 
			la lang cedlas	
=======
                if ("`type'"=="type(sedlac-03)") local mod "mod(all)"
			cap datalibweb, country(`country') year(`year') `theperiod' `type' `mod' clear 
			
			if ("`type'"=="type(sedlac-03)") la lang cedlas	
>>>>>>> JayneVersion
			}	
			
		
			if ("`source'"=="datalib") {
				if ("`type'"=="type(sedlac)") local mod "mod(all)"
			cap datalib, country(`country') year(`year') `type' clear `mod' `period' `survey' clear
*noi di "datalib, country(`country') year(`year') `type' clear `mod' `period' `survey'" 
			la lang cedlas	
			}
	
		*Analysis per variable 		
/*------------------------ basic Analysis----------------------------------*/

	
	*set trace on
	di 	"`weighttype' `weight'"
	
	if (regexm("`cases'", `"^.*basic"'))  {
	*qui di as text "`country'-`year'-dynamic-basic"
	foreach var in `variables' {

	cap confirm variable `var'	
				
		if _rc!=0 {										// var doesn't exist;
		di in yellow "`var' does not exist"
		gen `var'=.
		}
	}
	if (regexm("`cases'", `"^.*basic"'))&("`variables'"!="") {
	
* weight defined
if ("`weight'" == "") {
	local weight 1	
	noi di as error "Results are unweighted"
}
	* country information
	qui {
	dis as text "{hline}" 
	dis as text "{p 4 4 2}{cmd:Country:} "   in y  "`country'    " as text " {p_end}"
	dis as text "{p 4 4 2}{cmd:Year:} "      in y  "`year'   " as text " {p_end}"
	dis as text "{p 4 4 2}{cmd:Module:} "    in y  "`module' " as text " {p_end}"
	dis as text "{p 4 4 2}{cmd:Type:} "      in y  "`type'   " as text " {p_end}"
	dis as text "{p 4 4 2}{cmd:Survey ID:} " in y  "`survey'" as text " {p_end}"
	dis as text "{hline}" _newline
	} // end of noise
	
	local listvar ""
foreach var of local variables {
	cap confirm variable `var'
	if _rc==0 {
		local listvar "`var' `listvar'"
	}
}
local variables `listvar'

		/*------------------------ procedure for categorical variables if any -------------------------*/

		* gather categorical variables
				foreach varctg of local varctgs {

					cap confirm variable `varctg'

		if _rc==0  {
			qui su `varctg'
			if r(N)>0 {
				loc _check: val l `varctg'
					if `"`_check'"' == "" {
						di as error `"Variable `varctg' does not have val labels assigned"'
						local lab =0
						}
					if `"`_check'"' != "" {
						local lab =1
						}
				levelsof `varctg', local(levels)
				local lbe : value label `varctg'
	
			qui {
				foreach l of local levels {
					qui su `weight'  
					loc tot=r(sum)
					qui su `weight' if `varctg'==`l'
					 
					loc value=`r(sum)'/`tot'*100
					local variable="`varctg'"
					local case="categorical"
					local source="`source'"
					local vermast="`vermast_p'"
					local module="`mmm'"
					local veralt="`veralt_p'"
					if ("`lab'"=="1") {
						local valuelabel="`: label `lbe' `l''"
						}
						else {
							local valuelabel="`l'"
							}
						qui post `cat' ("`source'") ("`acronym'") ("`year'") ("`veralt'") ("`survey'") ("`vermast'") ("`type'") ("`module'") ("`case'") ("`variable'") ("`valuelabel'") (`value')
					
				}
		}
	glo saveresultscat=1
	}
	
	}
				}				// end of categorical var loop
				}
				
												}
											}
										}
												}                     //end of data loop	
				}   			//  End of module loop			
			}            //  End of Years loop		
		}                // end of countrylist loop	

	}                         // end of Source =2	
	
	if (`source'==1)	{				
		
		*local countries "`countries'"  
		local module "${module}"   
		local years "${years}"    
		
		
		foreach country in `countries' {
			
			qui datalibweb_inventory, code(`country')
			local region       = r(region)
			local countryname  = r(countryname)

			* Set years
			foreach year of local years { 
			*qui di "`country' - `year'"
			* Open data 

				* Set module 
				foreach mmm in "${module}" {
					noi dis in yellow "`country' - `year' - `mmm' - source(`source')"
					qui cap dlw, country(`country') year(`year') `vermast' `veralt' `gtype'  ${survey}  /*`gmodule'*/ module("`mmm'") clear   `fileserver'

					if _rc {  // if _rc
						disp in red "No data for `country'-`year' "
						continue 
					}  // close if _rc
			
					if (_rc==0)  {
						cap confirm variable countrycode
					if (_rc!=0)  {
						*local gmodule "module(UDB-C)"   
						qui cap dlw, country(`country') year(`year') `vermast' `veralt' `gtype'  ${survey}  /*`gmodule'*/ module("`mmm'") clear   `fileserver'
					}

			//weight
			cap confirm var weight
				if _rc!=0 {
					cap confirm var weight_p
					if _rc==0 {
					clonevar weight=weight_p 
					}
					}
					
			* create welfare
			foreach m in "`module'" {
			if "`m'"=="3"	{
				capture confirm variable welfare
				if !_rc {
				   qui di in red "welfare exists"
				}
				else {
					clonevar welfare=gallT 
				}
			}
			}

			* Set locals for data information
			local veralt_p  = r(vera)
			local vermast_p = r(verm)
			local surveyid    = r(surveyid)
			tokenize `surveyid', parse("_")
			local survey ="`5'"
			local acronym   = "`country'"
			local name 	  = "`countryname'" 
			local type      = r(type)
			local module    = "`r(module)'"
			local year	  = `year'
		
		//check if weight exists
		cap confirm var `weight'
		if _rc!=0 {
			noi di as txt "`country' - `year' - `mmm' - source(`source'): variable "`weight'" not found"
			exit
			}
		* weight defined
		if ("`weight'" == "") {
			local weight 1	
			di as error "Results are unweighted"
		}
			*weighttype
			cap confirm variable weighttype
			if _rc==0 {
				levelsof weighttype , local(weighttype)
				local weighttype=strlower(weighttype)
				cap tab countrycode [`weighttype'=`weight']
				if _rc!=0 {
		*local noteend`countryname'`year' "Variable -weighttype- not match with weight type for `countryname' `year' `veralt_p' `vermast_p'. Analitycal weight is assumed "
		qui di in red "`noteend`country'`year''"
					local weighttype "aw"
				}
			}
			else {
				*qui dis in red "Variable -weighttype- not found for `countryname' `year' `veralt_p' `vermast_p'. Analitycal weight is assumed "
				gen weighttype="aw"
				local weighttype "aw"
				
				*local noteend`countryname'`year' "Variable -weighttype- not found for `countryname' `year' `veralt_p' `vermast_p'. Analitycal weight is assumed "
			}

			* country information
			qui {
			dis as text "{hline}" 
			dis as text "{p 4 4 2}{cmd:Country:} "   in y  "`country'    " as text " {p_end}"
			dis as text "{p 4 4 2}{cmd:Year:} "      in y  "`year'   " as text " {p_end}"
			dis as text "{p 4 4 2}{cmd:Module:} "    in y  "`module' " as text " {p_end}"
			dis as text "{p 4 4 2}{cmd:Type:} "      in y  "`type'   " as text " {p_end}"
			dis as text "{p 4 4 2}{cmd:Survey ID:} " in y  "`survey'" as text " {p_end}"
			dis as text "{hline}" _newline
			} // end of quise


		*Analysis per variable 		
		/*------------------------ basic Analysis----------------------------------*/

			
			*set trace on
			*di 	"`weighttype' `weight'"

			if (regexm("`cases'", `"^.*basic"')) &("`variables'"=="") {
			
			foreach var in `variables' {

				cap confirm variable `var'	
				
				if _rc!=0 {										// var doesn't exist;
				di in yellow "`var' does not exist"
				exit
				}
			}
			}
			*qui di as text "is this working?"
			*qui di as text "`country'-`year'-dynamic-basic"
	if (regexm("`cases'", `"^.*basic"'))&("`variables'"!="") {
			qui ds
			loc varl `r(varlist)'

	#delimit ;
			basic_dyncheck `varl' [`weighttype'=`weight'],  source("`source'") veralt_p("`veralt_p'")	vermast_p("`vermast_p'")	project_p("`project_p'")	survey("`survey'")		year("`year'")	 module("`module'")		acronym("`country'")		name("`name'")		type("`type'")		nature("`nature'")		cname("`bc'") ;
	#delimit cr
	}	
			

			
			*if regexm("`variables'","welfare") {
		/*------------------------Poverty Analysis --------------------------*/
				if (regexm("`cases'", `"^.*pov(e|er|ert|erty)"')) {
					#delimit ;  
					di as text "`country'-`year'-dynamic-poverty" ;   
					#delimit cr	
					poverty_dyncheck `variables' [`weighttype'=`weight'], source(`source') veralt_p(`veralt_p')	vermast_p(`vermast_p')	project_p(`project_p')	survey(`survey')		year(`year')		acronym(`acronym')		name(`countryname' )		type(`type')	 module("`mmm'")		nature(`nature')		cname(`pic') `all'
				}
		/*------------------------inequality Analysis -----------------------*/
				if (regexm("`cases'", `"^.*ineq(u|ua|ual|uali|ualit|uality)"')) {
					#delimit ;  
					di as text "`country'-`year'-`mmm'-dynamic-inequality" ;   
					#delimit cr	
					ineq_dyncheck `variables' [`weighttype'=`weight'], source(`source')  veralt_p(`veralt_p')	vermast_p(`vermast_p')	project_p(`project_p')	survey(`survey')		year(`year')		acronym(`acronym')		name(`countryname' )		type(`type')	 module("`mmm'")		nature(`nature')		cname(`pic') `all'
				
				}		
	
			if (regexm("`cases'", `"^.*categorical"')) {

		/*------------------------ procedure for categorical variables if any -------------------------*/
/*
		foreach var in `variables' {

				cap confirm variable `var'	
				
									// var doesn't exist;
				di in yellow "`var' does not exist"
				qui gen `var'=.
				}
			}
*/
		* gather categorical variables
				foreach varctg of local varctgs {

					cap confirm variable `varctg'
				

		if _rc==0  {
			qui su `varctg'
			if r(N)>0 {
				loc _check: val l `varctg'
					if `"`_check'"' == "" {
						di as error `"Variable `varctg' does not have val labels assigned"'
						local lab =0
						}
					if `"`_check'"' != "" {
						local lab =1
						}
				levelsof `varctg', local(levels)
				local lbe : value label `varctg'
	
			qui {
				foreach l of local levels {
					qui su `weight'  
					loc tot=r(sum)
					qui su `weight' if `varctg'==`l'
					 
					loc value=`r(sum)'/`tot'*100
					local variable="`varctg'"
					local case="categorical"
					local source="`source'"
					local vermast="`vermast_p'"
					local module="`mmm'"
					local veralt="`veralt_p'"
					if ("`lab'"=="1") {
						local valuelabel="`: label `lbe' `l''"
						}
						else {
							local valuelabel="`l'"
							}
						qui post `cat' ("`source'") ("`acronym'") ("`year'") ("`veralt'") ("`survey'") ("`vermast'") ("`type'") ("`module'") ("`case'") ("`variable'") ("`valuelabel'") (`value')
					
				}
		}
	
	glo saveresultscat=1
	}
	
	}
				}				// end of categorical var loop
				

			
				} 
				} // end datalibweb condition
				} //  End of Module loop
				} //  End of Years loop
			} // end of countrylist loop  

		} // end of Source =1




}                                // end of Sources loop


/*=================
 2.2 Export info
 =================*/
* basic results
if (regexm("`cases'", `"^.*basic"')) & (${saveresultsbas}==1) {
	drop _all
	postclose `bc'
	use "`basiccheck'", clear
	compress
	* dta
	*save "`path'/basic`outfile'", `replace'
	if ("${format}"=="") {
		qui export excel "${salt_pathfile}/${salt_outfile}_long.xlsx", sheetreplace firstrow(variables) sheet("Basic_long")

	}
	if ("${format}"=="excel") {

		keep  vermast veralt value year variable   survey acronym type module case source
		qui reshape wide vermast veralt value, i(year variable   survey acronym type module case) j(source) string
		foreach v in veralt1 vermast1 veralt2 vermast2 value1 value2 {
				cap confirm variable `v'
				if _rc!=0 {
					qui g `v'=.
					}
					}	
		
		qui replace case=subinstr(case,"% ","",.)
		qui replace case=subinstr(case,". ","",.)
		qui gen version=case
		

		*qui replace version=case+"_Percent_"+source if inlist(case,"Missing","Zero")
		qui replace version=case+"_Percent" if inlist(case,"Missing","Zero")
		*qui keep year variable  vermast veralt  survey acronym type module version value
		qui keep year variable   survey acronym type module veralt1 vermast1 veralt2 vermast2 value1 value2  version
		*bys year variable survey acronym type module veralt1 vermast1 veralt2 vermast2: gen id=_n

		qui reshape wide value*, i(year variable survey acronym type module veralt1 vermast1 veralt2 vermast2) j(version) string	
		
		//create id for figure
		loc outvar acronym year type module survey vermast1 veralt1 vermast2 veralt2 variable value1Mean value1SD value1Missing_Percent value1Zero_Percent value1MillPop value2Mean value2SD value2Missing_Percent value2Zero_Percent value2MillPop
		qui egen id= group(acronym year )	
		qui egen concat=concat(acronym year variable)
		qui egen concat2=concat(acronym id)

		drop id
		*qui gen time = "`c(current_date)' `c(current_time)'" 
		qui keep `outvar' concat concat2
		order concat `outvar' concat2
		qui destring year, replace
		tempfile bexp
		save `bexp', replace
		
		//clear existing data in excel file
		qui import excel "${salt_pathfile}/${salt_outfile}.xlsx", sheet("Basic") firstrow clear

		qui ds 
		set trace off
		loc vars=r(varlist)

		foreach v of loc vars {
		cap confirm numeric var `v'
			if _rc==0 {
				qui replace `v'=.
			}
			if _rc!=0 {
				qui replace `v'=""
			}
			}

		export excel  using "${salt_pathfile}/${salt_outfile}.xlsx", sheet("Basic") cell(A3) sheetmodify
		
		//export final version
		qui u `bexp', clear
		qui format value1Mean value1SD value1Missing_Percent value1Zero_Percent value1MillPop value2Mean value2SD value2Missing_Percent value2Zero_Percent value2MillPop %30.2f
		export excel  using "${salt_pathfile}/${salt_outfile}.xlsx", sheet("Basic") cell(A3) sheetmodify
		
		//Log
			qui keep acronym	year	type	module
			qui duplicates drop
			qui gen no=.
			qui gen analysis="Basic"
			qui gen time = "`c(current_date)' `c(current_time)'"
					tempfile log
					qui save `log', replace
					qui import excel "${salt_pathfile}/${salt_outfile}.xlsx", sheet("Log") firstrow clear
					tempfile logori
					qui save `logori', replace
					qui u `log', clear
					qui append using `logori', force
			keep acronym	year	type	module	no	analysis	time	Note	
			qui export excel "${salt_pathfile}/${salt_outfile}.xlsx", sheetreplace firstrow(variables) sheet("Log")		
	}
	if ("${format}"=="all") {
		qui export excel "${salt_pathfile}/${salt_outfile}_long.xlsx", sheetreplace firstrow(variables) sheet("Basic_long")	
		keep  vermast veralt value year variable   survey acronym type module case source
		qui reshape wide vermast veralt value, i(year variable   survey acronym type module case) j(source) string
		foreach v in veralt1 vermast1 veralt2 vermast2 value1 value2 {
				cap confirm variable `v'
				if _rc!=0 {
					qui g `v'=.
					}
					}	
		
		qui replace case=subinstr(case,"% ","",.)
		qui replace case=subinstr(case,". ","",.)
		qui gen version=case
		

		*qui replace version=case+"_Percent_"+source if inlist(case,"Missing","Zero")
		qui replace version=case+"_Percent" if inlist(case,"Missing","Zero")
		*qui keep year variable  vermast veralt  survey acronym type module version value
		qui keep year variable   survey acronym type module veralt1 vermast1 veralt2 vermast2 value1 value2  version
		*bys year variable survey acronym type module veralt1 vermast1 veralt2 vermast2: gen id=_n

		qui reshape wide value*, i(year variable survey acronym type module veralt1 vermast1 veralt2 vermast2) j(version) string	
		
		//create id for figure
		loc outvar acronym year type module survey vermast1 veralt1 vermast2 veralt2 variable value1Mean value1SD value1Missing_Percent value1Zero_Percent value1MillPop value2Mean value2SD value2Missing_Percent value2Zero_Percent value2MillPop
		qui egen id= group(acronym year )	
		qui egen concat=concat(acronym year variable)
		qui egen concat2=concat(acronym id)

		drop id
		*qui gen time = "`c(current_date)' `c(current_time)'" 
		qui keep `outvar' concat concat2
		order concat `outvar' concat2
		qui destring year, replace
		tempfile bexp
		save `bexp', replace
		
		//clear existing data in excel file
		qui import excel "${salt_pathfile}/${salt_outfile}.xlsx", sheet("Basic") firstrow clear

		qui ds 
		set trace off
		loc vars=r(varlist)

		foreach v of loc vars {
		cap confirm numeric var `v'
			if _rc==0 {
				qui replace `v'=.
			}
			if _rc!=0 {
				qui replace `v'=""
			}
			}

		export excel  using "${salt_pathfile}/${salt_outfile}.xlsx", sheet("Basic") cell(A3) sheetmodify
		
		//export final version
		qui u `bexp', clear
		qui format value1Mean value1SD value1Missing_Percent value1Zero_Percent value1MillPop value2Mean value2SD value2Missing_Percent value2Zero_Percent value2MillPop %30.2f
		export excel  using "${salt_pathfile}/${salt_outfile}.xlsx", sheet("Basic") cell(A3) sheetmodify
		
		//Log
		
			qui keep acronym	year	type	module
			qui duplicates drop
			qui gen no=.
			qui gen analysis="Basic"
			qui gen time = "`c(current_date)' `c(current_time)'"
					tempfile log
					qui save `log', replace
					qui import excel "${salt_pathfile}/${salt_outfile}.xlsx", sheet("Log") firstrow clear
					tempfile logori
					qui save `logori', replace
					qui u `log', clear
					qui append using `logori', force
			keep acronym	year	type	module	no	analysis	time	Note	
			qui export excel "${salt_pathfile}/${salt_outfile}.xlsx", sheetreplace firstrow(variables) sheet("Log")		
	}

	if ("`cases'"=="basic categorical") {
		noi di as txt "Basic analysis is done."
	*qui di as txt "Click" as smcl `"{browse "${salt_pathfile}/${salt_outfile}.xlsx": here }"' `"to open results in excel for dynamic analysis, basic case. Saved in: "${salt_pathfile}/${salt_outfile}.xlsx" "'
	}
	if ("`cases'"=="basic") {
	noi di as txt "Click" as smcl `"{browse "${salt_pathfile}/${salt_outfile}.xlsx": here }"' `"to open results in excel for dynamic analysis, basic case. Saved in: "${salt_pathfile}/${salt_outfile}.xlsx" "'
	}
	
}
* Categorical analysis
if (regexm("`cases'", `"^.*categorical"')) & (${saveresultscat}==1) {

*dta
	*use `ctgdta', clear  
	*save "`path'/categ`outfile'", `replace'  
*excel
	postclose `cat'
	qui use "`catcheck'", clear

	qui destring year, replace
	qui ren value percent

	if ("${format}"=="") {

		qui export excel using "${salt_pathfile}/${salt_outfile}_long.xlsx", sheet("Categ_long") sheetreplace first(variable)
	}
	if ("${format}"=="excel") {
		drop case
		qui destring source, replace
		qui su source
		
		if (r(max)!=r(min)) {
				duplicates drop 
				qui reshape wide veralt vermast  percent, i( acronym year survey type module variable valuelabel) j(source)  
		}
		if (r(max)==r(min)) {
			*qui destring source, replace 
			if (r(max)==1) {
				ren ( veralt vermast  percent) ( vermast1	veralt1  percent1 )
				}
			
			if (r(max)==2) {

				ren ( veralt vermast  percent) ( vermast2	veralt2  percent2 )
				}
		*qui reshape wide veralt vermast  percent, i( acronym year survey type module variable valuelabel) j(  source) string
		foreach v in veralt1 vermast1 veralt2 vermast2 percent1 percent2 {
				cap confirm variable `v'
				if _rc!=0 {
					qui g `v'=.
					}
					}		
		}
		
		
		qui keep acronym year type survey  module veralt1 vermast1	veralt2 vermast2	  variable valuelabel percent1 percent2
		qui order acronym year type survey  module veralt1 vermast1	veralt2 vermast2	  variable valuelabel percent1 percent2
		*qui gen time = "`c(current_date)' `c(current_time)'"
		
		//create id for figure	

		cap drop id
		gen id=.
		levelsof acronym, loc(c)
		
		levelsof year, loc(yr)
		set trace off
		tostring year, replace
		
		foreach f of loc c {
			encode year if acronym=="`f'", gen(id`f')
			replace id=id`f' if id==.
			drop id`f'
		}
		destring year, replace
		qui egen concat=concat(acronym year variable)
		
		cap drop id2
		gen id2=.
		levelsof concat, loc(conc)
		*levelsof year, loc(yr)
		tostring concat, replace
		foreach f of loc conc {
			encode valuelabel if conc=="`f'", gen(id`f')
			replace id2=id`f' if id2==.
			drop id`f'
		}

		qui egen concat2=concat(acronym id)
		qui egen concat3=concat(acronym year variable id2)
		drop id id2 
		*qui gen time = "`c(current_date)' `c(current_time)'" 
		qui keep acronym year type survey  module veralt1 vermast1	veralt2 vermast2	  variable valuelabel percent1 percent2 concat concat2 concat3
		order concat acronym year type survey  module veralt1 vermast1	veralt2 vermast2	  variable valuelabel percent1 percent2 concat2 concat3

		tempfile cexp
		save `cexp', replace
		
		//clear existing data in excel file
		qui import excel "${salt_pathfile}/${salt_outfile}.xlsx", sheet("Categ") firstrow clear

		qui ds 
		set trace off
		loc vars=r(varlist)

		foreach v of loc vars {
		cap confirm numeric var `v'
			if _rc==0 {
				qui replace `v'=.
			}
			if _rc!=0 {
				qui replace `v'=""
			}
			}

		export excel  using "${salt_pathfile}/${salt_outfile}.xlsx", sheet("Categ") cell(A3) sheetmodify
		
		//export final version
		qui u `cexp', clear
		qui format percent1 percent2 %30.2f
		qui export excel  using "${salt_pathfile}/${salt_outfile}.xlsx", sheet("Categ") cell(A3) sheetmodify
			
			//Log
			
			qui keep acronym	year	type	module
			qui duplicates drop
			qui gen no=.
			qui gen analysis="Categorical"
			qui gen time = "`c(current_date)' `c(current_time)'"
					tempfile log
					qui save `log', replace
					qui import excel "${salt_pathfile}/${salt_outfile}.xlsx", sheet("Log") firstrow clear
					tempfile logori
					qui save `logori', replace
					qui u `log', clear
					qui append using `logori', force
			*keep acronym	year	type	module	no	analysis	time	Note	
			qui export excel "${salt_pathfile}/${salt_outfile}.xlsx", sheetreplace firstrow(variables) sheet("Log")			
	}
	if ("${format}"=="all") {

		qui export excel using "${salt_pathfile}/${salt_outfile}_long.xlsx", sheet("Categ_long") sheetreplace first(variable)
		
		drop case
		qui destring source, replace
		qui su source
		
		if (r(max)!=r(min)) {
				duplicates drop 
				qui reshape wide veralt vermast  percent, i( acronym year survey type module variable valuelabel) j(source)  
		}
		if (r(max)==r(min)) {
			*qui destring source, replace 
			if (r(max)==1) {
				ren ( veralt vermast  percent) ( vermast1	veralt1  percent1 )
				}
			
			if (r(max)==2) {

				ren ( veralt vermast  percent) ( vermast2	veralt2  percent2 )
				}
		*qui reshape wide veralt vermast  percent, i( acronym year survey type module variable valuelabel) j(  source) string
		foreach v in veralt1 vermast1 veralt2 vermast2 percent1 percent2 {
				cap confirm variable `v'
				if _rc!=0 {
					qui g `v'=.
					}
					}		
		}
		
		
		qui keep acronym year type survey  module veralt1 vermast1	veralt2 vermast2	  variable valuelabel percent1 percent2
		qui order acronym year type survey  module veralt1 vermast1	veralt2 vermast2	  variable valuelabel percent1 percent2
		*qui gen time = "`c(current_date)' `c(current_time)'"
		
		//create id for figure	

		cap drop id
		gen id=.
		levelsof acronym, loc(c)
		
		levelsof year, loc(yr)
		set trace off
		tostring year, replace
		
		foreach f of loc c {
			encode year if acronym=="`f'", gen(id`f')
			replace id=id`f' if id==.
			drop id`f'
		}
		destring year, replace
		qui egen concat=concat(acronym year variable)
		
		cap drop id2
		gen id2=.
		levelsof concat, loc(conc)
		*levelsof year, loc(yr)
		tostring concat, replace
		foreach f of loc conc {
			encode valuelabel if conc=="`f'", gen(id`f')
			replace id2=id`f' if id2==.
			drop id`f'
		}

		qui egen concat2=concat(acronym id)
		qui egen concat3=concat(acronym year variable id2)
		drop id id2 
		*qui gen time = "`c(current_date)' `c(current_time)'" 
		qui keep acronym year type survey  module veralt1 vermast1	veralt2 vermast2	  variable valuelabel percent1 percent2 concat concat2 concat3
		order concat acronym year type survey  module veralt1 vermast1	veralt2 vermast2	  variable valuelabel percent1 percent2 concat2 concat3

		tempfile cexp
		save `cexp', replace
		
		//clear existing data in excel file
		qui import excel "${salt_pathfile}/${salt_outfile}.xlsx", sheet("Categ") firstrow clear

		qui ds 
		set trace off
		loc vars=r(varlist)

		foreach v of loc vars {
		cap confirm numeric var `v'
			if _rc==0 {
				qui replace `v'=.
			}
			if _rc!=0 {
				qui replace `v'=""
			}
			}

		export excel  using "${salt_pathfile}/${salt_outfile}.xlsx", sheet("Categ") cell(A3) sheetmodify
		
		//export final version
		qui u `cexp', clear
		qui qui format percent1 percent2 %30.2f
		qui export excel  using "${salt_pathfile}/${salt_outfile}.xlsx", sheet("Categ") cell(A3) sheetmodify

			
			//Log
			
			qui keep acronym	year	type	module
			qui duplicates drop
			qui gen no=.
			qui gen analysis="Categorical"
			qui gen time = "`c(current_date)' `c(current_time)'"
					tempfile log
					qui save `log', replace
					qui import excel "${salt_pathfile}/${salt_outfile}.xlsx", sheet("Log") firstrow clear
					tempfile logori
					qui save `logori', replace
					qui u `log', clear
					qui append using `logori', force
			*keep acronym	year	type	module	no	analysis	time	Note	

			qui export excel "${salt_pathfile}/${salt_outfile}.xlsx", sheetreplace firstrow(variables) sheet("Log")			
	}
	
	if ("`cases'"=="basic categorical") {
		noi di as txt "Click" as smcl `"{browse "${salt_pathfile}/${salt_outfile}.xlsx": here }"' `"to open results in excel for dynamic analysis, basic & categorical case. Saved in: "${salt_pathfile}/${salt_outfile}.xlsx" "'
	}
	if ("`cases'"=="categorical") {
		noi di as txt "Click" as smcl `"{browse "${salt_pathfile}/${salt_outfile}.xlsx": here }"' `"to open results in excel for dynamic analysis, categorical case. Saved in: "${salt_pathfile}/${salt_outfile}.xlsx" "'
	}
	}
	}
if (regexm("`cases'", `"^.*categorical"')) & (${saveresultscat}!=1) {
		noi di as txt "Variables are not eligible for categorical analysis"
	}
	* Poverty
if ((regexm("`cases'", `"^.*pov(e|er|ert|erty)"')) & (${saveresultspov}==1)) | ((regexm("`cases'", `"^.*ineq(u|ua|ual|uali|ualit|uality)"')) & (${saveresultsinq}==1)) {
	drop _all
	postclose `pic'
	use "`povcheck'", clear
	compress
	* dta
	*save "`path'/pov_inq_`outfile'", `replace' 

	* excel
	export excel using "${salt_pathfile}/${salt_outfile}.xlsx", sheet("Poverty_Inequality") sheetreplace first(variable)
	noi di as txt "Click" as smcl `"{browse "${salt_pathfile}/${salt_outfile}.xlsx": here }"' `"to open results in excel for dynamic analysis, poverty and inequality case. Saved in: "${salt_pathfile}/${salt_outfile}.xlsx" "' 
	
	preserve 
	* excel version for checking   
	keep year case source vermast veralt  survey acronym type  analysis value 
	reshape wide value, i(year source vermast veralt  survey acronym type  analysis) j(case ) string
	rename value* *
	order year source veralt vermast survey acronym  type 
	*qui gen time = "`c(current_date)' `c(current_time)'"
	export excel using "${salt_pathfile}/${salt_outfile}_wide.xlsx", sheet("Poverty_Inequality") sheetreplace first(variable)
	noi di as txt "Click" as smcl `"{browse "${salt_pathfile}/${salt_outfile}_wide.xlsx": here }"' `"to open results in excel for dynamic analysis, poverty and inequality case in wide format. Saved in: "${salt_pathfile}/${salt_outfile}_wide.xlsx" "' 
	restore	
}
/*
* Inequality
if (regexm("`cases'", `"^.*ineq(u|ua|ual|uali|ualit|uality)"')) & (${saveresultsinq}==1) {
	drop _all
	postclose `pic'
	use inqcheck, clear
	compress
	* dta
	*save "`path'/inq_`outfile'", `replace'
	* excel
	export excel using "`path'/dyn_`outfile'.xlsx", sheet("Poverty_Inequality") sheetreplace first(variable)
	noi di as txt "Click" as smcl `"{browse "`path'/dyn_`outfile'.xlsx": here }"' `"to open results in excel for dynamic analysis, inequality case. Saved in: "`path'/dyn_`outfile'.xlsx" "' 
}	
*/

	foreach country of local countries {
		qui datalibweb_inventory, code(`country')
		local countryname  = r(countryname)
		foreach year of local years { 
	  if "`noteend`country'`year''"!="" {
      qui di in red "`noteend`country'`year''"
		}
	}
		}

end


