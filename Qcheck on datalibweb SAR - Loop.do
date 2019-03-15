********************************************************************************
* QCHECK application to SARMD
* Javier Parada 
* Revised: February 26, 2019
********************************************************************************

clear
clear matrix
set mem 400m
set matsize 800

***************************** Set main directory *******************************

	if ("`c(hostname)'" == "wbgmsbdat001") {
		global hostdrive "D:"
	}
	else {
		global hostdrive "\\Wbgmsbdat001"
	}
	cd "${hostdrive}\SOUTH ASIA MICRO DATABASE\05.projects_requ\01.SARMD_Guidelines\02. qcheck\02. sar qcheck\03. sarmd qcheck\" 

************************** Load checks into the system *************************

	clear all
	qcheck load, test(qcheck_sarmd) path(CD) replace

****************** Import variable names from excel table (209) ****************

	use "${hostdrive}\SOUTH ASIA MICRO DATABASE\05.projects_requ\01.SARMD_Guidelines\02. qcheck\02. sar qcheck\02. sarmd summary\sarmd_variable_list.dta", clear
	levelsof Variables, local(vars)

******************** Import sar inventory from excel table *********************

	import excel "${hostdrive}\SOUTH ASIA MICRO DATABASE\05.projects_requ\01.SARMD_Guidelines\02. qcheck\02. sar qcheck\01. sarmd inventory\inventory.xlsx", sheet("inventory") firstrow allstring clear
	levelsof countries, local(countries)

******************************** QCHECK STATIC *********************************

