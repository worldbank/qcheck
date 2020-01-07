/* *===========================================================================
	_dyncheck: Program to check the quality of the data over time
	Reference: 
-------------------------------------------------------------------
Created datalib/lac: 		15Jul2013	(Santiago Garriga & Andres Castaneda) 
Adapted datalibweb:			01Aug2016 	Laura Moreno Herrera
				20Nov2013	(Santiago Garriga & Andres Castaneda) 
Last Modifications: 7Oct2019   Sandra Segovia / Laura Moreno
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
				module(passthru)				///
				project(passthru)				///
				period(passthru)				///				
				type(passthru)					///	
				survey(passthru)				///
				logfile							///
				replace							///
				path(string)					///
				outfile(string)					///
				CASEs(string)					///
				Weight(string)					///
				VARCtgs(string)				///
				VARWelfare(string)				///
				noppp							///
				bins(numlist)					///
				SOurce(string)					///
				REView(string)					///
				EXCELoutput(string)			///
			]

/*-----------------------------------------------------
		0. Check for errors and defaults
-----------------------------------------------------*/
noi { 
	if ("`source'"=="current") {
	tempfile database2qcheck
	save `database2qcheck', replace
	}
	if ("`outfile'"=="") {
	local outfile "${salt_outfile}"	
	}

qui {
local gtype "`type'"
local gsurvey "`survey'"
local gperiod "`period'"
local gproject "`project'"


	************** long vs wide    
	if ("`exceloutput'"=="" ) {
		disp in red "you should indicate output format, default long"
		local exceloutput="long"
		}
	if ("`exceloutput'"=="long" ) {
			di as txt "Output will be saved in long format only"
			}	
	if ("`exceloutput'"=="none" ) {
			di as txt "No excel output will be saved"
			}
	if !inlist("`exceloutput'", "none", "long") {
		disp in red "you must select excel long, none"
		error
	}

if ("`bins'"=="") local bins=1
* programs
cap which distinct 
if (_rc > 0 ) ssc install distinct
* file to save categorical analysis
clear all
tempfile ctgdta
save `ctgdta', replace emptyok
* file with information
*tempfile to save others check
tempname bc
postfile `bc' str10 veralt str10 vermast str10 project str10 period str30 survey str30 year str30 acronym str30 country str30 type str30 nature str30 variable str244 description str30 module str30 analysis str30 case double value bin using basiccheck, replace

*postfile `bc' str30 country str10 year str30 acronym str10 vermast str10 veralt str30 survey str30 type str30 nature str10 project str10 period str10 contador str30 module str30 variable str30 warning str10 frequency str10 size double percentage str244 description str244 iff str30 data_year using basiccheck, replace;



tempname pic
postfile `pic' str10 veralt str10 vermast str10 project  str10 period str30 survey str30 year str30 acronym str30 country str30 type str30 nature str30 variable str244 description str30 module str30 analysis str30 case double value bin using povcheck, replace



/*-----------------------------------------------------
		1. Dynamic Analysis
-----------------------------------------------------*/
glo saveresultsbas=0
glo saveresultspov=0
glo saveresultsinq=0
glo saveresultscat=0

foreach country of local countries {
	
	* Set years
	foreach year of local years { 
	noi di "`country' - `year'"
	* Open data 
*noi di "country(`country') year(`year')  `vermast' `veralt' `gperiod' `gproject' `gtype' `gsurvey'  `noppp'  lang(es) clear"
	*local gmod
	*if ("`gtype'"=="type(lablac)") local gmod "" `module'
	*************************************************
	
			if ("`source'"=="current") {
				use `database2qcheck', clear
				
			}
			
			
			if ("`source'"=="review") {;
			*##4. Jayne, here I call the ado from your code. it is possible to complement as needed with additional options;
			cap qcheck_opendata, country("`country'") year(`year') type("`type'") module("`mod'") review(`review') 
			if _rc!=0 {
				noi di "please check open data inputs"
			}
			}
			
			if ("`source'"=="datalibweb") {
				if ("`periodo'"!="") local theperiod "period(`periodo')"
				if ("`type'"=="type(sedlac)") local mod "mod(all)"
                if ("`type'"=="type(sedlac-03)") local mod "mod(all)"
			cap datalibweb, country(`country') year(`year') `theperiod' `type' `mod' clear 
			
			if ("`type'"=="type(sedlac-03)") la lang cedlas	
			}	
			
			if ("`source'"=="datalib") {
				if ("`periodo'"!="") local theperiod "period(`periodo')"
				if ("`type'"=="type(sedlac)") local mod "mod(all)"
			cap datalib, country(`country') year(`year') `theperiod' `type' clear `mod'
			la lang cedlas	
			}
	
	
	*************************************************
			if _rc!=0 {  // if _rc
			
				noi disp in red "No data for `country'-`year' "
				continue 
			}  // close if _rc
	
	if (_rc==0)  {
	* Set locals for data information

		if ("`source'"=="datalib") {
			local veralt_p  = r(veralt)
			local vermast_p =  r(vermast)
			local survey    = r(survname)
			local acronym   = "`country'"
			local name 	  =  r(country) 
			local countryname 	  =  r(country) 
			local type      = r(type)
			local module    = r(nature)
			local year	  = "`year'"
			local period_p = r(period)
			local project_p = r(project)
		}
		
		
		if ("`source'"=="datalibweb") {
			local veralt_p  = r(vera)
			local vermast_p =  r(verm)
			local survey    = r(survname)
			local acronym   = "`country'"
			local name 	  =  r(country) 
			local countryname 	  =  r(country) 
			local type      = r(type)
			local module    = r(nature)
			local year	  = "`year'"
			local period_p = r(period)
			local project_p = r(project)
		}
	
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

* bins

gen bins=`bins'
if (`bins'!=1) {
	_ebin ipcf [aw=`weight'], gen(xx) nq(`bins')
	replace bins=xx
	drop xx
}

	
*Analysis per variable 		
/*------------------------ basic Analysis----------------------------------*/

	

	di 	"`weighttype' `weight'"

foreach nq of numlist 1/`bins' {	
	if (regexm("`cases'", `"^.*basic"')) & ("`variables'"!="") {
	local gsaved
	noi di as text "`country'-`year'-dynamic-basic"
			basic_dyncheck `variables' [aw=`weight'],  veralt_p(`veralt_p')	vermast_p(`vermast_p')	project_p(`project_p') period_p(`period_p')	survey(`survey') year(`year') acronym(`country') name(`name') type(`type') nature(`nature') cname(`bc') nq(`nq')
	}
}
	if (regexm("`cases'", `"^.*basic"')) & ("`variables'"=="") {
		noi di in red "Variable included does not exits in database"
		exit
	}

	
	if regexm("`variables'","ipcf") {
*------------------------Poverty Analysis --------------------------*
		if (regexm("`cases'", `"^.*pov(e|er|ert|erty)"')) {
		noi di as text "`country'-`year'-dynamic-poverty"
		local varwelfare "ipcf_ppp11"
			poverty_dyncheck `varwelfare' [aw=`weight'],  veralt_p(`veralt_p')	vermast_p(`vermast_p')	project_p(`project_p') period_p(`period_p')	survey(`survey') year(`year') acronym(`acronym') name(`countryname' ) type(`type') nature(`nature') cname(`pic') `all'
		}

*------------------------inequality Analysis -----------------------*

	if (regexm("`cases'", `"^.*ineq(u|ua|ual|uali|ualit|uality)"')) {
		noi di as text "`country'-`year'-dynamic-inequality"
			ineq_dyncheck `varwelfare' [aw=`weight'],  veralt_p(`veralt_p')	vermast_p(`vermast_p')	project_p(`project_p') period_p(`period_p')	survey(`survey') year(`year') acronym(`acronym') name(`countryname' ) type(`type') nature(`nature') cname(`pic') `all'
		}		
	}
		


foreach nq of numlist 1/`bins' {

	if (regexm("`cases'", `"^.*categorical"')) {
/*------------------------ procedure for categorical variables if any -------------------------*/
	* gather categorical variables
	noi di as text "`country'-`year'-dynamic-categorical"
	tempfile database 
	save `database', replace
	
	* calculate proportion share in each categorical variable
	if (`: word count `varctgs'' > 0  & `: word count `varctgs'' < .) {

		tempname P F A V Y B
		cap mat drop `P'

		local vc = 0 			// variable counter
		foreach varctg of local varctgs {

		*if regexm("`variables'","`varctg'") {
		cap gen `varctg'=""

		//  CHeck whether the variable is missing in all obs
		tempvar missvar
		missings tag `varctg', gen(`missvar')
		count
		local n = r(N)
		count if `missvar'
		local mn = r(N)
		local diffm = `mn'-`n'
		
		if (`diffm' == 0) {
			cap confirm numeric variable `varctg'
			if (_rc == 0) replace `varctg'=-999
			else  replace `varctg'="NA"
		}  

	
		********************************************************************************	

		// generate auxiliary variable with proper labels
		tempvar varctgaux
		cap confirm numeric variable `varctg'
		if _rc != 0 {
			rename  `varctg' `varctgaux' 
			encode `varctgaux', generate(`varctg') label(`varctg')
		}
		else {
			local la: value label `varctg'
			if ("`la'" != "") labelrename `la' `varctg' 
		}

		********************************************************************************


		// calculation of shares and extraction of labels in matrices
		local ++vc
		tab `varctg' [aw = `weight'], matcell(`F') matrow(`V')
		mata: A = st_matrix("`F'")
		mata: st_matrix("`F'", (A:/colsum(A))*100)
  
		local nr = rowsof(`F')
		mat `Y' = J(`nr', 1, `year')
		mat `B' = J(`nr', 1, `vc')
		
		mat `A' = `Y', `V', `F', `B'	 // matrix with year, categories value, proportion shares and var test
		mat `P' = nullmat(`P')\ `A'
			
	
		*} // condition, variable is in the database list
		} // end loop categorical variable
		mat colnames `P' = year valuelab freq varname

		drop _all
		svmat `P', n(col)
		
		
		tostring varname valuelab, replace force
		label var freq "Participation share (%)"
		
		local vc = 0
		foreach varctg of local varctgs {
			local ++vc
			replace varname = "`varctg'" if varname == "`vc'"
			
			levelsof valuelab if varname == "`varctg'", local(values)
			
			* asign value labels
			foreach value of local values {
				replace valuelab = "`: label `varctg' `value''" ///
					if  valuelab == "`value'"					///
					& varname == "`varctg'"
			}
		} 		//  end of categorical variables loop
		
		gen region="`region'"
		gen countrycode="`country'"
		gen countryname="`countryname'"
		gen period = "`period_p'"
		gen project = "`project_p'"
		gen weight = "`weight'"
		* save data
		append using `ctgdta'
		save `ctgdta', replace
		glo saveresultscat=1
	}
	}
	* end categorical
	}
	*bins categorical
	}
	// end datalib/datalibweb condition
	
	} //  End of Years loop

} // end of countrylist loop




