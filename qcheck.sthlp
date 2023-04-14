{smcl}
{* 01Feb2023 }{...}
{viewerjumpto "Syntax" "qcheck##syntax"}{...}
{viewerjumpto "Menu" "qcheck##menu"}{...}
{viewerjumpto "Description" "qcheck##description"}{...}
{viewerjumpto "Links to Github documentation" "qcheck##linksgithub"}{...}
{viewerjumpto "Options" "qcheck##options"}{...}
{viewerjumpto "Examples" "qcheck##examples"}{...}
{viewerjumpto "Stored results" "qcheck##results"}{...}

{cmd:help qcheck} {hline 2} 
{hline}

{title:Title}

{p2colset 9 22 22 2}{...}
{p2col :{hi:qcheck} {hline 2}} Technical package for quality control of different types of data.{p_end}
{p2colreset}{...}

{marker syntax}{...}
{title:Syntax}

{p 8 13 2}
{cmd:qcheck} 
[{it:{help qcheck##variables:variables}}]
{ifin}
[{it:{help qcheck##weight:weight}}]{cmd:,}
{opth r:eport(analysis)}
{opth i:nput(input_file)}
{opth f:ile(output_file)}
{opth o:utput(output_path)}
[{it:options}]
{...}

{marker desc}{...}
{title:Description}

{p 8 12 2}{...}
{cmd:qcheck} shorthand for quality check is a technical package for quality control of different types of data. -qcheck- performs two big types of complementary types of analysis: static and dynamic. The dynamic analysis has two subanalysis (basic and categoric).{p_end}

{synoptset 20 tabbed}{...}
{synoptline}

{syntab:Analysis}
{p2coldent:* {opth r:eport(static)}}This option performs the static analysis.{p_end}
{p2coldent:* {opth r:eport(basic)}}This option performs the dynamic-basic analysis.{p_end}
{p2coldent:* {opth r:eport(categoric)}}This option performs the dynamic-categoric analysis.{p_end}

{syntab:Input}
{p2coldent:* {opth i:nput(file)}}This import the input file to be used in the static analysis.{p_end}

{syntab:File}
{p2coldent:* {opth f:ile(output_file)}}Output file name with the analysis performed.{p_end}

{syntab:Output}
{p2coldent:* {opth o:utput(output_path)}}Output path where the analysis performed is saved.{p_end}

{syntab:Weight}
{marker weight}{...}
{p 4 6 2}{cmd:aweight}s, {cmd:fweight}s, and {cmd:pweight}s are allowed; see
{help weight}.{p_end}

{synoptset 20 tabbed}{...}
{synoptline}

{marker options}{...}
{title:Options}
{dlgtab:restore}
{phang}{cmd:restore} can be used when the static analysis is performed. {cmd:restore} reloads the original data the user was using before performing the static analysis. 


{synoptset 20 tabbed}{...}
{synoptline}

{marker examples}{...}
{title:Examples}


{pstd}Analysis: Dynamic-basic{p_end}
{phang2}{cmd:. sysuse citytemp.dta, clear}{p_end}
{phang2}{cmd:. local dir `c(pwd)'}{p_end}
{phang2}{cmd:. qcheck heatdd, out("`dir'") report(basic)}{p_end}

{pstd}Analysis: Dynamic-categoric{p_end}
{phang2}{cmd:. sysuse voter.dta, clear}{p_end}
{phang2}{cmd:. local dir `c(pwd)'}{p_end}
{phang2}{cmd:. qcheck candidat, out("`dir'") report(categoric)}{p_end}

{pstd}Analysis: Static{p_end}
{phang2}{cmd:. ssc install wbopendata}{p_end}
{phang2}{cmd:. wbopendata, indicator(ag.agr.trac.no;si.pov.dday; ny.gdp.pcap.pp.kd) clear long}{p_end}
{phang2}{cmd:. keep if year==2015}{p_end}
{phang2}{cmd:. local filename= r(filename)}{p_end} 
{phang2}{cmd:. qui des, varlist}{p_end}
{phang2}{cmd:. local Allvars=r(varlist)}{p_end}
{phang2}{cmd:. local dir `c(pwd)'}{p_end}
{phang2}{cmd:. qcheck `Allvars', file("`filename'") out("`dir'") report(static) input(qcheck_example.xlsx) restore}{p_end}

{synoptset 20 tabbed}{...}
{synoptline}

{marker linksgithub}{...}
{title:Links to Github documentation}

        {mansection R qcheck:Github   }  {browse "https://github.com/lamoreno/qcheck_v02"}

		
 {title:Acknowledgements}

{p 4 4 2}This program was developed by teams of the "Poverty, Equity, Global Practice" from the World Bank Group.{p_end} 
{p 4 4 2}Comments and suggestions are most welcome.{p_end} 

{title:Authors}

{p 4 4 4}Santiago Garriga, The World Bank{p_end}
{p 6 6 4}Email {browse "sgarriga@worldbank.org":sgarriga@worldbank.org}{p_end}
{p 6 6 4}Email {browse "garrigasantiago@gmail.com":garrigasantiago@gmail.com}{p_end}

{p 4 4 4}R.Andres Castaneda, The World Bank{p_end}
{p 6 6 4}Email {browse "acastanedaa@worldbank.org":acastanedaa@worldbank.org}{p_end}
{p 6 6 4}Email {browse "r.andres.castaneda@gmail.com ":r.andres.castaneda@gmail.com }{p_end}
	
{p 4 4 4}Laura Moreno{p_end}
{p 6 6 4}Email {browse "lmorenoherrera@worldbank.org":lmorenoherrera@worldbank.org}{p_end}
{p 6 6 4}Email {browse "laumorenoh@gmail.com":laumorenoh@gmail.com }{p_end}

{p 4 4 4}Adriana Castillo-Castillo{p_end}
{p 6 6 4}Email {browse "acastillocastill@worldbank.org":acastillocastill@worldbank.org}{p_end}
{p 6 6 4}Email {browse "adrianacastilloc@gmail.com":adrianacastilloc@gmail.com }{p_end}














