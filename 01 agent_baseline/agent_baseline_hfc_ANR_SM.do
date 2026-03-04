*===================================================*
* Full-Scale - Agent Survey (Baseline)
* HFC
* Author: Riko
* Last modified: 17 August 2025
* Last modified by: Muthia
* Stata version: 16
*===================================================*

clear all
set more off

*****************************************
**--------------DATA PATH--------------**
*****************************************

// gl user = c(username)

* Set your username here (change your "$user" == "[your username here]" and recheck the path on the next line)
// dis c(username) // activate this code if you need to check your username

* Naufal
	gl path "/Users/athonaufalridwan/Library/CloudStorage/Dropbox/J-PAL IFII Agent Banking Network (BM)/06 Data/c Full-Scale"

if "`c(username)'" == "jpals" {
        * Set 'path' to be main path
        gl  path "C:\Users\jpals\Dropbox\J-PAL IFII Agent Banking Network (BM)\06 Data\c Full-Scale"
 }

* Set the path
gl do            "$path/06 Survey Data/dofiles/agent_baseline"
gl dta           "$path/06 Survey Data/dtafiles"
gl log           "$path/06 Survey Data/logfiles"
gl output        "$path/06 Survey Data/output"
gl raw           "$path/06 Survey Data/rawresponses"

***IMPORTANT***

* Set local date
local date : di %tdDNCY daily("$S_DATE", "DMY") //this is the default code, it will automatically capture the current date
//local date "DDMMYYYY" // only use this manual setting if you're running this code late than the supposed day


*************
*IMPORT DATA*
*************
use "$dta/02 agent_baseline/cleaned_baseline_agent_survey_`date'.dta", clear 		

*************
*HFC*
*************

*--------------------------------------------------------------------------
** Survey duration
*--------------------------------------------------------------------------
preserve

/*	sum total_duration

	qui su total_duration, det
	local total_before = r(N)

	keep if total_duration < 120 // M: we only keep the durations above 10 minutes and below two hours just to keep those agents who take a break during filling out the questionaire

//	keep if total_duration > 10  & total_duration < 120 // M: we only keep the durations above 10 minutes and below two hours just to keep those agents who take a break during filling out the questionaire

	qui su total_duration, detail
	return list

	local total_after = r(N)
	local dropped_obs = `total_before' - `total_after'

	* Histogram
	gen td_hist = round(total_duration, 1)
	qui sum td_hist,det
	*ssc install blindschemes // if plotplain error
	set scheme jpalfull

		histogram td_hist, percent fcolor(emerald*0.30) ///
	   	lcolor(emerald*0.55) ///
		discrete ///
		xlabel(0(10)100) ///
		xtitle(" ", size(small)) ///
		ytitle("Percentage of agents", size(small)) ///
		title("Survey duration (in minutes)") ///
		note("Note:" "Total agents = `: di %6.0fc `r(N)''" "Survey duration above 100 minutes is dropped" "Number of dropped observations = `dropped_obs'", size(small))
		
	graph export "$output/Agent Baseline - `date'/1 - survey_duration_hist.png", as(png) replace

restore
*/
***************
*DATA ANALYSIS*
***************
gen agents_n = _n  // for notes on total N agents
drop if informed_consent == 0 // drop people who refuse to participate in the survey

*** Prior & posterior 

* Create density plots for priors
	local date : display %tdDNCY daily("$S_DATE", "DMY")
	capture shell mkdir -p "$output/Agent Baseline - `date'"

qui sum agents_n if treatment_status==0
kdensity prior if treatment_status==0, nodraw name(control_prior_density, replace) ///
		 title("Control group", size(regular)) ylabel(0(0.005)0.02) xtitle("Estimated changes in N agents (%)", size(small)) ///
		 note("Total agents = `r(N)'", size(small))

qui sum agents_n if treatment_status==1
kdensity prior	if treatment_status==1, name(treatment_1_prior_density, replace) ///
		 title("Treatment 1", size(regular)) ylabel(0(0.005)0.02) xtitle("Estimated changes in N agents (%)", size(small)) ///
		 note("Total agents = `r(N)'", size(small))

qui sum agents_n if treatment_status==2
kdensity prior	if treatment_status==2, name(treatment_2_prior_density, replace) ///
		 title("Treatment 2", size(regular)) ylabel(0(0.005)0.02) xtitle("Estimated changes in N agents (%)", size(small)) ///
		 note("Total agents = `r(N)'", size(small))

qui sum agents_n if treatment_status==3
kdensity prior	if treatment_status==3, name(treatment_3_prior_density, replace) ///
		 title("Treatment 3", size(regular)) ylabel(0(0.005)0.02) xtitle("Estimated changes in N agents (%)", size(small)) ///
		 note("Total agents = `r(N)'", size(small))

qui sum agents_n if treatment_status==4
kdensity prior	if treatment_status==4, name(treatment_4_prior_density, replace) ///
		 title("Treatment 4", size(regular)) ylabel(0(0.005)0.02) xtitle("Estimated changes in N agents (%)", size(small)) ///
		 note("Total agents = `r(N)'", size(small))

graph combine control_prior_density treatment_1_prior_density treatment_2_prior_density treatment_3_prior_density treatment_4_prior_density, cols(2) ///
	  title("Priors about expected changes in competition", size(regular))
graph export "$output/Agent Baseline - `date'/competition_kdensity_priors.png", as(png) replace

* Create density plots for posteriors
qui sum agents_n if treatment_status==0
kdensity posterior if treatment_status==0, nodraw name(control_posterior_density, replace) ///
		 title("Control group", size(regular)) ylabel(0(0.005)0.02) xtitle("Estimated changes in N agents (%)", size(small)) ///
		 note("Total agents = `r(N)'", size(small))

qui sum agents_n if treatment_status==1
kdensity posterior	if treatment_status==1, name(treatment_1_posterior_density, replace) ///
		 title("Treatment 1", size(regular)) ylabel(0(0.005)0.02) xtitle("Estimated changes in N agents (%)", size(small)) ///
		 note("Total agents = `r(N)'", size(small))

qui sum agents_n if treatment_status==2
kdensity posterior	if treatment_status==2, name(treatment_2_posterior_density, replace) ///
		 title("Treatment 2", size(regular)) ylabel(0(0.005)0.02) xtitle("Estimated changes in N agents (%)", size(small)) ///
		 note("Total agents = `r(N)'", size(small))

qui sum agents_n if treatment_status==3
kdensity posterior	if treatment_status==3, name(treatment_3_posterior_density, replace) ///
		 title("Treatment 3", size(regular)) ylabel(0(0.005)0.02) xtitle("Estimated changes in N agents (%)", size(small)) ///
		 note("Total agents = `r(N)'", size(small))

qui sum agents_n if treatment_status==4
kdensity posterior	if treatment_status==4, name(treatment_4_posterior_density, replace) ///
		 title("Treatment 4", size(regular)) ylabel(0(0.005)0.02) xtitle("Estimated changes in N agents (%)", size(small)) ///
		 note("Total agents = `r(N)'", size(small))

graph combine control_posterior_density treatment_1_posterior_density treatment_2_posterior_density treatment_3_posterior_density treatment_4_posterior_density, cols(2) ///
	  title("Posteriors about expected changes in competition", size(regular))
