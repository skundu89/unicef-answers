global  pct2 `" 0 "0" 0.2 "20" 0.4 "40" 0.6 "60" 0.8 "80" 1 "100" "'

insheet using "$raw_data/Zimbabwe_children_under5_interview.csv", clear

qui ds ec*
foreach var in `r(varlist)'{
    replace `var'=. if !inlist(`var',1,2) //turning don't knows into missing values having tabulated and confirmed that the don't knows are a negligible portion of each variable (max 1.335%, n=34 for ec9)
    replace `var' = 0 if `var'==2 //changing the yes=1, no=2 notation to a dummy notation of 0=no, 1=yes
}

egen lit_math = rowtotal(ec6 ec7 ec8) //calculating domain-wise attainment of individual components
egen physical = rowtotal(ec9 ec10)
egen learning = rowtotal(ec11 ec12)
egen socio_emo = rowtotal(ec13 ec14 ec15)
egen ecd = rowtotal(ec6-ec15)

gen interview_date2=date(interview_date,"YMD") //converting dates to days past since 01Jan1960 for easy conversion
gen child_birthday2=date(child_birthday,"YMD")

gen child_age_days=interview_date2-child_birthday2 //calculating age in months from days
gen child_age_months=round(child_age_days/30)-1

label variable lit_math "Literacy & Numeracy"
label variable physical "Physical Development"
label variable learning "Learning Abilities"
label variable socio_emo "Socio Emotional Development"

gen lit_math_qualifier=lit_math>=2 if lit_math!=. //calculating domain wise attainmwent based on the required number of individual components
gen physical_qualifier=physical>=1 if physical!=.
gen learning_qualifier=learning>=1 if learning!=.
gen socio_emo_qualifier=socio_emo>=2 if socio_emo!=.

egen ecd_overall=rowtotal(*_qualifier) //calculating overall ECD attainment based on on-track in atleast 3 out of 4 domains
gen ecd_qualifier=ecd_overall>=3 if ecd_overall!=.

save "$working_folder/final_task2.dta", replace

graph twoway lpoly lit_math_qualifier child_age_months ||lpoly physical_qualifier child_age_months||lpoly learning_qualifier child_age_months||lpoly socio_emo_qualifier child_age_months||lpoly ecd_qualifier child_age_months,lcolor(red) legend(size(small)) plotregion(fcolor(white)) graphregion(fcolor(white)) ytitle("% of Children",size(small)) ysca(titlegap(3) outergap(1)) ylabel(,labsize(small)) legend(label(1 "Literacy & Numeracy") label(2 "Physical Development") label(3 "Learning Ability") label(4 "Socio-Emotional Development") label(5 "Overall ECD") size(small) cols(2)) sch(stsj) xtitle("Age of Child in Months",size(small)) xsca(titlegap(3) outergap(1)) xlabel(,labsize(small)) title("Proportion of On-Track Children in Each Domain of ECD", size(med)) ylab($pct2)

graph export "$output_folder/task2_fig1.png", replace

graph twoway lpoly ec6 child_age_months ||lpoly ec7 child_age_months||lpoly ec8 child_age_months, legend(size(small)) plotregion(fcolor(white)) graphregion(fcolor(white)) ytitle("% of Children",size(small)) ysca(titlegap(3) outergap(1)) ylabel(,labsize(small)) legend(label(1 "Can identify or name atleast ten letters of alphabet") label(2 "Can read atleast four simple, popular words") label(3 "Name and recognize the symbol of all numbers from 1 to 10") size(small) cols(1)) sch(stsj) xtitle("Age of Child in Months",size(small)) xsca(titlegap(3) outergap(1)) xlabel(,labsize(small)) ylab($pct2) title("Proportion of Children with Abilities that Determine Literacy and Numeracy", size(med))

graph export "$output_folder/task2_fig2.png", replace