/*=================
 2.2 Export info
 =================*/
 
* basic results
if (regexm("`cases'", `"^.*basic"')) & (${saveresultsbas}==1) {
	drop _all
	postclose `bc'
	use basiccheck, clear
	compress
	* dta
	save "`path'/basic`outfile'", `replace'
	* excel
	if "`exceloutput'"=="long" {	
	export excel using "`path'/dyn_`outfile'.xlsx", sheet("Basic") sheetreplace first(variable)
	noi di as txt "Click" as smcl `"{browse "`path'/dyn_`outfile'.xlsx": here }"' `"to open results in excel for dynamic analysis, basic case. Saved in: "`path'/dyn_`outfile'.xlsx" "'
	}
}


* Categorical analysis
if (regexm("`cases'", `"^.*categorical"')) & (${saveresultscat}==1) {
*dta
	use `ctgdta', clear
	save "`path'/categ`outfile'", `replace'
*excel
	if "`exceloutput'"=="long" {
	use `ctgdta', clear
	if (weight != "1") export excel using "`path'/dyn_`outfile'.xlsx", sheet("Categ_w") sheetreplace first(variable) 
	if (weight == "1") export excel using "`path'/dyn_`outfile'.xlsx", sheet("Categ_unw") sheetreplace first(variable) 	
	noi di as txt "Click" as smcl `"{browse "`path'/dyn_`outfile'.xlsx": here }"' `"to open results in excel for dynamic analysis, categorical case. Saved in: "`path'/dyn_`outfile'.xlsx" "'
	}
}


* Poverty
if ((regexm("`cases'", `"^.*pov(e|er|ert|erty)"')) & (${saveresultspov}==1)) | ((regexm("`cases'", `"^.*ineq(u|ua|ual|uali|ualit|uality)"')) & (${saveresultsinq}==1)) {
	drop _all
	postclose `pic'
	use povcheck, clear
	compress
	* dta
	save "`path'/pov_inq_`outfile'", `replace'
	* excel
	if "`exceloutput'"=="long" {
	export excel using "`path'/dyn_`outfile'.xlsx", sheet("Poverty_Inequality") sheetreplace first(variable)
	noi di as txt "Click" as smcl `"{browse "`path'/dyn_`outfile'.xlsx": here }"' `"to open results in excel for dynamic analysis, poverty and inequality case. Saved in: "`path'/dyn_`outfile'.xlsx" "'
		}
}


* 3 restore original base
*if ("`outcome'" != "base")  restore //  Keep original data

} // end of qui
} // end of noi 
end // end of _dyncheck program. 




******************************************************************************************************************
******************************************************************************************************************
***************************************Basic Analysis Program*****************************************************
qui {

cap program drop basic_dyncheck
program define basic_dyncheck, rclass

syntax varlist									///
		[if] [in]								///
		[aweight fweight pweight], 				///
			[ 									///
			veralt_p(string)					///
			vermast_p(string)					///
			project_p(string)					///
			period_p(string)					///
			survey(string)						///
			year(string)						///
			acronym(string)						///
			name(string)						///
			type(string)						///
			nature(string)						///
			cname(string)						///
			all 								///
			nq(numlist)						///
			]
			
* Weights treatment
loc weight "[`weight' `exp']"

foreach var of local varlist {

	cap confirm numeric variable `var'
	
	if (_rc == 0) {
		local description: variable label `var'
		
		* Missing analysis
		tempvar aux
		gen `aux' = missing(`var') 
		sum `aux' `weight' if bins==`nq'
		local missing = r(mean)
		post `cname' ("`veralt_p'") ("`vermast_p'") ("`project_p'") ("`period_p'") ("`survey'") ("`year'") ("`acronym'") ("`name'") ("`type'") ("`nature'") ("`var'") ("`description'") ("Income") ("Basic") ("% Missing") (`missing') (`nq')
		
		* Look for zero values
		tab `var' if `var' == 0 & bins==`nq'  `weight'
		local zero = r(N)
		count
		local zero = (`zero'/r(N))
		post `cname' ("`veralt_p'") ("`vermast_p'") ("`project_p'") ("`period_p'") ("`survey'") ("`year'") ("`acronym'") ("`name'") ("`type'") ("`nature'") ("`var'") ("`description'") ("Income") ("Basic")  ("% Zero") (`zero') (`nq')
		
		* Look for Mean values
		local caution  = 1
		sum `var' if bins==`nq' `weight', meanonly
		local mean = r(mean)
		post `cname' ("`veralt_p'") ("`vermast_p'") ("`project_p'") ("`period_p'") ("`survey'") ("`year'") ("`acronym'") ("`name'") ("`type'") ("`nature'") ("`var'") ("`description'") ("Income") ("Basic")  ("Mean") (`mean') (`nq')
		
		* Look for SD values
		sum `var' if bins==`nq'  `weight'
		local sd = r(sd)
		post `cname' ("`veralt_p'") ("`vermast_p'") ("`project_p'") ("`period_p'") ("`survey'") ("`year'") ("`acronym'") ("`name'") ("`type'") ("`nature'") ("`var'") ("`description'") ("Income") ("Basic")  ("SD") (`sd') (`nq')
		
		if ("`var'" == "weight") {
			sum `var' if bins==`nq' 
			local sum = r(sum)/1000000
			post `cname' ("`veralt_p'") ("`vermast_p'") ("`project_p'") ("`period_p'") ("`survey'") ("`year'") ("`acronym'") ("`name'") ("`type'") ("`nature'") ("`var'") ("`description'") ("Income") ("Basic")  ("Mill. Pop") (`sum') (`nq')
		}

	
	} // end of if _rc == 0
	else {
		disp in red "`var' is not numeric..."
	}
} // end of varlist loop
glo saveresultsbas=1
end
} // end of qui

