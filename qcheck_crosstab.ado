/* *===========================================================================
	
New: 23-Dec-2019   Jayne Jungsun / Laura Moreno
	
	_crosstabcheck: Program to check the quality of the in one point of time, coparing two variables. 
	Reference: 
-------------------------------------------------------------------

Version 1 Created:		Check any raw household survey data. Adapted from datacheck_static
Dependencies: 	WORLD BANK - LCSPP

/*WARNING: Inside this program you may find smaller but not less important programs, created with the idea to simplify and reduce repetitive code. For this reason, some parameters required in all the code are saved in global macros with the SALT prefix. This prefix is used with the intention to not disturbs other programs that could be running in the same stata session. SALT does not have a special meaning. */
*===========================================================================*/
#delimit ;
discard;
cap program drop qcheck;
program define qcheck_static, rclass;
syntax [anything]								///
		[if] [in], 								///
			[ 									///
			COUNTries(string)					///
			Years(numlist)						///
			VARiables(string)					///
				VERMast(string)					///
				VERAlt(string)					///
				module(passthru)				///
				project(passthru)				///
				period(string)				    ///
				type(passthru)					///	
				survey(passthru)				///
				logfile							///
				replace							///
				path(string)					///
				test(string)					///
				outfile(string)					///
				noppp							///
				SOurce(string)					///
			];

