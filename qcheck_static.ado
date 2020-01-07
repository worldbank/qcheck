/* *===========================================================================
	
Last Modifications: 7-Oct2019   Sandra Segovia / Laura Moreno
Last Modifications: 3-Jan2019   Laura Moreno / Jayne Yoo

	_statcheck: Program to check the quality of the in one point of time. 
	Reference: 
-------------------------------------------------------------------

Version 1 Created:		Check any raw household survey data. Adapted from datacheck_static
Dependencies: 	WORLD BANK - LCSPP

/*WARNING: Inside this program you may find smaller but not less important programs, created with the idea to simplify and reduce repetitive code. For this reason, some parameters required in all the code are saved in global macros with the SALT prefix. This prefix is used with the intention to not disturbs other programs that could be running in the same stata session. SALT does not have a special meaning. */
*===========================================================================*/
#delimit ;
discard;
cap program drop qcheck_static;
program define qcheck_static, rclass;
syntax [anything]								///
		[if] [in], 								///
			[ 									///
			COUNTries(string)					///
			Years(numlist)						///
			VARiables(string)					///
				VERMast(string)					///
				VERAlt(string)					///
				module(string)				///
				project(passthru)				///
				period(string)				    ///
				type(string)					///	
				survey(passthru)				///
				logfile							///
				replace							///
				path(string)					///
				test(string)					///
				outfile(string)					///
				noppp							///
				SOurce(string)					///
				REView(string)					///
				EXCELoutput(string)	
			];

