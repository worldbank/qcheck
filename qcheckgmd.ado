*!v 0.1 <30Nov2016> <Laura Moreno> <Andres Castaneda>
*=====================================================================
* qcheck: Program to check the quality of the data
* Reference: 
*-------------------------------------------------------------------
*Created for datalib/LAC:  15Jul2013 (Santiago Garriga & Andres Castaneda) 
*Adapted for datalibweb:  8/1/2016 (Laura Moreno) 
*Last Modifications: 7Oct2019   Sandra Segovia / Laura Moreno
*Last Modifications: 20Dec2019   Sandra Segovia / Laura Moreno / Jayne Jungsun
*Last Modifications: 02Jan2020   Laura Moreno / Jayne Jungsun
*Version not using datalibweb/datalib:  Adriana Casillo / Laura Moreno
*version:  01 
*Dependencies:  WORLD BANK - LCSPP
*=====================================================================

cap program drop qcheckgmd
program define qcheckgmd, rclass

syntax anything        ///
  [if] [in]       ///
  [aweight fweight pweight]   ///
  [, Report(string)  File(string) Out(string) INput(string) restore ]

  *input(): this is required when the option"static" is chosen. 
  *Select file that has the test you want to perform. 
*---------------------------------
* Validation     
*---------------------------------
if !inlist("`anything'", "IDN", "COR", "GEO", "DEM", "LBR") & !inlist("`anything'", "UTL", "DWL", "CON", "GMD20", "GMD15", "CAT") {
    noi di "select one of the following modules: IDN COR GEO DEM LBR UTL DWL CON GMD20 GMD15 CAT"
    error
}
*******************************************************************************
* List of all variables in GMD 2.0
*******************************************************************************
      
  loc IDN countrycode year int_year int_month hhid hhid_orig pid pid_orig weight weighttype
   
 loc COR spdef weight  weighttype cpiperiod survey vermast ///
         veralt harmonization converfactor welfare welfarenom welfaredef ///
         welfaretype welfshprosperity welfshprtype welfareother ///
         welfareothertype hsize school literacy educy educat4 educat5 ///
         educat7 primarycomp
    
 loc GEO subnatid1 subnatid2 subnatid3 subnatid4 subnatidsurvey ///
        strata psu subnatid1_prev subnatid2_prev subnatid3_prev ///
        subnatid4_prev gaul_adm1_code gaul_adm2_code urban childyr childmth

 
 loc DEM language age agecat male relationharm relationcs marital ///
  eye_dsablty hear_dsablty walk_dsablty conc_dsord slfcre_dsablty ///
  comm_dsablty
 
 loc LBR minlaborage lstatus nlfreason unempldur_l unempldur_u empstat ///
 ocusec industry_orig industrycat10 industrycat4 occup_orig  ///
 wage_no_compen wage_nc unitwage whours wmonths wage_total contract ///
 healthins socialsec union firmsize_l firmsize_u empstat_2 ocusec_2 ///
 industry_orig_2 industrycat10_2 industrycat4_2 occup_orig_2 occup_2 ///
 wage_nc_2 unitwage_2 whours_2 wmonths_2 wage_total_2 firmsize_l_2 firmsize_u_2 ///
 t_hours_others t_wage_nc_others t_wage_others t_hours_total t_wage_nc_total ///
 t_wage_total minlaborage_year lstatus_year nlfreason_year unempldur_l_year ///
 unempldur_u_year empstat_year ocusec_year industry_orig_year industrycat10_year ///
 industrycat4_year occup_orig_year occup_year wage_nc_year unitwage_year ///
 whours_year wmonths_year wage_total_year contract_year healthins_year ///
 socialsec_year union_year firmsize_l_year firmsize_u_year empstat_2_year ///
 ocusec_2_year industry_orig_2_year industrycat10_2_year industrycat4_2_year ///
 occup_orig_2_year occup_2_year wage_nc_2_year unitwage_2_year whours_2_year ///
 wmonths_2_year wage_total_2_year firmsize_l_2_year firmsize_u_2_year ///
 t_hours_others_year t_wage_nc_others_year t_wage_others_year t_hours_total_year ///
 t_wage_nc_total_year t_wage_total_year njobs t_hours_annual linc_nc laborincome

 
 loc UTL water_source imp_wat_rec water_original watertype_quest ///
  piped_to_prem w_30m w_avail sanitation_source sanitation_original ///
  toilet_acc sewer open_def imp_san_rec waste central_acc heatsource ///
  gas cooksource lightsource elec_acc electricity elechr_acc electyp ///
  pwater_exp hwater_exp water_exp garbage_exp sewage_exp waste_exp  ///
  dwelothsvc_exp elec_exp ngas_exp  LPG_exp  gas_exp gasoline_exp ///
  diesel_exp kerosene_exp othliq_exp  liquid_exp wood_exp coal_exp ///
  peat_exp othsol_exp solid_exp  othfuel_exp central_exp heating_exp ///
  utl_exp dwelmat_exp dwelsvc_exp othhousing_exp transfuel_exp ///
  landphone_exp cellphone_exp tel_exp internet_exp telefax_exp ///
  comm_exp tv_exp tvintph_exp pipedwater_acc
 
 loc DWL landphone cellphone phone computer etablet internet radio ///
  tv tv_cable video fridge sewmach washmach stove ricecook fan ///
  ac ewpump bcycle mcycle oxcart boat car canoe roof wall floor ///
  kitchen bath rooms areaspace ybuilt ownhouse acqui_house dwelownlti ///
  fem_dwelownlti dwelownti selldwel transdwel ownland acqui_land ///
  doculand fem_doculand landownti sellland transland agriland ///
  area_agriland ownagriland area_ownagriland purch_agriland ///
  areapurch_agriland inher_agriland areainher_agriland ///
  rentout_agriland arearentout_agriland rentin_agriland ///
  arearentin_agriland docuagriland area_docuagriland fem_agrilandownti ///
  agrilandownti sellagriland transagriland dweltyp typlivqrt

    loc CON ctry_adq fdtexp_own fdtexp_buy fdtexp nfdtexp totexp fdpindex nfdpindex pindex ctry_totexp pl_ext pl_abs


 loc GMD20 `IDN' `COR' `GEO' `DEM' `LBR' `UTL' `DWL' `CON'

