***************************************Categrorical Analysis Program*****************************************************
qui {

cap program drop qcheckcat iqr
program define qcheckcat, rclass

*gettoken cmd 0 : 0

syntax varlist                                   ///
          [if] [in]                                ///
          [aweight fweight pweight],               ///
          [                                        ///
                          file(string)             ///
                          out(string)              ///
          ] 
***************************************************************
*Check aux programs
*cap findit svmat2dm79 from http://www.stata.com/stb/stb56
*if _rc!=0 noi di "Please install dm79 from http://www.stata.com/stb/stb56"
***************************************************************
*#F1# Get the name of the file in memory
mata: st_local("fileinmemory",pathbasename("`c(filename)'"))
di "WORKING WITH ... `fileinmemory'"
*#F1# If file is not defined, the program will save the results using the filename in memory
if ("`file'"=="") local file "`fileinmemory'"
***************************************************************
*#F1# If a path to save the results is not defined, the program use the current (working) directory
if ("`out'"=="") local out c(pwd)
***************************************************************
*#F1# files will be saved in <out> with the name "basicqcheck_<file>"
local outpathfile "`out'`c(dirsep)'cateqcheck_`file'"
***************************************************************
* Weights treatment
loc weight "[`weight' `exp']"
***************************************************************
preserve


* CATEGORIC REPORT         
      /*
          foreach v of local varlist {
          capture unab V : `v'
          if (_rc == 0) local varlist `varlist' `V'
          else        local badlist `badlist' `v'
          }          

          if ("`varlist'" != "") {
          local n : word count `varlist'
          local what = plural(`n', "variable")
          *di as txt "{p}`what': `varlist'{p_end}"
          return local varlist "`varlist'"
          }
          if ("`badlist'" != "") {
          local n : word count `badlist'
          local what = plural(`n', "not variable")
          *di as err "{p}`what': `badlist'{p_end}"
          return local badlist "`badlist'"
            foreach z of local badlist {
                          gen `z'="Not originally in this database"
            }
          }
      */    
      local all_syntaxvars "`varlist'"
        local year=1
        
          tempname P F A V Y B
          cap mat drop `P'
          
                    local vc = 0 
                    qui foreach varctg of local varlist {
                    *#F1# continue if more than 20 unique values, more than 20 categories.
					*ds, has(type string)
					*di in red "String vars: `r(varlist)'"
					unique  `varctg'
					local num_categories=r(unique)
					if `num_categories'<50 & "`varctg'"!="`weight'" {
					    
					/*
					cap confirm numeric variable `varctg'
                    if (_rc == 0) local numerica="numerica" //Si la variable es num'erica, crea un local llamado "numerica"
                    cap tab `varctg' 
					
                    if (_rc==134 & "`varctg'"!="`weight'") {
                        if ("`numerica'"=="numerica" ) replace `varctg'=9999999999 
                        if ("`numerica'"!="numerica" )  replace `varctg'="no categoric" 
                    } 
                    else {
						di "nooooooooooothing to display"
                      if (`r(r)'>20  & "`varctg'"!="`weight'") {
                        if ("`numerica'"=="numerica" ) replace `varctg'=9999999999 
                        *replace `varctg'="no categoric" if ("`numerica'"!="numerica" )
						if ("`numerica'"!="numerica" ) replace `varctg'="no categoric" 
                      }
                    }
					*/
                    tempvar missvar
                    missings tag `varctg', gen(`missvar')
                    count
                    local n = r(N)
                    count if `missvar'
                    local mn = r(N)
                    local diffm = `mn'-`n'
          
                    if (`diffm' == 0) {
                                    cap confirm numeric variable `varctg'
                                    if (_rc == 0) replace `varctg'=-999
                                    else  replace `varctg'="NA"
                    }  
          
                    * generate auxiliary variable with proper labels
                    tempvar varctgaux
                    cap confirm numeric variable `varctg'
                    if _rc != 0 {
                                    rename  `varctg' `varctgaux' 
                                    encode `varctgaux', generate(`varctg') label(`varctg')
                    }
                    else {
                    local la: value label `varctg'
                    if ("`la'" != "") {
                        cap labelrename `la' `varctg' 
                    }
                    }
          
                    *calculation of shares and extraction of labels in matrices
                    local ++vc
                    qui tab `varctg' `weight' , matcell(`F') matrow(`V')
                    mata: A = st_matrix("`F'")
                    mata: st_matrix("`F'", (A:/colsum(A))*100)
  
                    local nr = rowsof(`F')
                    mat `Y' = J(`nr', 1, `year')
                    mat `B' = J(`nr', 1, `vc')
					
					local rows 
					local this = strtoname("`: variable label `varctg''") 
					local rows `rows' `this'
					mat L=J(`nr',1,.)
					mat rownames L = `rows'
					mac li 
					mat li L
				
                    mat `A' = `Y', `V', `F', `B'  
					mat rownames `A' = `rows'
					mac li 
					mat li `A'
					
                    // matrix with year, categories value, proportion shares and var test
                    mat `P' = nullmat(`P')\ `A'
                    *}
					}

					else if `num_categories'>=50 & "`varctg'"!="`weight'" {
					    drop `varctg'
						gen `varctg'="this is a continous variable and is will not be analyzed by the qcheck categoric"
					    di "this is a continous variable and is will not be analyzed by the qcheck categoric"
					}
					} // End of local vars 
                         
                          // end loop categorical variable
                          mat colnames `P' = year valuelab freq varname
                          drop _all
                          *svmat `P', n(col)
				qui svmat2 `P', n(col) rnames(label_var)
          
                        qui tostring varname valuelab, replace force
                          label var freq "Participation share (%)"
                          
                          local vc = 0
                        qui foreach varctg of local all_syntaxvars {
                              local ++vc
                              replace varname = "`varctg'" if varname == "`vc'"
                              levelsof valuelab if varname == "`varctg'", local(values)
                              *di `valuelab'
                        
                              * asign value labels
                              qui foreach value of local values {
                                    replace valuelab = "`: label `varctg' `value''" ///
                                    if  valuelab == "`value'"                      ///
                                    & varname == "`varctg'"
                              }                    
                        }   //End of loop            


qui {
    la var valuelab "label"
    la var freq "frequency"
    la var varname "variable name"
    la var label_var "value label"
    gen filename="`file'"
    order filename year valuelab freq varname label_var
    drop year

}                
qui save "`outpathfile'", replace

noi di  _col(10) as result "Results were saved at `outpathfile'"
restore              
end
} 
* end of qui
exit