* Create locals for each country and year

	foreach country of local countries {
		display "`country'"
		levelsof years if (countries == "`country'"), local(`country'_years)
		foreach year of local `country'_years { 
			levelsof surveys if (countries == "`country'" & years == "`year'"), local(`country'_`year'_surveys) 
		}
	}

/********************** Loop static qcheck over countries ***********************

foreach country of local countries {
	foreach year of local `country'_years {
		foreach survey of local `country'_`year'_surveys {
					noi display "`country' `year' `survey'"
					cap datalibweb, country(`country') year(`year') type(SARMD) mod(IND) /* 
					*/ surveyid(`survey')
					sum
					if (_rc) continue
					
					local vera = "`r(vera)'"
					local verm = "`r(verm)'"
					noi display "`vera' `verm'"
					
					noi di "qcheck static, countries(`country') year(`year') type(SARMD) mod(IND) vermast(`verm') veralt(`vera') surveyid(`survey') test(qcheck_sarmd) var(all) path(cd) outfile(myresults_`country'_`year') replace"
					  
					qcheck static, countries(`country') year(`year') type(SARMD) mod(IND) /* 
					 */ vermast(`verm') veralt(`vera') surveyid(`survey') test(qcheck_sarmd) /* 
					  */ var(all) path(cd) outfile(myresults_`country'_`year') replace			  
		}
	}
}
*/
*********** Append and export files to Excel for Tableau dashboards ************

clear all
cap erase check1.dta

local filenames : dir "." files "*myresults*.dta"
foreach b of local filenames{
display " appending `b'"
append using `b'
}

gen Region="SAR"
gen Countrylabel=""
gen date_year=.
replace Countrylabel="Afghanistan" if country=="AFG"
replace Countrylabel="Bangladesh" if country=="BGD"
replace Countrylabel="Bhutan" if country=="BTN"
replace Countrylabel="India" if country=="IND"
replace Countrylabel="Maldives" if country=="MDV"
replace Countrylabel="Nepal" if country=="NPL"
replace Countrylabel="Pakistan" if country=="PAK"
replace Countrylabel="Sri Lanka" if country=="LKA"

rename variable Variables
merge m:1 Variables using "D:\SOUTH ASIA MICRO DATABASE\05.projects_requ\01.SARMD_Guidelines\02. qcheck\02. sar qcheck\02. sarmd summary\sarmd_variable_list.dta"
rename Variables Variable
export excel using "static_qcheck", sheetreplace firstrow(variables)

*/


********************** QCHECK DYNAMIC **********************

* 1. Basic Dynamic Analysis 
* Exports to dyn_qcheck@basic

	local basic_vars "age hsize male urban ownhouse welfare*"
	qcheck dynamic, countries (afg bgd btn ind mdv npl pak lka) test(qcheck_sarmd) var(`basic_vars') year(1993/2017) type(SARMD) case(basic)  out(basic) path (cd) weight(wgt) replace

	import excel "dyn_qcheck@basic.xlsx", sheet("Basic") firstrow clear
	rename variable Variables
	merge m:1 Variables using "D:\SOUTH ASIA MICRO DATABASE\05.projects_requ\01.SARMD_Guidelines\02. qcheck\02. sar qcheck\02. sarmd summary\sarmd_variable_list.dta"
	keep if _merge==3
	drop _merge
	rename Variables variable
	export excel using "dyn_qcheck@basic.xlsx", sheet("Basic") firstrow(variables) replace
	
	
* 2. Categories Dashboard
* Exports to dyn_qcheck@categorical

	local categorical_vars "bicycle buffalo cellphone chicken computer cow fan lamp landphone motorcar motorcycle radio refrigerator sewingmachine television washingmachine countrycode int_month int_year subnatid1 subnatid2 survey veralt vermast year male marital relationcs relationharm soc atschool ed_mod_age educat4 educat5 educat7 educy everattend literacy urban electricity internet ownhouse piped_water sar_improved_toilet sar_improved_water sewage_toilet toilet_jmp toilet_orig water_jmp water_orig empstat empstat_2 empstat_2_year empstat_year firmsize_l industry industry_2 industry_e lb_mod_age lstatus njobs nlfreason occup ocusec "
	*qcheck dynamic, countries (afg bgd btn ind mdv npl pak lka) test(qcheck_sarmd) var (`categorical_vars') year(1993/2017) type(SARMD) case(categorical)  out(categorical) path (cd) weight(wgt) replace

	use "categqcheck@categorical.dta", clear
	rename varname Variables
	merge m:1 Variables using "D:\SOUTH ASIA MICRO DATABASE\05.projects_requ\01.SARMD_Guidelines\02. qcheck\02. sar qcheck\02. sarmd summary\sarmd_variable_list.dta"
	keep if _merge==3
	drop _merge
	rename Variables Varname
	export excel using "dyn_qcheck@categorical.xlsx", sheetreplace firstrow(variables)


* 3. Poverty Dashboard
* Exports to dyn_qcheck@poverty

	local poverty_vars "welfare" 
	qcheck dynamic, countries (bgd ind pak lka) test(qcheck_sarmd) var (`poverty_vars') year(1993/2017) type(SARMD) case(poverty)  out(poverty) path (cd) weight(wgt) replace

	
* 4. Inequality Dashboard
* Exports to dyn_qcheck@inequality

	local inequality_vars "welfare" 
	qcheck dynamic, countries (bgd ind pak lka) test(qcheck_sarmd) var (`inequality_vars') year(1993/2017) type(SARMD) case(inequality)  out(inequality) path (cd) weight(wgt) replace

	
* Append and export files to Excel for Tableau dashboards

clear all

local filenames : dir "." files "*pov_inq_qcheck@*.dta"
foreach b of local filenames{
display " appending `b'"
append using `b'
}

gen Region="SAR"
gen Countrylabel=""
gen date_year=.
replace Countrylabel="Afghanistan" if country=="AFG"
replace Countrylabel="Bangladesh" if country=="BGD"
replace Countrylabel="Bhutan" if country=="BTN"
replace Countrylabel="India" if country=="IND"
replace Countrylabel="Maldives" if country=="MDV"
replace Countrylabel="Nepal" if country=="NPL"
replace Countrylabel="Pakistan" if country=="PAK"
replace Countrylabel="Sri Lanka" if country=="LKA"

export excel using "dynamic_qcheck_pov_inq", sheetreplace firstrow(variables)
