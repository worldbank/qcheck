/* *===========================================================================
	
New: 23-Dec-2019   Jayne Yoo/ Laura Moreno
	
	_crosstabcheck: Program to check the quality of the in one point of time, coparing two variables. 
	Reference: 
-------------------------------------------------------------------

Version 1 Created:		Check any raw household survey data. Adapted from datacheck_static
Dependencies: 	WORLD BANK - LCSPP

/*WARNING: Inside this program you may find smaller but not less important programs, created with the idea to simplify and reduce repetitive code. For this reason, some parameters required in all the code are saved in global macros with the SALT prefix. This prefix is used with the intention to not disturbs other programs that could be running in the same stata session. SALT does not have a special meaning. */
*===========================================================================*/

***************************************Open Data Program*****************************************************

cap program drop qcheck_static_wide
program define qcheck_static_wide, rclass

/*syntax [anything]								///
		[if] [in]	,			 				///
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
				replace							///
				path(string)					///
				outfile(string)					///
				CASEs(string)					///
				Weight(string)					///
				VARCtgs(string)				///
				VARWelfare(string)				///
				bins(numlist)					///
				SOurce(string)					///
				ALTSOurce(string)				///
			]*/
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

end


exit
****************************************************************************************************************
*Jayne, assume here that in `path'\${salt_outfile}_`source'.dta exits the text for each source. The idea of this ado is take both sources, merge them, transform from long to wide and applied the code you already have that produce your excel.
*Jayne, I also recomment you create the excel as a template that call the output of this code, but you are free here to decide which work better
*commented by JY 12/26/2019: I created this ado in a way that it runs as a do file, using "check1.dta" so it does not require any syntax required for the program to run. 