*************************************Poverty Analysis Program******************************************************

qui {
cap program drop poverty_dyncheck
program define poverty_dyncheck, rclass

syntax varlist									///
		[if] [in]								///
		[aweight fweight pweight], 				///
			[ 									///
			veralt_p(string)					///
			vermast_p(string)					///
			project_p(string)					///
			period_p(string) 					///
			survey(string)						///
			year(string)						///
			acronym(string)						///
			name(string)						///
			type(string)						///
			nature(string)						///
			cname(string)						///
			all 								///
			nq(numlist)							///
			]
			
* Weights treatment
loc weight "[`weight' `exp']"

foreach var of local varlist {


		* Moderate Poverty
		apoverty `var' `weight' , line(`=4.0*365/12')
		noi di "		apoverty `var' `weight' , line(4.0) "
	
		post `cname' ("`veralt_p'") ("`vermast_p'") ("`project_p'") ("`period_p'") ///
			("`survey'") ("`year'") ("`acronym'") ("`name'") ("`type'") ///
			("`nature'") ("`var'") ("`description'") ("Income")  ("Poverty")  ("Mod Poverty") (`r(head_1)') (1)
		 

		* Extreme Poverty
		apoverty `var' `weight' , line(`=2.5*365/12')
		post `cname' ("`veralt_p'") ("`vermast_p'") ("`project_p'") ("`period_p'") ///
			("`survey'") ("`year'") ("`acronym'") ("`name'") ("`type'") ///
			("`nature'") ("`var'") ("`description'") ("Income")  ("Poverty")  ("Ext Poverty") (`r(head_1)') (1)
			
		* Extreme Poverty
		apoverty `var' `weight' , line(`=1.25*365/12')
		post `cname' ("`veralt_p'") ("`vermast_p'") ("`project_p'") ("`period_p'") ///
			("`survey'") ("`year'") ("`acronym'") ("`name'") ("`type'") ///
			("`nature'") ("`var'") ("`description'") ("Income")  ("Poverty")  ("Global Ext Poverty") (`r(head_1)') (1)
		

	else {
		disp in red "`var' is not numeric..."
	}
} // end of varlist loop

glo saveresultspov=1
end

}


*************************************Inequality Analysis Program**************************************************
qui {

cap program drop ineq_dyncheck
program define ineq_dyncheck, rclass

syntax varlist									///
		[if] [in]								///
		[aweight fweight pweight], 				///
			[ 									///
			veralt_p(string)					///
			vermast_p(string)					///
			project_p(string)					///
			period_p(string) 					///
			survey(string)						///
			year(string)						///
			acronym(string)						///
			name(string)						///
			type(string)						///
			nature(string)						///
			cname(string)						///
			all									///
			nq(numlist)							///
			]
			
* Weights treatment
loc weight "[`weight' `exp']"


qui {

foreach var of local varlist {
	cap confirm numeric variable `var'
	if (_rc == 0) {
		local description: variable label `var'
		
		* Inequality (including zeros)
		sum `var', meanonly 
		if (r(N) == 0 ) continue 			// skip if variable is only missing values
		ainequal `var'   `weight', `all' 
	
		*Gini
		post `cname' ("`veralt_p'") ("`vermast_p'") ("`project_p'") ("`period_p'") ///
				("`survey'") ("`year'") ("`acronym'") ("`name'") ("`type'") ///
				("`nature'") ("`var'") ("`description'") ("Income") ("Inequality")  ("Gini") (`r(gini_1)') (1)
		
		*Theil
		post `cname' ("`veralt_p'") ("`vermast_p'") ("`project_p'") ("`period_p'") ///
				("`survey'") ("`year'") ("`acronym'") ("`name'") ("`type'") ///
				("`nature'") ("`var'") ("`description'") ("Income") ("Inequality")  ("Theil") (`r(theil_1)') (1)
	
		
		if ("`all'" == "all") {
		
			*Mean Log devitaion
			post `cname' ("`veralt_p'") ("`vermast_p'") ("`project_p'") ("`period_p'") ///
					("`survey'") ("`year'") ("`acronym'") ("`name'") ("`type'") ///
					("`nature'") ("`var'") ("`description'") ("Income") ("Inequality")  ("Mean Log deviation") (`r(mld_1)') (1)

			*General entropy alpha == 1
			post `cname' ("`veralt_p'") ("`vermast_p'") ("`project_p'") ("`period_p'") ///
					("`survey'") ("`year'") ("`acronym'") ("`name'") ("`type'") ///
					("`nature'") ("`var'") ("`description'") ("Income") ("Inequality")  ("GE 1") (`r(ge_1_1)') (1)
					
			* General entropy alpha == 2
			post `cname' ("`veralt_p'") ("`vermast_p'") ("`project_p'") ("`period_p'") ///
					("`survey'") ("`year'") ("`acronym'") ("`name'") ("`type'") ///
					("`nature'") ("`var'") ("`description'") ("Income") ("Inequality")  ("GE 2") (`r(ge2_1)') (1)
				
			* Atkinson 
			post `cname' ("`veralt_p'") ("`vermast_p'") ("`project_p'") ("`period_p'") ///
					("`survey'") ("`year'") ("`acronym'") ("`name'") ("`type'") ///
					("`nature'") ("`var'") ("`description'") ("Income") ("Inequality") ("Atkinson") (`r(atkin1_1)') (1)
					
			*Kakwani
			post `cname' ("`veralt_p'") ("`vermast_p'") ("`project_p'") ("`period_p'") ///
						("`survey'") ("`year'") ("`acronym'") ("`name'") ("`type'") ///
						("`nature'") ("`var'") ("`description'") ("Income") ("Inequality")  ("kakwani") (`r(kakwani_1)') (1)
		
		} //  end of if ("`all'" == "all")
	
	} // end of if _rc == 0
	else {
		disp in red "`var' is not numeric..."
	}
} // end of varlist loop
} //  end of qui 

glo saveresultsinq=1
end

}


*************************************Distribution Analysis Program**************************************************
qui {

cap program drop dist_dyncheck
program define dist_dyncheck, rclass

syntax varlist									///
		[if] [in]								///
		[aweight fweight pweight], 				///
			[ 									///
			veralt_p(string)					///
			vermast_p(string)					///
			project_p(string)					///
			period_p(string)
			survey(string)						///
			year(string)						///
			acronym(string)						///
			name(string)						///
			type(string)						///
			nature(string)						///
			cname(string)						///
			all 								///
			nq(numlist)							///
			]

* Weights treatment
loc weight "[`weight' `exp']"

qui {
foreach var of local varlist {
	cap confirm numeric variable `var'
	if (_rc == 0) {
		local description: variable label `var'
		
		* Look for percentiles
		local numlist 1 5 10 25 50 75 90 95 99
		sum `var'  `weight', d
		foreach num of numlist `numlist' {
			di `num'
			local p = r(p`num')
			post `cname' ("`veralt_p'") ("`vermast_p'") ("`project_p'") ("`period_p'") ("`survey'") ("`year'") ("`acronym'") ("`name'") ("`type'") ("`nature'") ("`var'") ("`description'") ("Income") ("Distribution") ("`num'") (`p') (`nq')
        }
	} // end of if _rc == 0
	else {
		disp in red "`var' is not numeric..."
	}
} // end of varlist loop
} //  end of qui 

end

}

exit

******************************************************************************************************************


destring year, replace force

two connected value year  if  variable == "asiste", 							///
	xlabel(2000(3)2012, labsize(small)) ytitle("") xtitle("")					///
	subtitle(, bcolor(white)) 													///
	by(case, rescale title("asiste", bcolor(white)) note("")) 					
	graph export "Z:\wb384996\Andres\temporal\tex\asiste.`ext'", as(`ext') replace



* 0.4 Path consistency
if ("`path'" != "" ) { // check if  the directory exists 
	cap local aa: dir "./`path'" dirs "*"			// check on current directory whether the folder exists
	if (_rc == 0 ) local path = "`c(pwd)'/`path'"	// create local if so
	else cap local aa: dir "`path'" dirs "*" 		// check whether the folder exists
	if (_rc) {
		disp in red _new "`path' does not exist or the directory permissions do not allow you to create a new file"
		error
	}
}
else local path "`c(pwd)'"






#delimit ; 
