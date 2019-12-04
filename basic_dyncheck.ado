***************************************Basic Analysis Program*****************************************************

noi {

cap program drop basic_dyncheck
program define basic_dyncheck, rclass

syntax varlist									///
		[if] [in]								///
		[aweight fweight pweight], 				///
			[ 									///
			source(string)						///
			veralt_p(string)					///
			vermast_p(string)					///
			module(string)									///
			project_p(string)					///
			survey(string)						///
			year(string)								///
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
	cap confirm var `var'
		if (_rc == 0) {
		cap confirm numeric variable `var'
	
		if (_rc == 0) {
			local description: variable label `var'
				
			* Missing analysis
			tempvar aux
			gen `aux' = missing(`var')
			sum `aux' `weight'
			local missing = r(mean)*100
			post `cname' ("`source'") ("`veralt_p'") ("`vermast_p'") ("`project_p'") ("`survey'") ("`year'") ("`acronym'") ("`name'") ("`type'") ("`nature'") ("`var'") ("`description'") ("`module'") ("Basic") ("Missing") (`missing')

			* Look for zero values
			
			tab `var' if `var' == 0   `weight'
			local zero = r(N)
			count
			local zero = (`zero'/r(N))*100
			post `cname' ("`source'") ("`veralt_p'") ("`vermast_p'") ("`project_p'") ("`survey'") ("`year'") ("`acronym'") ("`name'") ("`type'") ("`nature'") ("`var'") ("`description'") ("`module'") ("Basic")  ("Zero") (`zero')
			
			* Look for Mean values
			local caution  = 1
			
			if ("`module'"=="2") | ("`module'"=="9") | ("`var'"!="welfare"){			
			sum `var'  `weight'
			}
			
			/*if ("`module'"=="3") | ( "`module'"=="4") | ( "`module'"=="6") | ( "`module'"=="7") | ("`var'"=="welfare") |( "`module'"=="GPWG")  {
				if ("`var'"=="hhsize") | ("`var'"=="urban") {
				sum `var'  `weight'
				local mean = r(mean)
				}
				else {
					local s=2011
					capture confirm variable `var'_ppp_`s'
					if !_rc {
						replace `var'_ppp_`s'=`var'/cpi`s'/icp`s' if mi(code)
					}
						else {
							  gen double `var'_ppp_`s' = `var'/cpi`s'/icp`s'	
						}
				sum `var'_ppp_`s'  `weight'		
				}
			}
		*/
			local mean = r(mean)

			post `cname' ("`source'") ("`veralt_p'") ("`vermast_p'") ("`project_p'") ("`survey'") ("`year'") ("`acronym'") ("`name'") ("`type'") ("`nature'") ("`var'") ("`description'") ("`module'") ("Basic")  ("Mean") (`mean')
			
			* Look for SD values
			sum `var'  `weight'
			local sd = r(sd)
			post `cname' ("`source'") ("`veralt_p'") ("`vermast_p'") ("`project_p'") ("`survey'") ("`year'") ("`acronym'") ("`name'") ("`type'") ("`nature'") ("`var'") ("`description'") ("`module'") ("Basic")  ("SD") (`sd')
			
			*observation
			if ("`var'" == "weight") {
	
				sum `var'  
				local obs = r(N)
				post `cname' ("`source'") ("`veralt_p'") ("`vermast_p'") ("`project_p'") ("`survey'") ("`year'") ("`acronym'") ("`name'") ("`type'") ("`nature'") ("`var'") ("`description'") ("`module'") ("Basic")  ("Obs") (`obs')
			}		
			
			if ("`var'" == "weight") {
				sum `var'  
				local sum = r(sum)/1000000
				post `cname' ("`source'") ("`veralt_p'") ("`vermast_p'") ("`project_p'") ("`survey'") ("`year'") ("`acronym'") ("`name'") ("`type'") ("`nature'") ("`var'") ("`description'") ("`module'") ("Basic")  ("Mill. Pop") (`sum')
			}

	
	} // end of if _rc == 0
	} // end of cap comf var
		else {
		disp in red "`var' is not numeric..."
			}

	} // end of varlist loop
	
glo saveresultsbas=1
end
} // end of qui

