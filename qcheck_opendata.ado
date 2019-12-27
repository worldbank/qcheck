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
cap program drop qcheck_opendata;
program define qcheck_opendata, rclass;
syntax [anything]							///
		[if] [in], 			///
			[ module(string)						///
			year(numlist)						///
			country(string)						///
			type(string)
			];
			*di in red "`country'";
			local data1: dir "${openpath}" files "*.dta";	
			*di `data1' ;
							foreach d of local data1    {;
								*noi di in yellow "`d'";
								local i = upper("`d'");
								local country=upper("`country'");
								noi di in yellow "`country'";
								if ("`country'"!="")&(ustrregexm("`i'","`country'")==1)     {;
									if ("`year'"!="")&(ustrregexm("`i'","`year'")==1)    {;
										if ("`module'"!="")&(ustrregexm("`i'","`module'.DTA")==1)    {;
									
														* Set locals for data information;
														*noi di in yellow "`country' - `year' - `module' - source(`review')";
														local str "`i'";
														tokenize `str', parse("_");
														local source	="`review'";
														local year	=`year';
														local module = "`module'";
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
	
	

#delimit cr	 	
end


exit
****************************************************************************************************************	
