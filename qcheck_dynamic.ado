/* *===========================================================================
	_dyncheck: Program to check the quality of the data over time
	Reference: 
-------------------------------------------------------------------
Created datalib/lac: 		15Jul2013	(Santiago Garriga & Andres Castaneda) 
Adapted datalibweb:			01Aug2016 	Laura Moreno Herrera
				20Nov2013	(Santiago Garriga & Andres Castaneda) 

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
				fileserver          			///
			]

/*-----------------------------------------------------
		0. Check for errors and defaults
-----------------------------------------------------*/
qui {
local gtype "`type'"
local gmodule "`module'"
* programs
cap which distinct 
if (_rc > 0 ) ssc install distinct
* file to save categorical analysis
clear all
tempfile ctgdta
save `ctgdta', replace emptyok
* file with information
*tempfile to save othres check
tempname bc
postfile `bc' str10 veralt str10 vermast str10 project str30 survey str30 year str30 acronym str30 country str30 type str30 nature str30 variable str244 description str30 module str30 analysis str30 case double value  using basiccheck, replace

tempname pic
postfile `pic' str10 veralt str10 vermast str10 project str30 survey str30 year str30 acronym str30 country str30 type str30 nature str30 variable str244 description str30 module str30 analysis str30 case double value  using povcheck, replace



/*-----------------------------------------------------
		1. Dynamic Analysis
-----------------------------------------------------*/
glo saveresultsbas=0
glo saveresultspov=0
glo saveresultsinq=0
glo saveresultscat=0

foreach country of local countries {
	
	datalibweb_inventory, code(`country')
	local region       = r(region)
	local countryname  = r(countryname)

	* Set years
	foreach year of local years { 
	noi di "`country' - `year'"
	* Open data 
	
	if "`country'"=="IND" & "`year'"=="2011"{
	cap datalibweb, country(`country') year(`year') type(SARMD) surveyid(NSS68-SCH1.0-T1) `vermast' `veralt' `gmodule' clear   `fileserver' `nocpi'
	}
	else {
	cap datalibweb, country(`country') year(`year') type(SARMD) `vermast' `veralt' `gmodule' clear   `fileserver'
	}
	qui ds
	local dsvars `r(varlist)'
	
		if _rc {  // if _rc
			noi disp in red "No data for `country'-`year' "
			continue 
		}  // close if _rc
	
	if (_rc==0)  {
	cap confirm variable countrycode
	if (_rc!=0)  {
		*local gmodule "module(SARMD)"
		*datalibweb, country(`country') year(`year') survey(`survey') `vermast' `veralt' `gtype' `gmodule' clear   `fileserver'
	}
	* Set locals for data information
	local veralt_p  = r(vera)
	local vermast_p = r(verm)
	local survey    = r(surveyid)
	local acronym   = "`country'"
	local name 	  = "`countryname'" 
	local type      = r(type)
	local module    = r(module)
	local year	  = "`year'"
* weight defined
if ("`weight'" == "") {
	local weight 1	
	noi di as error "Results are unweighted"
}
	*weighttype
	cap confirm variable weighttype
	if _rc==0 {
		levelsof weighttype , local(weighttype)
		local weighttype=strlower(weighttype)
		cap tab countrycode [`weighttype'=`weight']
		if _rc!=0 {
local noteend`countryname'`year' "Variable -weighttype- not match with weight type for `countryname' `year' `veralt_p' `vermast_p'. Analitycal weight is assumed "
noi di in red "`noteend`country'`year''"
			local weighttype "aw"
		}
	}
	else {
		noi dis in red "Variable -weighttype- not found for `countryname' `year' `veralt_p' `vermast_p'. Analitycal weight is assumed "
		gen weighttype="aw"
		local weighttype "aw"
		
		local noteend`countryname'`year' "Variable -weighttype- not found for `countryname' `year' `veralt_p' `vermast_p'. Analitycal weight is assumed "
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
		
*Analysis per variable 		
/*------------------------ basic Analysis----------------------------------*/

	
	*set trace on
		di 	"`weighttype' `weight'"
	
	if (regexm("`cases'", `"^.*basic"')) & ("`variables'"!="") {
	noi di as text "`country'-`year'-dynamic-basic"
			display "`variables' `weighttype' `weight' `veralt_p' `vermast_p' `survey' `year' `country' `name' `type' `nature' `bc'"
			local variables2: list variables & dsvars
			noi di "`variables2'"
			cap basic_dyncheck `dsvars' [`weighttype'=`weight'],  veralt_p(`veralt_p')	vermast_p(`vermast_p')	project_p(`project_p')	survey(`survey') year(`year') acronym(`country') name(`name')		type("`type'")		nature(`nature')		cname(`bc')
	}
	if (regexm("`cases'", `"^.*basic"')) & ("`variables'"=="") {
		noi di in red "Variable included does not exits in database"
		exit
	}
	
	if regexm("`variables'","welfare") {
/*------------------------Poverty Analysis --------------------------*/
		if (regexm("`cases'", `"^.*pov(e|er|ert|erty)"')) {
		noi di as text "`country'-`year'-dynamic-poverty"
			poverty_dyncheck `varwelfare' [`weighttype'=`weight'],  veralt_p(`veralt_p')	vermast_p(`vermast_p')	project_p(`project_p')	survey(`survey')		year(`year')		acronym(`acronym')		name(`countryname' )		type(`type')		nature(`nature')		cname(`pic') `all'
		}
/*------------------------inequality Analysis -----------------------*/
		if (regexm("`cases'", `"^.*ineq(u|ua|ual|uali|ualit|uality)"')) {
		noi di as text "`country'-`year'-dynamic-inequality"
			ineq_dyncheck `varwelfare' [`weighttype'=`weight'],  veralt_p(`veralt_p')	vermast_p(`vermast_p')	project_p(`project_p')	survey(`survey')		year(`year')		acronym(`acronym')		name(`countryname' )		type(`type')		nature(`nature')		cname(`pic') `all'
		}		
	}
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
		

		// calculation of shares and extraction of labels in matrices
		local ++vc
		tab `varctg' [`weighttype' = `weight'], matcell(`F') matrow(`V')
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
		* save data
		append using `ctgdta'
		save `ctgdta', replace
		glo saveresultscat=1
	}
	
	} 
	} // end datalibweb condition
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
	export excel using "`path'/dyn_`outfile'.xlsx", sheet("Basic") sheetreplace first(variable)
	noi di as txt "Click" as smcl `"{browse "`path'/dyn_`outfile'.xlsx": here }"' `"to open results in excel for dynamic analysis, basic case. Saved in: "`path'/dyn_`outfile'.xlsx" "'
}
* Categorical analysis
if (regexm("`cases'", `"^.*categorical"')) & (${saveresultscat}==1) {
*dta
	use `ctgdta', clear
	save "`path'/categ`outfile'", `replace'
*excel
	use `ctgdta', clear
	export excel using "`path'/dyn_`outfile'.xlsx", sheet("Categ") sheetreplace first(variable)
	noi di as txt "Click" as smcl `"{browse "`path'/dyn_`outfile'.xlsx": here }"' `"to open results in excel for dynamic analysis, categorical case. Saved in: "`path'/dyn_`outfile'.xlsx" "'
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
	export excel using "`path'/dyn_`outfile'.xlsx", sheet("Poverty_Inequality") sheetreplace first(variable)
	noi di as txt "Click" as smcl `"{browse "`path'/dyn_`outfile'.xlsx": here }"' `"to open results in excel for dynamic analysis, poverty and inequality case. Saved in: "`path'/dyn_`outfile'.xlsx" "' 
}
/*
* Inequality
if (regexm("`cases'", `"^.*ineq(u|ua|ual|uali|ualit|uality)"')) & (${saveresultsinq}==1) {
	drop _all
	postclose `pic'
	use inqcheck, clear
	compress
	* dta
	save "`path'/inq_`outfile'", `replace'
	* excel
	export excel using "`path'/dyn_`outfile'.xlsx", sheet("Poverty_Inequality") sheetreplace first(variable)
	noi di as txt "Click" as smcl `"{browse "`path'/dyn_`outfile'.xlsx": here }"' `"to open results in excel for dynamic analysis, inequality case. Saved in: "`path'/dyn_`outfile'.xlsx" "' 
}	
*/

	foreach country of local countries {
		datalibweb_inventory, code(`country')
		local countryname  = r(countryname)
		foreach year of local years { 
			if "`noteend`country'`year''"!="" {
			noi di in red "`noteend`country'`year''"	
			}
		}
	}
* 3 restore original base
*if ("`outcome'" != "base")  restore //  Keep original data


} // end of qui / noi 
end // end of _dyncheck program. 


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
			survey(string)						///
			year(string)						///
			acronym(string)						///
			name(string)						///
			type(string)						///
			nature(string)						///
			cname(string)						///
			all 								///
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
		sum `aux' `weight'
		local missing = r(mean)
		post `cname' ("`veralt_p'") ("`vermast_p'") ("`project_p'") ("`survey'") ("`year'") ("`acronym'") ("`name'") ("`type'") ("`nature'") ("`var'") ("`description'") ("Income") ("Basic") ("% Missing") (`missing')
		
		* Look for zero values
		tab `var' if `var' == 0   `weight'
		local zero = r(N)
		count
		local zero = (`zero'/r(N))
		post `cname' ("`veralt_p'") ("`vermast_p'") ("`project_p'") ("`survey'") ("`year'") ("`acronym'") ("`name'") ("`type'") ("`nature'") ("`var'") ("`description'") ("Income") ("Basic")  ("% Zero") (`zero')
		
		* Look for Mean values
		local caution  = 1
		sum `var'  `weight', meanonly
		local mean = r(mean)
		post `cname' ("`veralt_p'") ("`vermast_p'") ("`project_p'") ("`survey'") ("`year'") ("`acronym'") ("`name'") ("`type'") ("`nature'") ("`var'") ("`description'") ("Income") ("Basic")  ("Mean") (`mean')
		
		* Look for SD values
		sum `var'  `weight'
		local sd = r(sd)
		post `cname' ("`veralt_p'") ("`vermast_p'") ("`project_p'") ("`survey'") ("`year'") ("`acronym'") ("`name'") ("`type'") ("`nature'") ("`var'") ("`description'") ("Income") ("Basic")  ("SD") (`sd')
		
		if ("`var'" == "weight") {
			sum `var'  
			local sum = r(sum)/1000000
			post `cname' ("`veralt_p'") ("`vermast_p'") ("`project_p'") ("`survey'") ("`year'") ("`acronym'") ("`name'") ("`type'") ("`nature'") ("`var'") ("`description'") ("Income") ("Basic")  ("Mill. Pop") (`sum')
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
			survey(string)						///
			year(string)						///
			acronym(string)						///
			name(string)						///
			type(string)						///
			nature(string)						///
			cname(string)						///
			all 								///
			]
			
* Weights treatment
loc weight "[`weight' `exp']"


foreach var of local varlist {
	if ("`type'"=="SARMD") {
	
	if (regexm("`var'", `"_ppp$"')) local ppp "_ppp"
	else local ppp ""
	cap confirm numeric variable `var'
	if (_rc == 0) {
		local description: variable label `var'
		
		* Poverty 
		local s=2011
		local ccc=strupper("`acronym'")
		***************************************
		* Adjustments for Particular Countries (Pov)
		***************************************	
		gen `var'used=`var'
		if "`ccc'"=="FJI" | "`ccc'"=="FSM" | "`ccc'"=="IDN" | "`ccc'"=="KHM" | "`ccc'"=="KIR" | "`ccc'"=="LAO" | "`ccc'"=="MNG" | "`ccc'"=="PNG" | "`ccc'"=="TLS" | "`ccc'"=="TON" | "`ccc'"=="TUV" | "`ccc'"=="VNM" | "`ccc'"=="WSM" | "`ccc'"=="VUT" {
			cap replace  `var'used = pcexp  //spatially deflated for EAP only
		}
		if "`ccc'"=="THA" | "`ccc'"=="SLB" {
			cap replace  `var'used = welfare
		}
		if "`ccc'"=="PHL" {
			cap replace  `var'used = pcinc // income for PHL
		}
		
		* gen double `var'_`s'_ppp = `var'used/cpi`s'/icp`s'/365
		gen double `var'_`s'_ppp = `var'used/cpi/ppp/365
	}
		
		* Moderate Poverty
		apoverty `var'_`s'_ppp  `weight' , line(3.1)
		post `cname' ("`veralt_p'") ("`vermast_p'") ("`project_p'") ///
			("`survey'") ("`year'") ("`acronym'") ("`name'") ("`type'") ///
			("`nature'") ("`var'") ("`description'") ("Income")  ("Poverty")  ("Mod Poverty") (`r(head_1)')
		
		* Extreme Poverty
		apoverty `var'_`s'_ppp  `weight' , line(1.9)
		post `cname' ("`veralt_p'") ("`vermast_p'") ("`project_p'") ///
			("`survey'") ("`year'") ("`acronym'") ("`name'") ("`type'") ///
			("`nature'") ("`var'") ("`description'") ("Income")  ("Poverty")  ("Ext Poverty") (`r(head_1)')

		
	} // end of if _rc == 0
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
			survey(string)						///
			year(string)						///
			acronym(string)						///
			name(string)						///
			type(string)						///
			nature(string)						///
			cname(string)						///
			all									///
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
		post `cname' ("`veralt_p'") ("`vermast_p'") ("`project_p'") ///
				("`survey'") ("`year'") ("`acronym'") ("`name'") ("`type'") ///
				("`nature'") ("`var'") ("`description'") ("Income") ("Inequality")  ("Gini") (`r(gini_1)')
		
		*Theil
		post `cname' ("`veralt_p'") ("`vermast_p'") ("`project_p'") ///
				("`survey'") ("`year'") ("`acronym'") ("`name'") ("`type'") ///
				("`nature'") ("`var'") ("`description'") ("Income") ("Inequality")  ("Theil") (`r(theil_1)')
		
		if ("`all'" == "all") {
			*Mean Log devitaion
			post `cname' ("`veralt_p'") ("`vermast_p'") ("`project_p'") ///
					("`survey'") ("`year'") ("`acronym'") ("`name'") ("`type'") ///
					("`nature'") ("`var'") ("`description'") ("Income") ("Inequality")  ("Mean Log deviation") (`r(mld_1)')

			*General entropy alpha == 1
			post `cname' ("`veralt_p'") ("`vermast_p'") ("`project_p'") ///
					("`survey'") ("`year'") ("`acronym'") ("`name'") ("`type'") ///
					("`nature'") ("`var'") ("`description'") ("Income") ("Inequality")  ("GE 1") (`r(ge_1_1)')
					
			* General entropy alpha == 2
			post `cname' ("`veralt_p'") ("`vermast_p'") ("`project_p'") ///
					("`survey'") ("`year'") ("`acronym'") ("`name'") ("`type'") ///
					("`nature'") ("`var'") ("`description'") ("Income") ("Inequality")  ("GE 2") (`r(ge2_1)')
					
			* Atkinson 
			post `cname' ("`veralt_p'") ("`vermast_p'") ("`project_p'") ///
					("`survey'") ("`year'") ("`acronym'") ("`name'") ("`type'") ///
					("`nature'") ("`var'") ("`description'") ("Income") ("Inequality")  ("Atkinson") (`r(atkin1_1)')
					
			*Kakwani
			post `cname' ("`veralt_p'") ("`vermast_p'") ("`project_p'") ///
					("`survey'") ("`year'") ("`acronym'") ("`name'") ("`type'") ///
					("`nature'") ("`var'") ("`description'") ("Income") ("Inequality")  ("kakwani") (`r(kakwani_1)')
		
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
			survey(string)						///
			year(string)						///
			acronym(string)						///
			name(string)						///
			type(string)						///
			nature(string)						///
			cname(string)						///
			all 								///
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
			post `cname' ("`veralt_p'") ("`vermast_p'") ("`project_p'") ("`survey'") ("`year'") ("`acronym'") ("`name'") ("`type'") ("`nature'") ("`var'") ("`description'") ("Income") ("Distribution") ("`num'") (`p')
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
