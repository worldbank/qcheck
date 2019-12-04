*!v 0.1 <30Nov2016> <Laura Moreno> <Andres Castaneda>
*=====================================================================
*	Qcheck: Program to check the quality of the data
*	Reference: 
*-------------------------------------------------------------------
*Created for datalib/LAC:		15Jul2013	(Santiago Garriga & Andres Castaneda) 
*Adapted for datalibweb:		8/1/2016	(Laura Moreno) 
*Adapted for ECAPOV:			06Oct2017	(Jayne Jungsun Yoo)
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
				module(string)					///
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
				Sources(numlist)				///
				REView(string)					///
				Format(string)
				fileserver						///
			];

*---------------------------------;
*		Update Static Analysis  test         ;
*---------------------------------;
cap which missings
if _rc ssc install missings

cap which labelrename
if _rc net install dm0012, from(http://www.stata-journal.com/software/sj5-2/)

cap which filelist
if _rc ssc install filelist

cap which apoverty
if _rc ssc install apoverty

cap which ainequal
if _rc ssc install ainequal

cap which tabmult
if _rc ssc install tabmult

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
	if ("`reportnames'"=="") {; qui di in text "		Tests have not been created. Create one using-> qcheck create, test(filename) path(yourpath)"; };
	else {;
	qui di as text "		You have created the following group of test for qcheck:";
	local bullet=0;
	foreach reportname of local reportnames {;
	local bullet=`bullet'+1;
	qui di as result "		     [`bullet'] -> `reportname'";
	
	};
	qui di as text "		In total `bullet'. You may use them in qcheck static/dynamic or create new versions with qcheck create";
	};
	exit;
};


		if ("`path'"=="cd" |"`path'"=="CD") {;
			local path "`c(pwd)'";
			qui di  _col(10) as result "results will be saved in the current directory: `path' ";
		};
		if ("`path'"=="") {;
			qui di as error "Define a folder to save results, type path" _request(_path) ;
				if ("`path'"=="cd") | ("`path'"=="CD") {;
				local path "`c(pwd)'";
				qui di  _col(10) as result "results will be saved in the current directory: `path' ";
				};
				glo salt_pathfile "`path'" ;
				qui di  _col(10) as result "results will be saved in the following directory: `path' ";
			};
		else {;
			glo salt_pathfile "`path'";
			qui di  _col(10) as result "results will be saved in the following directory: `path' ";
			};

		if ("`testfile'"=="") {;
			qui di as error "Test file is not defined, type test file test" _request(_testfile) ;
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
		qui di in text "Tests from `testfile'.xlsx. Note: sheets must be named Test and Variable";
		import excel using "${salt_pathfile}\\`testfile'.xlsx", sheet(Test) case(lower) clear firstrow;
		cap save "${salt_adoeditpath}\testqcheck_`test'.dta", `replace' ;
		if (_rc==602) {; qui di in red "	-> `test' already exists. Try with the option replace"; exit; };

		import excel using "${salt_pathfile}\\`testfile'.xlsx", sheet(Variables) case(lower) clear firstrow;
		save "${salt_adoeditpath}\varqcheck_`test'.dta", `replace' ;
		qui di in text "Tests from `testfile'.xlsx saved. Both sheets Test and Variables were saved";
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
local countries=strupper("`countries'");
local regions=strupper("`region'"); 
glo qc_countries "";

************** 1. Countries;
* if local countries are not defined, the program stop and ask for a country/region list. if regions are defined, those are replaced by country list;
if ("`countries'"=="" ) {;
	if ("`regions'"=="" ) {; disp in red "you must indicate a country list or region: LAC EAP ECA MNA SAR SSA"; error;
	};
	else {;
		foreach region of local regions {;
		if (regexm("`region'", `"^.*(LAC|EAP|ECA|MNA|SAR|SSA"'))==0 {;
		qui di in red "you must indicate a valid regions list"; 		};
		qui datalibweb_inventory, region(`region');
		glo qc_countries "${qc_countries}  `r(countrylist)'";
		};
	};
	else {;
		foreach region of local regions {;
		if (regexm("`region'", `"^.*(LAC|EAP|ECA|MNA|SAR|SSA"'))==0 {;
		qui di in red "you must indicate a valid regions list"; 		};
		qui datalibweb_inventory, region(`region');
		glo qc_countries "${qc_countries}  `r(countrylist)'";
		};
	};
};
* if local countris are defined;
else {;

  local qc_EAP ASM AUS BRN CHN FJI FSM GUM HKG IDN JPN KHM KIR KOR LAO MAC MHL MMR MNG MNP MYS NCL NZL PHL PLW PNG PRK PYF SGP SLB THA TLS TON TUV VNM VUT WSM;
  local qc_ECA ALB AND ARM AUT AZE BEL BGR BIH BLR CHE CHI CYP CZE DEU DNK ESP EST FIN FRA FRO GBR GEO GRC GRL HRV HUN IMN IRL ISL ITA KAZ KGZ KSV LIE LTU LUX LVA MCO MDA MKD MLT MNE NLD NOR POL PRT ROU RUS SMR SRB SVK SVN SWE TJK TKM TUR UKR UZB;
  local qc_LAC ABW ARG ATG BHS BLZ BOL BRA BRB CHL COL CRI CUB CUW CYM DMA DOM ECU GRD GTM GUY HND HTI JAM KNA LCA MEX NIC PAN PER PRI PRY SLV SUR TCA TTO URY VCT VEN VIR SXM MAF;
  local qc_MNA ARE BHR DJI DZA EGY IRN IRQ ISR JOR KWT LBN LBY MAR OMN PSE QAT SAU SYR TUN YEM;
  local qc_SAR AFG BGD BTN IND LKA MDV NPL PAK;
  local qc_SSA AGO BDI BEN BFA BWA CAF CIV CMR COD COG COM CPV ERI ETH GAB GHA GIN GMB GNB GNQ KEN LBR LSO MDG MLI MOZ MRT MUS MWI NAM NER NGA RWA SDN SEN SLE SOM SSD STP SWZ SYC TCD TGO TZA UGA ZAF ZMB ZWE;
  //local qc_NAC BMU CAN USA;
 * save in a global de country list related to a region, if regions are specified;
	local qc_all "";
	foreach region in LAC EAP ECA MNA SAR SSA {;
		local qc_all "`qc_all' `qc_`region''";
		if (regexm("`countries'", `"`region'"')) {;  glo qc_countries "${qc_countries}  `qc_`region''";
		};
	};
* if countries have been included, check country codes. If they match, those are included in the global of country list;
	foreach country of local countries {;
		if (regexm("`qc_all'", `"^`country'"')==1 | regexm("${qc_countries}", `"^`country'"')==0)  {;
			glo qc_countries "${qc_countries}  `country'";
		};
		if (regexm("`qc_all'", `"`country'"')==0 & regexm("LAC EAP ECA MNA SAR SSA", `"^`country'"')==0) {;
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
			numlist "1990/`=`cyear'-1'";
		};
		else {; numlist "`years'";
		};
		glo years = r(numlist);
		
************** 3 Variables to analyze ;
				* retest variables;
				use "${salt_adoeditpath}\varqcheck_`test'.dta", clear ;
				qui count;
				local nlvar =r(N);
				glo totalvars="";
				local total_vars="";
				foreach variable of numlist 1/`nlvar' {;
					local raw_varname`variable' = raw_varname[`variable'] ;
					glo totalvars="${totalvars} `raw_varname`variable''";
					local total_vars="`total_vars'|`raw_varname`variable''";
					
				};
				foreach typean in "basic" "categorical" "welfare" {;
				preserve;
				qui keep if `typean'==1;
				qui count;
				local nlvar =r(N);
				glo totalvars`typean'="";
				foreach variable of numlist 1/`nlvar' {;
					local raw_varname`variable' = raw_varname[`variable'] ;
					glo totalvars`typean'="${totalvars`typean'} `raw_varname`variable''";
				};
				restore;
				};
			
********
		local totalvars "";
		local totalctgs "";
		if ("`variables'" != "") {;
		local vari="`variables'";  // If variables option is defined; ///Modifie by JaY cancelled lower function(12/22/2017);
		};
		else {; qui di "List of variables is empty. Type a variables list OR type 'total' if you want to define default list. " _request(_vari);
		};
		
		if (regexm("`vari'", `"^.*total"')) {;
		local vari "${totalvars}";
		local varbasi "${totalvarsbasic}";
		local varctgs "${totalvarscategorical}";
		local varwelf "${totalvarswelfare}";
		};
		else {;
		local varbasi "";
		local varctgs "";
		local varwelf "";
		foreach varia of local vari {;
		foreach var of glo totalvarsbasic {;
		if (strmatch("`var'", "`varia'"))==1 {;
		local varbasi "`varbasi' `var'"; 
		}; };
		
		foreach var of glo totalvarscategorical {;
		if (strmatch("`var'", "`varia'"))==1 {;
		local varctgs "`varctgs' `var'"; 
		}; };
		
		foreach var of glo totalvarswelfare {;
		if (strmatch("`var'", "`varia'"))==1 {;
		local varwelf "`varwelf' `var'"; 
		}; };
		};
		};
		if ("`variables'" == "") {;
		qui di "variable `var' defined does not exits";
		};
		
************** 4 Default type;
if ("`type'" == "") local type "type(sedlac)";
				
************** 5 log file and  file test;

	
		if ("`outfile'"=="") {;
			glo salt_outfile "qcheck@0";
		} ;
		else {;
			glo salt_outfile "qcheck@`outfile'" ;
		} ;
	
		if ("`logfile'" == "logfile") {	;
			log using "${salt_pathfile}", text test(${salt_outfile}) `replace';
		};
************** 6 case;
if (regexm("`anything'", `"^dy(n|na|nam|nami|namic)"')) {;
if ("`cases'" == "") {; local cases "cases(basic)"; qui di in red "Basic case in dynamic analysis was defined"; };
if ("`cases'" == "cases(all)") | ("`cases'" == "cases(ALL)") {; local cases "cases(basic categorical poverty inequality)"; qui di in red "All cases in dynamic analysis were defined: Basic, Categorical, Poverty, Inequality"; };
* check weights;
if (regexm("`cases'", `"^.*basic"'))==1 & ("`varbasi'"=="") {; qui di in red "Basic case in dynamic analysis is not allowed with the selected variables"; };
if (regexm("`cases'", `"^.*categorical"'))==1 & ("`varctgs'"=="") {; qui di in red "Categorical case in dynamic analysis is not allowed with the selected variables"; };
if (regexm("`cases'", `"^.*pov(e|er|ert|erty)"'))==1 & ("`varwelf'"=="") {; qui di in red "Poverty case in dynamic analysis is not allowed with the selected variables"; };
if (regexm("`cases'", `"^.*ineq(u|ua|ual|uali|ualit|uality)"'))==1 & ("`varwelf'"=="") {; qui di in red "Inequality case in dynamic analysis is not allowed with the selected variables"; };
};

************** 7. Sources to analyze ;    
if ("`sources'"=="" ) {;
	disp in red "you must indicate sources"; error;
	};
	else {;	
		numlist "`sources'";
		glo sources = r(numlist);
		};		

************** 8. Module to analyze ;    
if ("`module'"=="" ) {;

	disp in red "you must indicate module"; error;
	};
	else {;	
			glo module =strupper("`module'"); 
		};


************** 9. Path to files for review ;    
if ("`review'"=="" ) {;
	disp in red "you must indicate path to files for review"; error;
	};
	else {;	
		glo openpath "`review'";
		};	
		
************** 10. Surveyid ;    
	glo survey "`survey'";
	
************** 11. Excel vs Dashboard ;    

if ("`format'"=="all" ) {;
	di as txt "Output will be formatted for dashboard and excel"; 
	glo format "`format'";
	};
if ("`format'"=="" ) {;
		di as txt "Output will be formatted for dashboard only";
		};		
if ("`format'"=="excel" ) {;
		di as txt "Output will be formatted for excel only";
		glo format "`format'";
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
		qui di in text "	(!) The output file already exists. Use option replace or define a different name";
		exit;
	};
dis in yellow "qcheck_dynamic starts";
	qcheck_dynamic , countries(${qc_countries}) years(${years}) variables(`varbasi') sources(${sources})  `vermast' `veralt' `type' ${survey} module(${module}) path(`path') outfile("${salt_outfile}") format("${format}") `logfile' `export'  `cases' `display'  `weight' `ppp' `outcome' `index' `replace' varc(`varctgs') varw(`varwelf') `fileserver' ;
dis in yellow "end of qcheck_dynamic";
};

*---------------------------------;
*		Static Analysis           ;
*---------------------------------;

if (regexm("`anything'", `"^sta(t|ti|tic)"')) {;

	cap findfile "${salt_outfile}.dta", path(`path');
	if _rc==0 & "`replace'"!="replace" {;
		qui di in text "	(!) The output file already exists. Use option replace or define a different name";
		exit;
	};
	
	qui di "${qc_countries} ${years}";
dis in yellow "qcheck_static starts";	
	qcheck_static , countries(${qc_countries}) years(${years}) variables(`vari') `vermast' `veralt' `period' `project' `module' `type'  `replace' path(`path')  `survey'  outfile(${salt_outfile}) `logfile' test(`test') `noppp' source(`source') ;
	if ("`source'"=="current") {; use `database2qcheck', clear; };
	noi di "${qc_countries} ${years}";
dis in yellow "end of qcheck_static";	
};
*;
};



#delimit cr	 	
end


exit
****************************************************************************************************************