qui {;	// open qui overall code;

	if ("`source'"=="current") {;
	tempfile database2qcheck;
	save `database2qcheck', replace;
	};
	
	
	preserve; //  Keep original data	;

/*-----------------------------------------------------
		A. Create file that save results
-----------------------------------------------------*/
*## Jayne, modify the logfile of the results as needed.
************** A. Create file that save results.;
	cap postutil clear;
	postfile resultados str30 country str10 year str30 acronym str10 vermast str10 veralt str30 survey str30 type str30 nature str10 project str10 period str10 contador str30 module str30 variableX str30 variableY str10 frequency  using check1, replace;
	
/*-----------------------------------------------------
		B. Static Analysis
-----------------------------------------------------*/

	qui{;  // begin static analysis;
	local messageend "";
	local gmodule `module';
	local gtype "`type'";
	local gsurvey "`survey'";
	local gproject "`project'";
	************* B2. Loops;
			foreach country of local countries {;  //loop country;

			if ("`period'"!="") {;
			local gperiod `period';
			local periodloop "foreach periodo of local gperiod";
			};
			else {;
				if ("`country'"=="arg") {;
					local gperiod s1 s2;
					local periodloop "foreach periodo of local gperiod";
				};
				else {;
					local gperiod "";
					local periodloop "qui";
				};
			};
				
			
			* Set years;
			foreach year in `years' {;  // loop year;
			
			`periodloop' { ;
				noi di "`country' - `year' `periodo'";
		
			* call excel conditions ;
				foreach var of local variables {;
				*##5 Jayne add here inputs from the excel
					use if variable=="`var'" using "${salt_adoeditpath}/crossqcheck_`test'.dta", clear;
					
					qui count;
					local n`var' =r(N);
					sort num;
				
					foreach check of numlist 1/`n`var'' {;
**************[......................] Jayne, call here inputs for the cross test
					};
					* end check loop;
				};
				* end variables loop;
				
			global salt_doncontador=0;
			global previous "previous";

				* Open data ;
				* retest variables;
				use "${salt_adoeditpath}/varqcheck_`test'.dta", clear ;

				qui count;
				local nlvar =r(N);
				
				foreach variable of numlist 1/`nlvar' {;
					local raw_varname`variable' = raw_varname[`variable'] ;
					local test_varname`variable' = test_varname[`variable'] ;
					local label`variable'=label[`variable'];
				};

		
			if ("`source'"=="current") {;
			use `database2qcheck', clear;
			};
			
	
			if ("`source'"=="datalibweb") {;
				if ("`periodo'"!="") local theperiod "period(`periodo')";
				if ("`type'"=="type(sedlac)") local mod "mod(all)";
                if ("`type'"=="type(sedlac-03)") local mod "mod(all)";
                noi di "datalibweb, country(`country') year(`year') `theperiod' `type' `mod' clear";
                
			cap datalibweb, country(`country') year(`year') `theperiod' `type' `mod' clear ;
			};
	
	
	
			if ("`source'"=="datalib") {;
				if ("`periodo'"!="") local theperiod "period(`periodo')";
				if ("`type'"=="type(sedlac)") local mod "mod(all)";
			cap datalib, country(`country') year(`year') `theperiod' `type' `mod' clear ;
		

			if _rc!=0 {; 
				noi di _rc;
				noi di "check datalib syntax: datalib, country(`country') year(`year') `theperiod' `type'";
				exit; 
				};
			
			};
			
			
			if ("`source'"=="review") {;
			*##4. Jayne, here I call the ado from your code. it is possible to complement as needed with additional options;
			qcheck_opendata, country(`countries') year(`years') `modules' ;
			};

			cap drop __*;

******************* Set globals for data information;
				
			if ("`source'"=="datalib") {;	
				global salt_veralt_p = r(veralt);
				global salt_vermast_p = r(vermast);
				global salt_survey 	= r(survname);
				global salt_acronym = "`country'";
				global salt_name= r(country);
				global salt_countryname = r(country);
				global salt_test 	= "`country'" ;
				global salt_type 	= r(type);
				global salt_nature 	= r(nature);
				global salt_year	="`year'";
				global salt_period = r(period);
				global salt_project = r(project);
				des;
				global salt_total = r(N) ;
			};
					

				if ("`source'"=="datalibweb") {;	
				global salt_veralt_p = r(vera);
				global salt_vermast_p = r(verm);
				global salt_survey 	= r(survname);
				global salt_acronym = "`country'";
				global salt_name= r(country);
				global salt_countryname = r(country);
				global salt_test 	= "`country'" ;
				global salt_type 	= r(type);
				global salt_nature 	= r(nature);
				global salt_year	="`year'";
				global salt_period = r(period);
				global salt_project = r(project);
				des;
				global salt_total = r(N) ;
			};
					

				if ("`source'"=="current") {;	
				global salt_veralt_p = .;
				global salt_vermast_p = .;
				global salt_survey 	= .;
				global salt_acronym = "`country'";
				global salt_name= .;
				global salt_countryname = .;
				global salt_test 	= "`country'" ;
				global salt_type 	= .;
				global salt_nature 	= .;
				global salt_year	="`year'";
				global salt_period = .;
				global salt_project = .;
				des;
				global salt_total = . ;
			};				
			
			if ("`source'"=="review") {;	
				global salt_veralt_p = `veralt_p';
				global salt_vermast_p = `vermast_p';
				global salt_survey 	= `survey';
				global salt_acronym = "`country'";
				global salt_name= .;
				global salt_countryname = .;
				global salt_test 	= "`country'" ;
				global salt_type 	= "`type'";
				global salt_nature 	= .;
				global salt_year	="`year'";
				global salt_period = .;
				global salt_project = .;
				des;
				global salt_total = . ;
			};
	
	qui{;
				foreach variable of numlist 1/`nlvar' {;
					cap retest `raw_varname`variable'' `test_varname`variable'';
					cap la var `test_varname`variable'' "`label`variable''";
				};
	};
	
	
	************* C1. Save tests data in locals;


			foreach var of local variables {;
					foreach check of numlist 1/`n`var'' {;
					local addnote=0;
		** set trace on ;
					if ("`temporal`var'`check''"!="no") {;
						local puntoycoma=strpos(`"`temporal`var'`check''"',";");  // encuentra el primer puntoycoma;
							while (`puntoycoma'>0) {;
								local linea = substr(`"`temporal`var'`check''"', 1, `puntoycoma'-1);
								local temporal`var'`check' = substr(`"`temporal`var'`check''"', `puntoycoma'+1,.);
								local puntoycoma=strpos(`"`temporal`var'`check''"',";");
								
								`linea';
								
								if _rc!=0 {; local addnote=1; };
								}; // end while;

				cap `temporal`var'`check'' ;
				if _rc!=0 {; local addnote=1; };
							} ; // end if;	
					
					if (`addnote'==1) {;local messageend "(*)Incorrect test for `var' `messageend'"; };
					
					if ("`description`var'`check''"=="") {;
					noi di as text "There are not test for `var'. Please, check your test file";
					local messageend_no`var' "(*) There are not test for `var'. Please, check your test file.";
					}; // end if
					
					else {;

					*## Jayne call here the crosstest
					noi log_crosstab `var', [.....];			
					


				}; // end else
				
					};  //  end of check of numlist;
				
			}; // end variables loop
			
		} ; // End loop period
			
	} ;  // End of Years loop;
} ; // end of Countries loop;		

} ; //End static Analysis;


/*	
* Close log file;
if ("`logfile'" != "") {;
	log close "`logfile'";
	noi disp as text `"note: results saved to `log'/`outfile'"';
	noi disp `"{ stata `"winexec "C:\Windows\system32\notepad.exe" "`outfile'/`salt_filetest'"': click here}"' _c ;
	noi disp  as text " to open with NotePad";
};  // end logfile options;
*/


	postclose resultados; //  Close post resultados;

	qui use check1.dta, clear;

	count if warning!="";
	*noi di `r(N)';
	if r(N)>0 {;
		duplicates drop variable warning description year country period project veralt vermast, force;
		egen n_error=seq();
		destring contador, replace;
		duplicates tag description variable warning  , generate(code);
		egen n=group(description variable warning);
		cap save "${salt_pathfile}/${salt_outfile}.dta", `replace';
		if _rc==0 {;
		qui export excel "${salt_pathfile}/${salt_outfile}.xlsx", sheetreplace firstrow(variables) sheet("check_results");
		noi di as txt "Click" as smcl `"{browse `""${salt_pathfile}/${salt_outfile}.xlsx""': here }"' `"to open results in excel "${salt_pathfile}/${salt_outfile}.xlsx" "';
		};
*set trace off;	

	}; // end if warning;
	else {;
		di in red "Caution: No flags for your selection";
		di as text "country(ies): `countries'";
		di as text "year(s): `years'";
		di as text "variable(s): `variables'";
	};
	
restore;
}; // close qui overall code;

end;  // end of program;

***************************************************************************************************
	
/*	

	di in red "`messageend'" ;
	
*	foreach var of local variables {;
*	if ("`messend_`var''"!="") {; di in red "`messend_`var''"; };
*	if ("`messageend_no`var''"!="") {; di in red "`messageend_no`var''"; };
*	};
*/


***************************Program to check logical statements ***********************************;

capture program drop log_crosstab;
program define log_crosstab, rclass;
	syntax anything								///
		[if] [in], 								///
			description(string)					///
			iff(string)							///
			[									///
			module(string)						/// 									
			warning(string)						///
			frequency(string)					///
			add(string)							///
			hint(string)						///
			STABDisp(string)					///
			STABLe(string)						///
			SWhen(string)						///
			];

	*Steps:	

*##6. Jayne add here the cross tab test code.
* how to test. This code should work alone, calling qcheck_crosstab, xxxxx after save it in C:\ado\personal\q
 
	};  // end save ;

end;

#delimit cr			
* fin
exit

**************************************NOTES*************************************

