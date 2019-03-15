{smcl}
{* 30nov2016 }{...}
{cmd:help qcheck} {hline 2} (help file in progress)
{hline}
 
{title:Title}

{p2colset 9 22 22 2}{...}
{p2col :{hi:qcheck} {hline 2}} Tool for checking quality of standardized data bases.{p_end}
{p2colreset}{...}

{* SYNTAX *}
{title:Syntax}

{p 4 4 2}
Static quality control

{p 6 16 2}
{cmd:qcheck} [{it:{ul:stat}ic}] {cmd:,} [	 {it:options}  ]  


{p 4 4 2}
Dynamic quality control

{p 6 16 2}
{cmd:qcheck} [{it:{ul:dyna}mic}] {cmd:,} [	{it:options} ] 

 
{p 4 4 2}
Load checks from Excel file into the {cmd:qcheck} system

{p 6 16 2}
{cmd:qcheck} {it:load}, [	 {it:options}  ] 
 
 
{p 4 4 2}
list available sets of checks

{p 6 16 2}
{cmd:qcheck} {it:list}
 
{marker sections}{...}
{title:sections}

{pstd}
Sections are presented under the following headings:

{p 18 18}{it:{help qcheck##Goptions:Options description}}{p_end}
{p 18 18}{it:{help qcheck##desc:Command description}}{p_end}
{p 18 18}{it:{help qcheck##Load:Load checks into the system}}{p_end}
{p 18 18}{it:{help qcheck##Options:Options explanation}}{p_end}
{p 18 18}{it:{help qcheck##SExamples:Static examples}}{p_end}
{p 18 18}{it:{help qcheck##DExamples:Dynamic examples}}{p_end}

{marker Goptions}{...}
{title:Options descriptions}

{synoptset 27 tabbed}{...}
{synopthdr:General options}
{synoptline}
{syntab:{help qcheck_dynamic##basics:Basics}} 
{synopt:{opt co:untries(string)}}{browse "http://www.nationsonline.org/oneworld/country_code_list.htm":ISO code} of countries composed of {it:three} letters. More than one country allowed{p_end}

{synopt:{opt years(numlist)}}{help numlist} of years for which the data is to be analysed{p_end}

{synopt:{opt type(string)}} Allows the user to specify the collection database. Default is GMD.{p_end}

{syntab:{help qcheck##additional:Additional}}

{synopt:{opt var:iables(string)}}This option allows selecting the variable to be analyzed. Take 
into account that variables list may variate amoung collection type. Example, GMD variables. More than one variables is allowed. See {it:{help datalibweb}}.{p_end}

{synopt:{opt verm:ast(string)}} Allows the user to specify the version of the master data.{p_end}

{synopt:{opt vera:lt(string)}} Allows the user to specify the version of the alternative data.{p_end}

{syntab:{help qcheck_static##additional:Save options}}

{synopt:{opt logfile}} Allows the user to generate a logfile with the results.{p_end}

{synopt:{opt out:file(string)}} Allows define a test for logfile, database and Excel file with the results. By default the test is qcheck_static. {p_end}

{synopt:{opt path(string)}} Allows define the path where the logfile, database and Excel file is going to be saved.{p_end}

{synopt:{opt test:file(string)}} Allows define the test for a specific collection. Test from an input Excel file has to be previously defined.{p_end}

{synopthdr:Dynamic-specific option}
{synoptline}
{synopt:{opt case:s(string)}}Type of analysis to be performed over time. Only five options are 
allowed: basic, categorical, poverty, inequality, and all. The latter includes the first four. 
Default is basic. 

{marker desc}{...}
{title:Command Description}

{pstd}
{cmd:qcheck} (short hand for "quality check") is a technical package for quality control of household surveys, comprehending
 variable-specific analysis in each dataset. In particular, {cmd:qcheck} performs two different but complementary types of assessments: {help qcheck##Static:static} and {help qcheck##Dynamic:dynamic}.
{p_end}

{pstd}
First, the {help qcheck##Static:static} analysis of {cmd:qcheck} verifies the internal consistent of each variable and its relationship with other variables in 
the same dataset. That is, it does not only verify that a variable makes sense in itself (e.g, it is not expected to find negative 
values for age), but also it checks the consistency of one variable with the others (e.g., It is expected that paid workers receive 
a positive income, rather than zero or missing income). The user is in the ability to create new tests, validations, and crosstabs 
to automate the assessing of variables across years, countries, regions, among others.
{p_end}

{pstd}
Second, assuming that all the datasets are standardized, the {help qcheck##Dynamic:dynamic} analysis of {cmd:qcheck} verifies the consistency of the same variable
 over time. In this regard, the basic case of {cmd:qcheck} dynamic performs four different calculations:
{p_end}		
{pin2}
* Percentage of missing values
{p_end}
{pin2} 
* Percentage of zero values
{p_end}
{pin2}
* Mean
{p_end}
{pin2} 
* Annualized percentage change of the mean with respect to previous year
{p_end}		
{pstd}
For the case of a categorical variable, {cmd:qcheck} presents changes in the participation share of each category over 
time to find inconsistencies.
{p_end}

{pstd} 
Finally, as a final extension of the dynamic analysis, {cmd:qcheck} calculates basic socioeconomic indicators for poverty 
and inequality. This analysis consists of a set of indicators such as poverty rates, Gini coefficients that allow the
 user to rapidly identify the main reasons of discrepancies between versions.
{p_end}
 
 
{marker Load}{...}
{title:Load checks into the system}
{pstd} 
Before using {cmd:qcheck}, the user needs to 'load' the checks into the system. To do so, 
you have to specify the function {it:load} in the {cmd:qcheck} command in Stata. Depending 
on where you have saved the Excel file “qcheck_NNN.xlsx”, you need to specify the directory
 path as indicated  below. this procedure has to be done for every set of checks or input 
 file you have. 
 
{p 4 12}{it:if file qcheck_#name# is saved in c:\ado\plus\q}

{p 8 12}{stata "qcheck load, test(qcheck_#name#)"}


{p 4 12}{it:if file qcheck_#name# is saved in other directory like "d:\test\qcheck"}

{p 8 12}{stata `"qcheck load, test(qcheck_#name#) path("d:\test\qcheck")"'}


{p 4 12}{it:if file qcheck_#name# is saved in current directory}

{p 8 12}{stata `"qcheck load, test(qcheck_#name#) path(CD)"'}

 
{marker Options}{...}
{title:Options explanation}
{p 50 20 2}(Go up to {it:{help qcheck_dynamic##sections:Sections Menu}}){p_end}
{marker basics}{...}
{dlgtab: basics}

{phang} {* COUNTRY *}
{opt coun:tries(["]srting["])} Three-letter {browse "http://www.nationsonline.org/oneworld/country_code_list.htm":ISO code} of the country. {cmd: qcheck} allows more than one country at a time. 

{phang} {* YEAR *}
{opt years(numlist)}  List of years for which only one type of survey and country are requested. If not specified, default list of  years is the period 2000-2014 {p_end}

{phang} {* TYPE *}
{opt type(string)}Refers to the collection of microdata to be analysed. It could be GMD, SEDLAC, ECAPOV, I2D2, among others. It depends on availability in {cmd:datalibweb}. {p_end}

{marker additional}{...} {p 80 20 2}({it:{help qcheck##Goptions:UP}}){p_end}
{dlgtab:Additional}
{phang} 
{opt var:iables(string)} Select variables to analyse. if '{it:all}' is specified, all the variables of the dataset will be analysed.{p_end}

{phang} {* VERMAST *}
{opt vermast(string)} The user can specify the version of the master data requested if needed. The version has to be entered as a two digits number (e.g. 01 , 02, …, etc). Default is the latest available version.{p_end}

{phang} {* VERALT *}
{opt veralt(string)} The user can specify the version of the alternative or sedlac data requested if needed. The version has to be entered as a two digits number (e.g. 01 , 02, …, etc) Default is the latest available version.{p_end}

{dlgtab:Dynamic-specific option}
{marker Cases}{...}

{phang} 
{opt case:s(basic|poverty|inequality|categorical|all)} Type of analysis that the user needs to perform. The user may select one or more of the first four options available. The fifth option, {it:all}, selects all the others. 

{p 10 12 2}{bf:basic}: For specified variable, {it:basic} calculates the proportion of zeros and missing values of the
 sample; the sample mean of the variable along with it's standard deviation. {err: Caution: If you analysis categorical variables or income variables in current prices the mean and the sd might not make sense} {p_end}

{p 10 12 2}{bf:poverty}: For specified variable, {it:poverty} calculates poverty rates for $2.5usd and $4usd a day. 
{it:More estimations will be added to the poverty analysis} {err: Caution: If you analysis categorical variables or income variables in current prices the mean and the sd might not make sense} {p_end}

{p 10 12 2}{bf:inequality}: For specified variable, {it:inequality} calculates basic inequality measures such as Gini and
 Theil index. However, if the user specifies the option {it:all} {cmd:qcheck} will calculate a bunch of common
 inequality measures. {err: Caution: make sure your are using weights to estimate inequality measures} {p_end} 
 {p 10 12 2}{bf:categorical}: For specified income variable, let identify strong changes in the series and patterns variations {err: Caution: make sure your are using weights to estimate inequality measures} {p_end} 
{p 10 12 2}{bf:all}: select all the above. 
{p_end}
{marker export}{...} {p 80 20 2}({it:{help qcheck##Goptions:UP}}){p_end}

{marker SExamples}{...}
{title:Static Examples}{p 50 20 2}(Go up to {it:{help qcheck##sections:Sections Menu}}){p_end}
{pstd}

{p 2 4}The examples below use light datasets like Paraguay or Panama, but the user can change to any  convenient country as long as the data exists.{p_end}

{dlgtab: Basic use}

{p 8 12}{stata "qcheck static, count(pry) years(2006/2009) variable(urban) test(qcheck_GMD) path(CD) type(gmd) outfile(myresults)"}

{pstd} Evaluate consistency of variable {it:urban} variable of Paraguay in the GMD collection for the period 2006-2009. It uses the file 'qcheck_GMD' where the checks of this collection are saved. 

{dlgtab: 'all' option}

{p 8 12}{stata "qcheck static, count(pry) years(2006/2009) variable(all) test(qcheck_pruebas) path(CD) type(gmd) outfile(myresults)"}{p_end}

{pstd} By selecting "all" inside the {it:variable()} option, {cmd:qcheck} {it:static} evaluates consistency of all variables for Paraguay from 2006 to 2009. 

{dlgtab: log}

{p 8 12}{stata "qcheck static, count(pry) years(2006) variable(all) test(qcheck_pruebas) path(CD) type(gmd) outfile(myresults) testlog(pry06)"}{p_end}

{pstd} The same example than above using Paraguay 2006 but this time {cmd:qcheck} {it:static} creates a log file with all the results, which is saved in the directory folder specified in the option {it:path()}. 


{marker DExamples}{...}
{title:Dynamic Examples}{p 40 20 2}(Go up to {it:{help qcheck_dynamic##sections:Sections Menu}}){p_end}
{pstd}

{p 2 4}The examples below uses light datasets like Paraguay and Panama, but the user can change to any convenient country as long as the data exists.{p_end}

{dlgtab: basic use}

{p 8 12}{stata "qcheck dynamic, countries(pry pan) years(2005/2009) var(welfare) name(qcheck_pruebas) path(cd) type(gmd) namefile(myfile)"}
{p_end}

{pstd}{cmd:qcheck} dynamic analysis for Paraguay and Panama between 2005 and 2009 for variable welfare in the GMD collection. Given that the {it:cases()} option was not specified, {cmd:qcheck} {it:dynamic} will perform the {it:basic} analysis. No weights are used in this example

{dlgtab: cases}

{p 8 12}{stata "qcheck dynamic, countries(pry pan) years(2007/2009) var(welfare)  weight(weight)cases(poverty inequality) name(qcheck_pruebas) path(cd) type(gmd) namefile(myfile)"}{p_end}

{pstd} Poverty and inequality Dynamic analysis for Paraguay between 2007 and 2009 for household welfare. Note that weights are used and the calculation in the 'basic' alternative of {it:cases()} won't be estimated.
 
{title:Acknowledgements}

{p 4 4 2}
{cmd:qcheck} is a generalized version of the {help datacheck} system (if installed)  developed by 
Andres Castaneda and Santiago Garriga. Originally, {cmd:datacheck} was developed to guarantee high quality and consistency 
of the SEDLAC and LABLAC databases under the  {browse "http://go.worldbank.org/IYDYF1BG70" : LAC Team for Statistical Development} 
project in the Latin American and Caribbean Poverty Reduction and Economic Management Group of the World Bank. 
{p_end} 

{p 4 4 2}
{cmd:qcheck} was developed under the Data for Goals (D4G) team direction in order to promote the high quality of the GMD and GPWG
databases in particular, and any other household survey collection in general. 
{p_end} 

{p 4 4 2}
Comments and suggesitons are most welcome.
{p_end} 
	
{title:Authors}

    {p 4 4 2}{browse "http://isearch.worldbank.org/skillfinder/ppl_profile_new/000384996": R. Andres Castaneda}
	and{browse "http://isearch.worldbank.org/skillfinder/ppl_profile_new/000473845": Laura Moreno}.{p_end}
	{p 4 4 2} Santiago Garriga (alumni){browse "mailto:santiago.garriga@psestudent.eu": santiago.garriga@psestudent.eu}.{p_end}

{title:See other user-written Stata programs}


{psee}Online:  {help datalibweb} (if installed){p_end}
{psee}Online:  {help missings} (if installed){p_end}
{psee}Online:  {help labelrename} (if installed){p_end}
{psee}Online:  {help filelist} (if installed){p_end}
{psee}Online:  {help apoverty} (if installed){p_end}
{psee}Online:  {help ainequal} (if installed){p_end}