graph export "$output/Agent Baseline - `date'/competition_kdensity_posteriors.png", as(png) replace

****

* For Control group
twoway (kdensity prior if treatment_status==0, lp(dash) color(gray) legend(label(1 "Prior"))) ///
       (kdensity posterior if treatment_status==0, lp(solid) color(black) legend(label(2 "Posterior"))), legend(cols(2)) ///
       title("Control (No info on competition)", size(small)) name(control, replace) xtitle("Estimated changes in future competition (%)", size(vsmall))

* For T1
twoway (kdensity prior if treatment_status==1, lp(dash) color(gray) legend(label(1 "Prior"))) ///
       (kdensity posterior if treatment_status==1, lp(solid) color(black) legend(label(2 "Posterior"))), ///
       title("T1 (Info on competition)", size(small)) name(treatment_1, replace) xtitle("Estimated changes in future competition (%)", size(vsmall))

* For T2
twoway (kdensity prior if treatment_status==2, lp(dash) color(gray) legend(label(1 "Prior"))) ///
       (kdensity posterior if treatment_status==2, lp(solid) color(black) legend(label(2 "Posterior"))), ///
       title("T2 (No info on competition)", size(small)) name(treatment_2, replace) xtitle("Estimated changes in future competition (%)", size(vsmall))

* For T3
twoway (kdensity prior if treatment_status==3, lp(dash) color(gray) legend(label(1 "Prior"))) ///
       (kdensity posterior if treatment_status==3, lp(solid) color(black) legend(label(2 "Posterior"))), ///
       title("T3 (Info on competition)", size(small)) name(treatment_3, replace) xtitle("Estimated changes in future competition (%)", size(vsmall))

* For T4
twoway (kdensity prior if treatment_status==4, lp(dash) color(gray) legend(label(1 "Prior"))) ///
       (kdensity posterior if treatment_status==4, lp(solid) color(black) legend(label(2 "Posterior"))), ///
       title("T4 (No info on competition)", size(small)) name(treatment_4, replace) xtitle("Estimated changes in future competition (%)", size(vsmall))


grc1leg control treatment_1 treatment_2 treatment_3 treatment_4, legendfrom(control) ///
title("Prior and posterior across treatment arms", size(medsmall)) ///
iscale(0.75) xcommon xsize(20) ysize(20) imargin(3 3 3) 
graph export "$output/Agent Baseline - `date'/competition_kdensity_combined.png", as(png) replace

