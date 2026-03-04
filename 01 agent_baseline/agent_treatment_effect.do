clear all
set more off

*****************************************
**--------------DATA PATH--------------**
*****************************************

// gl user = c(username)

* Set your username here (change your "$user" == "[your username here]" and recheck the path on the next line)
// dis c(username) // activate this code if you need to check your username

* Naufal
//  gl path "/Users/athonaufalridwan/Library/CloudStorage/Dropbox/J-PAL IFII Agent Banking Network (BM)/06 Data/c Full-Scale"

if "`c(username)'" == "jpals" {
        * Set 'path' to be main path
        gl  path "C:\Users\jpals\Dropbox\J-PAL IFII Agent Banking Network (BM)\06 Data\c Full-Scale"
 }
 
* Set the path
gl dta           "$path/06 Survey Data/dtafiles/02 agent_baseline"
gl output        "$path/06 Survey Data/output"

***IMPORTANT***

*************
*IMPORT DATA*
*************
use "$dta/cleaned_baseline_agent_survey_26012026", clear  

gen choose_transparency = (q_7a == 0) if treatment_status == 2 | treatment_status == 3
gen received_info = (treatment_status == 3) if treatment_status == 2 | treatment_status == 3

eststo  treatment_effect_first: reg choose_transparency received_info i.strata, r 
        
        sum     choose_transparency   if e(sample) == 1       
        estadd  local strata    "Yes"                                   : treatment_effect_first
        estadd  local num_obs   = string(e(N),"%15.0fc")                : treatment_effect_first

        sum     choose_transparency   if e(sample) == 1 & treatment_status == 2
        estadd  local dv_mean   = string(round(r(mean),0.001),"%9.3f")  : treatment_effect_first

esttab  treatment_effect_first, keep(received_info) mtitles b(3) se(3) star(* 0.10 ** 0.05 *** 0.01)

        #delimit ;
        local   note    "Robust standard errors in parentheses. 
                        The dependent variable is a dummy which indicates if an agent chose a marketing plan through which the bank will distribute the price poster directly to their clients.
                        The main explanatory variable is a dummy which indicates if an agent received information on an increased level in agent competition.
                        All specifications control for strata fixed effects." ;
        #delimit cr
        
        esttab treatment_effect_first using "$output\\competition_table_treatment_effect_first.tex", replace ///
        style(tex) booktabs ///
        cells(b(fmt(3) star) se(par fmt(3))) ///
        collabels(none) starlevels(* 0.10 ** 0.05 *** 0.01) ///
        keep(received_info) ///
        varlabels(received_info "Treatment (info)") ///
        mgroups("Choosing transparency marketing plan", pattern(1 0) prefix(\multicolumn{@span}{c}{) suffix(}) span) ///
        prehead(`"\begin{table}[htbp]\centering"' `"\caption{The treatment effect of giving information to agents}"' `"\begin{tabular}{l*{2}{c}}"' `"\toprule"') ///
        title("\text{The treatment effect of giving information to agents}") mlabels(none) nonum ///
        postfoot(`"\bottomrule"' `"\end{tabular}"' `"\begin{tablenotes}"' `"\setlength\labelsep{0pt}"' `"\item \textit{Note:} `note' "' `"\end{tablenotes}"' `"\end{table}"') ///
        stats(num_obs strata dv_mean, label("Observations" "Strata fixed effects" "Mean of dependent variable (control group)") fmt(%15.0fc 0 0))
    


gen interaction = signal_prior * received_info

eststo  treatment_effect_second: reg choose_transparency interaction signal_prior i.strata, r 
        
        sum     choose_transparency   if e(sample) == 1       
        estadd  local strata    "Yes"                                   : treatment_effect_second
        estadd  local num_obs   = string(e(N),"%15.0fc")                : treatment_effect_second

        sum     choose_transparency   if e(sample) == 1 & treatment_status == 2
        estadd  local dv_mean   = string(round(r(mean),0.001),"%9.3f")  : treatment_effect_second


esttab  treatment_effect_second, keep(interaction signal_prior) mtitles b(3) se(3) star(* 0.10 ** 0.05 *** 0.01)

        * Export table (latex)

        #delimit ;
        local   note    "Robust standard errors in parentheses. 
                        The dependent variable is a dummy which indicates if an agent chose a marketing plan through which the bank will distribute the price poster directly to their clients.
                        The main explanatory variable is a dummy which indicates if an agent received information on an increased level in agent competition.
                        All specifications control for strata fixed effects." ;
        #delimit cr
        
        esttab treatment_effect_second using "$output\\competition_table_treatment_effect_second.tex", replace ///
        style(tex) booktabs ///
        cells(b(fmt(3) star) se(par fmt(3))) ///
        collabels(none) starlevels(* 0.10 ** 0.05 *** 0.01) ///
        keep(interaction signal_prior) ///
        varlabels(interaction "(Signal - Prior) x Treated" signal_prior "(Signal - Prior") ///
        mgroups("Choosing transparency marketing plan", pattern(1 0) prefix(\multicolumn{@span}{c}{) suffix(}) span) ///
        prehead(`"\begin{table}[htbp]\centering"' `"\caption{The treatment effect of giving information to agents}"' `"\begin{tabular}{l*{2}{c}}"' `"\toprule"') ///
        title("\text{The treatment effect of giving information to agents}") mlabels(none) nonum ///
        postfoot(`"\bottomrule"' `"\end{tabular}"' `"\begin{tablenotes}"' `"\setlength\labelsep{0pt}"' `"\item \textit{Note:} `note' "' `"\end{tablenotes}"' `"\end{table}"') ///
        stats(num_obs strata dv_mean, label("Observations" "Strata fixed effects" "Mean of dependent variable (control group)") fmt(%15.0fc 0 0))


