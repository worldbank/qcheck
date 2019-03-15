/* *===========================================================================
	_statcheck: Program to check the quality of the in one point of time. 
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
				project(string)					///
				type(passthru)					///	
				survey(passthru)				///
				logfile							///
				replace							///
				path(string)					///
				test(string)					///
				outfile(string)					///
				fileserver						///
				nocpi 							///
				*								///
			];
*open qui overall code;
qui { ;	

	preserve; //  Keep original data	;

************** A. Create file that save results.;
	cap postutil clear;
	postfile resultados str30 country str10 year str30 acronym str10 vermast str10 veralt str30 survey str30 type str30 nature str10 contador str30 module str30 variable str30 warning str10 frequency str10 percentage str244 description str244 iff using check1, replace;
	
	************* B. Static Analysis;

	qui{;  // Begin static Analysis;
	local messageend "";
	************* B2. Loops;
			foreach country of local countries {;  //loop country;

			* Set years;
			foreach year in `years' {;  // loop year;
			*set trace on;
			* call excel conditions ;
				foreach var of local variables {;
				
					use if variable=="`var'" using "${salt_adoeditpath}/testqcheck_`test'.dta", clear;
					
					qui count;
					local n`var' =r(N);
					sort num;
				
					foreach check of numlist 1/`n`var'' {;
						local description`var'`check' = description[`check'] ;
						local iff`var'`check' = iff[`check'] ;
						local temporal`var'`check'=temporalvars[`check'];
						local warning`var'`check'=warning[`check'];
						local frequency`var'`check'=frequency[`check'];	
						local module`var'=module[`check'];
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
			
			*set trace off;
			cap	datalibweb, country(`country') year(`year')  clear `vermast' `veralt' `type' `project' `survey' `gmodule' `fileserver' `nocpi' `options';
			*set trace on;
				if _rc {;  // if _rc;
					noi disp in red "No data for `country'-`year' ";
					continue ;
				};  // close if _rc;
			
			cap confirm variable countrycode;
				if (_rc!=0)  {;
					local gmodule "module(UDB-C)";
					datalibweb, country(`country') year(`year') `vermast' `veralt' `type' `gmodule' clear   `fileserver' `nocpi';
				};
						
				* Set globals for data information;
				global salt_veralt_p = r(vera);
				global salt_vermast_p = r(verm);
				global salt_survey 	= r(surveyid);
				global salt_acronym = "`country'";
				global salt_test 	=  "`country'" ;
				global salt_type 	= r(type);
				global salt_nature 	= r(module);
				global salt_year	="`year'";
			
				count if countrycode!="";
				return list;
				global salt_total = r(N) ;
			
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
								
								cap `linea';
								
								if _rc!=0 {; local addnote=1; };
								};

				cap `temporal`var'`check'' ;
				if _rc!=0 {; local addnote=1; };
							} ;
							* end while punto y coma;			
					
					if (`addnote'==1) {;local messageend "(*)Incorrect specification for `var' in this test: `description`var'`check'' `messageend'"; };
					
					if ("`description`var'`check''"=="") {;
					noi di as text "There are not test for `var'. Please, check your test file";
					local messageend_no`var' "(*) There are not test for `var'. Please, check your test file.";
					};
					
					else {;
		** set trace on ;	
					
					noi log_statement `var', iff(`iff`var'`check'') ///
						description("`description`var'`check''") 	///
						module("`module`var''")						///
						warning("`warning`var'`check''")			///
						frequency("`frequency`var'`check''");			
					
		** set trace off;		

				};
			};  //  end of variable loops;
				
					};
			} ;
			
		
			*End of Years loop;
	} ;
	* end of Countries loop;		
} ;
* End static Analysis;

	* Close log file;

if ("`logfile'" != "") {;
	log close "`logfile'";
	noi disp as text `"note: results saved to `log'/`outfile'"';
	noi disp `"{ stata `"winexec "C:\Windows\system32\notepad.exe" "`outfile'/`salt_filetest'"': click here}"' _c ;
	noi disp  as text " to open with NotePad";
};  // end logfile options;

*set trace on ;
	postclose resultados; //  Close post resultados;

	qui use check1.dta, clear;

	count if warning!="";
	if r(N)>0 {;
		duplicates drop variable warning description year country, force;
		egen n_error=seq();
		destring contador, replace;
		duplicates tag description variable warning , generate(code);
		egen n=group(description variable warning);
		cap save "${salt_pathfile}/${salt_outfile}.dta", `replace';
		if _rc==0 {;
		qui export excel "${salt_pathfile}/${salt_outfile}.xlsx", sheetreplace firstrow(variables) sheet("check_results");
		noi di as txt "Click" as smcl `"{browse `""${salt_pathfile}/${salt_outfile}.xlsx""': here }"' `"to open results in excel "${salt_pathfile}/${salt_outfile}.xlsx" "';
		};
		
	};
	else {;
		di in red "Caution: No flags for your selection";
		di as text "country(ies): `countries'";
		di as text "year(s): `years'";
		di as text "variable(s): `variables'";
	};
*set trace off ;
	*set trace on;
	di in red "`messageend'" ;
	foreach var of local variables {;
	if ("`messend_`var''"!="") {; di in red "`messend_`var''"; };
	if ("`messageend_no`var''"!="") {; di in red "`messageend_no`var''"; };
	};
restore;

} ;  // end qui overall code;

end;  // end of program _statcheck. ;

***************************Program to check logical statements ***********************************;

capture program drop log_statement;
program define log_statement, rclass;
	syntax anything								///
		[if] [in], 								///
			description(string)					///
			iff(string)							///
			module(string)						///
			[ 									///
			warning(string)						///
			frequency(string)					///
			add(string)							///
			hint(string)						///
			STABDisp(string)					///
			STABLe(string)						///
			SWhen(string)						///
			];

	*Steps:	
	*1.  Does the variable exist?;
		cap confirm variable `anything';
		if _rc!=0 {;											// var doesn't exist;
			if regexm("`anything'", `"("${previous}")"') {;		// first check of this var, save post
				local description "Variable does not found. It should be missing";
				local frequency "${salt_total}";
				local warning "Missed";
				local savepost "yes";
			};
			else {;
				local savepost "no";		// do nothing;
			};
		};
	*2. Is not the variable missing?;
		else {;												// var exists but no information;
		cap confirm string var `anything';
		if !_rc {;
			tempvar saltblancos;  qui gen `saltblancos'="" ; 
			if ("`anything'"==`saltblancos') {; local description "All empty"; };
		};
		else {;
			qui sum `anything';
			if r(N)==0  {;
				local frequency "${salt_total}";
				local warning "Missing";
				local savepost "yes";

				tempvar saltmissing saltzeros saltblancos; qui gen `saltmissing'=. ; qui gen `saltzeros'=0; qui gen `saltblancos'="" ;
				if (`anything'==`saltmissing') {; local description "All missing"; };
				if (`anything'==`saltzeros') {; local description "All zero" ; };
				if ("`anything'"==`saltblancos') {; local description "All empty"; };
			};
		};
	*3.  Afther verify that the variable exists, and if does, that it's not missing, the revision begins ;
			else {;
		* The condition look for number of obs with this inconsistency;
				if strpos("`iff'", "`anything'")!=0 {;	// the condition include the var;
					qui count if (`iff');
					if r(N)>0 {;
						local frequency=r(N);
						local savepost "yes";
					};
					else {;
						local savepost "no";
						local frequency=0;
					};
				};  // end stuff when condition lookfor number of obs with inconsistency;
		* The condition holds or not holds whitin a all the observation. These checks use tempvars;
				else {;
				cap count if (`iff');
				if _rc!=0 {;
					local messend_`var' "(*) Incorrect specification for `var' in this test: `description`var'`check''"; 
				};
					qui count if (`iff');
					if r(N)>0 {;
						if ("`frequency'"==""){;
							local frequency "${salt_total}";
							local savepost "yes";
						};
		* The condition holds or not holds whitin a group of observation. These checks use tempvars.;
						else {;
							local frequency "`frequency'";
							local savepost "yes";
						};
					};
				};  // close stuff when confition holds in all or group of obsd;

			};  // end stuff when var is exist and is defined;
		
		};  // end existence condition;

	global previous="${previous}|"`anything'"";		// varlist of vars tested in specific country-year;
	
	* 4. If the condition wasn't hold, we save it in the post file;		

	if ("`savepost'"=="yes") {;  
		// if save post was target;
		* Create percentages instead frequencies;
			local percentage=`frequency'/${salt_total};
		
		* Updated counter;
			global salt_doncontador=${salt_doncontador}+1;
		* Save results;
			post resultados  ("${salt_test}") ("${salt_year}") ("${salt_acronym}") ("${salt_vermast_p}") ("${salt_veralt_p}") ("${salt_survey}") ("${salt_type}") ("${salt_nature}") ("${salt_doncontador}") ("`module'") ("`anything'") ("`warning'") ("`frequency'") ("`percentage'") ("`description'") ("`iff'");
			
		* Create a brouse;
		
			noi di in white "{hline 20} " "#${salt_doncontador} - " "${salt_test} - " "${salt_year} - " "`module' -" "`anything'" " {hline 20}>";
			noi di in red "`warning':" in white "	`description'`description2'." _newline;
			noi di in white "--> No of obs with this inconsistency:`frequency' of ${salt_total}. Equivalent to `percentage'" _newline;

	};  // end save ;

end;

#delimit cr			
* fin
exit

**************************************NOTES*************************************

