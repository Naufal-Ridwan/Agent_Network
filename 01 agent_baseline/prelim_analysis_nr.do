*===================================================*
* Full-Scale - Client Survey (Baseline)
* Currently cleaning the benchtest survey
* Author: Riko
* Last modified: 2 Sep 2025
* Last modified by: Muthia
* Stata version: 16
*===================================================*

clear all
set more off


*****************************************
**--------------DATA PATH--------------**
*****************************************
gl user = c(username)

* Set your username here (change your "$user" == "[your username here]" and recheck the path on the next line)
// dis c(username) // activate this code if you need to check your username
	
	* Naufal
	gl path "/Users/athonaufalridwan/Library/CloudStorage/Dropbox/J-PAL IFII Agent Banking Network (BM)/06 Data/c Full-Scale/06 Survey Data"


if "`c(username)'" == "jpals" {
        * Set 'path' to be main path
        gl  path "C:\Users\jpals\Dropbox\J-PAL IFII Agent Banking Network (BM)\06 Data\c Full-Scale\06 Survey Data"

 }

* Set the path
gl do            "$path/dofiles/agent_baseline"
gl dta           "$path/dtafiles/02 agent_baseline"
gl log           "$path/logfiles"
gl output        "$path/output"
gl raw           "$path/rawresponses/agent_baseline"

***IMPORTANT***

* Set local date
local date : di %tdDNCY daily("$S_DATE", "DMY") // this is the default code, it will automatically capture the current date
// loc date "DDMMYYYY" // only use this manual setting if you're running this code late than the supposed day
***IMPORTANT***

shell mkdir "$output/Agent Baseline - `date'/prelim_analysis"

*************
*IMPORT DATA*
*************
use "$dta/cleaned_baseline_agent_survey_`date'", clear  

/*Defining signal values

gen signal = .

replace signal = 51 if code_province == 1
replace signal = 49 if code_province == 2
replace signal = 49 if code_province == 3
replace signal = 49 if code_province == 4
replace signal = 49 if code_province == 5
replace signal = 45 if code_province == 6
replace signal = 48 if code_province == 7
replace signal = 48 if code_province == 8
replace signal = 49 if code_province == 9
replace signal = 49 if code_province == 10
replace signal = 48 if code_province == 11
replace signal = 46 if code_province == 12
replace signal = 48 if code_province == 13
replace signal = 46 if code_province == 14
replace signal = 46 if code_province == 15
replace signal = 43 if code_province == 16
replace signal = 49 if code_province == 17
replace signal = 46 if code_province == 18
replace signal = 49 if code_province == 19
replace signal = 46 if code_province == 20
replace signal = 46 if code_province == 21
replace signal = 48 if code_province == 22
replace signal = 47 if code_province == 23
replace signal = 44 if code_province == 24
replace signal = 44 if code_province == 25
replace signal = 48 if code_province == 26
replace signal = 48 if code_province == 27
replace signal = 48 if code_province == 28
replace signal = 47 if code_province == 29
replace signal = 48 if code_province == 30
replace signal = 46 if code_province == 31
replace signal = 48 if code_province == 32
replace signal = 47 if code_province == 33
replace signal = 48 if code_province == 34

gen posterior_prior = posterior - prior
gen signal_prior = signal - prior

gen posterior_per_prior = posterior / prior
gen signal_per_prior = signal / prior

*/

/*Run Regression

gen choose_transparency = (q_7a == 0) // AGENT WANT TO THE POSTER SENT TO THE CLIENTS
	
gen info_treat = (treatment_status == 1 | treatment_status ==3)


gen treat_signal_prior = signal_prior * info_treat

gen expected_up   = (signal_prior >= 0) // If + or equal to 0
gen expected_down = (signal_prior < 0) // if the number is -

gen treat_expected_up          = expected_up   * info_treat
gen treat_expected_down        = expected_down * info_treat

*/
preserve

keep if treatment_status == 2 | treatment_status == 3
	
*=============*
****# 1a #*****
	eststo  tab_1a: reg choose_transparency treat_signal_prior signal_prior i.strata, r
	sum     choose_transparency   if e(sample) == 1       
        estadd  local strata    "Yes"                                   : tab_1a
        estadd  local num_obs   = string(e(N),"%15.0fc")                : tab_1a

        sum     choose_transparency   if e(sample) == 1
        estadd  local dv_mean   = string(round(r(mean),0.001),"%9.3f")  : tab_1a
	

