/* *===========================================================================
	_indcheck: Program to check indicators over versions and time
	Reference: 
-------------------------------------------------------------------
Created: 		19Jul2013	(Santiago Garriga & Andres Castaneda) 
Modified:		19Jul2013	(Santiago Garriga & Andres Castaneda) 
version:		01 
Dependencies: 	WORLD BANK - LCSPP
*===========================================================================*/

discard
cap program drop qcheck_indicators
program define qcheck_indicators, sortpreserve

syntax [anything]								///
		[if] [in], 								///
			[ 									///
			COUNTries(string)					///
			years(numlist)						///
			CASEs(string)						///
			COMPare(string)						///
			path(string)						///
			export								///
			]

/*-----------------------------------------------------
		0. Check for errors and defaults
-----------------------------------------------------*/
preserve 							//  Keep original data

qui {
	* 0.1 Countries to analyze
	if ("`countries'" == "" | "`countries'" == "all" ) {	//  Set default option: all disposable countries
		local countries "arg bol bra chl col cri dom ecu slv gtm hnd mex nic pan pry per ury"
	}

	* 0.2 Years to analyze
	if ( wordcount("`years'") == 0 ) {	//  Set default option:: years available from 2000 to 2011
		numlist "2000/2011"
	}
	else {
		numlist "`years'"
	}
	local years = r(numlist)

	* 0.3 Type of analysis: cases

	if ("`cases'" == "") {	// Set default option: Poverty
		local cases "Poverty"
	}
	
	if (regexm("`cases'", `"^[Pp]ov(e|er|ert|erty)"')) & ( wordcount("`cases'") == 1){ 	// Poverty option 		
		local cases "Poverty"
	}
	
	if (regexm("`cases'", `"^[Ii]neq(u|ua|ual|uali|ualit|uality)"' )) & ( wordcount("`cases'") == 1) { 	// Inequality option 		
		local cases "Inequality"
	}
	
	if ( "`cases'" != "Poverty" & "`cases'" != "Inequality" ) {	// Either poverty or inequality is allowed 		
		noi di as err "you must specify either poverty or inequality"
		error 197
	}

	if ( wordcount("`cases'") >= 2) {	// Only one option is allowed 		
		noi di as err "you must specify either poverty or inequality"
		error 197
	}
	
	* 0.4 Compare either projects or versions within projects
	
	if ("`compare'" == "") {	// Set default option: project
		local compare "project"
	}
	
	if (regexm("`compare'", `"^[Pp]ro(j|je|jec|ject)"')) & ( wordcount("`cases'") == 1){ 	// Project option 		
		local compare "project"
	}
	
	if (regexm("`compare'", `"^[Vv]er(s|si|sio|sion)"' )) & ( wordcount("`cases'") == 1) { 	// Version option 		
		local compare "version"
	}
	
	if ( "`compare'" != "project" & "`compare'" != "version" ) {	// Either project or version is allowed 		
		noi di as err "you must specify either project or version"
		error 197
	}

	if ( wordcount("`compare'") >= 2) {	// Only one option is allowed 		
		noi di as err "you must specify either project or version"
		error 197
	}
	* 0.4.1 Module for Project alternative
	
	if ( "`compare'" == "project") {	// Either project or version is allowed 		
		local alternative = "01 02"	//  Set Project versions
	}
	
	* 0.4.2 Module for Version alternative
	
	if ( "`compare'" == "version") {	// Either project or version is allowed 		
		local alternative = "01 02 03 04"	//  Set Project versions
	}
	
	* 0.5 Path consistency

	if ("`path'" != "" ) { // check if  the directory exists 
		cap local aa: dir "./`path'" dirs "*"			// check on current directory whether the folder exists
		if (_rc == 0 ) local path = "`c(pwd)'/`path'"	// create local if so
		else cap local aa: dir "`path'" dirs "*" 		// check whether the folder exists
		if (_rc) {
			disp in red _new "`path' does not exist or the directory permissions do not allow you to create a new file"
			error
		}
	}
	
	
	/*-----------------------------------------------------
			1. Indicator Analysis
	-----------------------------------------------------*/

	* 1.0 file with information and indicator calculation
	tempfile check
	tempname c
	postfile `c' str10 veralt str10 vermast str10 project str30 survey str30 year str30 acronym str30 country str30 type str30 nature str30 variable str244 description str30 module double value  using `check', replace

	foreach cnt of local countries {	// loop for countries 
	
		foreach year of local years {	// loop for year 
	
			foreach alt of local alternative { 	// Compare option loop: Either project or version is allowed 
				
				* Project
				if ( "`compare'" == "project") qui: capture datalib, country(`cnt') years(`year') project("`alt'") veralt("")  clear // Project alternative
				
				* Version
				if ( "`compare'" == "version") qui: capture datalib, country(`cnt') years(`year') project("") veralt("`alt'")  clear // Version alternative				
				
				* Dataset available
				if _rc == 0 {
					
					* Set locals for data information
					local veralt = r(veralt)
					local vermast = r(vermast)
					local project = r(project)
					local survey = r(surveys)
					local acronym = r(acronym)
					local name =  r(country) 
					local type = r(type)
					local nature = r(nature)				

					
					* 1.1 Indicators
					
					* Poverty
					if ( "`cases'" == "Poverty") { 	// loop for poverty numbers		
						
						* Extreme
						
						 * National
						apoverty ipcf [w=pondera] , varpl(lp_2usd)
						post `c' ("`veralt'") ("`vermast'") ("`project'") ("`survey'") ("`year'") ("`acronym'") ("`name'") ("`type'") ("`nature'") ("`cases'") ("Extreme") ("National")  (`r(head_1)')	
								
						 * Urban
						apoverty ipcf [w=pondera] if urbano == 1, varpl(lp_2usd)
						post `c' ("`veralt'") ("`vermast'") ("`project'") ("`survey'") ("`year'") ("`acronym'") ("`name'") ("`type'") ("`nature'") ("`cases'") ("Extreme") ("Urban")  (`r(head_1)')	
						
						* Rural
						cap apoverty ipcf [w=pondera] if urbano == 0, varpl(lp_2usd) 
						if _rc == 0 local rural = r(head_1) 
						if _rc != 0 local  rural = .
						post `c' ("`veralt'") ("`vermast'") ("`project'") ("`survey'") ("`year'") ("`acronym'") ("`name'") ("`type'") ("`nature'") ("`cases'") ("Extreme") ("Rural")  (`rural')	
						
						* Moderate
						
						 * National
						apoverty ipcf [w=pondera] , varpl(lp_4usd)
						post `c' ("`veralt'") ("`vermast'") ("`project'") ("`survey'") ("`year'") ("`acronym'") ("`name'") ("`type'") ("`nature'") ("`cases'") ("Moderate") ("National")  (`r(head_1)')	
									
						* Urban
						apoverty ipcf [w=pondera] if urbano == 1, varpl(lp_4usd)
						post `c' ("`veralt'") ("`vermast'") ("`project'") ("`survey'") ("`year'") ("`acronym'") ("`name'") ("`type'") ("`nature'") ("`cases'") ("Moderate") ("Urban")  (`r(head_1)')	
									
						* Rural
						cap apoverty ipcf [w=pondera] if urbano == 0, varpl(lp_4usd)
						if _rc == 0 local rural = r(head_1) 
						if _rc != 0 local  rural = .				
						post `c' ("`veralt'") ("`vermast'") ("`project'") ("`survey'") ("`year'") ("`acronym'") ("`name'") ("`type'") ("`nature'") ("`cases'") ("Moderate") ("Rural")  (`rural')	
						
					}	// end loop for poverty numbers		
					
					* 1.2 Inequality
					if ( "`cases'" == "Inequality") { 	// loop for poverty numbers		
										
						* Without zero
						
						* National
						ainequal ipcf  [w=pondera] if ipcf > 0
						post `c' ("`veralt'") ("`vermast'") ("`project'") ("`survey'") ("`year'") ("`acronym'") ("`name'") ("`type'") ("`nature'") ("`cases'") ("Without zero") ("National")  (`r(gini_1)')	
									
						* Urban
						ainequal ipcf  [w=pondera] if ipcf > 0 & urbano == 1
						post `c' ("`veralt'") ("`vermast'") ("`project'") ("`survey'") ("`year'") ("`acronym'") ("`name'") ("`type'") ("`nature'") ("`cases'") ("Without zero") ("Urban")  (`r(gini_1)')	
									
						* Rural
						cap ainequal ipcf  [w=pondera] if ipcf > 0 & urbano == 0
						if _rc == 0 local rural = r(gini_1) 
						if _rc != 0 local  rural = .	
						post `c' ("`veralt'") ("`vermast'") ("`project'") ("`survey'") ("`year'") ("`acronym'") ("`name'") ("`type'") ("`nature'") ("`cases'") ("Without zero") ("Rural")  (`rural')	
						
						* With zero
						
						 * National
						ainequal ipcf  [w=pondera]
						post `c' ("`veralt'") ("`vermast'") ("`project'") ("`survey'") ("`year'") ("`acronym'") ("`name'") ("`type'") ("`nature'") ("`cases'") ("With zero") ("National")  (`r(gini_1)')	 
						
						 * Urban
						ainequal ipcf  [w=pondera] if urbano == 1
						post `c' ("`veralt'") ("`vermast'") ("`project'") ("`survey'") ("`year'") ("`acronym'") ("`name'") ("`type'") ("`nature'") ("`cases'") ("With zero") ("Urban")  (`r(gini_1)')	 
						
						* Rural
						cap ainequal ipcf  [w=pondera] if urbano == 0	
						if _rc == 0 local rural = r(gini_1) 
						if _rc != 0 local  rural = .					
						post `c' ("`veralt'") ("`vermast'") ("`project'") ("`survey'") ("`year'") ("`acronym'") ("`name'") ("`type'") ("`nature'") ("`cases'") ("With zero") ("Rural")  (`rural')	 
						
					}	// end loop for inequality numbers		
				}	// end loop _rc == 0
			}	// end loop for project or version variations
		}	// end loop for year 
	}	// end loop for countries


	* Close Post file
	postclose `c'
	use `check', clear		
	compress
	
	* 2.0 estimate difference and display results
	
	* 2.1 Project Alternative
	
	if ( "`compare'" == "project") {
		
		* Local for # of projects
		destring project, replace
		sum project
		local min = r(min)
		local max = r(max)
		
		* Reshape data to calculate change
		reshape wide value veralt vermast, i( survey year acronym country type nature variable description module ) j(project) 
		
		if `min' != `max' gen value3 = ((value2- value1)/ value1)*100	// Both projects available
		if `min' == `max' & `min' == 1 gen value2 = .	// Only project 01 available
		if `min' == `max' & `min' == 2 gen value3 = .	// Only project 02 available
		
		* Reshape in long to show in a table
		reshape long  value veralt0 vermast0 , i( survey year acronym country type nature variable description module ) j(project) 
		 
		* Set labels to project
		label values project project
		if `min' != `max' label define project 1 "01"  2 "02" 3 "Dif 2/1(%)"	// Both projects available
		if `min' == `max' & `min' == 1 label define project 1 "01" 2 "Dif 2/1(%)"	// Only project 01 available
		if `min' == `max' & `min' == 2 label define project 2 "02" 3 "Dif 2/1(%)"	// Only project 02 available
		
		format %3.2f value*
		
		* Display tables for each country
		foreach cnt of local countries {	// loop for countries 
			noi {
				dis as text "{hline}" 
				dis as text "{p 10 4 2}{cmd:Country:} " 	in y  "`cnt'" as text " {p_end}"
				dis as text "{p 10 4 2}{cmd:Analysis:} " 	in y  "`cases'" as text " {p_end}"
				tabdisp year  project description if acronym == "`cnt'",  cellvar(value) by(module) center
				disp _newline
			} // end of noise
		}	// end loop for countries 
	}	// end if project 
	
	
	* 2.2 Version Alternative
	
	if ( "`compare'" == "version") {
		
		* Local for # of versions
		destring veralt, replace
		sum veralt
		local min = r(min)
		local max = r(max)
		
		* Reshape data to calculate change
		reshape wide value vermast, i( survey year acronym country type nature variable description module project) j(veralt) 
		
		* Generate the change
		if `max' == 2 gen value3 = .	// Only version 02 available	
		if `max' == 3 gen value4 = ((value3- value2)/ value2)*100	// Version 02 and 03 available
		if `max' == 4 {	// Version 02, 03 and 04 available
			gen value5 = ((value3- value2)/ value2)*100
			gen value6 = ((value4- value3)/ value3)*100
		}
			
		* Reshape in long to show in a table
		reshape long  value veralt0 vermast0 , i( survey year acronym country type nature variable description module project ) j(veralt) 
		format %3.2f value
				
		* Set labels to version
		label values veralt veralt
		if `max' == 2 label define veralt 2 "02" 3 "Dif (%)"
		if `max' == 3 label define veralt 2 "02" 3 "03" 4 "Dif 3/2(%)"
		if `max' == 4 label define veralt 2 "02" 3 "03" 4 "04" 5 "Dif 3/2(%)" 6 "Dif 4/3(%)"
				
		* Display tables for each country
		foreach cnt of local countries {	// loop for countries 
			noi {
				dis as text "{hline}" 
				dis as text "{p 10 4 2}{cmd:Country:} " 	in y  "`cnt'" as text " {p_end}"
				dis as text "{p 10 4 2}{cmd:Analysis:} " 	in y  "`cases'" as text " {p_end}"
				tabdisp year  veralt description if acronym == "`cnt'",  cellvar(value) by(module) center
				disp _newline
			} // end of noise
		}	// end loop for countries 
	}	// end if version 
}	// end qui 

