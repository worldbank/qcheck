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
program define qcheckstatic, rclass;
syntax varlist							///
		[if] [in]						///
		[aweight fweight pweight], 		///
		[								///
			FIle(string)				///
			Out(string)					///
			INput(string)				///
			restore						///
			];
*open qui overall code;
qui { ;	
***************************************************************;
*#F1# Get the name of the file in memory;
mata: st_local("fileinmemory",pathbasename("`c(filename)'"));
di "WORKING WITH ... `fileinmemory'";
*#F1# If file is not defined, the program will save the results using the filename in memory;
if ("`file'"=="") local file "`fileinmemory'";
tempfile database2qcheck;
save `database2qcheck', replace;
***************************************************************;
*#F1# If a path to save the results is not defined, the program use the current (working) directory;
if ("`out'"=="") local out `c(pwd)';
***************************************************************;
*#F1# files will be saved in <out> with the name "basicqcheck_<file>";
local outpathfile "`out'`c(dirsep)'staticqcheck_`file'";
*noi di "save in `outpathfile'";

***************************************************************;
* Weights treatment;
loc weight "[`weight' `exp']";
***************************************************************;
**Load test from excel;
	quietly findfile qcheckstatic.ado;
	global salt_adoeditpath=subinstr("`r(fn)'","/qcheckstatic.ado","",.);
	* check testfile;
	if ("`input'"=="") {;
		noi di as error "Test file is not defined, type test file test" _request(_input) ;
		local input `input';
	} ;
	if ("`input'"=="qcheck_example.xlsx") {;
		noi di "using ${salt_adoeditpath}/qcheck_example.xlsx" ;
		local input "${salt_adoeditpath}/qcheck_example.xlsx";
	} ;
	* load test file;
	*noi di in text "Tests from `testfile'.xlsx. Note: sheets must be named Test and Variable";
	cap import excel using "`input'", sheet(Test) case(lower) clear firstrow;
	if (_rc==601) {;
		noi di in text "sheet 'Test' in `input' not found. Revise the file and the format";
		error 601;
	};
	rename description dd;
	save "${salt_adoeditpath}\testqcheckstatic.dta", replace ;		
	noi di in text "... revising all the columns/variables are in `input'";
	confirm variable warning dd temporalvars iff frequency module , exact;	
	clear;
************** A. Create file that save results.;
	cap postutil clear;
	postfile resultados str10 contador str30 variable str30 warning  int frequency double percentage str244 dd str244 iff using "`outpathfile'", replace;
	
	************* B. Static Analysis;

	qui{;  
	* Begin static Analysis;
	local messageend "";
	************* B2. Loops;
			* call excel conditions ;
				foreach var of local varlist {;
				
					use if variable=="`var'" using "${salt_adoeditpath}/testqcheckstatic.dta", clear;
					
					qui count;
					local n`var' =r(N);
					cap sort num;
				
					foreach check of numlist 1/`n`var'' {;
						local dd`var'`check' = dd[`check'] ;
						local iff`var'`check' = iff[`check'] ;
						local temporal`var'`check'=temporalvars[`check'];
						local warning`var'`check'=warning[`check'];
						local frequency`var'`check'=frequency[`check'];	
					};
					* end check loop;
				};
				* end variables loop;
				
			global salt_doncontador=0;
			global previous "previous";
			
	use `database2qcheck', clear;
	count;
	global salt_total `r(N)' ;
	
	************* C1. Save tests data in locals;
	
			foreach var of local varlist {;
				foreach check of numlist 1/`n`var'' {;
					local addnote=0;
		
						if ("`temporal`var'`check''"!="no") {;
							local puntoycoma=strpos(`"`temporal`var'`check''"',";");  
								while (`puntoycoma'>0) {;
									local linea = substr(`"`temporal`var'`check''"', 1, `puntoycoma'-1);
									local temporal`var'`check' = substr(`"`temporal`var'`check''"', `puntoycoma'+1,.);
									local puntoycoma=strpos(`"`temporal`var'`check''"',";");	
									cap `linea';
									if (_rc>0) { ; 
									local addnote=1 ; 
									};
								}; 
								* end while punto y coma; *last line;
								cap `temporal`var'`check'' ;
								if (_rc>0) {;
									local addnote=1; 
								};

								if (`addnote'==1) {; 
									local messageend "(*)Incorrect specification for `var' in this test: `dd`var'`check'' `messageend'"; 
								};
						};
						*End temporal variables;

						if ("`dd`var'`check''"=="") {;
							noi di as text "There are not test for `var'. Please, check your test file";
							cap local messageend_no`var' "(*) There are not test for `var'. Please, check your test file.";
						};
						else {;
						****************************************************************;
						noi log_statement `var', iff(`iff`var'`check'') ///
							dd("`dd`var'`check''") 	///
							warning("`warning`var'`check''")			///
							frequency("`frequency`var'`check''");			
						****************************************************************;	
						};
						* END TEST;
				};	
				* END all tests same variable;
			};
			* END loop varlies;	
	};
	* qui End static Analysis;

	postclose resultados; //  Close post resultados;
	qui use "`outpathfile'", clear;
	count if warning!="";
	if r(N)>0 {;
		duplicates drop variable warning dd, force;
		egen n_error=seq();
		destring contador, replace;
		duplicates tag dd variable warning , generate(code);
		egen n=group(dd variable warning);
		replace percentage=round(percentage*10000)/100;
		replace frequency=${salt_total} if mi(frequency);
		*Labels;
		order contador variable warning frequency percentage dd;
		keep contador variable warning frequency percentage dd iff;
		la var contador "warnings/flags counter recordings";
		la var variable "varname";
		la var warning "level of importance";
		la var frequency "records that meet the statement (number)";
		la var percentage "records that meet the statement (percentage)";
		la var dd "statement dd";
		la var iff "stata statement code";
		cap save "`outpathfile'", `replace';

	};
	else {;
		di in red "Caution: No flags for your selection";
		di as text "file: `fileinmemory'";
		di as text "variable(s): `variables'";
	};
	di in red "`messageend'" ;
	foreach var of local varlist {;
		if ("`messend_`var''"!="") { ; di in red "`messend_`var''"; };
		if ("`messageend_no`var''"!="") {; di in red "`messageend_no`var''"; };
	};

	if ("`restore'"=="restore") use `database2qcheck', clear;


} ;  // end qui overall code;

end;  // end of program _statcheck. ;

***************************Program to check logical statements ***********************************;

capture program drop log_statement;
program define log_statement, rclass;
	syntax anything								///
		[if] [in], 								///
			dd(string)					///
			iff(string)							///
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
		*NO;
			if regexm("`anything'", `"("${previous}")"')  | strpos(`anything',"Missed")  {;		// first check of this var, save post
				local dd "Variable -`anything'- not found. If it cannot be defined, create it using special missing categories";
				local frequency ${salt_total};
				local warning "Missed";
				local savepost "yes";
			};
			else {;
				local savepost "no";		// do nothing;
			};
		};
		else {;
		*YES;											// var exists but no information;
	*2. Is the variable string?;
		cap confirm string var `anything';
		if !_rc {;
		*YES;
			tempvar saltblancos;  qui gen `saltblancos'="" ; 
			if ("`anything'"==`saltblancos') {; local dd "All empty"; };
		};
		else {;
		*NO;
			qui sum `anything';
			if r(N)==0  {;
				local frequency ${salt_total};
				local warning "Missing";
				local savepost "yes";

				tempvar saltmissing saltzeros saltblancos; qui gen `saltmissing'=. ; qui gen `saltzeros'=0; qui gen `saltblancos'="" ;
				tempvar saltmissing_a saltmissing_b saltmissing_c saltmissing_z; qui gen `saltmissing_a'=.a ; qui gen `saltmissing_b'=.b ; qui gen `saltmissing_c'=.c ; qui gen `saltmissing_z'=.z ;
				if (`anything'==`saltmissing') {; local dd "All missing, unknown reason"; };
				if (`anything'==`saltmissing_a') {; local dd "All missing .a, variable had not been harmonized"; };
				if (`anything'==`saltmissing_b') {; local dd "All missing .b, variable cannot be harmonized, data does not meet harmonization definition"; };
				if (`anything'==`saltmissing_c') {; local dd "All missing .c, variable not harmonized, data not available"; };
				if (`anything'==`saltmissing_z') {; local dd "Variable missed, not defined in the database"; };
				if (`anything'==`saltzeros') {; local dd "All zero" ; };
				if ("`anything'"==`saltblancos') {; local dd "All empty"; };
			};
		};
	*3.  Afther verify that the variable exists, and it's not missing, the revision begins ;
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
					local messend_`var' "(*) Incorrect specification for `var' in this test: `dd`var'`check''"; 
				};
					qui count if (`iff');
					if r(N)>0 {;
						if ("`frequency'"==""){;
							local frequency ${salt_total};
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
			post resultados  ("${salt_doncontador}") ("`anything'") ("`warning'") (`frequency') (`percentage') ("`dd'") ("`iff'");
					* Create a brouse;
		
			noi di in white "{hline 20} " "#${salt_doncontador} - "  "`anything'" " {hline 20}>";
			noi di in red "`warning':" in white "	`dd'`dd2'." _newline;
			noi di in white "-> " in red `frequency' in white "  observations with this inconsistency";
			noi di in white "-> " in red "`=round(`percentage'*100000)/1000' %" in white "  of the ${salt_total} observations" _newline;
			*noi di ${salt_total};

	};  // end save ;

end;

#delimit cr			
* fin
exit

**************************************NOTES*************************************

