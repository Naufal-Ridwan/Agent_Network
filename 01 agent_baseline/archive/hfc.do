*===================================================*
* PILOT - AGENT SURVEY								*
* By            : Saskia Maulida					*
* Last Modified : 12 September 2023	              	*
* Stata Ver     : 15                               	*
*===================================================*

clear
set more off

***********
*DATA PATH*
***********

gl user = c(username)

*Set your username here (change your "$user" == "[your username here]" and recheck the path on the next line)
// dis c(username) // activate this code if you need to check your username

*Saskia
if "$user" == "ASUS"{
	gl path "C:\Users\ASUS\Dropbox\J-PAL IFII Agent Banking Network (BM)\06 Data\13 Pilot"
	loc initials "sm"
	}


*Set the path (do not meddle with this) 
		gl do			"$path\dofiles"
		gl dta			"$path\dtafiles"
		gl log			"$path\logfiles"
		gl output		"$path\output"
		gl raw			"$path\rawresponses"
	
***IMPORTANT***

*Set local date
loc date : di %tdDNCY daily("$S_DATE", "DMY") // this is the default code, it will automatically capture the current date
// loc date "DDMMYYYY" // only use this manual setting if you're running this code late than the supposed day

*************
*IMPORT DATA*
*************
// ssc install veracrypt // only activate this code if you have yet to install veracrypt command

// veracrypt "$dta\\agentsurvey", mount // only activate this code if you haven't manually mounted the veracrypt

*import cleaned survey

// use "A:\\cleaned_agent_survey_`date'.dta", clear 
use "A:\\cleaned_agent_survey_27112023.dta", clear 

set more off
set scheme 	plotplain

***************
*DATA ANALYSIS*
***************

* Check attrition rates

gen agents_n = _n  // for notes on total N agents

tab Progress
set scheme 	plotplain
qui sum agents_n
histogram Progress, percent color(brown) ///
	discrete ///
    xtitle("Survey progress (in %)", size(small)) ///
    ytitle("Percentage of agents", size(small)) ///
    title("Survey progress (in %)") ///
	note("Note:" "Total agents = `r(N)'", size(small))
graph export "$output/agent_survey/`date'/progress.png", as(png) replace

drop if finished==0 
drop if informed_consent==.
drop agents_n

** IMPORTANT VARS **

gen agents_n = _n  // for notes on total N agents

* Survey duration