* 3.0 Export info
if ("`export'" == "export") {
	if ("`path'" == "") local path = "`c(pwd)'"
	export excel using "`path'/data_check.xlsx", sheet("Indicator raw") sheetreplace first(variable)
	local abc = "`c(pwd)'"
	cd "`path'"
	noi disp in green "to open the file " _conti
	noi display `"{ stata shell "data_check.xlsx" : click here}"' 
	cd "`abc'"
}

restore //  Keep original data
end // end of program. 
exit

************************************************************************************************

* Observations
sum pondera
post `c' ("`veralt'") ("`vermast'") ("`project'") ("`survey'") ("`year'") ("`acronym'") ("`name'") ("`type'") ("`nature'") ("`cases'") ("Observations") ("National")  (`r(N)')

* Population
post `c' ("`veralt'") ("`vermast'") ("`project'") ("`survey'") ("`year'") ("`acronym'") ("`name'") ("`type'") ("`nature'") ("`cases'") ("Population") ("National")  (`r(sum)')

* Percentage of zero (ipcf) (weighted)
sum ipcf [w=pondera] if ipcf == 0
local zero = r(N)
count
local zero = (`zero'/r(N))
post `c' ("`veralt'") ("`vermast'") ("`project'") ("`survey'") ("`year'") ("`acronym'") ("`name'") ("`type'") ("`nature'") ("`cases'") ("Zero IPCF") ("National")  (`zero')

* Percentage of missing (ipcf) (weighted)
tempvar aux
gen `aux' = missing(ipcf)
sum ipcf [w=pondera]
post `c' ("`veralt'") ("`vermast'") ("`project'") ("`survey'") ("`year'") ("`acronym'") ("`name'") ("`type'") ("`nature'") ("`cases'") ("Miss IPCF") ("National")  (`r(mean)')

* Average ipcf (weighted)
sum ipcf [w=pondera], meanonly
post `c' ("`veralt'") ("`vermast'") ("`project'") ("`survey'") ("`year'") ("`acronym'") ("`name'") ("`type'") ("`nature'") ("`cases'") ("Miss IPCF") ("National")  (`r(mean)')


