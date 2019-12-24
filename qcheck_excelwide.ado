/* *===========================================================================
	
New: 23-Dec-2019   Jayne Jungsun / Laura Moreno
	
	_crosstabcheck: Program to check the quality of the in one point of time, coparing two variables. 
	Reference: 
-------------------------------------------------------------------

Version 1 Created:		Check any raw household survey data. Adapted from datacheck_static
Dependencies: 	WORLD BANK - LCSPP

/*WARNING: Inside this program you may find smaller but not less important programs, created with the idea to simplify and reduce repetitive code. For this reason, some parameters required in all the code are saved in global macros with the SALT prefix. This prefix is used with the intention to not disturbs other programs that could be running in the same stata session. SALT does not have a special meaning. */
*===========================================================================*/

***************************************Open Data Program*****************************************************

cap program drop qcheck_excelwide
program define qcheck_excelwide, rclass

syntax [anything]								///
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
			]
		


*Jayne, assume here that in `path'\${salt_outfile}_`source'.dta exits the text for each source. The idea of this ado is take both sources, merge them, transform from long to wide and applied the code you already have that produce your excel.

*Jayne, I also recomment you create the excel as a template that call the output of this code, but you are free here to decide which work better