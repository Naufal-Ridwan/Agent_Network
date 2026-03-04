*===================================================*
* PILOT - CLIENT SURVEY (BASELINE)					*
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

use "$dta\deidentified_client_baseline_survey.dta", clear
// use "A:\\cleaned_client_survey_baseline_`date'.dta", clear 

set more off
set scheme 	plotplain

***************
*DATA ANALYSIS*
***************
//gen clients_n = _n  // for notes on total N agents

* Check attrition rates
/*
tab Progress
set scheme 	plotplain
qui sum clients_n
histogram Progress, percent color(brown) ///
	discrete ///
    xtitle("Survey progress (in %)", size(small)) ///
    ytitle("Percentage of clients", size(small)) ///
    title("Survey progress (in %)") ///
	note("Note:" "Total clients = `r(N)'", size(small))
graph export "$output/client_survey_baseline/`date'/progress.png", as(png) replace
*/

//drop if finished==0 
//drop if informed_consent==.
//drop clients_n

gen clients_n = _n  // for notes on total N agents

* Survey duration

set scheme jpalfull
su total_duration, detail
return list
local mean_rounded = round(`r(mean)', 1)
graph box total_duration if total_duration < 100, yline(`r(mean)', lpattern(.)) ///
	ytitle("Survey duration (in minutes)", size(small)) ///
    title("Box plot: Survey duration (in minutes)", size(medsmall)) ///
	text(`r(p50)' 95 "Median=`r(p50)'", size(vsmall)) ///
	text(`r(p75)' 95 "Q3=`r(p75)'", size(vsmall)) ///
    text(`r(p25)' 95 "Q1=`r(p25)'", size(vsmall)) ///
    text(`r(mean)' 95 "Mean=`mean_rounded'", size(vsmall)) ///
	note("Note:" "Total clients = `r(N)'", size(small))
graph export "$output/client_survey_baseline/`date'/survey_duration.png", as(png) replace


** IMPORTANT VARS **

* Summary table

labvars Q_1b_1_1 Q_2b_1_1 Q_8b Q_9c_1 ///
"Cash deposit: Amount of charged fees" ///
"Cash deposit: Amount of charged fees" ///
"Estimated N of agents in the area" ///
"Percentage of transactions with regular BM agent"

eststo clear
eststo a: quietly estpost summarize ///
		Q_1b_1_1 Q_2b_1_1 Q_8b Q_9c_1
esttab a using "$output/client_survey_baseline/`date'/summary_stats_client_survey_baseline.tex", replace ///
		tex cells("mean(fmt(%13.2fc)) sd(fmt(%13.2fc)) count(fmt(%13.0fc)) min(fmt(%13.0fc)) max(fmt(%13.0fc))") ///
		nonumber nomtitle nonote noobs label collabels("Mean" "SD" "N" "Min" "Max")	


* Q_1b_1

// a. Hist
set scheme 	plotplain
qui sum Q_1b_1_1
histogram Q_1b_1_1, percent color(brown) ///
	discrete ///
	xlabel(0(1000)10000) ///
    xtitle("Cash deposit: Charged transaction fees", size(small)) ///
    ytitle("Percentage of clients", size(small)) ///
    title("Cash deposit: Charged transaction fees by BM agent") ///
	note("Note:" "Total clients = `r(N)'", size(small))
graph export "$output/client_survey_baseline/`date'/Q_1b_1_hist.png", as(png) replace

// b. Box plot
set scheme jpalfull
su Q_1b_1_1, detail
return list
local mean_rounded = round(`r(mean)', 1)
graph box Q_1b_1_1, yline(`r(mean)', lpattern(.)) ///
	ytitle("Cash deposit: Charged transaction fees", size(small)) ///
    title("Cash deposit: Charged transaction fees by BM agent", size(medsmall)) ///
	text(`r(p50)' 95 "Median=`r(p50)'", size(vsmall)) ///
	text(`r(p75)' 95 "Q3=`r(p75)'", size(vsmall)) ///
    text(`r(p25)' 95 "Q1=`r(p25)'", size(vsmall)) ///
    text(`r(mean)' 95 "Mean=`mean_rounded'", size(vsmall)) ///
	note("Note:" "Total clients = `r(N)'", size(small))
graph export "$output/client_survey_baseline/`date'/Q_1b_1_boxplot.png", as(png) replace
	
* Q_2b_1

// a. Hist
set scheme 	plotplain
qui sum Q_2b_1_1
histogram Q_2b_1_1, percent color(brown) ///
	discrete ///
	xlabel(0(1000)10000) ///
    xtitle("Cash withdrawal: Charged transaction fees", size(small)) ///
    ytitle("Percentage of clients", size(small)) ///
    title("Cash withdrawal: Charged transaction fees by BM agent") ///
	note("Note:" "Total clients = `r(N)'", size(small))
graph export "$output/client_survey_baseline/`date'/Q_2b_1_hist.png", as(png) replace

// b. Box plot
set scheme jpalfull
su Q_2b_1_1, detail
return list
local mean_rounded = round(`r(mean)', 1)
graph box Q_2b_1_1, yline(`r(mean)', lpattern(.)) ///
	ytitle("Cash withdrawal: Charged transaction fees", size(small)) ///
    title("Cash withdrawal: Charged transaction fees by BM agent", size(medsmall)) ///
	text(`r(p50)' 95 "Median=`r(p50)'", size(vsmall)) ///
	text(`r(p75)' 95 "Q3=`r(p75)'", size(vsmall)) ///
    text(`r(p25)' 95 "Q1=`r(p25)'", size(vsmall)) ///
    text(`r(mean)' 95 "Mean=`mean_rounded'", size(vsmall)) ///
	note("Note:" "Total clients = `r(N)'", size(small))
graph export "$output/client_survey_baseline/`date'/Q_2b_1_boxplot.png", as(png) replace

* Q_8b

// a. Hist
set scheme 	plotplain
qui sum Q_8b
histogram Q_8b if Q_8b<51, percent color(brown) ///
	discrete ///
    xtitle("Estimated N of agents in the area", size(small)) ///
    ytitle("Percentage of clients", size(small)) ///
    title("How many agents are in your area?") ///
	subtitle("(BM agents & agents from other banks)") ///
	note("Note:" "Total clients = `r(N)'", size(small))
graph export "$output/client_survey_baseline/`date'/Q_8b_hist.png", as(png) replace
	
// b. Box plot
set scheme jpalfull
su Q_8b, detail
return list
local mean_rounded = round(`r(mean)', 1)
graph box Q_8b, yline(`r(mean)', lpattern(.)) ///
	ytitle("Estimate of N agents within 5 km/in the same village", size(small)) ///
    title("Box plot: Estimate of N agents within 5 km/in the same village", size(medsmall)) ///
	subtitle ("") ///
	text(`r(p50)' 95 "Median=`r(p50)'", size(vsmall)) ///
	text(`r(p75)' 95 "Q3=`r(p75)'", size(vsmall)) ///
    text(`r(p25)' 95 "Q1=`r(p25)'", size(vsmall)) ///
    text(`r(mean)' 95 "Mean=`mean_rounded'", size(vsmall)) ///
	note("Note:" "Total clients = `r(N)'", size(small))
graph export "$output/client_survey_baseline/`date'/Q_8b_boxplot.png", as(png) replace

* Q_9c

// a. Hist
set scheme 	plotplain
qui sum Q_9c_1
histogram Q_9c_1, percent color(brown) ///
	discrete ///
	xlabel(0(5)100) ///
	ylabel(0(2)15) ///
    xtitle("% of overall agent banking transactions with regular BM agent", size(small)) ///
    ytitle("Percentage of clients", size(small)) ///
    title("What percentage of your agent banking transactions") ///
	subtitle("do you do with your regular BM agent?") ///
	note("Note:" "Total clients = `r(N)'", size(small))
graph export "$output/client_survey_baseline/`date'/Q_9c_hist.png", as(png) replace
	
// b. Box plot
set scheme jpalfull
su Q_9c_1, detail
return list
local mean_rounded = round(`r(mean)', 1)
graph box Q_9c_1, yline(`r(mean)', lpattern(.)) ///
	ytitle("% of overall agent banking transactions with regular BM agent", size(small)) ///
    title("Box plot: % of overall agent banking transactions with regular BM agent", size(medsmall)) ///
	subtitle ("") ///
	text(`r(p50)' 95 "Median=`r(p50)'", size(vsmall)) ///
	text(`r(p75)' 95 "Q3=`r(p75)'", size(vsmall)) ///
    text(`r(p25)' 95 "Q1=`r(p25)'", size(vsmall)) ///
    text(`r(mean)' 95 "Mean=`mean_rounded'", size(vsmall)) ///
	note("Note:" "Total clients = `r(N)'", size(small))
graph export "$output/client_survey_baseline/`date'/Q_9c_boxplot.png", as(png) replace
	
* Q_1a

forval y = 1/6 {
	g Q_1a_`y' = Q_1a==`y'
	}

set scheme jpalfull
qui sum clients_n if Q_1a!=. 
graph bar Q_1a_* if inrange(Q_1a,1,6), percentages /// percent is the default
ytitle("%", size(small) orientation(horizontal)) ylabel(, labsize(small)) blabel(bar, pos(top) size(vsmall) format(%15.1fc)) ///
title("When was the last time you did a cash deposit", size(small)) ///
subtitle("with your regular BM agent?", size(small)) ///
legend(order(1 "Within the past 7 days" 2 "8-15 days ago" 3 "16-30 days ago" 4 "More than 1 (one) month ago" 5 "More than 6 (six) months ago" 6 "I haven't done this transaction with BM agent") size(small) col(1)) ///
note("Note:" "Total clients = `r(N)'", size(small))
graph export "$output/client_survey_baseline/`date'/Q_1a.png", as(png) replace

* Q_2a

forval y = 1/6 {
	g Q_2a_`y' = Q_2a==`y'
	}

set scheme jpalfull
qui sum clients_n if Q_2a!=. 
graph bar Q_2a_* if inrange(Q_2a,1,6), percentages /// percent is the default
ytitle("%", size(small) orientation(horizontal)) ylabel(, labsize(small)) blabel(bar, pos(top) size(vsmall) format(%15.1fc)) ///
title("When was the last time you did a cash withdrawal", size(small)) ///
subtitle("with your regular BM agent?", size(small)) ///
legend(order(1 "Within the past 7 days" 2 "8-15 days ago" 3 "16-30 days ago" 4 "More than 1 (one) month ago" 5 "More than 6 (six) months ago" 6 "I haven't done this transaction with BM agent") size(small) col(1)) ///
note("Note:" "Total clients = `r(N)'", size(small))
graph export "$output/client_survey_baseline/`date'/Q_2a.png", as(png) replace

* Q_1b_2

forval y = 1/7 {
	g Q_1b_2_`y' = Q_1b_2==`y'
	}

set scheme jpalfull
qui sum clients_n if Q_1b_2!=. 
graph bar Q_1b_2_* if inrange(Q_1b_2,1,7), percentages /// percent is the default
ytitle("%", size(small) orientation(horizontal)) ylabel(, labsize(small)) blabel(bar, pos(top) size(vsmall) format(%15.1fc)) ///
title("If you are unsure of the exact amount of fees charged for your latest cash deposit transaction,", size(small)) ///
subtitle("what was the approximate amount?", size(small)) ///
legend(order(1 "Rp 0 – 750" 2 "Rp 750 – 1.500" 3 "Rp 1.500 – 2.250" 4 "Rp 2.250 – 3.000" 5 "Rp 3.000 – 3.750" 6 "Rp 3.750 – 4.500" 7 "> Rp 4.500") size(small) col(1)) ///
note("Note:" "Total clients = `r(N)'", size(small))
graph export "$output/client_survey_baseline/`date'/Q_1b_2.png", as(png) replace

* Q_2b_2

forval y = 1/7 {
	g Q_2b_2_`y' = Q_2b_2==`y'
	}

set scheme jpalfull
qui sum clients_n if Q_2b_2!=. 
graph bar Q_2b_2_* if inrange(Q_2b_2,1,7), percentages /// percent is the default
ytitle("%", size(small) orientation(horizontal)) ylabel(, labsize(small)) blabel(bar, pos(top) size(vsmall) format(%15.1fc)) ///
title("If you are unsure of the exact amount of fees charged for your latest cash withdrawal transaction,", size(small)) ///
subtitle("what was the approximate amount?", size(small)) ///
legend(order(1 "Rp 0 – 750" 2 "Rp 750 – 1.500" 3 "Rp 1.500 – 2.250" 4 "Rp 2.250 – 3.000" 5 "Rp 3.000 – 3.750" 6 "Rp 3.750 – 4.500" 7 "> Rp 4.500") size(small) col(1)) ///
note("Note:" "Total clients = `r(N)'", size(small))
graph export "$output/client_survey_baseline/`date'/Q_2b_2.png", as(png) replace

* Q_3a_1

forval y = 1/3 {
	g Q_3a_1_`y' = Q_3a_1==`y'
	}

set scheme jpalfull
qui sum clients_n if Q_3a_1!=. 
graph bar Q_3a_1_* if inrange(Q_3a_1,1,3), percentages /// percent is the default
ytitle("%", size(small) orientation(horizontal)) ylabel(, labsize(small)) blabel(bar, pos(top) size(vsmall) format(%15.1fc)) ///
title("Is there an official list of transaction fees from BM", size(small)) ///
subtitle("that the agents must follow?", size(small)) ///
legend(order(1 "Yes" 2 "No" 3 "I don't know") size(small) col(3)) ///
note("Note:" "Total clients = `r(N)'", size(small))
graph export "$output/client_survey_baseline/`date'/Q_3a_1.png", as(png) replace

* Q_3a_2

forval y = 1/2 {
	g Q_3a_2_`y' = Q_3a_2==`y'
	}

set scheme jpalfull
qui sum clients_n if Q_3a_2!=. 
graph bar Q_3a_2_* if inrange(Q_3a_2,1,2), percentages /// percent is the default
ytitle("%", size(small) orientation(horizontal)) ylabel(, labsize(small)) blabel(bar, pos(top) size(vsmall) format(%15.1fc)) ///
title("Does your regular BM agent display the official pricelist", size(small)) ///
subtitle("before transactions?", size(small)) ///
legend(order(1 "Yes" 2 "No") size(small) col(3)) ///
note("Note:" "Total clients = `r(N)'", size(small))
graph export "$output/client_survey_baseline/`date'/Q_3a_2.png", as(png) replace

* Q_3b

forval y = 1/2 {
	g Q_3b_`y' = Q_3b==`y'
	}

set scheme jpalfull
qui sum clients_n if Q_3b!=. 
graph bar Q_3b_* if inrange(Q_3b,1,2), percentages /// percent is the default
ytitle("%", size(small) orientation(horizontal)) ylabel(, labsize(small)) blabel(bar, pos(top) size(vsmall) format(%15.1fc)) ///
title("Do you agree with the statement:", size(small)) ///
subtitle("Majority of banking agents charge higher fees than what's set by the bank", size(small)) ///
legend(order(1 "Yes" 2 "No") size(small) col(3)) ///
note("Note:" "Total clients = `r(N)'", size(small))
graph export "$output/client_survey_baseline/`date'/Q_3b.png", as(png) replace

** BAR CHARTS FOR OTHER VARS **

* Q_4b

forval y = 1/3 {
	g Q_4b__`y' = Q_4b==`y'
	}

set scheme jpalfull
qui sum clients_n if Q_4b!=.
graph bar Q_4b__* if inrange(Q_4b,1,3), percentages /// percent is the default
ytitle("%", size(small) orientation(horizontal)) ylabel(, labsize(small)) blabel(bar, pos(top) size(vsmall) format(%15.1fc)) ///
title("For your latest transaction with your regular BM,", size(small)) ///
subtitle("which of the following statement do you agree with?", size(small)) ///
legend(order(1 "BM agent charged me more than the official fee" 2 "BM agent charged me exactly the official fee" 3 "BM agent charged me less than the official fee") size(small) col(1)) ///
note("Note:" "Total clients = `r(N)'", size(small))
graph export "$output/client_survey_baseline/`date'/Q_4b.png", as(png) replace

* Q_4c

forval y = 1/3 {
	g Q_4c__`y' = Q_4c==`y'
	}

set scheme jpalfull
qui sum clients_n if Q_4c!=.
graph bar Q_4c__* if inrange(Q_4c,1,3), percentages /// percent is the default
ytitle("%", size(small) orientation(horizontal)) ylabel(, labsize(small)) blabel(bar, pos(top) size(vsmall) format(%15.1fc)) ///
title("For your latest transaction with your regular BM,", size(small)) ///
subtitle("which of the following statement do you agree with?", size(small)) ///
legend(order(1 "The agent was happy to help me" 2 "The agent didn't have time & couldn't help" 3 "The agent asked me to do transaction with another agent") size(small) col(1)) ///
note("Note:" "Total clients = `r(N)'", size(small))
graph export "$output/client_survey_baseline/`date'/Q_4c.png", as(png) replace


* Q_4d

set scheme 	plotplain
qui sum Q_4d_1
histogram Q_4d_1, percent color (brown) ///
	discrete ///
    xtitle("Satisfaction level", size(small)) ///
    ytitle("Percentage of clients", size(small)) ///
	title("For your latest transaction with your regular BM,", size(small)) ///
	subtitle("how satisfied were you with the service?", size(small)) ///
	note("Note:" "Total clients = `r(N)'", size(small))
	graph export "$output/client_survey_baseline/`date'/Q_4d_hist.png", as(png) replace

* Q_5a

forval y = 1/9 {
	g Q_5a__`y' = Q_5a1==`y' | Q_5a2==`y' | Q_5a3==`y'
	}
	
set scheme jpalfull
graph bar Q_5a__*, percentages ///
ytitle("%", size(small) orientation(horizontal)) ylabel(, labsize(small)) blabel(bar, pos(top) size(vsmall) format(%15.1fc)) ///
title("When selecting a regular agent,", size(small)) ///
subtitle("which of the following characteristics are the most important?", size(small)) ///
legend(order(1 "I have been a prior customer" 2 "Can clearly answer my questions" ///
3 "Is within close proximity" 4 "Often has sufficient cash for transactions" ///
5 "Is transparent by displaying official price list" 6 "Is available everytime I need to make transactions" ///
7 "Offers the lowest transaction fees" 8 "Works with the bank where I want to open an account" ///
9 "Others") size(small) col(1))
graph export "$output/client_survey_baseline/`date'/Q_5a.png", as(png) replace

* Q_5b

forval y = 1/2 {
	g Q_5b_`y' = Q_5b==`y'
	}

set scheme jpalfull
qui sum clients_n if Q_5b!=.
graph bar Q_5b_* if inrange(Q_5b,1,2), percentages /// percent is the default
ytitle("%", size(small) orientation(horizontal)) ylabel(, labsize(small)) blabel(bar, pos(top) size(vsmall) format(%15.1fc)) ///
title("Which of the following statements do you agree with most?", size(small)) ///
legend(order(1 "Continue transacting with my regular agent, even if other agents offer lower prices" 2 "Switch to transact with other agents who offer lower prices") size(small) col(1)) ///
note("Note:" "Total clients = `r(N)'", size(small))
graph export "$output/client_survey_baseline/`date'/Q_5b.png", as(png) replace

* Q_6b (TBD)

// ssc install splitvallabels

la var  Q_6b_1	"Honest or fair" 
la var 	Q_6b_2 	"Competent"
la var 	Q_6b_3 	"Socially minded"
la var  Q_6b_4 	"Trustworthy"
la var 	Q_6b_5	"Interested in helping clients"

set scheme jpalfull
foreach		x 	of varlist 	Q_6b_1 Q_6b_2 Q_6b_3 Q_6b_4 Q_6b_5	{
				
				qui sum clients_n  if `x' !=.
				loc obs = `r(N)'

				loc	z: 	var lab 	`x'
				splitvallabels		`x'	
				
				graph bar, over(`x', label(labsize(vsmall)) relabel(`r(relabel)')) ytitle("%", size(small)) ylabel(0(20)100, grid labsize(vsmall)) ///
							title("`z'", size(small)) bar(1) blabel(bar, size(vsmall) format(%4.1f)) ///
							note("Note:" "Total clients = `obs'", span size(vsmall)) name(`x', replace)
		}

graph		combine Q_6b_1 Q_6b_2 Q_6b_3 Q_6b_4 Q_6b_5, ///
			col(2) iscale(0.75) xcommon xsize(20) ysize(20) imargin(3 3 3) ///
			title("BM agent vs agents from other banks", size(medsmall))
graph 		export "$output/client_survey_baseline/`date'/Q_6b.png", as(png) replace

* Q_7a (TBD)

la var  Q_7a_1	"Cares building long-term relation w/ clients" 
la var 	Q_7a_2 	"Cares about clients' well-being"
la var 	Q_7a_3 	"Honest & trustworthy"
la var  Q_7a_4 	"Cares about educating clients"
la var 	Q_7a_5	"Cares about benefitting society"
la var 	Q_7a_6	"Cares about clients new to banking"

set scheme jpalfull
foreach		x 	of varlist 	Q_7a_1 Q_7a_2 Q_7a_3 Q_7a_4 Q_7a_5 Q_7a_6	{
				
				qui sum clients_n  if `x' !=.
				loc obs = `r(N)'

				loc	z: 	var lab 	`x'
				splitvallabels		`x'	
				
				graph bar, over(`x', label(labsize(vsmall)) relabel(`r(relabel)')) ytitle("%", size(small)) ylabel(0(20)100, grid labsize(vsmall)) ///
							title("`z'", size(small)) bar(1) blabel(bar, size(vsmall) format(%4.1f)) ///
							note("Note:" "Total clients = `obs'", span size(vsmall)) name(`x', replace)
		}


graph		combine Q_7a_1 Q_7a_2 Q_7a_3 Q_7a_4 Q_7a_5 Q_7a_6, ///
			col(2) iscale(0.75) xcommon xsize(20) ysize(20) imargin(3 3 3) ///
			title("BM vs other banks", size(medsmall))
graph 		export "$output/client_survey_baseline/`date'/Q_7a.png", as(png) replace

* Q_8a

forval y = 1/2 {
	g Q_8a_`y' = Q_8a==`y'
	}

set scheme jpalfull
qui sum clients_n if Q_8a!=.
graph bar Q_8a_* if inrange(Q_8a,1,2), percentages /// percent is the default
ytitle("%", size(small) orientation(horizontal)) ylabel(, labsize(small)) blabel(bar, pos(top) size(vsmall) format(%15.1fc)) ///
title("Which of the following statements do you agree with most?", size(small)) ///
legend(order(1 "Many agents available in my area, and I have a lot of options" 2 "Limited number of agents available in my area, and I have limited options") size(small) col(1)) ///
note("Note:" "Total clients = `r(N)'", size(small))
graph export "$output/client_survey_baseline/`date'/Q_8a.png", as(png) replace

* Q_9b

set scheme plotplain
qui sum Q_9b_1 if Q_9b_1!=.
histogram Q_9b_1, percent color(brown) ///
	discrete ///
	xlabel(2013(1)2023) ///
	ylabel(0(5)30) ///
    xtitle("Year", size(small)) ///
    ytitle("Percentage of clients", size(small)) ///
    title("Since when have you been doing transactions") ///
    subtitle("with your regular BM agent?") ///
	note("Note:" "Total clients = `r(N)'", size(small))
graph export "$output/client_survey_baseline/`date'/Q_9b.png", as(png) replace

* Q_9d_1

forval y = 1/3 {
	g Q_9d_1__`y' = Q_9d_1==`y'
	}

set scheme jpalfull
qui sum clients_n if Q_9d_1!=.
graph bar Q_9d_1__* if inrange(Q_9d_1,1,3), percentages /// percent is the default
ytitle("%", size(small) orientation(horizontal)) ylabel(, labsize(small)) blabel(bar, pos(top) size(vsmall) format(%15.1fc)) ///
title("Prior to your first transaction with your regular BM agent,", size(small)) ///
subtitle("did the agent approach you to sign up for BM products?", size(small)) ///
legend(order(1 "Yes, the agent approached me first" 2 "No, I was interested in signing myself up" 3 "I don't remember") size(small) col(1)) ///
note("Note:" "Total clients = `r(N)'", size(small))
graph export "$output/client_survey_baseline/`date'/Q_9d_1.png", as(png) replace

* Q_9d_2

forval y = 1/6 {
	g Q_9d_2__`y' = Q_9d_2==`y'
	}

set scheme jpalfull
qui sum clients_n if Q_9d_2!=.
graph bar Q_9d_2__* if inrange(Q_9d_2,1,6), percentages /// percent is the default
ytitle("%", size(small) orientation(horizontal)) ylabel(, labsize(small)) blabel(bar, pos(top) size(vsmall) format(%15.1fc)) ///
title("When the agent approached you first,", size(small)) ///
subtitle("what was her main strategy?", size(small)) ///
legend(order(1 "Trustworthiness of the agent" ///
2 "Quality of products and services they offer" ///
3 "Reliability and availability of sufficient cash balance for withdrawals" ///
4 "Convenience and proximity to your location" ///
5 "Low fees for transactions" ///
6 "Help they provide with transactions") size(small) col(1)) ///
note("Note:" "Total clients = `r(N)'", size(small))
graph export "$output/client_survey_baseline/`date'/Q_9d_2.png", as(png) replace

* Q_9e

forval y = 1/3 {
	g Q_9e__`y' = Q_9e==`y'
	}

set scheme jpalfull
qui sum clients_n if Q_9e!=.
graph bar Q_9e__* if inrange(Q_9e,1,3), percentages /// percent is the default
ytitle("%", size(small) orientation(horizontal)) ylabel(, labsize(small)) blabel(bar, pos(top) size(vsmall) format(%15.1fc)) ///
title("Compared to agents from other banks,", size(small)) ///
subtitle("do you think your regular BM agent is more / less honest and transparent about prices?", size(small)) ///
legend(order(1 "More honest & transparent" ///
2 "No difference" ///
3 "Less honest & transparent") size(small) col(1)) ///
note("Note:" "Total clients = `r(N)'", size(small))
graph export "$output/client_survey_baseline/`date'/Q_9e.png", as(png) replace

* Q_10a

forval y = 1/4 {
	g Q_10a__`y' = Q_10a==`y'
	}

set scheme jpalfull
qui sum clients_n if Q_10a!=.
graph bar Q_10a__* if inrange(Q_10a,1,4), percentages /// percent is the default
ytitle("%", size(small) orientation(horizontal)) ylabel(, labsize(small)) blabel(bar, pos(top) size(vsmall) format(%15.1fc)) ///
title("Suppose your regular agent charged you a higher fee than the bank's official pricelist,", size(small)) ///
subtitle("how'd you react?", size(small)) ///
legend(order(1 "I'd be indifferent" ///
2 "I'd think it is unfair, and switch to transact with another agent" ///
3 "I'd think it is unfair, but continue transacting with my regular agent" ///
4 "I'd think it is fair") size(small) col(1)) ///
note("Note:" "Total clients = `r(N)'", size(small))
graph export "$output/client_survey_baseline/`date'/Q_10a.png", as(png) replace

* Q_10b

forval y = 1/4 {
	g Q_10b__`y' = Q_10b==`y'
	}

set scheme jpalfull
qui sum clients_n if Q_10b!=.
graph bar Q_10b__* if inrange(Q_10b,1,4), percentages /// percent is the default
ytitle("%", size(small) orientation(horizontal)) ylabel(, labsize(small)) blabel(bar, pos(top) size(vsmall) format(%15.1fc)) ///
title("Suppose your regular agent charged another client a lower fee than you (for the same transaction),", size(small)) ///
subtitle("how'd you react?", size(small)) ///
legend(order(1 "I'd be indifferent" ///
2 "I'd think it is unfair, and switch to transact with another agent" ///
3 "I'd think it is unfair, but continue transacting with my regular agent" ///
4 "I'd think it is fair") size(small) col(1)) ///
note("Note:" "Total clients = `r(N)'", size(small))
graph export "$output/client_survey_baseline/`date'/Q_10b.png", as(png) replace

* Q_10c

forval y = 1/3 {
	g Q_10c__`y' = Q_10c==`y'
	}

set scheme jpalfull
qui sum clients_n if Q_10c!=.
graph bar Q_10c__* if inrange(Q_10c,1,3), percentages /// percent is the default
ytitle("%", size(small) orientation(horizontal)) ylabel(, labsize(small)) blabel(bar, pos(top) size(vsmall) format(%15.1fc)) ///
title("Suppose there are two agents who both charge IDR 2k,", size(small)) ///
subtitle("which agent would you choose?", size(small)) ///
legend(order(1 "Agent A, who charges an official fee of 2k" ///
2 "Agent B, who charges an official fee of 1k + interest fee of 1k" ///
3 "I am indifferent") size(small) col(1)) ///
note("Note:" "Total clients = `r(N)'", size(small))
graph export "$output/client_survey_baseline/`date'/Q_10c.png", as(png) replace

* Q_10d

set scheme plotplain
qui sum Q_10d_1 if Q_10d_1!=.
histogram Q_10d_1, percent color(brown) ///
	discrete ///
	xlabel(0(10)100) ///
	ylabel(0(2)15) ///
    xtitle("% of total charged fees for agent's commission", size(small)) ///
    ytitle("Percentage of clients", size(small)) ///
    title("What percentage of the total charged fees do you think") ///
    subtitle("agents get as commission?") ///
	note("Note:" "Total clients = `r(N)'", size(small))
graph export "$output/client_survey_baseline/`date'/Q_10d.png", as(png) replace


* Q_11b

forval y = 1/2 {
	g Q_11b_`y' = Q_11b==`y'
	}

set scheme jpalfull
qui sum clients_n if Q_11b!=.
graph bar Q_11b_* if inrange(Q_11b,1,3), percentages /// percent is the default
ytitle("%", size(small) orientation(horizontal)) ylabel(, labsize(small)) blabel(bar, pos(top) size(vsmall) format(%15.1fc)) ///
title("Outside your regular BM agent,", size(small)) ///
subtitle("do you do transactions with other BM agents?", size(small)) ///
legend(order(1 "Yes" 2 "No") size(small) col(2)) ///
note("Note:" "Total clients = `r(N)'", size(small))
graph export "$output/client_survey_baseline/`date'/Q_11b.png", as(png) replace

* Q_11c_1

forval y = 1/2 {
	g Q_11c_1_`y' = Q_11c_1==`y'
	}

set scheme jpalfull
qui sum clients_n if Q_11c_1!=.
graph bar Q_11c_1_* if inrange(Q_11c_1,1,3), percentages /// percent is the default
ytitle("%", size(small) orientation(horizontal)) ylabel(, labsize(small)) blabel(bar, pos(top) size(vsmall) format(%15.1fc)) ///
title("Outside your regular BM agent,", size(small)) ///
subtitle("do you do transactions with agents from other banks (outside BM)?", size(small)) ///
legend(order(1 "Yes" 2 "No") size(small) col(2)) ///
note("Note:" "Total clients = `r(N)'", size(small))
graph export "$output/client_survey_baseline/`date'/Q_11c_1.png", as(png) replace

* Q_11c_2

forval y = 1/5 {
	g Q_11c_2_`y' = Q_11c_2==`y'
	}

set scheme jpalfull
qui sum clients_n if Q_11c_2!=.
graph bar Q_11c_2_* if inrange(Q_11c_2,1,5), percentages /// percent is the default
ytitle("%", size(small) orientation(horizontal)) ylabel(, labsize(small)) blabel(bar, pos(top) size(vsmall) format(%15.1fc)) ///
title("When was the last time you did a transaction", size(small)) ///
subtitle("with agents from other banks (outside BM)?", size(small)) ///
legend(order(1 "Within the past 7 days" 2 "8-15 days ago" 3 "16-30 days ago" 4 "More than 1 (one) month ago" 5 "More than 6 (six) months ago") size(small) col(2)) ///
note("Note:" "Total clients = `r(N)'", size(small))
graph export "$output/client_survey_baseline/`date'/Q_11c_2.png", as(png) replace

* Q_12a

forval y = 0/1{
	g Q_12a_`y' = Q_12a==`y'
	}

set scheme jpalfull
qui sum clients_n if Q_12a!=.
graph bar Q_12a_* if inrange(Q_12a,0,1), percentages /// percent is the default
ytitle("%", size(small) orientation(horizontal)) ylabel(, labsize(small)) blabel(bar, pos(top) size(vsmall) format(%15.1fc)) ///
title("What is your gender?", size(small)) ///
legend(order(1 "Male" 2 "Female") size(small) col(2)) ///
note("Note:" "Total clients = `r(N)'", size(small))
graph export "$output/client_survey_baseline/`date'/Q_12a.png", as(png) replace
	
* Q_12b

forval y = 1/5{
	g Q_12b_`y' = Q_12b==`y'
	}

set scheme jpalfull
qui sum clients_n if Q_12b!=.
graph bar Q_12b_* if inrange(Q_12b,1,5), percentages /// percent is the default
ytitle("%", size(small) orientation(horizontal)) ylabel(, labsize(small)) blabel(bar, pos(top) size(vsmall) format(%15.1fc)) ///
title("How old are you?", size(small)) ///
legend(order(1 "18-25 years old" 2 "26-30 years old" 3 "31-40 years old" 4 "41-50 years old" 5 ">50 years old") size(small) col(3)) ///
note("Note:" "Total clients = `r(N)'", size(small))
graph export "$output/client_survey_baseline/`date'/Q_12b.png", as(png) replace

* Q_12c

forval y = 1/2{
	g Q_12c_`y' = Q_12c==`y'
	}

set scheme jpalfull
qui sum clients_n if Q_12c!=.
graph bar Q_12c_* if inrange(Q_12c,1,2), percentages /// percent is the default
ytitle("%", size(small) orientation(horizontal)) ylabel(, labsize(small)) blabel(bar, pos(top) size(vsmall) format(%15.1fc)) ///
title("Are you self-employed?", size(small)) ///
legend(order(1 "Yes" 2 "No") size(small) col(2)) ///
note("Note:" "Total clients = `r(N)'", size(small))
graph export "$output/client_survey_baseline/`date'/Q_12c.png", as(png) replace

* Q_12d_1

forval y = 1/2{
	g Q_12d_1_`y' = Q_12d_1==`y'
	}

set scheme jpalfull
qui sum clients_n if Q_12d_1!=.
graph bar Q_12d_1_* if inrange(Q_12d_1,1,2), percentages /// percent is the default
ytitle("%", size(small) orientation(horizontal)) ylabel(, labsize(small)) blabel(bar, pos(top) size(vsmall) format(%15.1fc)) ///
title("Do you use agent banking services for your business", size(small)) ///
legend(order(1 "Yes" 2 "No") size(small) col(2)) ///
note("Note:" "Total clients = `r(N)'", size(small))
graph export "$output/client_survey_baseline/`date'/Q_12d_1.png", as(png) replace

* Q_12d_2

forval y = 1/2{
	g Q_12d_2_`y' = Q_12d_2==`y'
	}

set scheme jpalfull
qui sum clients_n if Q_12d_2!=.
graph bar Q_12d_2_* if inrange(Q_12d_2,1,2), percentages /// percent is the default
ytitle("%", size(small) orientation(horizontal)) ylabel(, labsize(small)) blabel(bar, pos(top) size(vsmall) format(%15.1fc)) ///
title("Do you use agent banking services to receive your salary?", size(small)) ///
legend(order(1 "Yes" 2 "No") size(small) col(2)) ///
note("Note:" "Total clients = `r(N)'", size(small))
graph export "$output/client_survey_baseline/`date'/Q_12d_2.png", as(png) replace

* Q_13a

forval y = 1/10{
	g Q_13a_`y' = Q_13a==`y'
	}

set scheme jpalfull
qui sum clients_n if Q_13a!=.
graph bar Q_13a_* if inrange(Q_13a,1,10), percentages /// percent is the default
ytitle("%", size(small) orientation(horizontal)) ylabel(, labsize(small)) blabel(bar, pos(top) size(vsmall) format(%15.1fc)) ///
title("How'll you like to receive your survey compensation?", size(small)) ///
legend(order(1 "Phone credit (Telkomsel)" 2 "Phone credit (Three)" 3 "Phone credit (XL)" 4 "Phone credit (Axis)" 5 "Phone credit (Indosat)" 6 "E-money (OVO)" 7 "E-money (GoPay)" 8 "E-money (LinkAja)" 9 "E-money (DANA)" 10 "E-money (ShopeePay)") size(small) col(2)) ///
note("Note:" "Total clients = `r(N)'", size(small))
graph export "$output/client_survey_baseline/`date'/Q_13a.png", as(png) replace