noi {;	// open qui overall code;

	if ("`source'"=="current") {;
	tempfile database2qcheck;
	save `database2qcheck', replace;
	};

	if ("`outfile'"=="") {;
	local outfile "${salt_outfile}"	;
	};
	preserve; //  Keep original data	;

/*-----------------------------------------------------
		A. Create file that save results
-----------------------------------------------------*/

************** A. Create file that save results.;
	cap postutil clear;
	postfile resultados str30 country str10 year str30 acronym str10 vermast str10 veralt str30 survey str30 type str30 nature str10 project str10 period str10 contador str30 module str30 variable str30 warning str10 frequency str10 size double percentage str244 description str244 iff str30 data_year using check1, replace;
	
/*-----------------------------------------------------
		B. Static Analysis
-----------------------------------------------------*/

	noi{;  // begin static analysis;
	local messageend "";
	local gmodule `module';
	local gtype "`type'";
	local gsurvey "`survey'";
	local gproject "`project'";
	

	************** long vs wide;    
	if ("`exceloutput'"=="" ) {;
		disp in red "you should indicate output format, default long"; local exceloutput="long";
		};
	if ("`exceloutput'"=="long" ) {;
			di as txt "Output will be saved in long format only";
			};		
	if ("`exceloutput'"=="none" ) {;
			di as txt "No excel output will be saved";
			};	
	if !inlist("`exceloutput'", "none", "long"){;
		disp in red "you must select excel long, none";
		error;
	};

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
				
					use if variable=="`var'" using "${salt_adoeditpath}/testqcheck_`test'.dta", clear;

					qui count;
					local n`var' =r(N);
					sort num;
				
					foreach check of numlist 1/`n`var'' {;
						local dddd`var'`check' = description[`check'] ;
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
				qui ds;
				loc list `r(varlist)';
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
			
			if ("`source'"=="review") {;
			noi di "qcheck_opendata, country(`country') year(`year') type(`type') module(`module') review(`review')";
			cap qcheck_opendata, country(`country') year(`year') type(`type') module(`module') review(`review') ; 				
			if _rc!=0 {;
				noi di "please check options for opendata";
			};
			};

			if ("`source'"=="datalibweb") {;
				if ("`periodo'"!="") local theperiod "period(`periodo')";
				if ("`type'"=="type(gmd)") local module "all";
				if ("`type'"=="type(sedlac)") local module "all";
                if ("`type'"=="type(sedlac-03)") local module "all";
                noi di in yellow "datalibweb, country(`country') year(`year') `theperiod' type(`type') module(`module') clear";
			cap datalibweb, country(`country') year(`year') `theperiod' type(`type') module("`module'") clear ;
			};
	
	
	
			if ("`source'"=="datalib") {;
				if ("`periodo'"!="") local theperiod "period(`periodo')";
				if ("`type'"=="type(sedlac)") local module "all";
			cap datalib, country(`country') year(`year') `theperiod' type(`type') module("`module'") clear ;
		

			if _rc!=0 {; 
				noi di _rc;
				noi di "check datalib syntax: datalib, country(`country') year(`year') `theperiod' type(`type')";
				exit; 
				};
			
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
				global salt_survey 	=  r(surveyname) ;
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
				
				if ("`source'"=="review") {;
				global salt_veralt_p = "`r(veralt_p)'";
				global salt_vermast_p = "`r(vermast_p)'";
				global salt_survey 	= "`r(survey)'";
				global salt_acronym = "`r(country)'";
				global salt_name= .;
				
				global salt_countryname = .;
				global salt_test 	="`r(country)'" ;
				global salt_type 	= "`r(type)'";
				global salt_nature 	= .;
				global salt_year	="`r(year)'";
				global salt_period = .;
				global salt_project = .;
				des;
				global salt_total = r(N);
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
			

	
************************* Flag when additional variables and no labels ******************************;
*<<Jayne>>;
if inlist("`source'", "datalibweb", "review") {;
								if (regexm("`variables'", `"^.*all"')) {;
									qui ds;
									loc varlistext `r(varlist)';

									foreach g of loc list {;
										local varlistext=`"`=subinword("`varlistext'","`g'","", 1)'"';
								};

								foreach v of loc varlistext {;
									loc anything="`v'";
									loc warning="Extra";
									loc description="Not in the variable list";
									loc frequency=.;
									loc percentage=.;
								* Save results;
								post resultados  ("${salt_test}") ("${salt_year}") ("${salt_acronym}") ("${salt_vermast_p}") ("${salt_veralt_p}") ("${salt_survey}") ("${salt_type}") ("${salt_nature}")  ("${salt_project}") ("${salt_period}") ("${salt_doncontador}") ("`module'") ("`anything'") ("`warning'") ("`frequency'") ("${salt_total}") (`percentage') ("`description'") ("`iff'") ("01/01/${salt_year}");
										*post resultados  ("`source'") ("${salt_test}") ("${salt_year}") ("${salt_acronym}") ("${salt_vermast_p}") ("${salt_veralt_p}") ("${salt_survey}") ("${salt_type}") ("${salt_nature}")  ("${salt_project}") ("${salt_period}") ("${salt_doncontador}") ("`module'") ("`anything'") ("`warning'") ("`frequency'") ("${salt_total}") (`percentage') ("`description'") ("`iff'") ("01/01/${salt_year}");
									};
								};
};								
*varialbles with no label;
								foreach g of loc varctgs  {;
									cap confirm var `g';
									if _rc==0 {;
										qui su `g';
										if r(N)>0 {;
											loc _check: val l `g';
												if (`"`_check'"' == "") {;

													loc variable="`g'";
													loc warning="Urgent";
													loc description="Variable `varctg' does not have val labels assigned";
													loc frequency=r(N);
													loc percentage=100;
												* Updated counter;
													global salt_doncontador=${salt_doncontador}+1;
												* Save results;
													post resultados  ("`source'") ("`country'") ("`year'") ("`country'") ("${salt_vermast_p}") ("${salt_veralt_p}") ("${salt_survey}") ("`type'") ("${salt_nature}")  ("${salt_project}") ("${salt_period}") ("${salt_doncontador}") ("`module'") ("`anything'") ("`warning'") ("`frequency'") (`percentage') ("`description'") ("`iff'") ("01/01/${salt_year}");

												};
										};
									};
								};
	
	
	************************* End flags when additional variables;
	
	
	
	
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
					
					if ("`dddd`var'`check''"=="") {;
					noi di as text "There are not test for `var'. Please, check your test file";
					local messageend_no`var' "(*) There are not test for `var'. Please, check your test file.";
					}; // end if
					
					else {;

					
					noi log_statement `var', iff(`iff`var'`check'') ///
						description("`dddd`var'`check''") 	///
						module("`module`var''")						///
						warning("`warning`var'`check''")			///
						frequency("`frequency`var'`check''");			
					


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
		gen source="`source'";
		cap save "${salt_pathfile}/`outfile'.dta", `replace';
		if _rc==0 {;
		if "`exceloutput'"=="long" {;
		qui export excel "${salt_pathfile}/`outfile'.xlsx", sheetreplace firstrow(variables) sheet("check_results");
		noi di as txt "Click" as smcl `"{browse `""${salt_pathfile}/`outfile'.xlsx""': here }"' `"to open results in excel "${salt_pathfile}/`outfile'.xlsx" "';
		};
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

capture program drop log_statement;
program define log_statement, rclass;
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
	*1.  Does the variable exist?;
		cap confirm variable `anything';
		if _rc!=0 {;											// var doesn't exist;
			*if regexm("`anything'", `"("${previous}")"') {;		// first check of this var, save post;
				local description "Variable not found. It should be defined as missing";
				local frequency "${salt_total}";
				local warning "Missed";
				local savepost "yes";
			*};
			/*else {;
				local description "Variable defined";
				local frequency "${salt_total}";
				local warning "Defined";
				local savepost "yes";
				local savepost "yes";		// do nothing;
			}*/;
			*commented by JY 12/26/2019: shouldnt we just remove this part if it does nothing?;
		};

	*2. Is not the variable missing?;
	*modified by JY 12/26/2019: section 2 & 3 were modified to include precondition;
		else  {;												// var exists but no information;
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
			*};
	*3.  Afther verify that the variable exists, and if does, that it's not missing, the revision begins ;
			*else {;
				if r(N)>0 {;
		* The condition look for number of obs with this inconsistency;
					if ("`temporalvars'"!="no") & ("`temporalvars'"!="yes") & ("`warning'"!="Missing") {;			
						if strpos("`iff'", "`anything'")!=0 {;	// the condition include the var;
							if (regexm("`temporalvars'", `"^.*cap noi confirm var"')) {;
							`temporalvars';
								if _rc==0 {;
									qui count if (`iff');
									if r(N)>0 {;
										local frequency=r(N);
										local savepost "yes";
									};
									};
							};
							else {;							
								`temporalvars';
								qui count if (`iff');
								if r(N)>0 {;
									local frequency=r(N);
									local savepost "yes";
								};
							};
							else {;
								local savepost "no";
								local frequency=0;
							};
						};  // end stuff when condition lookfor number of obs with inconsistency;
					};	//("`temporalvars'"!="no")
		* The condition holds or not holds whitin a all the observation. These checks use tempvars;
					
					if ("`temporalvars'"=="no")& ("`warning'"!="Missing") {;
						if strpos("`iff'", "`anything'")!=0 {;	
					qui count if (`iff');
							*if _rc!=0 {;
							*	local messend_`var' "(*) Incorrect specification for `var' in this test: `dddd`var'`check''"; 
							*};
							if r(N)>0 {;
								local frequency=r(N);
								local savepost="yes";
							};
							else {;
								local savepost="no";
								local frequency=0;
							};
						}; 	//condition includes the var
					};  //("`temporalvars'"=="no");
				};		//r(N)>0 
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
			post resultados  ("${salt_test}") ("${salt_year}") ("${salt_acronym}") ("${salt_vermast_p}") ("${salt_veralt_p}") ("${salt_survey}") ("${salt_type}") ("${salt_nature}")  ("${salt_project}") ("${salt_period}") ("${salt_doncontador}") ("`module'") ("`anything'") ("`warning'") ("`frequency'") ("${salt_total}") (`percentage') ("`description'") ("`iff'") ("01/01/${salt_year}");
			
		* Create a brouse;
		
			noi di in white "{hline 20} " "#${salt_doncontador} - " "${salt_test} - " "${salt_year} - " "`module' -" "`anything'" " {hline 20}>";
			noi di in red "`warning':" in white "	`description'`description2'." _newline;
			noi di in white "--> No of obs with this inconsistency:`frequency' of ${salt_total}. Equivalent to `percentage'" _newline;

	};  // end save ;

end;

#delimit cr			
* fin
*exit

**************************************NOTES*************************************