*******************************************************************************
* List of all variables in GMD 1.5
*******************************************************************************
*GMD 1.5 variables:
  loc GMD15 countrycode year hhid pid strata psu weight weighttype hsize ///
        cpiperiod survey vermast veralt spdef welfaretype welfare  welfarenom ///
        welfaredef welfshprosperity welfshprtype welfareother welfareothertype ///
        age agecat male relationharm relationcs marital ///
        school literacy educy educat4 educat5 educat7 primarycomp ///
        urban subnatid1 subnatid2 subnatid3 gaul_adm1_code gaul_adm2_code ///
        lstatus minlaborage empstat industrycat10 industrycat4 ///
        landphone cellphone computer electricity   ///
        imp_wat_rec water_source water_original watertype_quest pipedwater_acc ///
        imp_san_rec sanitation_source sanitation_original toilet_acc

    loc gmd_1_5_vars_string countrycode hhid pid weighttype cpiperiod survey vermast veralt welfaretype ///
        welfshprtype welfareothertype relationcs subnatid1 subnatid2 subnatid3 

*******************************************************************************
* List of Categorical variables
*******************************************************************************
local CAT school literacy educat4 educat5 educat7 primarycomp int_year int_month ///
          subnatid1 subnatid2 urban male relationharm relationcs marital ///
          eye_dsablty hear_dsablty walk_dsablty conc_dsord slfcre_dsablty comm_dsablty ///
          minlaborage lstatus nlfreason unempldur_l unempldur_u empstat ocusec ///
          industry_orig industrycat10 industrycat4 occup_orig unitwage ///
          contract healthins socialsec union firmsize_l firmsize_u empstat_2 ///
          industry_orig_2 industrycat10_2 industrycat4_2 occup_2 ocusec_2 ///
          industrycat10_2 industrycat4_2 occup_orig_2 occup_2 wage_no_compen_2 ///
          unitwage_2 firmsize_l_2 firmsize_u_2 water_source imp_wat_rec water_original ///
           watertype_quest piped  piped_to_prem sanitation_source sanitation_original ///
           toilet_acc sewer open_def imp_san_rec waste central_acc heatsource gas cooksource ///
           lightsource elec_acc electricity landphone cellphone phone computer etablet ///
           internet radio tv tv_cable video fridge sewmach washmach stove ricecook fan ac ///
           ewpump bcycle mcycle oxcart boat car canoe roof wall floor kitchen bath rooms ///
           ownhouse acqui_house dweltyp


    foreach mod in IDN COR GEO DEM LBR UTL DWL CON GMD20 GMD15 CAT {
    if ("`anything'"=="`mod'") local varlistgmd ``mod''
    }
    *noi di "`varlistgmd'"

    cap gen piped="Missed"
    cap gen occup="Missed"
     
      foreach var of local varlistgmd {
            cap confirm var `var'
            if _rc {
                gen `var'="Missed"
                local missedvars "`missedvars' `var'"
            }
         }
    noi di as error "URGENT: You need to create the folowwing variables:"
    noi di as error "`missedvars'" _n

/*
    preserve
    drop `varlistgmd'
    qui des, varlist
 local extravars="`r(varlist)'"
    noi di as error "WARNING: The following variables are not part of module `anything':"
    noi di "`extravars'"
    restore
*/

*---------------------------------------------
* Weights treatment
loc weight "[`weight' `exp']"
*---------------------------------------------
qcheck `varlistgmd' `weight', report(`report') file("`file'") out(`out') input(`input') `restore'
 
 
end



****************************************************************************************************************










