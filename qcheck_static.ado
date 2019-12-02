/* *===========================================================================
	_statcheck: Program to check the quality of the in one point of time. 
	Reference: 
-------------------------------------------------------------------

Version 1 Created:		Check any raw household survey data. Adapted from datacheck_static
Dependencies: 	WORLD BANK - LCSPP
Adapted for ECAPOV:			06Oct2017	(Jayne Jungsun Yoo)
/*WARNING: Inside this program you may find smaller but not less important programs, created with the idea to simplify and reduce repetitive code. For this reason, some parameters required in all the code are saved in global macros with the SALT prefix. This prefix is used with the intention to not disturbs other programs that could be running in the same stata session. SALT does not have a special meaning. */
*12/14/2017 : Cross tabulation not available if one of the var does not exists; not allowed the display of descrtiption on each error. 
*===========================================================================*/
#delimit ;
discard;
cap program drop qcheck_static;
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
				module(string)					//
				type(passthru)					///	
				survey(passthru)				///
				logfile							///
				replace							///
				path(string)					///
				test(string)					///
				outfile(string)					///
				Sources(numlist)				///
				fileserver						///
			];
*open qui overall code;
qui { ;	

	preserve; //  Keep original data	;

************** A. Create file that save results.;
	cap postutil clear;
	tempfile staticcheck;
	postfile resultados str10 source /*str30 country*/ str10 year str30 acronym str10 vermast str10 veralt str30 survey str30 type str30 /*nature str10*/ contador str30 module str30 variable str30 warning double frequency double percentage str244 description str244 iff using "`staticcheck'", replace;
	
	************* B. Static Analysis;

	*qui{;  // Begin static Analysis;
	local messageend "";
	************* B2. Loops;

	**set trace on;
	* call excel conditions ;
	foreach var of local variables {;
				
		use if variable=="`var'" using "${salt_adoeditpath}/testqcheck_`test'.dta", clear;		
		qui ds;
		local list `r(varlist)';


		qui count;
		local n`var' =r(N);
		*sort num;
				
		foreach check of numlist 1/`n`var'' {;
			local temporal`var'`check'=temporalvars[`check'];
			local descrip`var'`check' = description[`check'] ;
			local iff`var'`check' = iff[`check'] ;
			local descrip`var'`check' = description[`check'] ;
			local warning`var'`check'=warning[`check'];
			local frequency`var'`check'=frequency[`check'];	
			local module`var'=module[`check'];
			};
					* end check loop;
	};
				* end variables loop;
				
	global salt_doncontador=0;
	global previous "previous";
	global module "`module'";
	local gtype "`type'";  
	
	* retest variables;
	use "${salt_adoeditpath}/varqcheck_`test'.dta", clear ;

	qui count;
	local nlvar =r(N);
					
	foreach variable of numlist 1/`nlvar' {;
		local raw_varname`variable' = raw_varname[`variable'] ;
		local test_varname`variable' = test_varname[`variable'] ;
		local label`variable'=label[`variable'];
	};

	* Open data ;
	foreach source of local sources {;			
		if (`source'==2)	{;
			
		
			local data1: dir "${openpath}" files "*.dta";		
			*di `data1' ;
			
				foreach country in `countries'    {;  	
					* Set years ;
					foreach year in `years'    {; 
					* Set module; 
						foreach mmm in "${module}" {;   // loop module;
							foreach d of local data1    {;
								*noi di in yellow "`d'";
								local i = upper("`d'");
								local country=upper("`country'");
								if (ustrregexm("`i'","`country'")==1)     {;
									if (ustrregexm("`i'","`year'")==1)    {;
										if (ustrregexm("`i'","`mmm'.DTA")==1)    {;
														* Set locals for data information;
														noi di in yellow "`country' - `year' - `mmm' - source(`source')";
														local str "`i'";
														tokenize `str', parse("_");
														local source	="`source'";
														local year	=`year';
														local module = "`mmm'";
														local vermast_p = lower("`7'");
														*noi di in yellow "`vermast_p'";
														local veralt_p = lower("`11'");
														*noi di in yellow "`veralt_p'";
														local survey 	= "`5'";
														local acronym = "`1'";
														local type 	= "`15'";
														local id=subinstr("`i'","`country'_`year'","",.);
														local id=subinstr("`id'",".DTA","",.);	
														*noi di in yellow "`country'_`year'_`survey'_`vermast_p'_M_`veralt_p'_A_`type'_`module'.dta";
														* Open data ;		
														qui use "${openpath}/`country'_`year'`id'.dta", clear;


										qui count;
										qui return list;
										global salt_total = r(N) ;
			
		//check extra variables
		if (regexm("`vari'", `"^.*total"')) {;

			qui ds;
			loc var `r(varlist)';
			loc max =c(k);
			
			foreach g of loc variables {;
				local var=`"`=subinword("`var'","`g'","", 1)'"';
			};


			foreach v of loc var {;
				loc variable="`v'";
				loc warning="Extra";
				loc description="Not in the list";
				loc frequency=.;
				loc percentage=.;
				* Save results;
				post resultados  ("`source'") ("`year'") ("`acronym'") ("${vermast_p}") ("${veralt_p}") ("`survey'") ("`type'") ("${salt_doncontador}") ("`module'") ("`variable'") ("`warning'") (`frequency') (`percentage') ("`description'") ("`iff'");
			};
		};			
			*set trace on;
		//varialbles with no label
			foreach g of loc varctgs {;
				cap confirm var `g';
				if _rc==0 {;
					qui su `g';
					if r(N)>0 {;
						loc _check: val l `g';
							if (`"`_check'"' == "") {;

								loc variable="`g'";
								loc warning="Urgent";
								loc description="Variable `g' does not have val labels assigned";
								loc frequency=r(N);
								loc percentage=100;
								* Save results;
								post resultados  ("`source'") ("`year'") ("`acronym'") ("${vermast_p}") ("${veralt_p}") ("`survey'") ("`type'") ("${salt_doncontador}") ("`module'") ("`variable'") ("`warning'") (`frequency') (`percentage') ("`description'") ("`iff'");

							};
					};
				};
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
		** *set trace off;
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
					
					if (`addnote'==1) {;local messageend "(*)Incorrect specification for `var' in this test: `descrip`var'`check'' `messageend'"; };
					
					if ("`descrip`var'`check''"=="") {;
						noi di as text "There are not test for `var'. Please, check your test file";
						local messageend_no`var' "(*) There are not test for `var'. Please, check your test file.";
					};
					
					else {;
		 *set trace off;	
					
					noi log_statement `var', iff(`iff`var'`check'')  ///
						description("`descrip`var'`check''")     ///
						source(`source')                             ///
						veralt_p("`veralt_p'")                             ///	
						vermast_p("`vermast_p'")                             ///	
						acronym(`country')                             ///	
						type(`type')                             ///
						year(`year')                             ///
						survey(`survey')							///
						module("`mmm'")						///
						warning("`warning`var'`check''")			 ///
						frequency("`frequency`var'`check''")		///			
						temporalvars(`temporal`var'`check'');
		** set trace off;		

					};
					};  //  end of variable loops;
			};
							};   //module;
							} ;  //year;
							};   //country;
						};	///data loop;
					};    //  End of Module loop;
				} ;		///End of Years loop;
			};	 ///end of Countries loop;  
		};   	 // end of Source =2;	
	
	if (`source'==1)	{;		
			foreach country in `countries' {;  	//loop country;

				* Set years;
				foreach year in `years' {;  // loop year;

				* Set module; 
					foreach mmm in "${module}" {;   // loop module;
						noi di in yellow "`country' - `year' - `mmm' - source(`source')";

						qui cap datalibweb, country(`country') year(`year') `vermast' `veralt' `gtype' ${survey} /*`gmodule'*/ mod("`mmm'") clear   `fileserver';
						
						if _rc {;  // if _rc;
							noi disp in red "No data for `country'-`year' ";
							continue ;
						};  // close if _rc;
						
						if (_rc==0)  {;
							cap confirm variable countrycode;
						if (_rc!=0)  {;
							qui cap datalibweb, country(`country') year(`year') `vermast' `veralt' `gtype' ${survey}/*`gmodule'*/ mod("`mmm'") clear   `fileserver';
						};

						* Set locals for data information;
						global veralt_p = "`r(vera)'";
						global vermast_p = "`r(verm)'";
						global surveyid 	= "`r(surveyid)'";
						tokenize ${surveyid}, parse("_");
						local survey ="`5'";
						local acronym = "`country'";
						local type 	= "`r(type)'";
						local module	= "`r(module)'";
						local year ="`year'";
						local source ="`source'";										
						qui count;
						qui return list;
						global salt_total = r(N) ;
						
		//check extra variables
		if (regexm("`vari'", `"^.*total"')) {;

			qui ds;
			loc var `r(varlist)';
			loc max =c(k);
			
			foreach g of loc variables {;
				local var=`"`=subinword("`var'","`g'","", 1)'"';
			};


			foreach v of loc var {;
				loc variable="`v'";
				loc warning="Extra";
				loc description="Not in the list";
				loc frequency=.;
				loc percentage=.;
				* Save results;
				post resultados  ("`source'") ("`year'") ("`acronym'") ("${vermast_p}") ("${veralt_p}") ("`survey'") ("`type'") ("${salt_doncontador}") ("`module'") ("`variable'") ("`warning'") (`frequency') (`percentage') ("`description'") ("`iff'");
			};
		};
			
		//varialbles with no label
			foreach g of loc varctgs {;
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
								* Save results;
								post resultados  ("`source'") ("`year'") ("`acronym'") ("${vermast_p}") ("${veralt_p}") ("`survey'") ("`type'") ("${salt_doncontador}") ("`module'") ("`variable'") ("`warning'") (`frequency') (`percentage') ("`description'") ("`iff'");

							};
							};
							};
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
		** *set trace off;
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
					
					if (`addnote'==1) {;local messageend "(*)Incorrect specification for `var' in this test: `descrip`var'`check'' `messageend'"; };
					
					if ("`descrip`var'`check''"=="") {;
					noi di as text "There are not test for `var'. Please, check your test file";
					local messageend_no`var' "(*) There are not test for `var'. Please, check your test file.";
					};
					
					else {;
		*set trace off;	
					noi log_statement `var', iff(`iff`var'`check'')  ///
						description("`descrip`var'`check''")     ///
						source(`source')                             ///
						veralt_p("`veralt_p'")                             ///	
						vermast_p("`vermast_p'")                             ///	
						acronym(`country')                             ///	
						type(`type')                             ///
						year(`year')                             ///
						survey(`survey')						///
						module("`mmm'")						///
						warning("`warning`var'`check''")			 ///
						frequency("`frequency`var'`check''")		///			
						temporalvars(`temporal`var'`check'');
					
		** set trace off;		

							};
							};  //  end of variable loops;
				
						};
					} ;  //end of datalibweb;
				};    //  End of Module loop;
			} ;		///End of Years loop;
		};	 ///end of Countries loop;  
	} ;   ///end of Source =1;	

	};		//end if source loop;
} ;
* End static Analysis;

	* Close log file;

if ("`logfile'" != "") {;
	log close "`logfile'";
	qui disp as text `"note: results saved to `log'/`outfile'"';
	noi disp `"{ stata `"winexec "C:\Windows\system32\notepad.exe" "`outfile'/`salt_filetest'"': click here}"' _c ;
	noi disp  as text " to open with NotePad";
};  // end logfile options;

**set trace off;
	postclose resultados; //  Close post resultados;

	qui use "`staticcheck'", clear;

	qui count if warning!="";
	if r(N)>0 {;

		*duplicates drop variable warning description year country, force;
		egen n_error=seq();
		qui destring contador, replace;
		qui duplicates tag description variable warning , generate(code);
		egen n=group(description variable warning);
		*cap save "${salt_pathfile}/${salt_outfile}.dta", `replace';
		*if _rc==0 {;
		qui keep vermast veralt frequency	percentage variable warning description iff acronym	year	type	module	survey source;
		qui duplicates drop vermast veralt variable warning description iff acronym	year	source type	module	survey frequency	percentage, force;
			#delimit cr	
		if ("${format}"==""|"${format}"=="all") {
			qui export excel "${salt_pathfile}/${salt_outfile}_long.xlsx", sheetreplace firstrow(variables) sheet("Static_long") 
		}
		qui reshape wide vermast veralt frequency	percentage, i(variable warning description iff acronym	year	type	module	survey) j(source) string


		loc varl vermast1	veralt1 vermast2	veralt2 frequency1	percentage1 frequency2	percentage2
		foreach v of loc varl {
			cap confirm variable `v'
			if _rc!=0 {
				qui g `v'=.
				}
		}	

		order acronym year type survey  module veralt1 vermast1	veralt2 vermast2	variable	warning	description	iff	frequency1	percentage1	frequency2	percentage2
		sort acronym	year	type	module variable

		tempfile sta
		qui save `sta', replace

		//clear existing data in excel file
		qui import excel "${salt_pathfile}/${salt_outfile}.xlsx", sheet("Static") firstrow clear

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
		qui export excel  using "${salt_pathfile}/${salt_outfile}.xlsx", sheet("Static") cell(A3) sheetmodify
		
		//export final version
		qui u `sta', clear
		qui export excel  using "${salt_pathfile}/${salt_outfile}.xlsx", sheet("Static") cell(A3) sheetmodify		
		
		//Log
		qui destring year, replace
		qui collapse (count) no=frequency2, by(acronym	year	type	module)
		qui gen analysis="Static"
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
		
		noi di as txt "Click" as smcl `"{browse `""${salt_pathfile}/${salt_outfile}.xlsx""': here }"' `"to open results in excel "${salt_pathfile}/${salt_outfile}.xlsx" "'
		
		*if ("`module'"=="2" |"`module'"=="ssapov") {;
			*noi di as txt "Click" as smcl `"{browse `""${salt_pathfile}/tab_${salt_outfile}.xls""': here }"' `"to open results in excel "${salt_pathfile}/tab_${salt_outfile}.xls" "';
		*};
	*};  
		
	}
	#delimit ;
	else {;
		di in red "Caution: No flags for your selection";
		di as text "country(ies): `countries'";
		di as text "year(s): `years'";
		di as text "variable(s): `variables'";
	};
*set trace off ;
	**set trace on;
	/*qui di in red "`messageend'" ;
	foreach var of local variables {;
	if ("`messend_`var''"!="") {; qui di in red "`messend_`var''"; };
	if ("`messageend_no`var''"!="") {; qui di in red "`messageend_no`var''"; };
	};*/
restore;

exit;
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
			source(numlist)						///
			veralt_p(string)					///
			vermast_p(string)					///
			survey(string)						///
			year(string)						///
			acronym(string)						///
			type(string)						///
			warning(string)						///
			frequency(string)					///
			add(string)							///
			hint(string)						///
			STABDisp(string)					///
			STABLe(string)						///
			SWhen(string)						///
			temporalvars(string)				///
			];

	*Steps:	
	*1.  Does the variable exist?;
		cap confirm variable `anything';

		if _rc!=0 {;											// var doesn't exist;
			if regexm("`anything'", `"("${previous}")"') {;		// first check of this var, save post
				di in yellow "`anything' does not exist";
				local description "Variable is not found. It should be missing";
				local frequency "${salt_total}";
				local warning "Missed";
				local savepost="yes";
				local iff="_rc!=0";
				*qui gen `anything'=. ;
			};
/*
			else {;
				local savepost="no";		// do nothing;
			};
			*/
		};
	*2. Is not the variable missing?;
		else {;												// var exists but no information;
		/*
		cap confirm string var `anything';					
		if _rc==0 {;
			tempvar saltblancos;  qui gen `saltblancos'="" ; 
			if ("`anything'"==`saltblancos') {; local description "All empty"; };
		};
		*/
		*else {;
			qui sum `anything';
			if r(N)==0  {;
			
				local frequency "${salt_total}";
				local warning "Missing";
				local savepost="yes";
				local iff="r(N)==0";
				/*
				tempvar saltmissing saltzeros saltblancos; 
				qui gen `saltmissing'=. ; 
				qui gen `saltzeros'=0; 
				qui gen `saltblancos'="" ;
				*/
				*if (`anything'==`saltmissing') {;
				cap confirm string var `anything';					
				if _rc==0 {;
					if ("`anything'"=="") {;
						local description "All empty";
						};				
				};
				else {;
					if (`anything'==.) {
					;
						local description "All missing"; 
						};
					*if (`anything'==`saltzeros') {;
					if (`anything'==0) {;
						local description "All zero" ;
						};
				*if ("`anything'"=="`saltblancos'") {;
					};
			};
		*};

	*3.  Afther verify that the variable exists, and if does, that it's not missing, the revision begins ;
			*else {;			
			*cap confirm variable `anything';
			*if _rc!=0 {;											// var doesn't exist;	
					if r(N)>0 {;			
					if ("`temporalvars'"!="no") & ("`temporalvars'"!="yes") & ("`warning'"!="Missing") {;

						*di in yellow "`temporal`var'`check''";
						if strpos("`iff'", "`anything'")==0 {;	// the condition include the var;

							*di in yellow "`iff`var'`check''";
							`temporalvars';
							*`temporal`var'`check'';
							qui count if (`iff');
							if r(N)>0 {;
								local frequency=r(N);
								local savepost="yes";
							};
							else {;				
								local savepost="no";
								local frequency=0;
							};
						};  // end stuff when condition lookfor number of obs with inconsistency;
						};
					};
					
					if ("`temporalvars'"=="no") {;
						if strpos("`iff'", "`anything'")!=0 {;	// the condition include the var;
						qui count if (`iff');
						if r(N)>0 {;
							local frequency=r(N);
							local savepost="yes";
						};
					else {;
						local savepost="no";
						local frequency=0;
							};
						};  // end stuff when condition lookfor number of obs with inconsistency;
					};
				
			/*
			if ("`temporalvars'"=="yes") {;
						if ("`anything'"=="educy") {;
									cap confirm var educat7 educat5 educat4;
									if _rc!=0 {;
										local frequency "${salt_total}";
										local warning "N/A";
										local description "Cross tabulation is not available"
										local savepost="yes";
									};
									if _rc==0 {;
										qui count if (`iff');
										if r(N)>0 {;
											local frequency=r(N);
											local savepost="yes";
										};	
									};
						};
						if ("`anything'"=="edlev") {;
								cap confirm var educat4;
									if _rc!=0 {;
										local frequency "${salt_total}";
										local warning "N/A";
										local description "Cross tabulation is not available";
										local savepost="yes";
									};
									if _rc==0 {;
										qui count if (`iff');
										if r(N)>0 {;
											local frequency=r(N);
											local savepost="yes";
										};	
									};
						};
						if ("`anything'"=="educat4") {;
									cap confirm var educat5 educy educat7;
									if _rc!=0 {;
										local frequency "${salt_total}";
										local warning "N/A";
										local description "Cross tabulation is not available";
										local savepost="yes";
									};
									if _rc==0 {;
										qui count if (`iff');
										if r(N)>0 {;
											local frequency=r(N);
											local savepost="yes";
										};	
									};
						};
					if ("`anything'"=="educat7") {;
									cap confirm var educat5 educy educat4;
									if _rc!=0 {;
										local frequency "${salt_total}";
										local warning "N/A";
										local description "Cross tabulation is not available";
										local savepost="yes";
									};
									if _rc==0 {;
										qui count if (`iff');
										if r(N)>0 {;
											local frequency=r(N);
											local savepost="yes";
										};	
									};						
					};
					if ("`anything'"=="educat5") {;		
									cap confirm var educat4 educy educat7;
									if _rc!=0 {;
										local frequency "${salt_total}";
										local warning "N/A";
										local description "Cross tabulation is not available";
										local savepost="yes";
									};
									if _rc==0 {;
										qui count if (`iff');
										if r(N)>0 {;
											local frequency=r(N);
											local savepost="yes";
										};	
									};
					};					
					if ("`anything'"=="primarycomp") {;
								cap confirm var educat5;
									if _rc!=0 {;
										local frequency "${salt_total}";
										local warning "N/A";
										local description "Cross tabulation is not available";
										local savepost="yes";
									};
									if _rc==0 {;
										qui count if (`iff');
										if r(N)>0 {;
											local frequency=r(N);
											local savepost="yes";
										};	
									};		
					};
					if ("`anything'"=="empstat") {;
								cap confirm var lfstat;
									if _rc!=0 {;
										local frequency "${salt_total}";
										local warning "N/A";
										local description "Cross tabulation is not available";
										local savepost="yes";
									};
									if _rc==0 {;
										qui count if (`iff');
										if r(N)>0 {;
											local frequency=r(N);
											local savepost="yes";
										};	
									};	
					};
					if ("`anything'"=="lfstat") {;
								cap confirm var industrycat4;
									if _rc!=0 {;
										local frequency "${salt_total}";
										local warning "N/A";
										local description "Cross tabulation is not available";
										local savepost="yes";
									};
									if _rc==0 {;
										qui count if (`iff');
										if r(N)>0 {;
											local frequency=r(N);
											local savepost="yes";
										};	
									};							
					};
					if ("`anything'"=="industrycat4") {;		
								cap confirm var industrycat10;
									if _rc!=0 {;
										local frequency "${salt_total}";
										local warning "N/A";
										local description "Cross tabulation is not available";
										local savepost="yes";
									};
									if _rc==0 {;
										qui count if (`iff');
										if r(N)>0 {;
											local frequency=r(N);
											local savepost="yes";
										};	
									};	
					};
					if ("`anything'"=="occup") {;
								cap confirm var lfstat;
									if _rc!=0 {;
										local frequency "${salt_total}";
										local warning "N/A";
										local description "Cross tabulation is not available";
										local savepost="yes";
									};
									if _rc==0 {;
										qui count if (`iff');
										if r(N)>0 {;
											local frequency=r(N);
											local savepost="yes";
										};	
									};	
					};
					if ("`anything'"=="sector_w") {;
								cap confirm var lfstat;
									if _rc!=0 {;
										local frequency "${salt_total}";
										local warning "N/A";
										local description "Cross tabulation is not available";
										local savepost="yes";
									};
									if _rc==0 {;
										qui count if (`iff');
										if r(N)>0 {;
											local frequency=r(N);
											local savepost="yes";
										};	
									};
					};
					if ("`anything'"=="sector_a") {;
								cap confirm var lfstat;
									if _rc!=0 {;
										local frequency "${salt_total}";
										local warning "N/A";
										local description "Cross tabulation is not available";
										local savepost="yes";
									};
									if _rc==0 {;
										qui count if (`iff');
										if r(N)>0 {;
											local frequency=r(N);
											local savepost="yes";
										};	
									};		
					};
					if ("`anything'"=="type_contract") {;
								cap confirm var lfstat;
									if _rc!=0 {;
										local frequency "${salt_total}";
										local warning "N/A";
										local description "Cross tabulation is not available";
										local savepost="yes";
									};
									if _rc==0 {;
										qui count if (`iff');
										if r(N)>0 {;
											local frequency=r(N);
											local savepost="yes";
										};	
									};	
					};
					if ("`anything'"=="empl_time") {;
								cap confirm var lfstat;
									if _rc!=0 {;
										local frequency "${salt_total}";
										local warning "N/A";
										local description "Cross tabulation is not available";
										local savepost="yes";
									};
									if _rc==0 {;
										qui count if (`iff');
										if r(N)>0 {;
											local frequency=r(N);
											local savepost="yes";
										};	
									};				
					};					
				
				};
				*/
			*};  // end stuff when var is exist and is defined;
};  // end existence condition;

	global previous="${previous}|"`anything'"";		// varlist of vars tested in specific country-year;
	
	* 4. If the condition wasn't hold, we save it in the post file;		
/*
	if ("`warning'"!="Missed")& ("`warning'"!="Missing")&("`savepost'"=="yes") {;  
		// if save post was target;
								*cross tabulation;
								if ("`anything'"=="edlev")  {;
									cap confirm var educat4;
										if _rc==0 {;
											tabmult, cat(educat4) by(edlev) m sh("`country'_`anything'_`year'_source(`source')") save("${salt_pathfile}/tab_${salt_outfile}.xls") append;
										};
								};
								if ("`anything'"=="educat4") {;
									cap confirm var educat5;
										if _rc==0 {;								
											tabmult, cat(educat5) by(educat4) m sh("`anything'_`year'_source(`source')") save("${salt_pathfile}/tab_${salt_outfile}.xls") append;
										};
								};
								if ("`anything'"=="educat5") {;
									cap confirm var educat7;
										if _rc==0 {;								
											tabmult, cat(educat7) by(educat5) m sh("`anything'_`year'_source(`source')") save("${salt_pathfile}/tab_${salt_outfile}.xls") append;
										};
								};
								if ("`anything'"=="primarycomp") {;
									cap confirm var educat7;
										if _rc==0 {;									
											tabmult, cat(educat7) by(primarycomp) m sh("`anything'_`year'_source(`source')")save("${salt_pathfile}/tab_${salt_outfile}.xls") append;
										};
								};
								if ("`anything'"=="empstat") {;
									cap confirm var lfstat;
										if _rc==0 {;												
											tabmult, cat( lfstat) by(empstat) m sh("`anything'_`year'_source(`source')") save("${salt_pathfile}/tab_${salt_outfile}.xls") append;
										};
								};
								if ("`anything'"=="lfstat") {;
									cap confirm var industrycat4;
										if _rc==0 {;	
											tabmult, cat(industrycat4) by(lfstat) m sh("`anything'_`year'_source(`source')") save("${salt_pathfile}/tab_${salt_outfile}.xls") append;
										};
								};
								if ("`anything'"=="industrycat4") {;
									cap confirm var industrycat10;
										if _rc==0 {;									
											tabmult, cat(industrycat10) by(industrycat4) m sh("`anything'_`year'_source(`source')") save("${salt_pathfile}/tab_${salt_outfile}.xls") append;
										};
								};
								if ("`anything'"=="occup") {;
									cap confirm var lfstat;
										if _rc==0 {;								
											tabmult, cat(lfstat) by(occup) m sh("`anything'_`year'_source(`source')") save("${salt_pathfile}/tab_${salt_outfile}.xls") append;
										};
								};
								if ("`anything'"=="sector_w") {;
									cap confirm var lfstat;
										if _rc==0 {;	
											tabmult, cat(lfstat) by(sector_w) m sh("`anything'_`year'_source(`source')") save("${salt_pathfile}/tab_${salt_outfile}.xls") append;
										};
								};
								if ("`anything'"=="sector_a") {;
									cap confirm var lfstat;
										if _rc==0 {;					
											tabmult, cat(lfstat) by(sector_a) m sh("`anything'_`year'_source(`source')") save("${salt_pathfile}/tab_${salt_outfile}.xls") append;
										};
								};
								if ("`anything'"=="type_contract") {;
									cap confirm var lfstat;
										if _rc==0 {;
											tabmult, cat(lfstat) by(type_contract) m sh("`anything'_`year'_source(`source')") save("${salt_pathfile}/tab_${salt_outfile}.xls") append;
										};
								};
								if ("`anything'"=="empl_time") {;
									cap confirm var lfstat;
										if _rc==0 {;
											tabmult, cat(lfstat) by(empl_time) m sh("`anything'_`year'_source(`source')") save("${salt_pathfile}/tab_${salt_outfile}.xls") append;
										};	
								};
		};
		*/
	if ("`savepost'"=="yes") { ;
		* Create percentages instead frequencies;

			local percentage=`frequency'/${salt_total}*100;
		
		* Updated counter;
			global salt_doncontador=${salt_doncontador}+1;
		* Save results;
			post resultados  ("`source'") ("`year'") ("`acronym'") ("${vermast_p}") ("${veralt_p}") ("`survey'") ("`type'") ("${salt_doncontador}") ("`module'") ("`anything'") ("`warning'") (`frequency') (`percentage') ("`description'") ("`iff'");

		* Create a brouse;
		
			noi di in white "{hline 20} " "source(`source') - " "#${salt_doncontador} - " "`acronym' - " "`year' - " "`module' -" "`anything'" " {hline 20}>" ;
			noi di in red "`warning':" in white "	`description'`description2'." _newline;
			noi di in white "--> No of obs with this inconsistency:`frequency' of ${salt_total}. Equivalent to `percentage'" _newline;
	};  // end save ;
end;

#delimit cr			
* fin
*exit

**************************************NOTES*************************************

