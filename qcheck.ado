*!v 0.1 <30Nov2016> <Laura Moreno> <Andres Castaneda>
*=====================================================================
*	Qcheck: Program to check the quality of the data
*	Reference: 
*-------------------------------------------------------------------
*Created for datalib/LAC:		15Jul2013	(Santiago Garriga & Andres Castaneda) 
*Adapted for datalibweb:		8/1/2016	(Laura Moreno) 
*Last Modifications: 7Oct2019   Sandra Segovia / Laura Moreno
*version:		01 
*Dependencies: 	WORLD BANK - LCSPP
*=====================================================================
#delimit ;
discard;
cap program drop qcheck;
program define qcheck, rclass;
syntax [anything]								///
		[if] [in], 								///
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
				REGion(string)					///
				CASEs(passthru)					///
				Weight(passthru)				///				
				all								///
				logfile							///
				replace							///
				path(string)					///
				TESTfile(string)				///
				OUTfile(string)					///
				noppp							///
				bins(numlist)					///
				SOurce(string)					///
			];

*---------------------------------;
*	Save database open         ;
*---------------------------------;
if ("`source'"=="") {;
	local source "datalibweb";
};

if ("`source'"=="current") {;
tempfile database2qcheck;
save `database2qcheck', replace;
};

*---------------------------------;
*		Update Static Analysis  test         ;
*---------------------------------;
cap which unique;
if _rc ssc describe unique;

cap which missings;
if _rc ssc install missings;

cap which labelrename;
if _rc net install dm0012, from(http://www.stata-journal.com/software/sj5-2/);

cap which filelist;
if _rc ssc install filelist;

cap which apoverty;
if _rc ssc install apoverty;

cap which ainequal;
if _rc ssc install ainequal;



*---------------------------------------------;
*		Check for errors and defaults - Path and Test file        ;
*---------------------------------------------;

		quietly findfile qcheck.ado;
		global salt_adoeditpath=subinstr("`r(fn)'","/qcheck.ado","",.);

if (regexm("`anything'", `"^list"')) {;
	local data: dir "${salt_adoeditpath}" files "testqcheck_*.dta";
	local reportnames="";
	foreach d of local data {;
	local names=subinstr("`d'","testqcheck_","",.);
	local names=subinstr("`names'",".dta","",.);
	local reportnames "`names' `reportnames'";
	};
	if ("`reportnames'"=="") {; noi di in text "		Tests have not been created. Create one using-> qcheck create, test(filename) path(yourpath)"; };
	else {;
	noi di as text "		You have created the following group of test for qcheck:";
	local bullet=0;
	foreach reportname of local reportnames {;
	local bullet=`bullet'+1;
	noi di as result "		     [`bullet'] -> `reportname'";
	
	};
	noi di as text "		In total `bullet'. You may use them in qcheck static/dynamic or create new versions with qcheck create";
	};
	exit;
};


		if ("`path'"=="cd" |"`path'"=="CD") {;
			local path "`c(pwd)'";
			noi di  _col(10) as result "results will be saved in the current directory: `path' ";
		};
		if ("`path'"=="") {;

				local path "`c(pwd)'";
				noi di  _col(10) as result "results will be saved in the current directory: `path' ";

				glo salt_pathfile "`path'" ;
				noi di  _col(10) as result "results will be saved in the following directory: `path' ";
			};
		else {;
			glo salt_pathfile "`path'";
			noi di  _col(10) as result "results will be saved in the following directory: `path' ";
			};

		if ("`testfile'"=="") {;
			noi di as error "Test file is not defined, type test file test" _request(_testfile) ;
			local test `testfile';
		};
		if (strmatch("`testfile'","qcheck")==0) {;
			if (strmatch("`testfile'","qcheck_")==0) {;
				local test=subinstr("`testfile'", "qcheck_","",.);
			};
			else {;
				local test=subinstr("`testfile'", "qcheck","",.);
			};
		};
		else {; local test "`testfile'"; };
		
		

		
if (regexm("`anything'", `"^load"')) {;
	qui{ ;  

		************* RELOAD OPTION;
		noi di in text "Tests from `testfile'.xlsx. Note: sheets must be named Test and Variable";
		import excel using "${salt_pathfile}\\`testfile'.xlsx", sheet(Test) case(lower) clear firstrow;
		cap save "${salt_adoeditpath}\testqcheck_`test'.dta", `replace' ;
		if (_rc==602) {; noi di in red "	-> `test' already exists. Try with the option replace"; exit; };
		
		import excel using "${salt_pathfile}\\`testfile'.xlsx", sheet(Variables) case(lower) clear firstrow;
		save "${salt_adoeditpath}\varqcheck_`test'.dta", `replace' ;
		noi di in text "Tests from `testfile'.xlsx saved. Both sheets Test and Variables were saved";
	} ; 
	exit;
};



else {;			
*---------------------------------------------;
*		Check for errors and defaults         ;
*---------------------------------------------;
if ("`anything'" == "") { ;
	disp in red "you must select either dynamic or static analysis";
	error;
};

if ( wordcount("`anything'") > 1 ) {;
	disp in red "you must select only one type of analysis";
	error;
};
* countries and regions codes in upper letters;
local countries=strlower("`countries'");
local regions=strlower("`region'"); 
glo qc_countries "";

************** 1. Countries;
* if local countries are not defined, the program stop and ask for a country/region list. if regions are defined, those are replaced by country list;
if ("`countries'"=="" ) {;
	if ("`regions'"=="" ) {; disp in red "you must indicate a country list or region: LAC EAP ECA MNA SAR SSA"; error;};
	else {;	
		if (regexm("`regions'", `"^.*lac"'))==0 {;
		noi di in red "you must indicate a valid regions list"; 		};
		glo qc_countries "arg bol bra chl col cri dom ecu slv gtm hnd mex nic pan pry per ury hti";
		
	};
};
* if local countries are defined;
else {;
* save in a global de country list related to a region, if regions are specified;
	local qc_all "arg bol bra chl col cri dom ecu slv gtm hnd mex nic pan pry per ury hti";
		glo qc_countries "`countries'";
	
* if countries have been included, check country codes. If they match, those are included in the global of country list;
	foreach country of local countries {;
		if (regexm("`qc_all'", `"^`country'"')==1 | regexm("${qc_countries}", `"^`country'"')==0)  {;
			glo qc_countries "${qc_countries}  `country'";
		};
		if (regexm("`qc_all'", `"`country'"')==0 & regexm("LAC", `"^`country'"')==0) {;
			disp in red "country code not found"; error;
		};
	};
* if all has been defined, include all;
	if ("`countries'"=="all" ) {;
		glo qc_countries "`qc_all'";
	};
};

************** 2 Years to analyze and default;
local date: display %td_CCYY_NN_DD date(c(current_date), "DMY");
local cyear=substr("`date'",1,5);
		if ( wordcount("`years'") == 0 ) {;	// Set default option for years: all available from 2000 to today;
			numlist "2000/`=`cyear'-1'";
		};
		else {; numlist "`years'";
		};
		glo years = r(numlist);
************** 3 Variables to analyze ;
				* retest variables;
				use "${salt_adoeditpath}\varqcheck_`test'.dta", clear ;
				qui count;
				local nlvar =r(N);
				glo allvars="";
				local allthevars="";
				foreach variable of numlist 1/`nlvar' {;
					local raw_varname`variable' = raw_varname[`variable'] ;
					glo allvars="${allvars} `raw_varname`variable''";
					local allthevars="`allthevars'|`raw_varname`variable''";
					
				};
				foreach typean in "basic" "categorical" "welfare" {;
				preserve;
				qui keep if `typean'==1;
				qui count;
				local nlvar =r(N);
				glo allvars`typean'="";
				foreach variable of numlist 1/`nlvar' {;
					local raw_varname`variable' = raw_varname[`variable'] ;
					glo allvars`typean'="${allvars`typean'} `raw_varname`variable''";
				};
				restore;
				};

********
		local allvars "";
		local allctgs "";
		if ("`variables'" != "") {;
		local vari=lower("`variables'");  // If variables option is defined;
		};
		else {; noi di "List of variables is empty. Type a variables list OR type 'all' if you want to define default list. " _request(_vari);
		};
		
		if (regexm("`vari'", `"^.*all"')) {;
		local vari "${allvars}";
		local varbasi "${allvarsbasic}";
		local varctgs "${allvarscategorical}";
		local varwelf "${allvarswelfare}";
		};
		else {;
		local varbasi "";
		local varctgs "";
		local varwelf "";
		foreach varia of local vari {;
		foreach var of glo allvarsbasic {;
		if (strmatch("`var'", "`varia'"))==1 {;
		local varbasi "`varbasi' `var'"; 
		}; };
		
		foreach var of glo allvarscategorical {;
		if (strmatch("`var'", "`varia'"))==1 {;
		local varctgs "`varctgs' `var'"; 
		}; };
		
		foreach var of glo allvarswelfare {;
		if (strmatch("`var'", "`varia'"))==1 {;
		local varwelf "`varwelf' `var'"; 
		}; };
		};
		};
		if ("`variables'" == "") {;
		noi di "variable `var' defined does not exits";
		};
		
