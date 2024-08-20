
**# 1. UNICEF Global Data Repository - ANC4 and SAB Data

import excel using "$admin_data/GLOBAL_DATAFLOW_2018-2022.xlsx", clear firstrow case(lower)
drop if geographicarea=="" //dropping one blank row that gets imported from the excel
tab sex

/*

        Sex |      Freq.     Percent        Cum.
------------+-----------------------------------
     Female |        447      100.00      100.00
------------+-----------------------------------
      Total |        447      100.00

*/

drop sex unitmultiplier-currentage //variables not needed

tab time_period //checking covered time period, all between 2018-2022

/*

TIME_PERIOD |      Freq.     Percent        Cum.
------------+-----------------------------------
       2018 |        132       29.53       29.53
       2019 |        116       25.95       55.48
       2020 |         78       17.45       72.93
       2021 |         40        8.95       81.88
       2022 |         81       18.12      100.00
------------+-----------------------------------
      Total |        447      100.00

*/

destring time_period obs_value, replace
encode indicator, g(indic)
drop indicator
ren indic indicator

preserve
keep if indicator==1 //making a dataset for anc4
bysort geographicarea: egen maxyear=max(time_period)
keep if time_period==maxyear
drop maxyear

ren geographicarea country_name
ren time_period year_anc4
ren obs_value anc4

drop if inlist(country_name,"East Asia and Pacific","Europe and Central Asia","Latin America and the Caribbean","Middle East and North Africa","South Asia","Sub-Saharan Africa", "Eastern Europe and Central Asia", "Eastern and Southern Africa", "West and Central Africa") //dropping regional estimates that remained in the dataset
drop if country_name=="North America"
drop indicator
save "$working_folder/scratch_anc4.dta", replace

restore

keep if indicator==2 //making a dataset for sab
bysort geographicarea: egen maxyear=max(time_period)
keep if time_period==maxyear
drop maxyear

ren geographicarea country_name
ren time_period year_sba
ren obs_value sba

drop if inlist(country_name,"East Asia and Pacific","Europe and Central Asia","Latin America and the Caribbean","Middle East and North Africa","South Asia","Sub-Saharan Africa", "Eastern Europe and Central Asia", "Eastern and Southern Africa", "West and Central Africa") //dropping regional estimates that remained in the dataset
drop if country_name=="North America"
drop indicator
save "$working_folder/scratch_sba.dta", replace

merge 1:1 country_name using "$working_folder/scratch_anc4.dta", nogen

save "$working_folder/scratch_indicators.dta", replace


**# 2. Population Data

**# 2.1.  Projections

import excel using "$raw_data/WPP2022_GEN_F01_DEMOGRAPHIC_INDICATORS_COMPACT_REV1.xlsx", clear firstrow cellrange(a17:x20613) case(lower) sheet("Projections")

tab type

/*
             Type |      Freq.     Percent        Cum.
------------------+-----------------------------------
     Country/Area |     17,064       82.85       82.85
Development Group |        360        1.75       84.60
     Income Group |        432        2.10       86.70
  Label/Separator |          4        0.02       86.72
           Region |        432        2.10       88.81
       SDG region |        576        2.80       91.61
    Special other |        144        0.70       92.31
        Subregion |      1,512        7.34       99.65
            World |         72        0.35      100.00
------------------+-----------------------------------
            Total |     20,596      100.00

*/

keep if type == "Country/Area" //keeping only country level estimates dropping sub-regional, regional, development group, etc. estimates
keep if year==2022
drop totalpopulationasof1januar-populationannualdoublingtime index variant notes locationcode iso2alphacode sdmxcode type parentcode year

destring birthsthousands, replace force //using force option to override the "..." notation used for missing values in the variable corresponding to VAT isocode3

ren regionsubregioncountryorar country_name
ren iso3alphacode country_code
ren birthsthousands birth_proj_2022

save "$working_folder/scratch_pop_proj2022.dta", replace

**# 3. On Track Off Track

import excel using "$raw_data/On-track and off-track countries.xlsx", clear firstrow case(lower)
ren officialname country_name
ren iso3code country_code
label define status 1 "Acceleration Needed" 2 "On Track" 3 "Achieved"
encode statusu5mr, g(status) label(status)
drop statusu5mr

tab status

/*

        Status.U5MR |      Freq.     Percent        Cum.
--------------------+-----------------------------------
Acceleration Needed |         38       28.57       28.57
           On Track |          4        3.01       31.58
           Achieved |         91       68.42      100.00
--------------------+-----------------------------------
              Total |        133      100.00


*/


gen status2=status!=1 //classifying "achieved" and "on track" countries together as "on track", and the remainder i.e. "acceleration needed" countries as "off track"
label define status2 0 "Off Track" 1 "On Track"
label values status2 status2

tab status2

/*

    status2 |      Freq.     Percent        Cum.
------------+-----------------------------------
  Off Track |         38       28.57       28.57
   On Track |         95       71.43      100.00
------------+-----------------------------------
      Total |        133      100.00

*/

save "$working_folder/scratch_ontrackofftrack.dta", replace

**# 4. Merging all files and doing weighted-coverage calculations

isid country_code

merge 1:m country_code using "$working_folder/scratch_pop_proj2022.dta"
keep if _m==3
drop _m

merge 1:1 country_name using "$working_folder/scratch_indicators.dta"
keep if _m==3
drop _m

replace birth_proj_2022=birth_proj_2022*1000 //since projected birth variable is counted in 1000s
gen numerator_anc4=anc4*birth_proj_2022
gen numerator_sba=sba*birth_proj_2022

bys status2: egen numerator2_anc4=total(numerator_anc4)
bys status2: egen numerator2_sba=total(numerator_sba)
bys status2: egen denominator=total(birth_proj_2022)

gen wc_anc4=numerator2_anc4/denominator
gen wc_sba=numerator2_sba/denominator

save "$working_folder/final_task1.dta", replace

cd "$working_folder"
qui fs scratch*.dta
foreach f in `r(files)'{
    rm `f'
}
