*===================================================*
* REGRESSION - Agent Survey (Baseline)
* Author: Naufal
* Last modified: 30 January 2026
* Last modified by: Naufal
* Stata version: 16
*===================================================*

clear all
set more off

*****************************************
**--------------DATA PATH--------------**
*****************************************


*Naufal
 gl path "/Users/athonaufalridwan/Library/CloudStorage/Dropbox/J-PAL IFII Agent Banking Network (BM)/06 Data/c Full-Scale"

/*if "`c(username)'" == "jpals" {
        * Set 'path' to be main path
        gl  path "C:\Users\jpals\Dropbox\J-PAL IFII Agent Banking Network (BM)\06 Data\c Full-Scale"
 }
 */
 
* Set the path
gl dta           "$path/06 Survey Data/dtafiles/02 agent_baseline"
gl output        "$path/06 Survey Data/output"

***IMPORTANT***

*************
*IMPORT DATA*
*************
use "$path/06 Survey Data/dtafiles/02 agent_baseline/cleaned_baseline_agent_survey_26012026.dta" 


	gen choose_transparency = 0
	replace choose_transparency = 1 if q_7a == 0
	
	gen posterior_prior_pct = posterior_prior / 100
	gen signal_prior_pct    = signal_prior / 100

	gen treat = 0
	replace treat = 1 if treatment_status == 3

	gen information = 0
	replace information = 1 if treatment_status == 3

	gen treat_signal_prior = signal_prior * information

	gen expected_up   = signal_prior > 0
	gen expected_down = signal_prior < 0

	gen treat_expected_up   = expected_up   * treat
	gen treat_expected_down = expected_down * treat


	keep if treatment_status == 2 | treatment_status == 3
	
*=============*
****# 1a #*****
	eststo  tab_1a:reg choose_transparency treat_signal_prior prior i.strata, r
	sum     choose_transparency   if e(sample) == 1       
        estadd  local strata    "Yes"                                   : tab_1a
        estadd  local num_obs   = string(e(N),"%15.0fc")                : tab_1a

        sum     choose_transparency   if e(sample) == 1 & treatment_status == 2
        estadd  local dv_mean   = string(round(r(mean),0.001),"%9.3f")  : tab_1a
	
*=============*
****# 1b #*****
	eststo  tab_1b:reg choose_transparency treat_signal_prior i.strata, r
	sum     choose_transparency   if e(sample) == 1       
        estadd  local strata    "Yes"                                   : tab_1b
        estadd  local num_obs   = string(e(N),"%15.0fc")                : tab_1b

        sum     choose_transparency   if e(sample) == 1 & treatment_status == 2
        estadd  local dv_mean   = string(round(r(mean),0.001),"%9.3f")  : tab_1b
	
*==============================*
****#Table for 1a and 1b  #*****
	#delimit ;
	local note "Robust standard errors in parentheses.
	The dependent variable is a dummy which indicates if an agent chose a marketing plan through which the bank will distribute the price poster directly to their clients.
	The main explanatory variables are agents' expectations about competition.
	All specifications control for strata fixed effects." ;
	#delimit cr

esttab tab_1a tab_1b using "$path/06 Survey Data/output/tab_1a_1b.tex", replace ///
    style(tex) booktabs ///
    cells(b(fmt(3) star) se(par fmt(3))) ///
    collabels(none) ///
    starlevels(* 0.10 ** 0.05 *** 0.01) ///
    keep(treat_signal_prior) ///
    varlabels( ///
        treat_signal_prior   "Treatment (info)" ///
    ) ///
   mlabels("(choose_transparency)" "(choose_transparency_prior)") ///
    prehead(`"\begin{table}[htbp]\centering"' ///
            `"\caption{The treatment effect of giving information to agents}"' ///
            `"\begin{tabular}{l*{2}{c}}"' ///
            `"\toprule"') ///
    nonum ///
    postfoot(`"\bottomrule"' ///
             `"\end{tabular}"' ///
             `"\begin{tablenotes}"' ///
             `"\setlength\labelsep{0pt}"' ///
             `"\item \textit{Note:} `note' "' ///
             `"\end{tablenotes}"' ///
             `"\end{table}"') ///
    stats(num_obs strata dv_mean, ///
          label("Observations" "Strata fixed effects" "Mean of dependent variable (control group)") ///
          fmt(%15.0fc 0 0))

		  
*=============*
****# 1c #*****
	eststo  tab_1c: reg choose_transparency treat_expected_up treat_expected_down prior i.strata, r
	sum     choose_transparency   if e(sample) == 1       
        estadd  local strata    "Yes"                                   : tab_1c
        estadd  local num_obs   = string(e(N),"%15.0fc")                : tab_1c

        sum     choose_transparency   if e(sample) == 1 & treatment_status == 2
        estadd  local dv_mean   = string(round(r(mean),0.001),"%9.3f")  : tab_1c

*=============*
****# 1d #*****
	eststo  tab_1d: reg choose_transparency treat_expected_up treat_expected_down i.strata, r
	sum     choose_transparency   if e(sample) == 1       
        estadd  local strata    "Yes"                                   : tab_1d
        estadd  local num_obs   = string(e(N),"%15.0fc")                : tab_1d

        sum     choose_transparency   if e(sample) == 1 & treatment_status == 2
        estadd  local dv_mean   = string(round(r(mean),0.001),"%9.3f")  : tab_1d
		
*==============================*
****#Table for 1c and 1d  #*****
	#delimit ;
	local note "Robust standard errors in parentheses.
	The dependent variable is a dummy which indicates if an agent chose a marketing plan through which the bank will distribute the price poster directly to their clients.
	The main explanatory variables are agents' expectations about competition.
	All specifications control for strata fixed effects." ;
	#delimit cr

esttab tab_1c tab_1d using "$path/06 Survey Data/output/tab_1c_1d.tex", replace ///
    style(tex) booktabs ///
    cells(b(fmt(3) star) se(par fmt(3))) ///
    collabels(none) ///
    starlevels(* 0.10 ** 0.05 *** 0.01) ///
    keep(treat_expected_up treat_expected_down) ///
    varlabels( ///
        treat_expected_up   "Expected competition up" ///
        treat_expected_down "Expected competition down" ///
    ) ///
    mlabels("Choose transparency" "choose_transparency_prior") ///
    prehead(`"\begin{table}[htbp]\centering"' ///
            `"\caption{The treatment effect of giving information to agents}"' ///
            `"\begin{tabular}{l*{2}{c}}"' ///
            `"\toprule"') ///
    nonum ///
    postfoot(`"\bottomrule"' ///
             `"\end{tabular}"' ///
             `"\begin{tablenotes}"' ///
             `"\setlength\labelsep{0pt}"' ///
             `"\item \textit{Note:} `note' "' ///
             `"\end{tablenotes}"' ///
             `"\end{table}"') ///
    stats(num_obs strata dv_mean, ///
          label("Observations" "Strata fixed effects" "Mean of dependent variable (control group)") ///
          fmt(%15.0fc 0 0))