*==============================*
****#Table for 1a #*****
	
	*Export table (in Stata)
	esttab 	tab_1a,	///
			keep(treat_signal_prior signal_prior) mtitles b(3) se(3) star(* 0.10 ** 0.05 *** 0.01)

	* Export table (latex)
	#delimit ;
	local 	note 	"Robust standard errors in parentheses.
			The dependent variable is a dummy which indicates if an agent chose a marketing plan through which the bank will distribute the price poster directly to their clients.
			The main explanatory variable is a dummy which indicates if an agent received any information on an increased level in agent competition.
			All specifications control for strata fixed effects." ;
	#delimit cr
	
	esttab tab_1a using "$output/Agent Baseline - `date'/prelim_analysis/tab_1a.tex", replace ///
        style(tex) booktabs ///
        cells(b(fmt(3) star) se(par fmt(3))) ///
        collabels(none) starlevels(* 0.10 ** 0.05 *** 0.01) ///
        keep(treat_signal_prior signal_prior) ///       
        varlabels(treat_signal_prior "Treat x (Signal - Prior)" signal_prior "(Signal - Prior)") ///
        mgroups("Choosing transparency", pattern(1 0) prefix(\multicolumn{@span}{c}{) suffix(}) span) ///
        prehead(`"\begin{table}[htbp]\centering"' `"\caption{The treatment effect of giving information to agents}"' `"\begin{tabular}{l*{1}{c}}"' `"\toprule"') ///
        title("\text{The treatment effect of giving information to agents}") mlabels(none) nonum ///
        postfoot(`"\bottomrule"' `"\end{tabular}"' `"\begin{tablenotes}"' `"\setlength\labelsep{0pt}"' `"\item \textit{Note:} `note' "' `"\end{tablenotes}"' `"\end{table}"') ///
        stats(num_obs strata dv_mean, label("Observations" "Strata fixed effects" "Mean of dependent variable") fmt(%15.0fc 0 0))

*=============*
****# 1b #*****
        eststo  tab_1b: reg choose_transparency treat_expected_up treat_expected_down signal_prior i.strata, r
        sum     choose_transparency   if e(sample) == 1       
        estadd  local strata    "Yes"                                   : tab_1b
        estadd  local num_obs   = string(e(N),"%15.0fc")                : tab_1b

        sum     choose_transparency   if e(sample) == 1
        estadd  local dv_mean   = string(round(r(mean),0.001),"%9.3f")  : tab_1b
        

*==============================*
****#Table for 1b #*****
        
        *Export table (in Stata)
        esttab  tab_1b, ///
                        keep(treat_expected_up treat_expected_down signal_prior) mtitles b(3) se(3) star(* 0.10 ** 0.05 *** 0.01)

        * Export table (latex)
        #delimit ;
        local   note    "Robust standard errors in parentheses.
                        The dependent variable is a dummy which indicates if an agent chose a marketing plan through which the bank will distribute the price poster directly to their clients.
                        The main explanatory variables are a dummy which indicates if signal-prior is positive or negative.
                        All specifications control for strata fixed effects." ;
        #delimit cr
        
        esttab tab_1b using "$output/Agent Baseline - `date'/prelim_analysis/tab_1b.tex", replace ///
        style(tex) booktabs ///
        cells(b(fmt(3) star) se(par fmt(3))) ///
        collabels(none) starlevels(* 0.10 ** 0.05 *** 0.01) ///
        keep(treat_expected_up treat_expected_down signal_prior) ///       
        varlabels(treat_expected_up "Treat x Expect Competition Up" treat_expected_down "Treat x Expect Competition Down" signal_prior "(Signal - Prior)") ///
        mgroups("Choosing transparency", pattern(1 0) prefix(\multicolumn{@span}{c}{) suffix(}) span) ///
        prehead(`"\begin{table}[htbp]\centering"' `"\caption{The treatment effect of giving information to agents}"' `"\begin{tabular}{l*{1}{c}}"' `"\toprule"') ///
        title("\text{The treatment effect of giving information to agents}") mlabels(none) nonum ///
        postfoot(`"\bottomrule"' `"\end{tabular}"' `"\begin{tablenotes}"' `"\setlength\labelsep{0pt}"' `"\item \textit{Note:} `note' "' `"\end{tablenotes}"' `"\end{table}"') ///
        stats(num_obs strata dv_mean, label("Observations" "Strata fixed effects" "Mean of dependent variable") fmt(%15.0fc 0 0))


*=============*
****# IV #*****	
	
	* Regression (pooled if control=treatment)
	eststo 	tab_second_stage: ivregress 2sls choose_transparency (posterior=treat_signal_prior) signal_prior prior i.strata, r


	sum 	choose_transparency	if e(sample) == 1 	
	estadd 	local strata 	"Yes"					: tab_second_stage
	estadd 	local num_obs 	= string(e(N),"%15.0fc")		: tab_second_stage
	estadd  local mean	= string(round(r(mean),0.001),"%9.3f")	: tab_second_stage
	
	estat firststage	
	mat fstat=r(singleresults)
	estadd scalar fstat=fstat[1,4], replace							: tab_second_stage
	
	* Export table (in Stata)
	esttab 	tab_second_stage,	///
			keep(posterior signal_prior prior) mtitles b(3) se(3) star(* 0.10 ** 0.05 *** 0.01)

	* Export table (latex)

	#delimit ;
	local 	note 	"Robust standard errors in parentheses.
					The dependent variable is a dummy which indicates if an agent chose a marketing plan through which the bank will distribute the price poster directly to their clients.
					The main explanatory variable is a dummy which indicates if an agent received any information on an increased level in agent competition.
					All specifications control for strata fixed effects." ;
	#delimit cr
	
esttab tab_second_stage using "$output/Agent Baseline - `date'/prelim_analysis/tab_second_stage.tex", replace ///
style(tex) booktabs ///
cells(b(fmt(3) star) se(par fmt(3))) ///
collabels(none) starlevels(* 0.10 ** 0.05 *** 0.01) ///
keep(posterior signal_prior prior) ///
varlabels(posterior "Posterior" signal_prior "(Signal - Prior)" prior "Prior") ///
mgroups("Choosing transparency", pattern(1 0) prefix(\multicolumn{@span}{c}{) suffix(}) span) ///
prehead(`"\begin{table}[htbp]\centering"' `"\caption{Second stage results}"' `"\begin{tabular}{l*{3}{c}}"' `"\toprule"') ///
title("\text{Second stage results}") mlabels(none) nonum ///
postfoot(`"\bottomrule"' `"\end{tabular}"' `"\begin{tablenotes}"' `"\setlength\labelsep{0pt}"' `"\item \textit{Note:} `note' "' `"\end{tablenotes}"' `"\end{table}"') ///
stats(num_obs strata mean fstat, label("Observations" "Strata fixed effects" "Mean of dependent var" "First-stage F test") fmt(%15.0fc))


*=======================*
****# IV Breakdown #*****	

****# First stage #*****
        eststo  tab_first_stage: reg posterior treat_signal_prior signal_prior prior i.strata, r
        sum     choose_transparency   if e(sample) == 1       
        estadd  local strata    "Yes"                                   : tab_first_stage
        estadd  local num_obs   = string(e(N),"%15.0fc")                : tab_first_stage

        sum     choose_transparency   if e(sample) == 1
        estadd  local dv_mean   = string(round(r(mean),0.001),"%9.3f")  : tab_first_stage
        

*==============================*
****#Table for first stage #*****
        
        *Export table (in Stata)
        esttab  tab_first_stage, ///
                        keep(treat_signal_prior signal_prior prior) mtitles b(3) se(3) star(* 0.10 ** 0.05 *** 0.01)

        * Export table (latex)
        #delimit ;
        local   note    "Robust standard errors in parentheses.
                        All specifications control for strata fixed effects." ;
        #delimit cr
        
        esttab tab_first_stage using "$output/Agent Baseline - `date'/prelim_analysis/tab_first_stage.tex", replace ///
        style(tex) booktabs ///
        cells(b(fmt(3) star) se(par fmt(3))) ///
        collabels(none) starlevels(* 0.10 ** 0.05 *** 0.01) ///
        keep(treat_signal_prior signal_prior prior) ///       
        varlabels(treat_signal_prior "Treat x (Signal - Prior)" signal_prior "(Signal - Prior)" prior "Prior") ///
        mgroups("Posterior", pattern(1 0) prefix(\multicolumn{@span}{c}{) suffix(}) span) ///
        prehead(`"\begin{table}[htbp]\centering"' `"\caption{First stage results}"' `"\begin{tabular}{l*{1}{c}}"' `"\toprule"') ///
        title("\text{First stage results}") mlabels(none) nonum ///
        postfoot(`"\bottomrule"' `"\end{tabular}"' `"\begin{tablenotes}"' `"\setlength\labelsep{0pt}"' `"\item \textit{Note:} `note' "' `"\end{tablenotes}"' `"\end{table}"') ///
        stats(num_obs strata dv_mean, label("Observations" "Strata fixed effects" "Mean of dependent variable") fmt(%15.0fc 0 0))


restore

*********************************************************************************
************************** FIGURE ON BELIEF UPDATING (ZOE's PAPER) **************
*********************************************************************************
local date : di %tdDNCY daily("$S_DATE", "DMY") // this is the def
shell mkdir "$output/Agent Baseline - `date'/prelim_analysis"
set scheme plotplain

// Treatment 1

binscatter posterior_prior signal_prior if treatment_status==1, ///
    msymbol(circle) nquantiles(40) line(none) ///
    savedata(`"$output/Agent Baseline - `date'/prelim_analysis/binned_treatment_1"') replace
preserve
clear
qui do `"$output/Agent Baseline - `date'/prelim_analysis/binned_treatment_1.do"'
save `"$output/Agent Baseline - `date'/prelim_analysis/binned_treatment_1.dta"', replace
restore
append using `"$output/Agent Baseline - `date'/prelim_analysis/binned_treatment_1.dta"', gen(binned_tag)




/*binscatter posterior_prior signal_prior if treatment_status==1, msymbol(circle) savedata("$output/Agent Baseline - `date'/prelim_analysis/binned_treatment_1") replace line(none) nquantiles(40)

clear
qui do "$output/Agent Baseline - `date'/prelim_analysis/binned_treatment_1"
save "$output/Agent Baseline - `date'/prelim_analysis/binned_treatment_1",replace
restore

append using "$output/Agent Baseline - `date'/prelim_analysis/binned_treatment_1", gen(binned_treatment_1)
*/
reg posterior_prior signal_prior i.strata if treatment_status==1, r noconstant
matrix b = e(b)
local beta = string(round(b[1,1],.001),"%15.3fc")
matrix p = e(V)
local se = string(round(sqrt(p[1,1]),.001),"%15.3fc")
local N = string(e(N),"%15.0fc")

local t = _b[signal_prior]/_se[signal_prior]
local pvalue =2*ttail(e(df_r),abs(`t'))
local stars = ""
if `pvalue' < 0.01 {
local stars = "***"
}
else if `pvalue' < 0.05 {
local stars = "**"
}
else if `pvalue' < 0.1 {
local stars = "*"
}

twoway scatter posterior_prior signal_prior if treatment_status == 1 & inrange(signal_prior, -100, 100) & inrange(posterior_prior, -40, 40), msymbol(circle) msize(tiny) mc(dimgray) ///
|| lfit posterior_prior signal_prior if binned_treatment_1 == 1 & inrange(signal_prior, -100, 100) & inrange(posterior_prior, -40, 40), sort lp(solid) lwidth(medium) lc(emerald) ///
|| scatter posterior_prior signal_prior if binned_treatment_1 == 1 & inrange(signal_prior, -100, 100) & inrange(posterior_prior, -40, 40), msymbol(diamond) mlcolor(emerald) mlwidth(thin) msize(medsmall) mc(emerald) ///
xline(0, lpattern(shortdash) lwidth(vthin) lcolor(gray)) yline(0, lpattern(shortdash) lwidth(vthin) lcolor(gray)) ///
xlabel(-100(20)100, nogrid labsize(medium)) graphregion(color(white)) ylabel(-40(10)40, nogrid labsize(medium)) graphregion(color(white)) ///
xtit((Signal - Prior), size(medium) height(7)) ytit((Posterior - Prior), size(medium) height(7)) ///
xtitle("(Signal - Prior)") ytitle("(Posterior - Prior)") ///
legend(order(1 3 2) label(1 "Raw data") label(2 "OLS") label(3 "Binned scatter") ring(0) pos(11) col(1) size(small) lpattern(solid) lcolor(emerald)) ///
text(-30 80 "Slope = `beta'`stars'" "SE = `se'    " "N = `N'    ", size(medsmall) just(right)) ///
name(treatment_1, replace) ///
title("Treatment 1", size(medium)) ///
subtitle("(Info on competition; no offer of marketing choice)", size(medium))

// Treatment 3

preserve
binscatter posterior_prior signal_prior if treatment_status==3, msymbol(circle) savedata("$output/Agent Baseline - `date'/prelim_analysis/binned_treatment_3") replace line(none) nquantiles(40)
clear
qui do "$output/Agent Baseline - `date'/prelim_analysis/binned_treatment_3"
save "$output/Agent Baseline - `date'/prelim_analysis/binned_treatment_3",replace
restore

append using "$output/Agent Baseline - `date'/prelim_analysis/binned_treatment_3", gen(binned_treatment_3)

reg posterior_prior signal_prior i.strata if treatment_status==3, r noconstant
matrix b = e(b)
local beta = string(round(b[1,1],.001),"%15.3fc")
matrix p = e(V)
local se = string(round(sqrt(p[1,1]),.001),"%15.3fc")
local N = string(e(N),"%15.0fc")

local t = _b[signal_prior]/_se[signal_prior]
local pvalue =2*ttail(e(df_r),abs(`t'))
local stars = ""
if `pvalue' < 0.01 {
local stars = "***"
}
else if `pvalue' < 0.05 {
local stars = "**"
}
else if `pvalue' < 0.1 {
local stars = "*"
}

twoway scatter posterior_prior signal_prior if treatment_status==3 & inrange(signal_prior, -100, 100) & inrange(posterior_prior, -40, 40), msymbol(circle) msize(tiny) mc(dimgray) ///
|| lfit posterior_prior signal_prior if binned_treatment_3==1 & inrange(signal_prior, -100, 100) & inrange(posterior_prior, -40, 40), sort lp(solid) lwidth(medium) lc(navy) ///
|| scatter posterior_prior signal_prior if binned_treatment_3==1 & inrange(signal_prior, -100, 100) & inrange(posterior_prior, -40, 40), msymbol(diamond) mlcolor(navy) mlwidth(thin) msize(medsmall) mc(navy) ///
xline(0, lpattern(shortdash) lwidth(vthin) lcolor(gray)) yline(0, lpattern(shortdash) lwidth(vthin) lcolor(gray)) ///
xlabel(-100(20)100, nogrid labsize(medium)) graphregion(color(white)) ylabel(-40(10)40, nogrid labsize(medium)) graphregion(color(white)) ///
xtit((Signal - Prior), size(medium) height(7)) ytit((Posterior - Prior), size(medium) height(7)) ///
xtitle("(Signal - Prior)") ytitle("(Posterior - Prior)") ///
legend(order(1 3 2) label(1 "Raw data") label(2 "OLS") label(3 "Binned scatter") ring(0) pos(11) col(1) size(small) lpattern(solid) lcolor(navy)) ///
text(-30 80 "Slope = `beta'`stars'" "SE = `se'    " "N = `N'    ", size(medsmall) just(right)) ///
name(treatment_3, replace) ///
title("Treatment 3", size(medium)) ///
subtitle("(Info on competition; marketing choice offer)", size(medium))

// Combine graphs

grc1leg2 treatment_1 treatment_3, loff ///
cols(2) ///
xcommon ycommon ///
title("Belief updating: Information on competition", size(large) span) ///
imargin(2 2 2 2) ///
graphregion(margin(medsmall)) ///
xsize(12) ysize(6)
graph export "$output/Agent Baseline - `date'/prelim_analysis/belief_updating_binscatter.png", as(png) replace

*********************************************************************************
************************** TREATMENT VS CONTROL *********************************
*********************************************************************************

gen received_info = (treatment_status == 1 | treatment_status == 3)

// Binned treatment (pooled)

preserve
binscatter posterior_prior signal_prior if received_info==1, msymbol(circle) savedata("$output/Agent Baseline - `date'/prelim_analysis/binned_treatment") replace line(none) nquantiles(40)
clear
qui do "$output/Agent Baseline - `date'/prelim_analysis/binned_treatment"
save "$output/Agent Baseline - `date'/prelim_analysis/binned_treatment",replace
restore

append using "$output/Agent Baseline - `date'/prelim_analysis/binned_treatment", gen(binned_treatment)

reg posterior_prior signal_prior i.strata if received_info==1, r noconstant
matrix b = e(b)
local beta = string(round(b[1,1],.001),"%15.3fc")
matrix p = e(V)
local se = string(round(sqrt(p[1,1]),.001),"%15.3fc")
local N = string(e(N),"%15.0fc")

local t = _b[signal_prior]/_se[signal_prior]
local pvalue =2*ttail(e(df_r),abs(`t'))
local stars = ""
if `pvalue' < 0.01 {
local stars = "***"
}
else if `pvalue' < 0.05 {
local stars = "**"
}
else if `pvalue' < 0.1 {
local stars = "*"
}

// Binned control

preserve
binscatter posterior_prior signal_prior if received_info==0, msymbol(circle) savedata("$output/Agent Baseline - `date'/prelim_analysis/binned_control") replace line(none) nquantiles(40)
clear
qui do "$output/Agent Baseline - `date'/prelim_analysis/binned_control"
save "$output/Agent Baseline - `date'/prelim_analysis/binned_control",replace
restore

append using "$output/Agent Baseline - `date'/prelim_analysis/binned_control", gen(binned_control)

reg posterior_prior signal_prior i.strata if received_info==0, r noconstant
matrix b = e(b)
local beta_c = string(round(b[1,1],.001),"%15.3fc")
matrix p = e(V)
local se_c = string(round(sqrt(p[1,1]),.001),"%15.3fc")
local N_c = string(e(N),"%15.0fc")

local t = _b[signal_prior]/_se[signal_prior]
local pvalue =2*ttail(e(df_r),abs(`t'))
local stars = ""
if `pvalue' < 0.01 {
local stars = "***"
}
else if `pvalue' < 0.05 {
local stars = "**"
}
else if `pvalue' < 0.1 {
local stars = "*"
}

twoway scatter posterior_prior signal_prior if binned_control == 1 & inrange(signal_prior, -100, 100) & inrange(posterior_prior, -40, 40), msymbol(circle) msize(medium) mc(dimgray) ///
|| lfit posterior_prior signal_prior if binned_control == 1 & inrange(signal_prior, -100, 100) & inrange(posterior_prior, -40, 40), sort lp(solid) lwidth(medium) lc(dimgray) ///
|| scatter posterior_prior signal_prior if binned_control == 1 & inrange(signal_prior, -100, 100) & inrange(posterior_prior, -40, 40), msymbol(circle) mlcolor(dimgray) mlwidth(thin) msize(medsmall) mc(dimgray) ///
|| scatter posterior_prior signal_prior if binned_treatment == 1 & inrange(signal_prior, -100, 100) & inrange(posterior_prior, -40, 40), msymbol(circle) msize(medium) mc(dimgray) ///
|| lfit posterior_prior signal_prior if binned_treatment == 1 & inrange(signal_prior, -100, 100) & inrange(posterior_prior, -40, 40), sort lp(solid) lwidth(medium) lc(navy) ///
|| scatter posterior_prior signal_prior if binned_treatment == 1 & inrange(signal_prior, -100, 100) & inrange(posterior_prior, -40, 40), msymbol(diamond) mlcolor(navy) mlwidth(thin) msize(medsmall) mc(navy) ///
xline(0, lpattern(shortdash) lwidth(vthin) lcolor(gray)) yline(0, lpattern(shortdash) lwidth(vthin) lcolor(gray)) ///
xlabel(-100(20)100, nogrid labsize(medium)) graphregion(color(white)) ylabel(-40(10)40, nogrid labsize(medium)) graphregion(color(white)) ///
xtit((Signal - Prior), size(medium) height(7)) ytit((Posterior - Prior), size(medium) height(7)) ///
xtitle("(Signal - Prior)") ytitle("(Posterior - Prior)") ///
legend(order(1 6) label(1 "Control group") label(6 "Treatment group") ring(0) pos(11) col(1) size(medium) lpattern(solid) lcolor(black)) ///
text(-20 65 "Slope_treatment = `beta'`stars'" "SE_treatment = `se'    " "N_treatment = `N'    " "Slope_control = `beta_c'`stars'" "SE_control = `se_c'    " "N_control = `N_c'    ", size(medsmall) just(right)) ///
name(pooled, replace) ///
title("Treatment (pooled) vs control (pooled)", size(medium))

graph export "$output/Agent Baseline - `date'/prelim_analysis/belief_updating_binscatter_c&t.png", as(png) replace



