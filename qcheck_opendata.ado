*!v 0.1 <17Dec2019> <Jayne Jungsun>
*=====================================================================
*	Qcheck: Program to check the quality of the data
*	Reference: 
*-------------------------------------------------------------------
*Created as new source of data for qcheck:		17Dec2019   Jayne Jungsun
*Last Modifications: 17Dec2019   Jayne Jungsun
*version:		01 
*Dependencies: 	WORLD BANK 
*=====================================================================
***************************************Open Data Program*****************************************************

#delimit ;
discard;
cap program drop qcheck_opendata
program define qcheck_opendata, rclass
*##1. Jayne, here I think you need more options. you need the path? or only the coutry/year/module is needed?
syntax varlist									///
		[if] [in]								///
		[aweight fweight pweight], 			///
			[ 									///
			module(string)						///
			year(string)						///
			acronym(string)						

			]
*---------------------------------------------;
*		Check for errors and defaults         ;
*---------------------------------------------;		
*##2. Jayne, here I think you must add the minimun requierements in order to avoid that the program stop. Example, only one country and one year. I added an example of a code for verify that is only one country. You may need also to add that is only one year
local countries=upper("`countries'");
if ( wordcount("`countries'") > 1 ) {;
	disp in red "you must select only one database: add only one country";
	error;
};
if ( wordcount("`years'") > 1 ) {;
	disp in red "you must select only one database: add only one year";
	error;
};
if ( wordcount("`countries'") ==0 ) {;
	disp in red "you must select at least one country";
	error;
};
if ( wordcount("`years'") ==0 ) {;
	disp in red "you must select at least one year";
	error;
};

if ( wordcount("`module'") ==0 | wordcount("`module'") > 1 ) {;
	disp in red "you must select only one module";
	error;
};

if "${openpath}"=="" {;
*##4 Jayne, do you want to add a default or an option for the openpath;
glo openpath="";
};

*---------------------------------------------;
*		Check for errors and defaults         ;
*---------------------------------------------;	
			local data1: dir "${openpath}" files "*.dta";		
			*di `data1' ;
			
				foreach country in `countries'    {;  	
					* Set years ;
					foreach year in `years'    {; 
					* Set module; 
						foreach mmm in "`module'" {;   // loop module;
							foreach d of local data1    {;
								*noi di in yellow "`d'";
								local i = upper("`d'");
								local country=upper("`country'");
								if (ustrregexm("`i'","`country'")==1)     {;
									if (ustrregexm("`i'","`year'")==1)    {;
										if (ustrregexm("`i'","`mmm'.DTA")==1)    {;
														* Set locals for data information;
														noi di in yellow "`country' - `year' - `mmm' - source(`review')";
														local str "`i'";
														tokenize `str', parse("_");
														local source	="`review'";
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
			

							};   //module;
							} ;  //year;
							};   //country;
						};	///data loop;
					};    //  End of Module loop;
				} ;		///End of Years loop;
			};	 ///end of Countries loop;  
		};   	 // end of Source =2;	
	

#delimit cr	 	
end


exit
****************************************************************************************************************	