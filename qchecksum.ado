***************************************Basic Analysis Program*****************************************************

qui {

cap program drop qchecksum
program define qchecksum, rclass

syntax varlist									///
		[if] [in]								///
		[aweight fweight pweight], 				///
		[									///
			file(string)					///
			out(string)					///
		]

***************************************************************
*#F1# Get the name of the file in memory
mata: st_local("fileinmemory",pathbasename("`c(filename)'"))
di "WORKING WITH ... `fileinmemory'"
*#F1# If file is not defined, the program will save the results using the filename in memory
if ("`file'"=="") local file "`fileinmemory'"
***************************************************************
*#F1# If a path to save the results is not defined, the program use the current (working) directory
if ("`out'"=="") local out c(pwd)
***************************************************************
*#F1# files will be saved in <out> with the name "basicqcheck_<file>"
local outpathfile "`out'`c(dirsep)'basicqcheck_`file'"
***************************************************************
* Weights treatment
loc weight "[`weight' `exp']"
***************************************************************
* BASIC REPORT
cap postutil clear
postfile postqchecksum str50 file str30 var str30 description str30 analysis str30 case double value using "`outpathfile'" , replace

qui foreach var of local varlist {
	cap confirm var `var'
		if (_rc == 0) {
		cap confirm numeric variable `var'
	
		if (_rc == 0) {
			local description: variable label `var'
				
			* Missing analysis
			tempvar aux
			gen `aux' = missing(`var')
			sum `aux' `weight'
			local missing = r(mean)
			post postqchecksum ("`file'")  ("`var'")  ("`description'")  ("Basic") ("Missing") (`missing')

			* Look for zero values
			tempvar aux2
			gen `aux2'=(`var' == 0)   
			sum `aux' `weight'
			local zero = r(mean)
			post postqchecksum ("`file'")  ("`var'")  ("`description'")  ("Basic")  ("Zero") (`zero')
			
			* Look for Mean values			
			sum `var'  `weight', d
			local mean = r(mean)
			local sd = r(sd)
			local max = r(max)
			local min = r(min)
			local Num = r(N)
           	local ske = r(skewness) 
            local kur = r(kurtosis) 
            local p1  = r(p1)
			local p5  = r(p5) 
            local p10  = r(p10)
            local p25  = r(p25)
            local p50  = r(p50)
            local p75  = r(p75)
            local p90  = r(p90)
            local p95  = r(p95)
            local p99  = r(p99)

			post postqchecksum ("`file'")  ("`var'")  ("`description'")  ("Basic")  ("Mean") (`mean')
			post postqchecksum ("`file'")  ("`var'")  ("`description'")  ("Basic")  ("SD") (`sd')
			post postqchecksum ("`file'")  ("`var'")  ("`description'")  ("Basic")  ("Max") (`max')
			post postqchecksum ("`file'")  ("`var'")  ("`description'")  ("Basic")  ("Min") (`min')
			post postqchecksum ("`file'")  ("`var'")  ("`description'")  ("Basic")  ("Num") (`Num')
           	post postqchecksum ("`file'")  ("`var'")  ("`description'")  ("Basic")  ("Skewess") (`ske') 
            post postqchecksum ("`file'")  ("`var'")  ("`description'")  ("Basic")  ("Kurtosis") (`kur') 
            post postqchecksum ("`file'")  ("`var'")  ("`description'")  ("Basic")  ("P1") (`p1')
			post postqchecksum ("`file'")  ("`var'")  ("`description'")  ("Basic")  ("P5") (`p5') 
            post postqchecksum ("`file'")  ("`var'")  ("`description'")  ("Basic")  ("P10") (`p10')
            post postqchecksum ("`file'")  ("`var'")  ("`description'")  ("Basic")  ("P25") (`p25')
            post postqchecksum ("`file'")  ("`var'")  ("`description'")  ("Basic")  ("P50") (`p50')
            post postqchecksum ("`file'")  ("`var'")  ("`description'")  ("Basic")  ("P75") (`p75')
            post postqchecksum ("`file'")  ("`var'")  ("`description'")  ("Basic")  ("P90") (`p90')
            post postqchecksum ("`file'")  ("`var'")  ("`description'")  ("Basic")  ("P95") (`p95')
            post postqchecksum ("`file'")  ("`var'")  ("`description'")  ("Basic")  ("P99") (`p99')
			
	} // end of if _rc == 0
	} // end of cap comf var
		else {
		disp in red "`var' is not numeric..."
			}

	} // end of varlist loop
	
postclose postqchecksum

noi di  _col(10) as result "Results were saved at `outpathfile'"

end

} // end of qui

