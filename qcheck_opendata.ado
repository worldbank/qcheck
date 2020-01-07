*!v 0.1 <17Dec2019> <Jayne Jungsun>
*=====================================================================
*	Qcheck: Program to check the quality of the data
*	Reference: 
*-------------------------------------------------------------------
*Created as new source of data for qcheck:		17Dec2019   Jayne Yoo
*Last Modifications: 17Dec2019   Jayne Jungsun
*version:		01 
*Dependencies: 	WORLD BANK 
*=====================================================================
***************************************Open Data Program*****************************************************


#delimit ;

cap program drop qcheck_opendata;
program define qcheck_opendata, rclass;
syntax [anything]							///
		[if] [in], 
			REView(string)							///
			[ module(string)						///
			year(numlist)						///
			country(string)						///
			type(string)
			];
			
			*di in red "`country'";
			local data1: dir "${openpath}" files "*.dta";	
			*di `data1' ;
*---------------------------------------------;
*		Check for errors and defaults         ;
*---------------------------------------------;	

if ("`review'"=="" ) {;
	disp in red "you must indicate path to files for review"; 
	error;
	};
	else {;	
		glo openpath "`review'";
	
	};
	
*;
*---------------------------------------------;
*		Open file         ;
*---------------------------------------------;	
foreach d of local data1 {;
	local i = upper("`d'");
	local country=upper("`country'");
	local module=upper("`module'");
	if ("`country'"!="") & (ustrregexm("`i'","`country'")==1) {;
		if ("`year'"!="") & (ustrregexm("`i'","`year'")==1) {;
			if ("`module'"!="")&(ustrregexm("`i'","`module'.DTA")==1) {;
							* Set locals for data information;
							noi di in yellow "`country' - `year' - `module' - source(`review')";
							local str "`i'";
							tokenize `str', parse("_");
							return local country = "`1'";
							return local year = "`3'";
							return local module="`module'";
							return local vermast_p = lower("`7'");
							return local veralt_p = lower("`11'");
							return local acronym = "`1'";
							return local survey = "`5'";
							return local type 	= "`15'";					
							local id=subinstr("`i'","`country'_`year'","",.);
							local id=subinstr("`id'",".DTA","",.);	
							* Open data ;		
							qui use "${openpath}/`country'_`year'`id'.dta", clear;


};
   
*module;
} ;  
*year;
};   
*country;
};	
*data loop;
	
	

#delimit cr	 	
end



****************************************************************************************************************	