************** 4 Default type;
if ("`type'" == "") local type "type(sedlac)";
*if ("`type'" == "type(lablac)") local period "period(all)";	
				
************** 6 log file and  file test;

	
		if ("`outfile'"=="") {;
			glo salt_outfile "qcheck@0";
		} ;
		else {;
			glo salt_outfile "qcheck@`outfile'" ;
		} ;
	
		if ("`logfile'" == "logfile") {	;
			log using "${salt_pathfile}", text test(${salt_outfile}) `replace';
		};
************** 7 case;
if (regexm("`anything'", `"^dy(n|na|nam|nami|namic)"')) {;
if ("`cases'" == "") {; local cases "cases(basic)"; noi di in red "Basic case in dynamic analysis was defined"; };
if ("`cases'" == "cases(all)") | ("`cases'" == "cases(ALL)") {; local cases "cases(basic categorical poverty inequality)"; noi di in red "All cases in dynamic analysis were defined: Basic, Categorical, Poverty, Inequality"; };
* check weights;
if (regexm("`cases'", `"^.*basic"'))==1 & ("`varbasi'"=="") {; noi di in red "Basic case in dynamic analysis is not allowed with the selected variables"; };
if (regexm("`cases'", `"^.*categorical"'))==1 & ("`varctgs'"=="") {; noi di in red "Categorical case in dynamic analysis is not allowed with the selected variables"; };
if (regexm("`cases'", `"^.*pov(e|er|ert|erty)"'))==1 & ("`varwelf'"=="") {; noi di in red "Poverty case in dynamic analysis is not allowed with the selected variables"; };
if (regexm("`cases'", `"^.*ineq(u|ua|ual|uali|ualit|uality)"'))==1 & ("`varwelf'"=="") {; noi di in red "Inequality case in dynamic analysis is not allowed with the selected variables"; };
};
*--------------------------------;
*		Additional inputs        ;
*--------------------------------;
local datatime  : disp %tcDDmonCCYY_HH.MM clock("`c(current_date)'`c(current_time)'", "DMYhms");
local user      = c(username);
local dirsep    = c(dirsep);
local vintage:  disp %tdD-m-CY date("`c(current_date)'", "DMY");	
	*End check for errors and defaults.;		
*---------------------------------;
*		Dynamic Analysis          ;
*---------------------------------;

if (regexm("`anything'", `"^dy(n|na|nam|nami|namic)"')) {;
	local myrc=0;
	
	cap findfile "dyn_${salt_outfile}.xlsx", path(`path');

	if _rc==0 & "`replace'"!="replace" {;
		noi di in text "	(!) The output file already exists. Use option replace or define a different name";
		exit;
	};

	qcheck_dynamic , countries(${qc_countries}) years(${years}) variables(`varbasi')  `vermast' `veralt' `period' `project' `module' `type'  path(`path') outfile("${salt_outfile}") `logfile' `cases'  `weight' `replace' varc(`varctgs') varw(`varwelf') `noppp' bins(`bins') source(`source') ;
};

*---------------------------------;
*		Static Analysis           ;
*---------------------------------;

if (regexm("`anything'", `"^sta(t|ti|tic)"')) {;

	cap findfile "${salt_outfile}.dta", path(`path');
	if _rc==0 & "`replace'"!="replace" {;
		noi di in text "	(!) The output file already exists. Use option replace or define a different name";
		exit;
	};
	
	noi di "${qc_countries} ${years}";
	if ("`source'"=="current") {; use `database2qcheck', clear; };
	
	qcheck_static , countries(${qc_countries}) years(${years}) variables(`vari')  `vermast' `veralt' `period' `project' `module' `type'  `replace' path(`path')  `survey'  outfile(${salt_outfile}) `logfile' test(`test') `noppp' source(`source') ;
	
};
*;
};



#delimit cr	 	
end


exit
****************************************************************************************************************