set scheme jpalfull
su total_duration, detail
return list
local mean_rounded = round(`r(mean)', 1)
local Q_1_rounded = round(`r(p25)', 1)
graph box total_duration if total_duration < 100, yline(`r(mean)', lpattern(.)) ///
	ytitle("Survey duration (in minutes)", size(small)) ///
    title("Box plot: Survey duration (in minutes)", size(medsmall)) ///
	text(`r(p50)' 95 "Median=`r(p50)'", size(vsmall)) ///
	text(`r(p75)' 95 "Q3=`r(p75)'", size(vsmall)) ///
    text(`r(p25)' 95 "Q1=`Q_1_rounded'", size(vsmall)) ///
    text(`r(mean)' 95 "Mean=`mean_rounded'", size(vsmall)) ///
	note("Note:" "Total agents = `r(N)'", size(small))
graph export "$output/agent_survey/`date'/survey_duration.png", as(png) replace
	

* Summary table

labvars Q_5 Q_7 Q_10a ///
"Prior beliefs (changes in competition)" ///
"Posterior beliefs (changes in competition)" ///
"Estimated N of agents in the area"

eststo clear
eststo a: quietly estpost summarize ///
		Q_5 Q_7 Q_10a
esttab a using "$output/agent_survey/`date'/summary_stats_agent_survey.tex", replace ///
		tex cells("mean(fmt(%13.2fc)) sd(fmt(%13.2fc)) count(fmt(%13.0fc)) min(fmt(%13.0fc)) max(fmt(%13.0fc))") ///
		nonumber nomtitle nonote noobs label collabels("Mean" "SD" "N" "Min" "Max")	


* Q_5

// a. Hist
set scheme 	plotplain
qui sum Q_5
histogram Q_5, percent color(brown) ///
	discrete ///
	xlabel(-100(10)100) ///
	ylabel(0(2)10) ///
    xtitle("Estimated change in the number of agents (in %)", size(small)) ///
    ytitle("Percentage of agents", size(small)) ///
    title("Estimated change in the number of agents in %") ///
	subtitle("(Prior beliefs)") ///
	note("Note:" "Total agents = `r(N)'", size(small))
graph export "$output/agent_survey/`date'/Q_5_hist.png", as(png) replace

// b. Box plot
set scheme jpalfull
su Q_5, detail
return list
local mean_rounded = round(`r(mean)', 1)
graph box Q_5, yline(`r(mean)', lpattern(.)) ///
	ytitle("Estimated change in the number of agents (in %)", size(small)) ///
    title("Box plot: Prior beliefs", size(medsmall)) ///
    subtitle("Estimated change in the number of agents over the next year (in %)", size(medsmall)) ///
	text(`r(p50)' 95 "Median=`r(p50)'", size(vsmall)) ///
	text(`r(p75)' 95 "Q3=`r(p75)'", size(vsmall)) ///
    text(`r(p25)' 95 "Q1=`r(p25)'", size(vsmall)) ///
    text(`r(mean)' 95 "Mean=`mean_rounded'", size(vsmall)) ///
	note("Note:" "Total agents = `r(N)'", size(small))
graph export "$output/agent_survey/`date'/Q_5_boxplot.png", as(png) replace
	
* Q_7

// a. Hist
set scheme 	plotplain
qui sum Q_7 if treatment_control!=0 
histogram Q_7, percent color(brown) ///
	discrete ///
	xlabel(-100(10)100) ///
    xtitle("Estimated change in the number of agents (in %)", size(small)) ///
    ytitle("Percentage of agents", size(small)) ///
    title("Estimated change in the number of agents in %") ///
	subtitle("(Posterior beliefs, treatment groups only)") ///
	note("Note:" "Total agents (treatment groups only) = `r(N)'", size(small))
graph export "$output/agent_survey/`date'/Q_7_hist.png", as(png) replace

// b. Box plot
set scheme jpalfull
su Q_7 if treatment_control!=0 , detail
return list
local mean_rounded = round(`r(mean)', 1)
graph box Q_7, yline(`r(mean)', lpattern(.)) ///
	ytitle("Estimated change in the number of agents (in %)", size(small)) ///
    title("Box plot: Posterior beliefs (treatment groups only)", size(medsmall)) ///
    subtitle("Estimated change in the number of agents over the next year (in %)", size(medsmall)) ///
	text(`r(p50)' 95 "Median=`r(p50)'", size(tiny)) ///
	text(`r(p75)' 95 "Q3=`r(p75)'", size(tiny)) ///
    text(`r(p25)' 95 "Q1=`r(p25)'", size(tiny)) ///
    text(`r(mean)' 95 "Mean=`mean_rounded'", size(tiny)) ///
	note("Note:" "Total agents (treatment groups only) = `r(N)'", size(small))
graph export "$output/agent_survey/`date'/Q_7_boxplot.png", as(png) replace


* Q_10a

// a. Hist
set scheme 	plotplain
qui sum Q_10a
histogram Q_10a if Q_10a < 51, percent color(brown) ///
	discrete ///
    xtitle("Estimated N of agents in the area", size(small)) ///
    ytitle("Percentage of agents", size(small)) ///
    title("How many agents are in your area?") ///
	subtitle("(BM agents & agents from other banks)") ///
	note("Note:" "Total agents = `r(N)'", size(small))
graph export "$output/agent_survey/`date'/Q_10a_hist.png", as(png) replace
	
// b. Box plot
set scheme jpalfull
su Q_10a, detail
return list
local mean_rounded = round(`r(mean)', 1)
graph box Q_10a, yline(`r(mean)', lpattern(.)) ///
	ytitle("Estimate of N agents within 5 km/in the same village", size(small)) ///
    title("Box plot: Estimate of N agents within 5 km/in the same village", size(medsmall)) ///
	subtitle ("") ///
	text(`r(p50)' 95 "Median=`r(p50)'", size(vsmall)) ///
	text(`r(p75)' 95 "Q3=`r(p75)'", size(vsmall)) ///
    text(`r(p25)' 95 "Q1=`r(p25)'", size(vsmall)) ///
    text(`r(mean)' 95 "Mean=`mean_rounded'", size(vsmall)) ///
	note("Note:" "Total agents = `r(N)'", size(small))
graph export "$output/agent_survey/`date'/Q_10a_boxplot.png", as(png) replace
	
* Outcome measures (all)

forval y = 1/2 {
	g outcome_measures_all_`y' = outcome_measures_all==`y'
	}

set scheme jpalfull
qui sum agents_n if outcome_measures_all!=. 
graph bar outcome_measures_all_* if inrange(outcome_measures_all,1,2), percentages /// percent is the default
ytitle("%", size(small) orientation(horizontal)) ylabel(, labsize(small)) blabel(bar, pos(center) size(small) format(%15.1fc)) ///
title("Outcome measures: Choices of marketing plans", size(small)) ///
legend(order(1 "Plan A (Agents receive the poster)" 2 "Plan B (Clients receive the poster)") size(small) col(3)) ///
note("Note:" "Total agents = `r(N)'", size(small))
graph export "$output/agent_survey/`date'/outcome_measures_all.png", as(png) replace width(1500)
	
* Outcome measures (by groups)

// groups treatment_control outcome_measures_all

graph bar outcome_measures_all_* if inrange(treatment_control,0,2), percentages /// percent is the default
over(treatment_control, label(labsize(small))) ///
ytitle("Percentage of agents", size(small) orientation(vertical)) ylabel(, labsize(small)) blabel(bar, pos(outside) size(vsmall) format(%15.1fc)) ///
title("By groups:", size(small)) ///
subtitle("Outcome measures (choices of marketing plans)", size(small)) ///
legend(order(1 "Plan A (Agents receive the poster)" 2 "Plan B (Clients receive the poster)") size(small) col(3))
graph export "$output/agent_survey/`date'/outcome_measures_by_groups.png", as(png) replace
	
* Randomization results

forval y = 0/2 {
	g treatment_control_`y' = treatment_control==`y'
	}

qui sum agents_n if treatment_control!=. 
graph bar treatment_control_* if inrange(treatment_control,0,2), percentages /// percent is the default
ytitle("%", size(small) orientation(horizontal)) ylabel(, labsize(small)) blabel(bar, pos(center) size(small) format(%15.1fc)) ///
title("Randomization results", size(small)) ///
legend(order(1 "Control: No information" 2 "Treatment: Information on low level of competition" 3 "Treatment: Information on high level of competition") size(small) col(1)) ///
note("Note:" "Total agents = `r(N)'", size(small))
graph export "$output/agent_survey/`date'/randomization_results.png", as(png) replace

* Randomization results (by strata groups)


** BAR CHARTS FOR OTHER VARS **

* Q_1a

forval y = 1/2 {
	g Q_1a_`y' = Q_1a==`y'
	}

set scheme jpalfull
qui sum agents_n if Q_1a!=.
graph bar Q_1a_* if inrange(Q_1a,1,2), percentages /// percent is the default
ytitle("%", size(small) orientation(horizontal)) ylabel(, labsize(small)) blabel(bar, pos(center) size(small) format(%15.1fc)) ///
title("Do you think most clients know that BM has an official pricelist?", size(small)) ///
legend(order(1 "Yes" 2 "No") size(small) col(3)) ///
note("Note:" "Total agents = `r(N)'", size(small))
graph export "$output/agent_survey/`date'/Q_1a.png", as(png) replace

* Q_1b

forval y = 1/2 {
	g Q_1b_`y' = Q_1b==`y'
	}

set scheme jpalfull
qui sum agents_n if Q_1b!=.
graph bar Q_1b_* if inrange(Q_1b,1,2), percentages /// percent is the default
ytitle("%", size(small) orientation(horizontal)) ylabel(, labsize(small)) blabel(bar, pos(center) size(small) format(%15.1fc)) ///
title("How well do you think clients are informed about the official pricelist?", size(small)) ///
legend(order(1 "Most clients know the fees well" 2 "Most clients don't know the fees") size(small) col(1)) ///
note("Note:" "Total agents = `r(N)'", size(small))
graph export "$output/agent_survey/`date'/Q_1b.png", as(png) replace

* Q_1c

forval y = 1/2 {
	g Q_1c_`y' = Q_1c==`y'
	}

set scheme jpalfull
qui sum agents_n if Q_1c!=.
graph bar Q_1c_* if inrange(Q_1c,1,2), percentages /// percent is the default
ytitle("%", size(small) orientation(horizontal)) ylabel(, labsize(small)) blabel(bar, pos(center) size(small) format(%15.1fc)) ///
title("Do you think m-banking clients prefer agents who display the official pricelist?", size(small)) ///
legend(order(1 "Yes" 2 "No") size(small) col(1)) ///
note("Note:" "Total agents = `r(N)'", size(small))
graph export "$output/agent_survey/`date'/Q_1c.png", as(png) replace

* Q_2a

forval y = 1/9 {
	g Q_2a__`y' = Q_2a1==`y' | Q_2a2==`y' | Q_2a3==`y'
	}
	
set scheme jpalfull
graph bar Q_2a__*, percentages ///
ytitle("%", size(small) orientation(horizontal)) ylabel(, labsize(small)) blabel(bar, pos(center) size(vsmall) format(%15.1fc)) ///
title("When a client is deciding to open a new account:", size(small)) ///
subtitle("Which of the following characteristics are the most important?", size(small)) ///
legend(order(1 "The client has been a prior customer" 2 "Agent can clearly answer clients' questions" ///
3 "Agent is within a close proximity" 4 "Agent has sufficient cash for transactions" ///
5 "Agent is transparent by showing the official pricelist" ///
6 "Agent is available every time" 7 "Agent can offer the lowest transaction fee" ///
8 "Agent works with the bank where the client wants to open an account" 9 "Others") size(small) col(1))
graph export "$output/agent_survey/`date'/Q_2a.png", as(png) replace

* Q_2b

forval y = 1/9 {
	g Q_2b__`y' = Q_2b1==`y' | Q_2b2==`y' | Q_2b3==`y'
	}

set scheme jpalfull
graph bar Q_2b__*, percentages ///
ytitle("%", size(small) orientation(horizontal)) ylabel(, labsize(small)) blabel(bar, pos(center) size(vsmall) format(%15.1fc)) ///
title("When selecting a regular agent to transact with:", size(small)) ///
subtitle("Which of the following characteristics are the most important?", size(small)) ///
legend(order(1 "The client has been a prior customer" 2 "Agent can clearly answer clients' questions" ///
3 "Agent is within a close proximity" 4 "Agent has sufficient cash for transactions" ///
5 "Agent is transparent by showing the official pricelist" ///
6 "Agent is available every time" 7 "Agent can offer the lowest transaction fee" ///
8 "Agent works with the bank where the client has an account" 9 "Others") size(small) col(1))
graph export "$output/agent_survey/`date'/Q_2b.png", as(png) replace

* Q_3a

forval y = 1/2 {
	g Q_3a_`y' = Q_1c==`y'
	}

set scheme jpalfull
qui sum agents_n if Q_3a!=.
graph bar Q_3a_* if inrange(Q_3a,1,2), percentages /// percent is the default
ytitle("%", size(small) orientation(horizontal)) ylabel(, labsize(small)) blabel(bar, pos(center) size(small) format(%15.1fc)) ///
title("Which of the following statements do you agree with most?", size(small)) ///
legend(order(1 "Many agents available in my area, clients have many options to choose" 2 "Limited number of agents in my area, clients have limited options to choose") size(small) col(1)) ///
note("Note:" "Total agents = `r(N)'", size(small))
graph export "$output/agent_survey/`date'/Q_3a.png", as(png) replace

* Q_3b

forval y = 1/2 {
	g Q_3b_`y' = Q_1c==`y'
	}

set scheme jpalfull
qui sum agents_n if Q_3b!=.
graph bar Q_3b_* if inrange(Q_3b,1,2), percentages /// percent is the default
ytitle("%", size(small) orientation(horizontal)) ylabel(, labsize(small)) blabel(bar, pos(center) size(small) format(%15.1fc)) ///
title("Which of the following statements do you agree with most?", size(small)) ///
legend(order(1 "Clients'd continue transacting with me, even if other agents offer lower prices" 2 "Clients'd transact with other agents who offer lower prices and switch easily") size(small) col(1)) ///
note("Note:" "Total agents = `r(N)'", size(small))
graph export "$output/agent_survey/`date'/Q_3b.png", as(png) replace

* Q_4a

forval y = 1/4 {
	g Q_4a__`y' = Q_4a==`y'
	}

set scheme jpalfull
qui sum agents_n if Q_4a!=.
graph bar Q_4a__* if inrange(Q_4a,1,4), percentages /// percent is the default
ytitle("%", size(small) orientation(horizontal)) ylabel(, labsize(small)) blabel(bar, pos(center) size(small) format(%15.1fc)) ///
title("Suppose the client finds she's charged higher than the bank's official fee by her regular agent:", size(small)) ///
subtitle("How'd she react?", size(small)) ///
legend(order(1 "Indifferent" 2 "Thinks it's unfair, and switch to another agent" 3 "Thinks it's unfair, but continue transacting with her regular agent" 4 "Thinks it's fair") size(small) col(1)) ///
note("Note:" "Total agents = `r(N)'", size(small))
graph export "$output/agent_survey/`date'/Q_4a.png", as(png) replace

* Q_4b

forval y = 1/4 {
	g Q_4b__`y' = Q_4b==`y'
	}

set scheme jpalfull
qui sum agents_n if Q_4b!=.
graph bar Q_4b__* if inrange(Q_4b,1,4), percentages /// percent is the default
ytitle("%", size(small) orientation(horizontal)) ylabel(, labsize(small)) blabel(bar, pos(center) size(small) format(%15.1fc)) ///
title("Suppose the client finds her agent charged another client a lower fee for the same transaction:", size(small)) ///
subtitle("How'd she react?", size(small)) ///
legend(order(1 "Indifferent" 2 "Thinks it's unfair, and switch to another agent" 3 "Thinks it's unfair, but continue transacting with her regular agent" 4 "Thinks it's fair") size(small) col(1)) ///
note("Note:" "Total agents = `r(N)'", size(small))
graph export "$output/agent_survey/`date'/Q_4b.png", as(png) replace

* Q_9a

forval y = 1/2 {
	g Q_9a__`y' = Q_9a==`y'
	}

set scheme jpalfull
qui sum agents_n if Q_9a!=.
graph bar Q_9a__* if inrange(Q_9a,1,2), percentages /// percent is the default
ytitle("%", size(small) orientation(horizontal)) ylabel(, labsize(small)) blabel(bar, pos(center) size(small) format(%15.1fc)) ///
title("Do you also work as an agent for other banks, besides BM?", size(small)) ///
legend(order(1 "Yes" 2 "No") size(small) col(2)) ///
note("Note:" "Total agents = `r(N)'", size(small))
graph export "$output/agent_survey/`date'/Q_9a.png", as(png) replace

* Q_9b

// a. Hist
set scheme 	plotplain
qui sum agents_n if Q_9a==1
histogram Q_9b_1, percent color(brown) ///
	discrete ///
	xlabel(0(10)100) ///
	ylabel(0(2)10) ///
    xtitle("% of revenue using BM EDC", size(small)) ///
    ytitle("Percentage of agents", size(small)) ///
    title("% of revenue using BM EDC") ///
	subtitle("(for agents who also work for other banks)") ///
	note("Note:" "Total agents = `r(N)'", size(small))
graph export "$output/agent_survey/`date'/Q_9b_hist.png", as(png) replace

// b. Box plot
set scheme jpalfull
su Q_9b_1 if Q_9a==1, detail
return list
local mean_rounded = round(`r(mean)', 1)
graph box Q_9b_1, yline(`r(mean)', lpattern(.)) ///
	ytitle("% of revenue using BM EDC", size(small)) ///
    title("Box plot: % of revenue using BM EDC", size(medsmall)) ///
    subtitle("(for agents who also work for other banks)", size(medsmall)) ///
	text(`r(p50)' 95 "Median=`r(p50)'", size(vsmall)) ///
	text(`r(p75)' 95 "Q3=`r(p75)'", size(vsmall)) ///
    text(`r(p25)' 95 "Q1=`r(p25)'", size(vsmall)) ///
    text(`r(mean)' 95 "Mean=`mean_rounded'", size(vsmall)) ///
	note("Note:" "Total agents = `r(N)'", size(small))
graph export "$output/agent_survey/`date'/Q_9b_boxplot.png", as(png) replace

* Q_10b

forval y = 1/3 {
	g Q_10b__`y' = Q_10b==`y'
	}

set scheme jpalfull
qui sum agents_n if Q_10b!=.
graph bar Q_10b__* if inrange(Q_10b,1,3), percentages /// percent is the default
ytitle("%", size(small) orientation(horizontal)) ylabel(, labsize(small)) blabel(bar, pos(center) size(small) format(%15.1fc)) ///
title("What's the level of agent competition in your area?", size(small)) ///
legend(order(1 "High (a lot of competition)" 2 "Neither high nor low" 3 "Low (not much competition)") size(small) col(1)) ///
note("Note:" "Total agents = `r(N)'", size(small))
graph export "$output/agent_survey/`date'/Q_10b.png", as(png) replace

* Q_10c

forval y = 1/3 {
	g Q_10c__`y' = Q_10c==`y'
	}

set scheme jpalfull
qui sum agents_n if Q_10c!=.
graph bar Q_10c__* if inrange(Q_10c,1,3), percentages /// percent is the default
ytitle("%", size(small) orientation(horizontal)) ylabel(, labsize(small)) blabel(bar, pos(center) size(small) format(%15.1fc)) ///
title("How easy for you to attract new clients?", size(small)) ///
legend(order(1 "Easy (a lot of demand from people around)" 2 "Neither easy nor difficult" 3 "Difficult (not much demand from people around)") size(small) col(1)) ///
note("Note:" "Total agents = `r(N)'", size(small))
graph export "$output/agent_survey/`date'/Q_10c.png", as(png) replace

* Q_10d

set scheme plotplain
qui sum Q_10d_1 if Q_10d_1!=.
histogram Q_10d_1, percent color(brown) ///
	discrete ///
	xlabel(2013(1)2023) ///
	ylabel(0(5)30) ///
    xtitle("Year", size(small)) ///
    ytitle("Percentage of agents", size(small)) ///
    title("Since when have you been an agent for BM?") ///
	note("Note:" "Total agents = `r(N)'", size(small))
graph export "$output/agent_survey/`date'/Q_10d.png", as(png) replace
	
* Q_11a

forval y = 0/1{
	g Q_11a_`y' = Q_11a==`y'
	}

set scheme jpalfull
qui sum agents_n if Q_11a!=.
graph bar Q_11a_* if inrange(Q_11a,0,1), percentages /// percent is the default
ytitle("%", size(small) orientation(horizontal)) ylabel(, labsize(small)) blabel(bar, pos(center) size(small) format(%15.1fc)) ///
title("What is your gender?", size(small)) ///
legend(order(1 "Male" 2 "Female") size(small) col(2)) ///
note("Note:" "Total agents = `r(N)'", size(small))
graph export "$output/agent_survey/`date'/Q_11a.png", as(png) replace
	
* Q_11b

forval y = 1/5{
	g Q_11b_`y' = Q_11b==`y'
	}

set scheme jpalfull
qui sum agents_n if Q_11b!=.
graph bar Q_11b_* if inrange(Q_11b,1,5), percentages /// percent is the default
ytitle("%", size(small) orientation(horizontal)) ylabel(, labsize(small)) blabel(bar, pos(center) size(small) format(%15.1fc)) ///
title("How old are you?", size(small)) ///
legend(order(1 "18-25 years old" 2 "26-30 years old" 3 "31-40 years old" 4 "41-50 years old" 5 ">50 years old") size(small) col(3)) ///
note("Note:" "Total agents = `r(N)'", size(small))
graph export "$output/agent_survey/`date'/Q_11b.png", as(png) replace

* Q_12a

forval y = 1/10{
	g Q_12a_`y' = Q_12a==`y'
	}

set scheme jpalfull
qui sum agents_n if Q_12a!=.
graph bar Q_12a_* if inrange(Q_12a,1,10), percentages /// percent is the default
ytitle("%", size(small) orientation(horizontal)) ylabel(, labsize(small)) blabel(bar, pos(top) size(vsmall) format(%15.1fc)) ///
title("How'll you like to receive your survey compensation?", size(small)) ///
legend(order(1 "Phone credit (Telkomsel)" 2 "Phone credit (Three)" 3 "Phone credit (XL)" 4 "Phone credit (Axis)" 5 "Phone credit (Indosat)" 6 "E-money (OVO)" 7 "E-money (GoPay)" 8 "E-money (LinkAja)" 9 "E-money (DANA)" 10 "E-money (ShopeePay)") size(small) col(2)) ///
note("Note:" "Total agents = `r(N)'", size(small))
graph export "$output/agent_survey/`date'/Q_12a.png", as(png) replace