**# 1. Section 1
	*** q_1a
	local x = 1
	forval nmr = 1/2 {
		gen gr_1a_`nmr' = 1 if q_1a == `x'
		recode gr_1a_`nmr' (. = 0)
		replace gr_1a_`nmr' = . if q_1a == .
		
		local x = `x' - 1
	}

	set scheme jpalfull

	qui sum agents_n if q_1a!=. 
	
	local date : display %tdDNCY daily("$S_DATE", "DMY")
	capture shell mkdir -p "$output/Agent Baseline - `date'"

	graph bar gr_1a_*, percentages /// percent is the default
		ytitle("Perc of agents", size(medsmall) orientation(vertical)) ///
		ylabel(0(25)100) ///
		blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
		title("How do you {bf:set trx fees}?", size(medsmall)) ///
		legend(order(1 "I follow the official list" 2 "I set my own prices") size(medsmall) col(2)) ///
		note("Total agents = `: di %6.0fc `r(N)''", size(medsmall)) 
		
	graph export "$output/Agent Baseline - `date'/2 - q_1a.png", as(png) replace


*** q_1b
	local x = 1
	forval nmr = 1/2 {
		gen gr_1b_`nmr' = 1 if q_1b == `x'
		recode gr_1b_`nmr' (. = 0)
		replace gr_1b_`nmr' = . if q_1b == .
		
		local x = `x' - 1
	}
	
	set scheme jpalfull

	qui sum agents_n if q_1b!=. 

	local date : display %tdDNCY daily("$S_DATE", "DMY")
	capture shell mkdir -p "$output/Agent Baseline - `date'"
	
	graph bar gr_1b_*, percentages /// percent is the default
		ytitle("Perc of agents", size(medsmall) orientation(vertical)) ///
		ylabel(0(25)100) ///
		blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
		title("Do you charge {bf:all} clients {bf:the same fee}?", size(medsmall)) ///
		subtitle(" ", size(medsmall)) ///
		legend(order(1 "Yes" 2 "No") size(medsmall) col(2)) ///
		note("Total agents = `: di %6.0fc `r(N)''", size(medsmall)) 
		
	graph export "$output/Agent Baseline - `date'/3 - q_1b.png", as(png) replace


*** q_1b_1_1

	local date : display %tdDNCY daily("$S_DATE", "DMY")
	capture shell mkdir -p "$output/Agent Baseline - `date'"
	

	forval y = 1/8 {
    gen q_1b_1_new_`y' = ///
        q_1b_1_11==`y' | q_1b_1_12==`y' | q_1b_1_13==`y' | q_1b_1_14==`y' | ///
        q_1b_1_15==`y' | q_1b_1_16==`y' | q_1b_1_17==`y' | q_1b_1_18==`y'
	}

	set scheme jpalfull

	qui sum agents_n if q_1b == 0

	graph bar q_1b_1_new_*, percentages ///
	ytitle("%", size(small) orientation(horizontal)) ylabel(, labsize(small)) blabel(bar, pos(center) size(vsmall) format(%15.1fc)) ///
	title("Type of client charge with low fees?", size(medsmall)) ///
	legend(order(1 "Friends" 2 "Family" 3 "High-value customers" 4 "New customers" 5 "Long-term customers" 6 "Lower-income customers" 7 "Local customers" 8 "Can switch agents") size(small) col(2)) ///
	note("Total agents = `: di %6.0fc `r(N)''", size(medsmall)) 
	
	graph export "$output/Agent Baseline - `date'/4 - q_1b_1_1.png", as(png) replace

*** q_1c

	local x = 1
	forval nmr = 1/2 {
		gen gr_1c_`nmr' = 1 if q_1c == `x'
		recode gr_1c_`nmr' (. = 0)
		replace gr_1c_`nmr' = . if q_1c == .
		
		local x = `x' - 1
	}
	
	set scheme jpalfull
	qui sum agents_n if q_1c!=. 

	local date : display %tdDNCY daily("$S_DATE", "DMY")
	capture shell mkdir -p "$output/Agent Baseline - `date'"
	
	graph bar gr_1c_*, percentages /// percent is the default
		ytitle("Perc of agents", size(medsmall) orientation(vertical)) ///
		ylabel(0(25)75) ///
		blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
		title("How well are customers {bf:informed about}", size(small)) ///
		subtitle("{bf:BM official fees}?", size(small)) ///
		legend(order(1 "Most clients know the fees well" 2 "Most clients do not know the fees") ///
	    size(small) rows(2) cols(2)) ///
		note("Total agents = `: di %6.0fc `r(N)''", size(small))
		
	graph export "$output/Agent Baseline - `date'/5 - q_1c.png", as(png) replace

**# 2. Section 2 

*** q_2a

	forval y = 1/10 {
		g q_2a_`y' = q_2a1==`y' | q_2a2==`y' | q_2a3==`y'
		}

	set scheme jpalfull
	qui sum agents_n if q_2a1 != . 

	graph bar q_2a_*, percentages ///
	ytitle("%", size(small) orientation(horizontal)) ylabel(, labsize(small)) blabel(bar, pos(center) size(vsmall) format(%15.1fc)) ///
	title("Most important characteristics of an agent", size(medsmall)) ///
	legend(order(1 "Prior customer" 2 "Answers clearly" 3 "Close proximity" 4 "Sufficient cash" 5 "Price transparency" 6 "Always available" 7 "Lowest price" 8 "Bank-affiliated" 9 "Trusted agent" 10 "Same price for all") size(vsmall) col(3)) ///
	note("Total agents = `: di %6.0fc `r(N)''", size(small)) 
	
	graph export "$output/Agent Baseline - `date'/6 - q_1b_1_1.png", as(png) replace


**# 3. Section 3
*** q_3a
	forval x = 1/4 {
		gen gr_3a_`x' = 1 if q_3a == `x'
		recode gr_3a_`x' (. = 0)
		replace gr_3a_`x' = . if q_3a == .
	}
	
	set scheme jpalfull

	qui sum agents_n if q_3a!=. 

	local date : display %tdDNCY daily("$S_DATE", "DMY")
	capture shell mkdir -p "$output/Agent Baseline - `date'"
	
	graph bar gr_3a_*, percentages /// percent is the default
		ytitle("Perc of agents", size(medsmall) orientation(vertical)) ///
		ylabel(, labsize(medsmall)) ///
		blabel(bar, pos(top) size(small) format(%15.1fc)) ///
		title("Client reaction to being overcharged – {bf:official fees}", size(medsmall)) ///
		subtitle("How would you react?", size(medsmall)) ///
		legend(order(1 "Indifferent" 2 "Unfair, switch" 3 "Unfair, stay" 4 "Fair") size(small) col(4)) ///
		note("Total agents = `: di %6.0fc `r(N)''", size(small)) 
		
	graph export "$output/Agent Baseline - `date'/7 - q_3a.png", as(png) replace

*** q_3b
set scheme 	plotplain
qui sum q_3b 
histogram q_3b, percent color(navy*0.95) ///
	discrete ///
	xlabel(0(10)100) ///
	title("Client reaction to being overcharged – {bf:official fees}", size(medsmall)) ///
    ytitle("Perc of agents", size(medsmall)) ///
    xtitle("Perc of estimated revenue loss", size(medsmall)) ///
	note("Total agents = `: di %6.0fc `r(N)''", size(small))
graph export "$output/Agent Baseline - `date'/8 - q_3b_hist.png", as(png) replace

set scheme 	plotplain
su q_3b, detail
return list
local mean_rounded = round(`r(mean)', 1)
graph box q_3b,  box(1, fcolor(navy*0.75) lcolor(navy*0.75)) yline(`r(mean)', lpattern(.) lcolor(navy*0.75)) ///
	title("{bf:Estimated agent revenue loss} from charging {bf:50% above official fees}", size(medsmall)) ///
	ytitle("Perc of estimated revenue loss", size(medsmall)) ///
	text(`r(p50)' 95 "Median=`r(p50)'", size(small)) ///
	text(`r(p75)' 95 "Q3=`r(p75)'", size(small)) ///
    text(`r(p25)' 95 "Q1=`r(p25)'", size(small)) ///
    text(`r(mean)' 95 "Mean=`mean_rounded'", size(small)) ///
	note("Total agents = `: di %6.0fc `r(N)''", size(small))
graph export "$output/Agent Baseline - `date'/8 - q_3b_boxplot.png", as(png) replace

*** q_3c
	forval x = 1/4 {
		gen gr_3c_`x' = 1 if q_3c == `x'
		recode gr_3c_`x' (. = 0)
		replace gr_3c_`x' = . if q_3c == .
	}
	
	set scheme jpalfull

	qui sum agents_n if q_3c!=. 

	local date : display %tdDNCY daily("$S_DATE", "DMY")
	capture shell mkdir -p "$output/Agent Baseline - `date'"
	
	graph bar gr_3c_*, percentages /// percent is the default
		ytitle("Perc of agents", size(medsmall) orientation(vertical)) ///
		ylabel(, labsize(medsmall)) ///
		blabel(bar, pos(top) size(small) format(%15.1fc)) ///
		title("Client reaction to being overcharged – {bf:other client}", size(medsmall)) ///
		subtitle("How would you react?", size(medsmall)) ///
		legend(order(1 "Indifferent" 2 "Unfair, switch" 3 "Unfair, stay" 4 "Fair") size(small) col(4)) ///
		note("Total agents = `: di %6.0fc `r(N)''", size(small)) 
		
	graph export "$output/Agent Baseline - `date'/9 - q_3c.png", as(png) replace

*** q_3d
set scheme 	plotplain
qui sum q_3d 
histogram q_3d, percent color(maroon*0.95) ///
	discrete ///
	xlabel(0(10)100) ///
	title("{bf:Estimated agent revenue loss} from charging one client {bf:50% more than others}", size(medsmall)) ///
    ytitle("Perc of agents", size(medsmall)) ///
    xtitle("Perc of estimated revenue loss", size(medsmall)) ///
	note("Total agents = `: di %6.0fc `r(N)''", size(small))
graph export "$output/Agent Baseline - `date'/10 - q_3d_hist.png", as(png) replace

set scheme 	plotplain
su q_3d, detail
return list
local mean_rounded = round(`r(mean)', 1)
graph box q_3d,  box(1, fcolor(maroon*0.75) lcolor(maroon*0.75)) yline(`r(mean)', lpattern(.) lcolor(maroon*0.75)) ///
	title("{bf:Estimated agent revenue loss} from charging one client {bf:50% more than others}", size(medsmall)) ///
	ytitle("Perc of estimated revenue loss", size(medsmall)) ///
	text(`r(p50)' 95 "Median=`r(p50)'", size(small)) ///
	text(`r(p75)' 95 "Q3=`r(p75)'", size(small)) ///
    text(`r(p25)' 95 "Q1=`r(p25)'", size(small)) ///
    text(`r(mean)' 95 "Mean=`mean_rounded'", size(small)) ///
	note("Total agents = `: di %6.0fc `r(N)''", size(small))
graph export "$output/Agent Baseline - `date'/10 - q_3d_boxplot.png", as(png) replace


*** q_3e
set scheme 	plotplain
qui sum q_3e 
histogram q_3e, percent color(emerald*0.95) ///
	discrete ///
	xlabel(0(10)100) ///
	title("{bf:Estimated revenue loss} from a IDR 1.5k withdrawal fee increase", size(medsmall)) ///
    ytitle("Perc of agents", size(medsmall)) ///
    xtitle("Perc of estimated revenue loss", size(medsmall)) ///
	note("Total agents = `: di %6.0fc `r(N)''", size(small))
graph export "$output/Agent Baseline - `date'/11 - q_3e_hist.png", as(png) replace

set scheme 	plotplain
su q_3e, detail
return list
local mean_rounded = round(`r(mean)', 1)
graph box q_3e,  box(1, fcolor(emerald*0.75) lcolor(emerald*0.75)) yline(`r(mean)', lpattern(.) lcolor(emerald*0.75)) ///
	title("{bf:Estimated revenue loss} from a IDR 1.5k withdrawal fee increase", size(medsmall)) ///
	ytitle("Perc of estimated revenue loss", size(medsmall)) ///
	text(`r(p50)' 95 "Median=`r(p50)'", size(small)) ///
	text(`r(p75)' 95 "Q3=`r(p75)'", size(small)) ///
    text(`r(p25)' 95 "Q1=`r(p25)'", size(small)) ///
    text(`r(mean)' 95 "Mean=`mean_rounded'", size(small)) ///
	note("Total agents = `: di %6.0fc `r(N)''", size(small))
graph export "$output/Agent Baseline - `date'/11 - q_3e_boxplot.png", as(png) replace


**# 4. Section 4
*** q_4a
	forval x = 1/2 {
		gen gr_4a_`x' = 1 if q_4a == `x'
		recode gr_4a_`x' (. = 0)
		replace gr_4a_`x' = . if q_4a == .
	}

	
	set scheme jpalfull

	local date : display %tdDNCY daily("$S_DATE", "DMY")
	capture shell mkdir -p "$output/Agent Baseline - `date'"
	
	qui sum agents_n if q_4a!=. 

	graph bar gr_4a_*, percentages /// percent is the default
		ytitle("Perc of agents", size(medsmall) orientation(vertical)) ///
		ylabel(0(25)75) ///
		blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
		title("Perceptions of agent availability in the area", size(medsmall)) ///
		subtitle(" ", size(medsmall)) ///
		legend(order(1 "Many agents nearby" 2 "Few agents nearby") size(small) col(2)) ///
		note("Total agents = `: di %6.0fc `r(N)''", size(small)) 
		
	graph export "$output/Agent Baseline - `date'/12 - q_4a.png", as(png) replace

*** q_4b
	forval x = 1/2 {
		gen gr_4b_`x' = 1 if q_4b == `x'
		recode gr_4b_`x' (. = 0)
		replace gr_4b_`x' = . if q_4b == .
	}

	set scheme jpalfull

	local date : display %tdDNCY daily("$S_DATE", "DMY")
	capture shell mkdir -p "$output/Agent Baseline - `date'"

	qui sum agents_n if q_4b!=. 

	graph bar gr_4b_*, percentages /// percent is the default
		ytitle("Perc of agents", size(medsmall) orientation(vertical)) ///
		ylabel(0(25)75) ///
		blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
		title("Customer loyalty when faced with lower-priced alternatives", size(medsmall)) ///
		subtitle(" ", size(medsmall)) ///
		legend(order(1 "Stay with me despite lower prices elsewhere" 2 "Switch to cheaper agents") size(small) col(1)) ///
		note("Total agents = `: di %6.0fc `r(N)''", size(small)) 
		
	graph export "$output/Agent Baseline - `date'/13 - q_4b.png", as(png) replace

*** q_4c
set scheme 	plotplain
qui sum q_4c 
histogram q_4c, percent color(chocolate*0.95) ///
	discrete ///
	xlabel(0(10)100) ///
	title("{bf:Estimated revenue loss} from a 50% cheaper new, competing agent", size(medsmall)) ///
    ytitle("Perc of agents", size(medsmall)) ///
    xtitle("Perc of estimated revenue loss", size(medsmall)) ///
	note("Total agents = `: di %6.0fc `r(N)''", size(small))
graph export "$output/Agent Baseline - `date'/14 - q_4c_hist.png", as(png) replace

set scheme 	plotplain
su q_4c, detail
return list
local mean_rounded = round(`r(mean)', 1)
graph box q_4c,  box(1, fcolor(chocolate*0.75) lcolor(chocolate*0.75)) yline(`r(mean)', lpattern(.) lcolor(chocolate*0.75)) ///
	title("{bf:Estimated revenue loss} from a 50% cheaper new, competing agent", size(medsmall)) ///
	ytitle("Perc of estimated revenue loss", size(medsmall)) ///
	text(`r(p50)' 95 "Median=`r(p50)'", size(small)) ///
	text(`r(p75)' 95 "Q3=`r(p75)'", size(small)) ///
    text(`r(p25)' 95 "Q1=`r(p25)'", size(small)) ///
    text(`r(mean)' 95 "Mean=`mean_rounded'", size(small)) ///
	note("Total agents = `: di %6.0fc `r(N)''", size(small))
graph export "$output/Agent Baseline - `date'/14 - q_4c_boxplot.png", as(png) replace


**# 5a. Treatment assignments (aggregate)
	local a = 0
	forval x = 1/5 {
		gen gr_tstat_`x' = 1 if treatment_status == `a'
		recode gr_tstat_`x' (. = 0)
		replace gr_tstat_`x' = . if treatment_status == .
		local a = `a' + 1
	}

	qui sum agents_n if treatment_status!=. 
	
	set scheme jpalfull

	local date : display %tdDNCY daily("$S_DATE", "DMY")
	capture shell mkdir -p "$output/Agent Baseline - `date'"
	
	graph bar gr_tstat_*, percentages /// percent is the default
		ytitle("Perc of agents", size(medsmall) orientation(vertical)) ///
		ylabel(0(5)25) ///
		blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
		title("Treatment assignments across all strata", size(medsmall)) ///
		subtitle(" ", size(medsmall)) ///
		legend(order(1 "Pure Control" 2 "T1" 3 "T2" 4 "T3" 5 "T4") size(medsmall) col(5)) ///
		note("Total agents = `: di %6.0fc `r(N)''", size(medsmall)) 
		
	graph export "$output/Agent Baseline - `date'/15 - treatment_randomization.png", as(png) replace

/**# Treatment assignments (within each strata)
*create separate var for each treatment_status value
	forval y = 0/4 {
		g treatment_status_`y'= treatment_status==`y'
	}

qui sum agents_n if treatment_status!=.

graph hbar (sum) treatment_status_*, stack percentage over(strata, label(labsize(tiny))) ///
title("Treatment assignments within each strata", size(medsmall)) /// 
legend(order(1 "Control" 2 "T1" 3 "T2" 4 "T3" 5 "T4") size(small) row(1) region(lstyle(none))) ///
ytitle("Perc of agents", size(small)) ylabel(, labsize(small)) blabel(bar, pos(center) size(vsmall) color(black) format(%15.0fc)) ///
note("Total agents = `: di %6.0fc `r(N)''", size(small)) 

graph export "$output/Agent Baseline - `date'/15 - treatment_randomization_strata.png", as(png) replace

*/

** Number of responses per province
*Gen separate var for each value in code_province
forval y = 1/34 {
	g code_province_`y' = code_province==`y'
	}

qui sum agents_n if code_province!=.

graph hbar if inrange(code_province,1,34), /// percent is the default
over(code_province, label(labsize(tiny))) ///
ytitle("Perc of agents", size(small) orientation(horizontal)) ylabel(, labsize(small)) blabel(bar, pos(outside) size(vsmall) format(%15.1fc)) ///
title("Number of responses within each province", size(medsmall)) ///
note("Total agents = `: di %6.0fc `r(N)''", size(small)) ///
bar(1,fcolor(*0.65))
graph export "$output/Agent Baseline - `date'/34 - n_responses_province.png", as(png) replace

**# 5b. Strata distribution

	destring strata, replace

	forval x = 1/8 {
		gen gr_strata_`x' = 1 if strata == `x'
		recode gr_strata_`x' (. = 0)
		replace gr_strata_`x' = . if strata == .
	}

	qui sum agents_n if strata!=. 
	
	set scheme jpalfull

	local date : display %tdDNCY daily("$S_DATE", "DMY")
	capture shell mkdir -p "$output/Agent Baseline - `date'"
	
	graph bar gr_strata_*, percentages /// percent is the default
		ytitle("Perc of agents", size(medsmall) orientation(vertical)) ///
		ylabel(0(5)25) ///
		blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
		title("Response distribution by strata", size(medsmall)) ///
		subtitle(" ", size(medsmall)) ///
		legend(order(1 "Strata 1" 2 "Strata 2" 3 "Strata 3" 4 "Strata 4" 5 "Strata 5" 6 "Strata 6" 7 "Strata 7" 8 "Strata 8") size(medsmall) col(2)) ///
		note("Total agents = `: di %6.0fc `r(N)''", size(medsmall)) 
		
	graph export "$output/Agent Baseline - `date'/15 - strata_distribution.png", as(png) replace




**# 7. Section 7 (Marketing Plans)

*** q_7a (aggregate)
	fre q_7a
	
	* Bar chart
	local x = 1
	forval nmr = 1/2 {
		gen gr_7a_`nmr' = 1 if q_7a == `x'
		recode gr_7a_`nmr' (. = 0)
		replace gr_7a_`nmr' = . if q_7a == .
		local x = `x' - 1
	}

	qui sum agents_n if q_7a!=. 
	
	set scheme jpalfull
	
	local date : display %tdDNCY daily("$S_DATE", "DMY")
	capture shell mkdir -p "$output/Agent Baseline - `date'"

	graph bar gr_7a_*, percentages /// percent is the default
		ytitle("Perc of agents", size(medsmall) orientation(vertical)) ///
		ylabel(0(25)75) ///
		blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
		title("Choice of marketing plans", size(medsmall)) ///
		subtitle(" ", size(medsmall)) ///
		legend(order(1 "Plan A (Agents receive the poster)" 2 "Plan B (Clients receive the poster)") size(small) col(1)) ///
		note("Total agents = `: di %6.0fc `r(N)''", size(medsmall)) 
		
	graph export "$output/Agent Baseline - `date'/16 - marketing_choice (aggregate).png", as(png) replace

* Bar chart (by treatment groups)
	forval a = 2/3 {
		gen gr_7a_t`a' = 1 if treatment_status == `a' & q_7a == 1
		replace gr_7a_t`a' = 2 if treatment_status == `a' & q_7a == 0
	}

	label var gr_7a_t2 "{bf:T2} (No info on competition)"
	label var gr_7a_t3 "{bf:T3} (Info on competition)"

	la def planab 1 "Agents receieve the poster" 2 "Clients receive the poster", replace
	la val gr_7a_t2 gr_7a_t3 planab

	foreach x of varlist gr_7a_t2 gr_7a_t3 {
					
		qui sum agents_n  if `x' !=.
		loc obs = `r(N)'

		loc	z: 	var lab 	`x'
		splitvallabels		`x'	
		
		set scheme jpalfull
					
		graph bar, over(`x', label(labsize(medium)) relabel(`r(relabel)')) ytitle("Perc of agents", size(medium) orientation(vertical)) ylabel(0(25)75, grid labsize(medium)) ///
		asyvars ///
		title("`z'", size(medium)) bar(1) blabel(bar, size(medium) format(%4.1f)) ///
		note("Total agents = `: di %6.0fc `obs''", span size(medium)) name(`x', replace) 
		
	}
	local date : display %tdDNCY daily("$S_DATE", "DMY")
	capture shell mkdir -p "$output/Agent Baseline - `date'"
	
	graph combine gr_7a_t2 gr_7a_t3, ///
		col(2) iscale(0.7) xcommon ///
		xsize(16) ysize(9) imargin(0 0 0 0) ///
		title("{bf: Choice of marketing plans}", size(medium)) ///
		subtitle("By treatment groups", size(medium))
		
	graph export "$output/Agent Baseline - `date'/16 - marketing_choice (breakdowns).png", as(png) replace

**# 8. Section 8
*** q_8a
forval x = 0/1 {
    gen gr_8a_`x' = (q_8a == `x') if q_8a < .
}
	qui sum agents_n if q_8a!=. 
	
	set scheme jpalfull

	local date : display %tdDNCY daily("$S_DATE", "DMY")
	capture shell mkdir -p "$output/Agent Baseline - `date'"
	
	graph bar gr_8a_*, percentages /// percent is the default
		ytitle("Perc of agents", size(medsmall) orientation(vertical)) ///
		ylabel(0(25)75) ///
		blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
		title("Do you offer additional benefits to customers?", size(medsmall)) ///
		subtitle(" ", size(medsmall)) ///
		legend(order(1 "No" 2 "Yes") size(small) col(2)) ///
		note("Total agents = `: di %6.0fc `r(N)''", size(medsmall)) 
		
	graph export "$output/Agent Baseline - `date'/17 - q_8a.png", as(png) replace

*** q_8a_1

forval y = 1/8 {
    gen q_8a_1_new_`y' = ///
        q_8a_11==`y' | q_8a_12==`y' | q_8a_13==`y' | q_8a_14==`y' | ///
        q_8a_15==`y' | q_8a_16==`y' | q_8a_17==`y' | q_8a_18==`y'
}

set scheme jpalfull

qui sum agents_n if q_8a==1

graph bar q_8a_1_new_*, percentages ///
    ytitle("%", size(small) orientation(horizontal)) ///
    ylabel(, labsize(small)) ///
    blabel(bar, pos(center) size(vsmall) format(%15.1fc)) ///
    title("Who do you offer {bf:additional benefits} to?", size(medsmall)) ///
    legend(order(1 "Friends" 2 "Family" 3 "High-value customers" 4 "New customers" ///
                 5 "Long-term customers" 6 "Lower-income customers" ///
                 7 "Local customers" 8 "Can switch agents") ///
           size(small) col(2)) ///
    note("Total agents = `: di %6.0fc `r(N)''", size(medsmall)) 
	
graph export "$output/Agent Baseline - `date'/18 - q_8a_1.png", as(png) replace


*** q_8a_2
set scheme 	plotplain
qui sum q_8a_2 
histogram q_8a_2, percent color(emerald*0.95) ///
	discrete ///
	xlabel(0(20)100) ///
	title("{bf:Number of customers offered additional benefits} last month", size(medsmall)) ///
    ytitle("Perc of agents", size(medsmall)) ///
    xtitle("Num of customers", size(medsmall)) ///
	note("Total agents = `: di %6.0fc `r(N)''", size(small))
graph export "$output/Agent Baseline - `date'/19 - q_8a_2_hist.png", as(png) replace

set scheme 	plotplain
su q_8a_2, detail
return list
local mean_rounded = round(`r(mean)', 1)
graph box q_8a_2,  box(1, fcolor(emerald*0.75) lcolor(emerald*0.75)) yline(`r(mean)', lpattern(.) lcolor(emerald*0.75)) ///
	title("{bf:Number of customers offered additional benefits} last month", size(medsmall)) ///
	ytitle("Num of customers", size(medsmall)) ///
	text(`r(p50)' 95 "Median=`r(p50)'", size(small)) ///
	text(`r(p75)' 95 "Q3=`r(p75)'", size(small)) ///
    text(`r(p25)' 95 "Q1=`r(p25)'", size(small)) ///
    text(`r(mean)' 95 "Mean=`mean_rounded'", size(small)) ///
	note("Total agents = `: di %6.0fc `r(N)''", size(small))
graph export "$output/Agent Baseline - `date'/19 - q_8a_2_boxplot.png", as(png) replace


*** q_8b
set scheme 	plotplain
qui sum q_8b 
histogram q_8b, percent color(chocolate*0.95) ///
	discrete ///
	xlabel(0(10)100) ///
	title("{bf:Agent banking revenue} (% of total business revenue)", size(medsmall)) ///
    ytitle("Perc of agents", size(medsmall)) ///
    xtitle("Perc of agent banking revenue", size(medsmall)) ///
	note("Total agents = `: di %6.0fc `r(N)''", size(small))
graph export "$output/Agent Baseline - `date'/20 - q_8b_hist.png", as(png) replace

set scheme 	plotplain
su q_8b, detail
return list
local mean_rounded = round(`r(mean)', 1)
graph box q_8b,  box(1, fcolor(chocolate*0.75) lcolor(chocolate*0.75)) yline(`r(mean)', lpattern(.) lcolor(chocolate*0.75)) ///
	title("{bf:Agent banking revenue} (% of total business revenue)", size(medsmall)) ///
	ytitle("Perc of agent banking revenue", size(medsmall)) ///
	text(`r(p50)' 95 "Median=`r(p50)'", size(small)) ///
	text(`r(p75)' 95 "Q3=`r(p75)'", size(small)) ///
    text(`r(p25)' 95 "Q1=`r(p25)'", size(small)) ///
    text(`r(mean)' 95 "Mean=`mean_rounded'", size(small)) ///
	note("Total agents = `: di %6.0fc `r(N)''", size(small))
graph export "$output/Agent Baseline - `date'/20 - q_8b_boxplot.png", as(png) replace

*** q_8c
	local x = 1
	forval nmr = 1/2 {
		gen gr_8c_`nmr' = 1 if q_8c == `x'
		recode gr_8c_`nmr' (. = 0)
		replace gr_8c_`nmr' = . if q_8c == .
		local x = `x' - 1
	}

	qui sum agents_n if q_8c!=. 
	
	set scheme jpalfull

	graph bar gr_8c_*, percentages /// percent is the default
    	ytitle("%", size(small) orientation(horizontal)) ///
		ylabel(0(25)75) ///
		blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
		title("Do you also work as an agent for other banks?", size(medsmall)) ///
		subtitle(" ", size(medsmall)) ///
		legend(order(1 "Yes" 2 "No") size(medsmall) col(2)) ///
		note("Total agents = `: di %6.0fc `r(N)''", size(medsmall)) 
		
	
	graph export "$output/Agent Baseline - `date'/21 - q_8c.png", as(png) replace

*** q_8c_1
set scheme 	plotplain
qui sum q_8c_1 
histogram q_8c_1, percent color(maroon*0.95) ///
	discrete ///
	xlabel(0(10)100) ///
	title("{bf:BM revenue} (% of total agent banking revenue)", size(medsmall)) ///
    ytitle("Perc of agents", size(medsmall)) ///
    xtitle("Perc of agent banking revenue", size(medsmall)) ///
	note("Total agents = `: di %6.0fc `r(N)''", size(small))
graph export "$output/Agent Baseline - `date'/22 - q_8c_1_hist.png", as(png) replace

set scheme 	plotplain
su q_8c_1, detail
return list
local mean_rounded = round(`r(mean)', 1)
graph box q_8c_1,  box(1, fcolor(maroon*0.75) lcolor(maroon*0.75)) yline(`r(mean)', lpattern(.) lcolor(maroon*0.75)) ///
	title("{bf:BM revenue} (% of total agent banking revenue)", size(medsmall)) ///
	ytitle("Perc of agent banking revenue", size(medsmall)) ///
	text(`r(p50)' 95 "Median=`r(p50)'", size(small)) ///
	text(`r(p75)' 95 "Q3=`r(p75)'", size(small)) ///
    text(`r(p25)' 95 "Q1=`r(p25)'", size(small)) ///
    text(`r(mean)' 95 "Mean=`mean_rounded'", size(small)) ///
	note("Total agents = `: di %6.0fc `r(N)''", size(small))
graph export "$output/Agent Baseline - `date'/22 - q_8c_1_boxplot.png", as(png) replace

**# 9. Section 9
*** q_9a
set scheme 	plotplain
qui sum q_9a
histogram q_9a, percent color(navy*0.95) ///
	discrete ///
	xlabel(0(10)50) ///
	title("How many agents in your area?", size(medsmall)) ///
    ytitle("Perc of agents", size(medsmall)) ///
    xtitle("Num of agents in the area", size(medsmall)) ///
	note("Total agents = `: di %6.0fc `r(N)''", size(small))
graph export "$output/Agent Baseline - `date'/23 - q_9a_hist.png", as(png) replace

set scheme 	plotplain
su q_9a, detail
return list
local mean_rounded = round(`r(mean)', 1)
graph box q_9a,  box(1, fcolor(navy*0.75) lcolor(navy*0.75)) yline(`r(mean)', lpattern(.) lcolor(navy*0.75)) ///
	title("How many agents in your area?", size(medsmall)) ///
	ytitle("Num of agents in the area", size(medsmall)) ///
	text(`r(p50)' 95 "Median=`r(p50)'", size(small)) ///
	text(`r(p75)' 95 "Q3=`r(p75)'", size(small)) ///
    text(`r(p25)' 95 "Q1=`r(p25)'", size(small)) ///
    text(`r(mean)' 95 "Mean=`mean_rounded'", size(small)) ///
	note("Total agents = `: di %6.0fc `r(N)''", size(small))
graph export "$output/Agent Baseline - `date'/23 - q_9a_boxplot.png", as(png) replace

*** q_9b

	forval x = 1/3 {
		gen gr_9b_`x' = 1 if q_9b == `x'
		recode gr_9b_`x' (. = 0)
		replace gr_9b_`x' = . if q_9b == .
	}

	qui sum agents_n if q_9b!=. 
	
	set scheme jpalfull

	graph bar gr_9b_*, percentages /// percent is the default
		ytitle("Perc of agents", size(medsmall) orientation(vertical)) ///
		ylabel(0(25)75) ///
		blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
		title("Perceived {bf:level of competition} with other agents in the area", size(medsmall)) ///
		subtitle(" ", size(medsmall)) ///
		legend(order(1 "High" 2 "Neither high nor low" 3 "Low") size(medsmall) col(3)) ///
		note("Total agents = `: di %6.0fc `r(N)''", size(medsmall)) 
		
	graph export "$output/Agent Baseline - `date'/24 - q_9b.png", as(png) replace

*** q_9c
	forval x = 1/3 {
		gen gr_9c_`x' = 1 if q_9c == `x'
		recode gr_9c_`x' (. = 0)
		replace gr_9c_`x' = . if q_9c == .
	}

	qui sum agents_n if q_9c!=. 
	
	set scheme jpalfull

	graph bar gr_9c_*, percentages /// percent is the default
		ytitle("Perc of agents", size(medsmall) orientation(vertical)) ///
		ylabel(0(25)75) ///
		blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
		title("How easy is it for you to {bf:attract new} customers?", size(medsmall)) ///
		subtitle(" ", size(medsmall)) ///
		legend(order(1 "Easy" 2 "Neither easy nor difficult" 3 "Difficult") size(medsmall) col(3)) ///
		note("Total agents = `: di %6.0fc `r(N)''", size(medsmall)) 
		
	graph export "$output/Agent Baseline - `date'/25 - q_9c.png", as(png) replace

*** q_9d
	local x = 1
	forval nmr = 1/2 {
		gen gr_9d_`nmr' = 1 if q_9d == `x'
		recode gr_9d_`nmr' (. = 0)
		replace gr_9d_`nmr' = . if q_9d == .
		local x = `x' - 1
	}

	qui sum agents_n if q_9d!=. 
	
	set scheme jpalfull

	graph bar gr_9d_*, percentages /// percent is the default
		ytitle("Perc of agents", size(medsmall) orientation(vertical)) ///
		ylabel(0(25)75) ///
		blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
		title("Display of BM official price list in shop", size(medsmall)) ///
		subtitle(" ", size(medsmall)) ///
		legend(order(1 "Yes" 2 "No") size(medsmall) col(2)) ///
		note("Total agents = `: di %6.0fc `r(N)''", size(medsmall)) 
		
	graph export "$output/Agent Baseline - `date'/26 - q_9d.png", as(png) replace

*** q_9e_1

	forval y = 1/9 {
		g q_9e_1_`y' = q_9e_11==`y' | q_9e_12==`y' | q_9e_13==`y'
		}

	set scheme jpalfull
	qui sum agents_n if q_9e_11 != . 

	graph bar q_9e_1_*, percentages ///
	ytitle("%", size(small) orientation(horizontal)) ylabel(, labsize(small)) blabel(bar, pos(center) size(vsmall) format(%15.1fc)) ///
	title("Expected strategies of {bf:a new competing agent}", size(medsmall)) ///
	legend(order(1 "Lower fees" 2 "Longer hours" 3 "Offers credit" 4 "Extra services" 5 "More cash" 6 "Clean premises" 7 "Better service" 8 "Builds trust" 9 "Closer to customers") size(vsmall) col(3)) ///
	note("Total agents = `: di %6.0fc `r(N)''", size(small)) 
	
	graph export "$output/Agent Baseline - `date'/27 - q_9e_1.png", as(png) replace

*** q_9e_2

	forval y = 1/9 {
		g q_9e_2_`y' = q_9e_21==`y' | q_9e_22==`y' | q_9e_23==`y'
		}

	set scheme jpalfull
	qui sum agents_n if q_9e_21 != . 

	graph bar q_9e_2_*, percentages ///
	ytitle("%", size(small) orientation(horizontal)) ylabel(, labsize(small)) blabel(bar, pos(center) size(vsmall) format(%15.1fc)) ///
	title("Strategies most effective {bf:at attracting your customers}", size(medsmall)) ///
	legend(order(1 "Lower fees" 2 "Longer hours" 3 "Offers credit" 4 "Extra services" 5 "More cash" 6 "Clean premises" 7 "Better service" 8 "Builds trust" 9 "Closer to customers") size(vsmall) col(3)) ///
	note("Total agents = `: di %6.0fc `r(N)''", size(small)) 
	
	graph export "$output/Agent Baseline - `date'/28 - q_9e_2.png", as(png) replace

*** q_9f

	forval y = 1/9 {
		g q_9f_`y' = q_9f1==`y' | q_9f2==`y' | q_9f3==`y'
		}

	set scheme jpalfull
	qui sum agents_n if q_9f1 != . 

	graph bar q_9f_*, percentages ///
	ytitle("%", size(small) orientation(horizontal)) ylabel(, labsize(small)) blabel(bar, pos(center) size(vsmall) format(%15.1fc)) ///
	title("Strategies {bf:implemented} to increase agent banking business", size(medsmall)) ///
	legend(order(1 "Lower fees" 2 "Longer hours" 3 "Offers credit" 4 "Extra services" 5 "More cash" 6 "Clean premises" 7 "Better service" 8 "Builds trust" 9 "Closer to customers") size(vsmall) col(3)) ///
	note("Total agents = `: di %6.0fc `r(N)''", size(small)) 
	
	graph export "$output/Agent Baseline - `date'/29 - q_9f.png", as(png) replace

*** q_9g
	forval x = 1/3 {
		gen gr_9g_`x' = 1 if q_9g == `x'
		recode gr_9g_`x' (. = 0)
		replace gr_9g_`x' = . if q_9g == .
	}

	qui sum agents_n if q_9g!=. 
	
	set scheme jpalfull

	graph bar gr_9g_*, percentages /// percent is the default
		ytitle("Perc of agents", size(medsmall) orientation(vertical)) ///
		ylabel(0(25)75) ///
		blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
		title("{bf:Time spent advertising agent banking services} (last month)", size(medsmall)) ///
		legend(order(1 "None at all" 2 "Some time" 3 "A lot of time") size(medsmall) col(3)) ///
		note("Total agents = `: di %6.0fc `r(N)''", size(medsmall)) 
	
	local date : display %tdDNCY daily("$S_DATE", "DMY")
	graph export "$output/Agent Baseline - `date'/30 - q_9g.png", as(png) replace

*** q_9h
	forval x = 1/6 {
		gen gr_9h_`x' = 1 if q_9h == `x'
		recode gr_9h_`x' (. = 0)
		replace gr_9h_`x' = . if q_9h == .
	}

	qui sum agents_n if q_9h!=. 
	
	set scheme jpalfull

	graph bar gr_9h_*, percentages /// percent is the default
		ytitle("Perc of agents", size(medsmall) orientation(vertical)) ///
		ylabel(0(10)50) ///
		blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
		title("How often approach customers to do{bf: more agent banking transactions}?", size(medsmall)) ///
		legend(order(1 "Every day" 2 "A few times a week" 3 "Once a week" 4 "A few times per month" 5 "Once a month" 6 "Not at all") size(small) col(3)) ///
		note("Total agents = `: di %6.0fc `r(N)''", size(medsmall)) 
		
	graph export "$output/Agent Baseline - `date'/31 - q_9h.png", as(png) replace

*** q_9i
	forval x = 1/6 {
		gen gr_9i_`x' = 1 if q_9i == `x'
		recode gr_9i_`x' (. = 0)
		replace gr_9i_`x' = . if q_9i == .
	}

	qui sum agents_n if q_9i!=. 
	
	set scheme jpalfull

	graph bar gr_9i_*, percentages /// percent is the default
		ytitle("Perc of agents", size(medsmall) orientation(vertical)) ///
		ylabel(0(10)50) ///
		blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
		title("How often approach customers to{bf: adopt new BM products}?", size(medsmall)) ///
		legend(order(1 "Every day" 2 "A few times a week" 3 "Once a week" 4 "A few times per month" 5 "Once a month" 6 "Not at all") size(small) col(3)) ///
		note("Total agents = `: di %6.0fc `r(N)''", size(medsmall)) 
		
	local date : display %tdDNCY daily("$S_DATE", "DMY")
	graph export "$output/Agent Baseline - `date'/32 - q_9i.png", as(png) replace

*** q_9j
	forval x = 1/6 {
		gen gr_9j_`x' = 1 if q_9j == `x'
		recode gr_9j_`x' (. = 0)
		replace gr_9j_`x' = . if missing(q_9j)
	}

	qui sum agents_n if q_9j!=. 
	
	set scheme jpalfull

	graph bar gr_9j_*, percentages /// percent is the default
		ytitle("Perc of agents", size(medsmall) orientation(vertical)) ///
		ylabel(0(10)50) ///
		blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
		title("How often approach customers to{bf: inform BM official prices}?", size(medsmall)) ///
		legend(order(1 "Every day" 2 "A few times a week" 3 "Once a week" 4 "A few times per month" 5 "Once a month" 6 "Not at all") size(small) col(3)) ///
		note("Total agents = `: di %6.0fc `r(N)''", size(medsmall)) 
		
	local date : display %tdDNCY daily("$S_DATE", "DMY")
	graph export "$output/Agent Baseline - `date'/33 - q_9j.png", as(png) replace

**# 10. Section 10
*** q_10a_1
	*** # q_10a_1
    destring q_10a_1, replace force

    qui sum q_10a_1 if q_10a_1 != .

histogram q_10a_1 , percent ///
    discrete ///
    fcolor(emerald*0.30) ///
    lcolor(emerald*0.55) ///
    xlabel(2013(1)2025, labsize(vsmall) angle(45)) ///
    ylabel(0(5)15) ///
    xtitle("Year", size(medsmall)) ///
    ytitle("Percent of agents", size(medsmall)) ///
    title("Since when have you been an agent for BM?", size(medsmall)) ///
    note("Total agents = `: di %6.0fc `r(N)''", size(medsmall))
    graph export "$output/Agent Baseline - `date'/34 - q_10a_1_hist.png", as(png) replace

*** q_10b (gender)
	local x = 1
	forval nmr = 1/2 {
		gen gr_gender_`nmr' = 1 if gender == `x'
		recode gr_gender_`nmr' (. = 0)
		replace gr_gender_`nmr' = . if gender == .
		local x = `x' - 1
	}

	qui sum agents_n if gender!=. 
	
	set scheme jpalfull

	graph bar gr_gender_*, percentages /// percent is the default
		ytitle("Perc of agents", size(medsmall) orientation(vertical)) ///
		ylabel(0(25)75) ///
		blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
		title("Gender", size(medsmall)) ///
		subtitle(" ", size(medsmall)) ///
		legend(order(1 "Female" 2 "Male") size(medsmall) col(2)) ///
		note("Total agents = `: di %6.0fc `r(N)''", size(medsmall)) 
		
	local date : display %tdDNCY daily("$S_DATE", "DMY")
	graph export "$output/Agent Baseline - `date'/35 - gender.png", as(png) replace



/*** q_10c (birthyear)
	set scheme jpalfull

	qui sum birthyear

	histogram birthyear, percent color("255 158 128") ///
		discrete ///
		ylabel(0(5)15) ///
		xtitle("Year", size(medsmall)) ///
		ytitle("Percentage of agents", size(medsmall)) ///
		title("Year of birth", size(medsmall)) ///
		subtitle(" ", size(medsmall)) ///
		note("Total agents = `: di %6.0fc `r(N)''", size(medsmall))
	local date : display %tdDNCY daily("$S_DATE", "DMY")
	graph export "$output/Agent Baseline - `date'/35 - birthyear_hist.png", as(png) replace
*/

0
	
*********************************************************************************
************************** FIGURE ON BELIEF UPDATING (ZOE's PAPER) **************
*********************************************************************************

use "$dta/02 agent_baseline/cleaned_baseline_agent_survey_`date'", clear 		


set scheme 	plotplain

// Treatment 1

preserve
binscatter posterior_prior signal_prior if treatment_status==1, msymbol(circle) savedata("temp/binned_treatment_1") replace line(none) nquantiles(40)
clear
qui do "temp/binned_treatment_1"
save "temp/binned_treatment_1",replace
restore

append using "temp/binned_treatment_1", gen(binned_treatment_1)

reg posterior_prior signal_prior i.strata if treatment_status==1, r noconstant 
matrix b = e(b)
local beta = string(round(b[1,1],.001),"%15.3fc")
matrix p =   e(V)  
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
binscatter posterior_prior signal_prior if treatment_status==3, msymbol(circle) savedata("temp/binned_treatment_3") replace line(none) nquantiles(40)
clear
qui do "temp/binned_treatment_3"
save "temp/binned_treatment_3",replace
restore

append using "temp/binned_treatment_3", gen(binned_treatment_3)

reg posterior_prior signal_prior i.strata if treatment_status==3, r noconstant 
matrix b = e(b)
local beta = string(round(b[1,1],.001),"%15.3fc")
matrix p =   e(V)  
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
    graph export "$output/belief_updating_binscatter.png", as(png) replace


0
********************
*Province breakdown*
********************

use "C:\Users\jpals\Dropbox\J-PAL IFII Agent Banking Network (BM)\06 Data\c Full-Scale\10 Respondent List\contact_list_agents_final.dta" 

merge 1:1 kode_unik_survei_agen using "C:\Users\jpals\Dropbox\J-PAL IFII Agent Banking Network (BM)\06 Data\c Full-Scale\10 Respondent List\21012026 Agent Respondents (Baseline Survey).dta"

gen responded = 0
replace responded = 1 if _merge == 3 // if matched with respondent list data


*create separate var for each treatment_status value
forval y = 0/1 {
	g responded_`y'= responded==`y'
}

set scheme jpalfull

graph hbar (sum) responded_*, stack percentage over(province, label(labsize(tiny))) ///
title("Agent response distribution by provinces", size(medsmall)) /// 
legend(order(1 "No response" 2 "Responded") size(small) row(1) region(lstyle(none))) ///
ytitle("Percentage of agents", size(small)) ylabel(, labsize(small)) blabel(bar, pos(center) size(tiny) color(black) format(%15.0fc))
graph export "$output/Agent Baseline - `date'/response_distribution_by_provinces.png", as(png) replace

***************************
*Client response breakdown*
***************************

clear 

use "C:\Users\jpals\Dropbox\J-PAL IFII Agent Banking Network (BM)\06 Data\c Full-Scale\10 Respondent List\26012026 Agent Respondents (Baseline Survey).dta"

merge 1:m kode_unik_survei_agen using "C:\Users\jpals\Dropbox\J-PAL IFII Agent Banking Network (BM)\06 Data\c Full-Scale\10 Respondent List\26012026 Client Respondents (Baseline Survey).dta"

bysort kode_unik_survei_agen: gen n_client_responses = _n if _merge == 3

replace n_client_responses = 0 if client_num >= 5 & n_client_responses == . 

set scheme jpalfull

	histogram n_client_responses, percent fcolor(emerald*0.30) ///
	lcolor(emerald*0.55) ///
	discrete ///
	xlabel(0(1)10) ///
	xtitle("Number of client responses", size(small)) ///
	ytitle("Percentage of agents", size(small)) ///
	title("Distribution of client responses") 
	graph export "$output/Agent Baseline - `date'/n_client_responses.png", as(png) replace
