*===================================================*
* Full-Scale - Agent Survey (Baseline)
* HFC
* Last modified: 25 November 2024
* Stata version: 17
*===================================================*

clear all
set more off

*****************************************
**--------------DATA PATH--------------**
*****************************************
gl user = c(username)

*Set your username here (change your "$user" == "[your username here]" and recheck the path on the next line)
// dis c(username) // activate this code if you need to check your username

* Riko
if "$user" == "Riko"{
	gl path "C:\Users\Riko\Dropbox\17 Large-Scale RCT"
	loc initials "MRP"
	}

* Set the path
	gl do			"$path\dofiles\agent_baseline"
	gl dta			"$path\dtafiles"
	gl log			"$path\logfiles"
	gl output		"$path\output"
	gl raw			"$path\rawresponses\agent_baseline"
	
	cd				"$path\scheme"

***IMPORTANT***

* Set local date
loc date : di %tdDNCY daily("$S_DATE", "DMY") // this is the default code, it will automatically capture the current date
// loc date "DDMMYYYY" // only use this manual setting if you're running this code late than the supposed day

shell mkdir "$output\\Agent Baseline - `date'"

*************
*IMPORT DATA*
*************
use "$dta\cleaned_baseline_agent_survey_`date'.dta", clear 

***************
*DATA ANALYSIS*
***************
gen agents_n = _n  // for notes on total N agents

drop if informed_consent == 0 // drop people who refuse to participate in the survey

**# Survey duration (in minutes)
preserve

qui su total_duration, det
local total_before = r(N)

keep if total_duration < 100

qui su total_duration, detail
return list

local total_after = r(N)
local dropped_obs = `total_before' - `total_after'

* Boxplot
set scheme jpalfull

local mean_rounded = round(`r(mean)', 1)
local Q_1_rounded = round(`r(p25)', 1)
local Q_3_rounded = round(`r(p75)', 1)
local median_rounded = round(`r(p50)', 1)

graph box total_duration, yline(`r(mean)', lpattern(.)) ///
	ytitle("Survey duration (in minutes)", size(small)) ///
    title("Survey duration (in minutes)", size(medsmall)) ///
	subtitle("Restricted to respondents who participate in the survey", size(medsmall)) ///
	text(`r(p50)' 95 "Median=`median_rounded'", size(vsmall)) ///
	text(`r(p75)' 95 "Q3=`Q_3_rounded'", size(vsmall)) ///
    text(`r(p25)' 95 "Q1=`Q_1_rounded'", size(vsmall)) ///
    text(`r(mean)' 95 "Mean=`mean_rounded'", size(vsmall)) ///
	note("Note:" "Total agents = `r(N)'" "Survey duration above 100 minutes is dropped" "Number of dropped observations = `dropped_obs'", size(small))
	
graph export "$output\\Agent Baseline - `date'/1 - survey_duration_boxplot.png", as(png) replace

* Histogram
gen td_hist = round(total_duration, 1)
qui sum td_hist,det
set scheme plotplain

histogram td_hist, percent color(brown) ///
	discrete ///
	xlabel(0(10)100) ///
	ylabel(0(5)30) ///
    xtitle(" ", size(small)) ///
    ytitle("Percentage of agents", size(small)) ///
    title("Survey Duration (in minutes)") ///
	subtitle("Restricted to respondents who participate in the survey") ///
	note("Note:" "Total agents = `r(N)'" "Survey duration above 100 minutes is dropped" "Number of dropped observations = `dropped_obs'", size(small))
	
graph export "$output\\Agent Baseline - `date'/1 - survey_duration_hist.png", as(png) replace

restore

**# Summary table
labvars q_3b q_3d q_3e q_4c q_4d q_6 q_8a q_8b_1 q_9a  ///
"Estd reduced rev if 50pc higher than official fees" ///
"Estd reduced rev if 50pc higher to other customer" ///
"Estd reduced rev if withdrawal fees increase 1,5K" ///
"Estd reduced rev if new agent charges 50pc less" ///
"Prior: Estd change in agent number" ///
"Posterior: Estd change in agent number" ///
"Pc of revenues from branchless banking bus last mth" ///
"Pc of revenues from BM business last month" ///
"Number of agents in the area"

*** Sumstat (general)
eststo clear
eststo a: estpost summarize ///
		q_3b q_3d q_3e q_4c q_4d q_6 q_8a q_8b_1 q_9a
esttab a using "$output\\Agent Baseline - `date'/summary_stats_agent_baseline.tex", replace ///
		tex cells("count(fmt(%13.0fc)) mean(fmt(%13.2fc)) sd(fmt(%13.2fc)) min(fmt(%13.0fc)) max(fmt(%13.0fc))") ///
		nonumber nomtitle noobs label collabels("N" "Mean" "SD" "Min" "Max") note("Note: pc refers to percent. Current date: `date'")
		
*** Sumstat (by treatment groups)
local num = 0
local tgroups Pure_Control T1 T2 T3 T4

forval t = 1/5 {
    local tgroup : word `t' of `tgroups'
	
	eststo clear
	eststo z: estpost summarize ///
			q_4d q_6 q_7a if treatment_status == `num', det
	esttab z using "$output\\Agent Baseline - `date'/sumstat_by_treatment_groups_`tgroup'.tex", replace ///
			tex cells("count(fmt(%13.0fc)) mean(fmt(%13.2fc)) p50(fmt(%13.2fc)) sd(fmt(%13.2fc)) min(fmt(%13.0fc)) max(fmt(%13.0fc))") ///
			nonumber nomtitle noobs label collabels("N" "Mean" "Median" "SD"  "Min" "Max") title("Treatment Group: `tgroup'") note("Current date: `date'")
		
	local num = `num' + 1
}

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

graph bar gr_1a_*, percentages /// percent is the default
	ytitle("In percentage (%)", size(medsmall) orientation(vertical)) ///
	ylabel(, labsize(medsmall)) ///
	blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
	title("Banking agents charge {bf:a fee} for each transaction made with them.", size(medsmall)) ///
	subtitle("How do you {bf:set these fees}?", size(medsmall)) ///
	legend(order(1 "I follow the official list" 2 "I set my own prices") size(medsmall) col(2)) ///
	note("Note:" "Total agents = `r(N)'", size(medsmall))
	
graph export "$output\\Agent Baseline - `date'/2 - q_1a.png", as(png) replace

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

graph bar gr_1b_*, percentages /// percent is the default
	ytitle("In percentage (%)", size(medsmall) orientation(vertical)) ///
	ylabel(, labsize(medsmall)) ///
	blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
	title("Do you charge {bf:all} clients {bf:the same fee}?", size(medsmall)) ///
	subtitle(" ", size(medsmall)) ///
	legend(order(1 "Yes" 2 "No") size(medsmall) col(2)) ///
	note("Note:" "Total agents = `r(N)'", size(medsmall))
	
graph export "$output\\Agent Baseline - `date'/3 - q_1b.png", as(png) replace

*** q_1b_1
local x = 1
forval nmr = 1/2 {
	gen gr_1b_1_`nmr' = 1 if q_1b_1 == `x'
	recode gr_1b_1_`nmr' (. = 0)
	replace gr_1b_1_`nmr' = . if q_1b_1 == .
	
	local x = `x' - 1
}

set scheme jpalfull

qui sum agents_n if q_1b_1!=. 

graph bar gr_1b_1_*, percentages /// percent is the default
	ytitle("In percentage (%)", size(medsmall) orientation(vertical)) ///
	ylabel(, labsize(medsmall)) ///
	blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
	title("Do you have {bf:a specific type of customers} that you charge", size(medsmall)) ///
	subtitle("{bf:the lowest fees} from?", size(medsmall)) ///
	legend(order(1 "Yes" 2 "No") size(medsmall) col(2)) ///
	note("Note:" "Total agents = `r(N)'", size(medsmall))

graph export "$output\\Agent Baseline - `date'/4 - q_1b_1.png", as(png) replace

*** q_1b_1_1
set scheme jpalfull

qui sum agents_n if q_1b_1_a != .

graph bar q_1b_1_a - q_1b_1_g,  ///
	ytitle("Proportion", size(medsmall) orientation(vertical)) ///
	ylabel(, labsize(medsmall)) ///
	blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
	title("Who do you charge {bf:the lowest fees}?", size(medsmall)) ///
	subtitle(" ", size(medsmall)) ///
	legend(order(1 "Friends and family" 2 "High-value cust" 3 "New cust" 4 "Long-time cust" 5 "Poorer cust" 6 "Cust from local area" 7 "Cust who can easily do business with other agents") size(small) col(2)) ///
	note("Note:" "Total agents = `r(N)'", size(medsmall))
	
graph export "$output\\Agent Baseline - `date'/5 - q_1b_1_1.png", as(png) replace

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

graph bar gr_1c_*, percentages /// percent is the default
	ytitle("In percentage (%)", size(medsmall) orientation(vertical)) ///
	ylabel(, labsize(medsmall)) ///
	blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
	title("How well do you think customers in your area are {bf:informed about}", size(medsmall)) ///
	subtitle("{bf:the official fees} for transactions set by Bank Mandiri?", size(medsmall)) ///
	legend(order(1 "Most clients know the fees well" 2 "Most clients do not know the fees") size(small) col(2)) ///
	note("Note:" "Total agents = `r(N)'", size(medsmall))
	
graph export "$output\\Agent Baseline - `date'/6 - q_1c.png", as(png) replace

**# 2. Section 2
*** q_2a
preserve

keep unique_code q_2a_*
drop q_2a_DO
drop if q_2a_1 == .

gen num = _n
qui sum num
local obs2a = `r(N)'

reshape long q_2a_, i(unique_code) j(q_2a)

la def q_2a ///
1 "Client is a prior cust" ///
2 "Agent clearly answer question" ///
3 "Agent proximity to home/work" ///
4 "Agent has sufficient cash" ///
5 "Price transparent and display" ///
6 "Agent always available" ///
7 "Agent offers lowest price" ///
8 "Agent affiliated w/bank to open acc" ///
9 "Client trust the agent" ///
10 "Agent equally charges everyone"

la val q_2a q_2a

tab q_2a_, gen(answer)

set scheme jpalfull

graph bar (sum) answer*, stack percentage over(q_2a, label(angle(30) labsize(small))) ///
	title("Important characteristics to be {bf:a regular cust}", size(medsmall)) ///
	subtitle(" ", size(medsmall)) ///
	legend(order(1 "Not important at all" 2 "Not very important" 3 "Important" 4 "Very important") size(medsmall) col(2)) ///
	note("Note:" "Total agents = `obs2a'", size(medsmall)) ///
	ytitle("%", size(medsmall) orientation(horizontal)) ///
	ylabel(, labsize(medsmall)) ///
	blabel(bar, pos(center) size(small) format(%15.1fc))
	
graph export "$output\\Agent Baseline - `date'/7 - q_2a.png", as(png) replace

restore

// labvars q_2a_1 - q_2a_10 ///
// "Client is a prior customer" ///
// "Agent can clearly answer question" ///
// "Agent proximity to home/workplace" ///
// "Agent has sufficient cash balance" ///
// "Price transparent and displayed on the store" ///
// "Agent always available every time needed" ///
// "Agent offers the lowest price" ///
// "Agent works w/ the bank whr client wants to open acc" ///
// "Client trust the agent" ///
// "Agent charges everyone the same prices"
//
// set scheme jpalfull
// foreach x of varlist q_2a_1 q_2a_2 q_2a_3 q_2a_4 q_2a_5 q_2a_6 q_2a_7 q_2a_8 q_2a_9 q_2a_10 {
//				
// 	qui sum agents_n  if `x' !=.
// 	loc obs = `r(N)'
//
// 	loc	z: 	var lab 	`x'
// 	splitvallabels		`x'	
//				
// 	graph bar, over(`x', label(labsize(vsmall)) relabel(`r(relabel)')) ytitle("%", size(small) orientation(horizontal)) ylabel(0(25)100, grid labsize(vsmall)) ///
// 	title("`z'", size(small)) bar(1) blabel(bar, size(vsmall) format(%4.1f)) ///
// 	note("Note:" "Total agents = `obs'", span size(vsmall)) name(`x', replace)
// }
//
//
// graph		combine q_2a_1 q_2a_2 q_2a_3 q_2a_4 q_2a_5 q_2a_6 q_2a_7 q_2a_8 q_2a_9 q_2a_10, ///
// 			col(2) iscale(0.55) xcommon xsize(30) ysize(30) imargin(0 0 0) ///
// 			title("Important characteristics to be {bf:a regular cust}", size(small))
// graph 		export "$output\\Agent Baseline - `date'/7 - q_2a.png", as(png) replace

**# 3. Section 3
*** q_3a
forval x = 1/4 {
	gen gr_3a_`x' = 1 if q_3a == `x'
	recode gr_3a_`x' (. = 0)
	replace gr_3a_`x' = . if q_3a == .
}

set scheme jpalfull

qui sum agents_n if q_3a!=. 

graph bar gr_3a_*, percentages /// percent is the default
	ytitle("In percentage (%)", size(medsmall) orientation(vertical)) ///
	ylabel(, labsize(medsmall)) ///
	blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
	title("Client reaction if the agent charges {bf:50% higher than the official fees}", size(medsmall)) ///
	subtitle(" ", size(medsmall)) ///
	legend(order(1 "Indifferent" 2 "Unfair, and start transacting with another agent" 3 "Unfair, but would continue making transactions with the same agent" 4 "Fair") size(small) col(1)) ///
	note("Note:" "Total agents = `r(N)'", size(medsmall))

graph export "$output\\Agent Baseline - `date'/8 - q_3a.png", as(png) replace

*** q_3b
preserve

** Drop missing variable (if any)
drop if q_3b == .

** Summary statistics
qui summarize q_3b, detail
return list

** Store obs number before dropping outlier(s)
local total_before = r(N)

** Detect and drop outlier(s)
generate iqr = r(p75) - r(p25)
generate lower_limit = r(p25) - 1.5 * iqr
generate upper_limit = r(p75) + 1.5 * iqr
generate outlier = (q_3b < lower_limit) | (q_3b > upper_limit)
drop if outlier == 1

** Store obs number after dropping outlier(s) and compute the difference
qui summarize q_3b, detail
local total_after = r(N)
local dropped_obs = `total_before' - `total_after'

** Store lower and upper threshold
qui su lower_limit, det
local ll = round(`r(mean)', 1)
qui su upper_limit, det
local ul = round(`r(mean)', 1)

* Histogram

histogram q_3b, percent color(brown) ///
	discrete ///
	xlabel(0(5)100) ///
	ylabel(0(2)15) ///
    xtitle("% of reduced revenue", size(medsmall)) ///
    ytitle("Percentage of agents", size(medsmall)) ///
    title("{bf:Estimated agent reduced revenue}", size(medsmall)) ///
	subtitle("if the agent charges {bf:50% higher than the official fees}", size(medsmall)) ///
	note("Note:" "Total agents = `r(N)'" "Outlier threshold = `ll' (lower) and `ul' (upper)" "Dropped outlier observation = `dropped_obs'", size(medsmall))
	
graph export "$output\\Agent Baseline - `date'/9 - q_3b_hist.png", as(png) replace

* Box plot

qui su q_3b, det
return list

local mean_rounded = round(`r(mean)', 1)	
local Q_1_rounded = round(`r(p25)', 1)
local Q_3_rounded = round(`r(p75)', 1)
local median_rounded = round(`r(p50)', 1)

graph box q_3b, yline(`r(mean)', lpattern(.)) ///
	ytitle("In percentage (%)", size(medsmall)) ///
    title("{bf:Estimated agent reduced revenue}", size(medsmall)) ///
    subtitle("if the agent charges {bf:50% higher than the official fees}", size(medsmall)) ///
	text(`r(p50)' 95 "Median=`median_rounded'", size(vsmall)) ///
	text(`r(p75)' 95 "Q3=`Q_3_rounded'", size(vsmall)) ///
    text(`r(p25)' 95 "Q1=`Q_1_rounded'", size(vsmall)) ///
    text(`r(mean)' 95 "Mean=`mean_rounded'", size(vsmall)) ///
	note("Note:" "Total agents = `r(N)'" "Outlier threshold = `ll' (lower) and `ul' (upper)" "Dropped outlier observation = `dropped_obs'", size(medsmall))
	
graph export "$output\\Agent Baseline - `date'/9 - q_3b_boxplot.png", as(png) replace

restore

*** q_3c
forval x = 1/4 {
	gen gr_3c_`x' = 1 if q_3c == `x'
	recode gr_3c_`x' (. = 0)
	replace gr_3c_`x' = . if q_3c == .
}

set scheme jpalfull

qui sum agents_n if q_3c!=. 

graph bar gr_3c_*, percentages /// percent is the default
	ytitle("In percentage (%)", size(medsmall) orientation(vertical)) ///
	ylabel(, labsize(medsmall)) ///
	blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
	title("Client reaction if the agent charges {bf:50% higher to another customer}", size(medsmall)) ///
	subtitle(" ", size(medsmall)) ///
	legend(order(1 "Indifferent" 2 "Unfair, and start transacting with another agent" 3 "Unfair, but would continue making transactions with the same agent" 4 "Fair") size(small) col(1)) ///
	note("Note:" "Total agents = `r(N)'", size(medsmall))
	
graph export "$output\\Agent Baseline - `date'/10 - q_3c.png", as(png) replace

*** q_3d
preserve

** Drop missing variable (if any)
drop if q_3d == .

** Summary statistics
qui summarize q_3d, detail
return list

** Store obs number before dropping outlier(s)
local total_before = r(N)

** Detect and drop outlier(s)
generate iqr = r(p75) - r(p25)
generate lower_limit = r(p25) - 1.5 * iqr
generate upper_limit = r(p75) + 1.5 * iqr
generate outlier = (q_3d < lower_limit) | (q_3d > upper_limit)
drop if outlier == 1

** Store obs number after dropping outlier(s) and compute the difference
qui summarize q_3d, detail
local total_after = r(N)
local dropped_obs = `total_before' - `total_after'

** Store lower and upper threshold
qui su lower_limit, det
local ll = round(`r(mean)', 1)
qui su upper_limit, det
local ul = round(`r(mean)', 1)

* Histogram
set scheme plotplain

histogram q_3d, percent color(brown) ///
	discrete ///
	xlabel(0(5)100) ///
	ylabel(0(2)15) ///
    xtitle("% of reduced revenue", size(medsmall)) ///
    ytitle("Percentage of agents", size(medsmall)) ///
    title("{bf:Estimated agent reduced revenue}", size(medsmall)) ///
	subtitle("if the agent charges {bf:50% higher to another customer}", size (medsmall)) ///
	note("Note:" "Total agents = `r(N)'" "Outlier threshold = `ll' (lower) and `ul' (upper)" "Dropped outlier observation = `dropped_obs'", size(medsmall))
	
graph export "$output\\Agent Baseline - `date'/11 - q_3d_hist.png", as(png) replace

* Box plot
set scheme jpalfull

qui su q_3d, det
return list

local mean_rounded = round(`r(mean)', 1)	
local Q_1_rounded = round(`r(p25)', 1)
local Q_3_rounded = round(`r(p75)', 1)
local median_rounded = round(`r(p50)', 1)

graph box q_3d, yline(`r(mean)', lpattern(.)) ///
	ytitle("In percentage (%)", size(medsmall)) ///
    title("{bf:Estimated agent reduced revenue}", size(medsmall)) ///
    subtitle("if the agent charges {bf:50% higher to another customer}", size(medsmall)) ///
	text(`r(p50)' 95 "Median=`median_rounded'", size(vsmall)) ///
	text(`r(p75)' 95 "Q3=`Q_3_rounded'", size(vsmall)) ///
    text(`r(p25)' 95 "Q1=`Q_1_rounded'", size(vsmall)) ///
    text(`r(mean)' 95 "Mean=`mean_rounded'", size(vsmall)) ///
	note("Note:" "Total agents = `r(N)'" "Outlier threshold = `ll' (lower) and `ul' (upper)" "Dropped outlier observation = `dropped_obs'", size(medsmall))
	
graph export "$output\\Agent Baseline - `date'/11 - q_3d_boxplot.png", as(png) replace

restore

*** q_3e
preserve

** Drop missing variable (if any)
drop if q_3e == .

** Summary statistics
qui summarize q_3e, detail
return list

** Store obs number before dropping outlier(s)
local total_before = r(N)

** Detect and drop outlier(s)
generate iqr = r(p75) - r(p25)
generate lower_limit = r(p25) - 1.5 * iqr
generate upper_limit = r(p75) + 1.5 * iqr
generate outlier = (q_3e < lower_limit) | (q_3e > upper_limit)
drop if outlier == 1

** Store obs number after dropping outlier(s) and compute the difference
qui summarize q_3e, detail
local total_after = r(N)
local dropped_obs = `total_before' - `total_after'

** Store lower and upper threshold
qui su lower_limit, det
local ll = round(`r(mean)', 1)
qui su upper_limit, det
local ul = round(`r(mean)', 1)

* Histogram
set scheme plotplain

histogram q_3e, percent color(brown) ///
	discrete ///
	xlabel(0(5)100) ///
	ylabel(0(2)15) ///
    xtitle("% of reduced revenue", size(medsmall)) ///
    ytitle("Percentage of agents", size(medsmall)) ///
    title("{bf:Estimated agent reduced revenue}", size(medsmall)) ///
	subtitle("if the withdrawal transaction fees {bf:increased from IDR 3K to 4,5K}", size(medsmall)) ///
	note("Note:" "Total agents = `r(N)'" "Outlier threshold = `ll' (lower) and `ul' (upper)" "Dropped outlier observation = `dropped_obs'", size(medsmall))
	
graph export "$output\\Agent Baseline - `date'/12 - q_3e_hist.png", as(png) replace

* Box plot
set scheme jpalfull

su q_3e, det
return list

local mean_rounded = round(`r(mean)', 1)	
local Q_1_rounded = round(`r(p25)', 1)
local Q_3_rounded = round(`r(p75)', 1)
local median_rounded = round(`r(p50)', 1)

graph box q_3e, yline(`r(mean)', lpattern(.)) ///
	ytitle("In percentage (%)", size(medsmall)) ///
    title("{bf:Estimated agent reduced revenue}", size(medsmall)) ///
    subtitle("if the withdrawal transaction fees {bf:increased from IDR 3K to 4,5K}", size(medsmall)) ///
	text(`r(p50)' 95 "Median=`median_rounded'", size(vsmall)) ///
	text(`r(p75)' 95 "Q3=`Q_3_rounded'", size(vsmall)) ///
    text(`r(p25)' 95 "Q1=`Q_1_rounded'", size(vsmall)) ///
    text(`r(mean)' 95 "Mean=`mean_rounded'", size(vsmall)) ///
	note("Note:" "Total agents = `r(N)'" "Outlier threshold = `ll' (lower) and `ul' (upper)" "Dropped outlier observation = `dropped_obs'", size(medsmall))
	
graph export "$output\\Agent Baseline - `date'/12 - q_3e_boxplot.png", as(png) replace

restore

**# 4. Section 4
*** q_4a
forval x = 1/2 {
	gen gr_4a_`x' = 1 if q_4a == `x'
	recode gr_4a_`x' (. = 0)
	replace gr_4a_`x' = . if q_4a == .
}

set scheme jpalfull

qui sum agents_n if q_4a!=. 

graph bar gr_4a_*, percentages /// percent is the default
	ytitle("In percentage (%)", size(medsmall) orientation(vertical)) ///
	ylabel(, labsize(medsmall)) ///
	blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
	title("Which of the following statements do you {bf:agree with most}?", size(medsmall)) ///
	subtitle(" ", size(medsmall)) ///
	legend(order(1 "Many agents in my area" 2 "A limited number of agents in my area") size(small) col(2)) ///
	note("Note:" "Total agents = `r(N)'", size(medsmall))
	
graph export "$output\\Agent Baseline - `date'/13 - q_4a.png", as(png) replace

*** q_4b
forval x = 1/2 {
	gen gr_4b_`x' = 1 if q_4b == `x'
	recode gr_4b_`x' (. = 0)
	replace gr_4b_`x' = . if q_4b == .
}

set scheme jpalfull

qui sum agents_n if q_4b!=. 

graph bar gr_4b_*, percentages /// percent is the default
	ytitle("In percentage (%)", size(medsmall) orientation(vertical)) ///
	ylabel(, labsize(medsmall)) ///
	blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
	title("Which of the following statements do you {bf:agree with most}?", size(medsmall)) ///
	subtitle(" ", size(medsmall)) ///
	legend(order(1 "Continue doing business with me, even if other agents offer lower price" 2 "Change to other agents who offer lower prices and can easily switch") size(small) col(1)) ///
	note("Note:" "Total agents = `r(N)'", size(medsmall))
	
graph export "$output\\Agent Baseline - `date'/14 - q_4b.png", as(png) replace

*** q_4c
preserve

** Drop missing variable (if any)
drop if q_4c == .

** Summary statistics
qui summarize q_4c, detail
return list

** Store obs number before dropping outlier(s)
local total_before = r(N)

** Detect and drop outlier(s)
generate iqr = r(p75) - r(p25)
generate lower_limit = r(p25) - 1.5 * iqr
generate upper_limit = r(p75) + 1.5 * iqr
generate outlier = (q_4c < lower_limit) | (q_4c > upper_limit)
drop if outlier == 1

** Store obs number after dropping outlier(s) and compute the difference
qui summarize q_4c, detail
local total_after = r(N)
local dropped_obs = `total_before' - `total_after'

** Store lower and upper threshold
qui su lower_limit, det
local ll = round(`r(mean)', 1)
qui su upper_limit, det
local ul = round(`r(mean)', 1)

* Histogram
set scheme plotplain

histogram q_4c, percent color(brown) ///
	discrete ///
	xlabel(0(5)100) ///
	ylabel(0(2)15) ///
    xtitle("% of reduced revenue", size(medsmall)) ///
    ytitle("Percentage of agents", size(medsmall)) ///
    title("{bf:Estimated agent reduced revenue}", size(medsmall)) ///
	subtitle("if a {bf:new agent charges 50% less}", size(medsmall)) ///
	note("Note:" "Total agents = `r(N)'" "Outlier threshold = `ll' (lower) and `ul' (upper)" "Dropped outlier observation = `dropped_obs'", size(medsmall))
	
graph export "$output\\Agent Baseline - `date'/15 - q_4c_hist.png", as(png) replace

* Box plot
set scheme jpalfull

su q_4c, det
return list

local mean_rounded = round(`r(mean)', 1)	
local Q_1_rounded = round(`r(p25)', 1)
local Q_3_rounded = round(`r(p75)', 1)
local median_rounded = round(`r(p50)', 1)

graph box q_4c, yline(`r(mean)', lpattern(.)) ///
	ytitle("In percentage (%)", size(medsmall)) ///
    title("{bf:Estimated agent reduced revenue}", size(medsmall)) ///
    subtitle("if a {bf:new agent charges 50% less}", size(medsmall)) ///
	text(`r(p50)' 95 "Median=`median_rounded'", size(vsmall)) ///
	text(`r(p75)' 95 "Q3=`Q_3_rounded'", size(vsmall)) ///
    text(`r(p25)' 95 "Q1=`Q_1_rounded'", size(vsmall)) ///
    text(`r(mean)' 95 "Mean=`mean_rounded'", size(vsmall)) ///
	note("Note:" "Total agents = `r(N)'" "Outlier threshold = `ll' (lower) and `ul' (upper)" "Dropped outlier observation = `dropped_obs'", size(medsmall))
	
graph export "$output\\Agent Baseline - `date'/15 - q_4c_boxplot.png", as(png) replace

restore

*** q_4d (Prior Beliefs: Overall)
preserve

** Drop missing variable (if any)
drop if q_4d == .

** Summary statistics
qui summarize q_4d, detail
return list

** Store obs number before dropping outlier(s)
local total_before = r(N)

** Detect and drop outlier(s)
generate iqr = r(p75) - r(p25)
generate lower_limit = r(p25) - 1.5 * iqr
generate upper_limit = r(p75) + 1.5 * iqr
generate outlier = (q_4d < lower_limit) | (q_4d > upper_limit)
drop if outlier == 1

** Store obs number after dropping outlier(s) and compute the difference
qui summarize q_4d, detail
local total_after = r(N)
local dropped_obs = `total_before' - `total_after'

** Store lower and upper threshold
qui su lower_limit, det
local ll = round(`r(mean)', 1)
qui su upper_limit, det
local ul = round(`r(mean)', 1)

* Histogram
set scheme plotplain

histogram q_4d, percent color(brown) ///
	discrete ///
	xlabel(-100(10)100) ///
	ylabel(0(2)10) ///
    xtitle("Estimated change in the number of agents (in %)", size(medsmall)) ///
    ytitle("Percentage of agents", size(medsmall)) ///
    title("Estimated change in the number of agents in %", size(medsmall)) ///
	subtitle("{bf: Prior beliefs}", size(medsmall)) ///
	note("Note:" "Total agents = `r(N)'" "Outlier threshold = `ll' (lower) and `ul' (upper)" "Dropped outlier observation = `dropped_obs'", size(medsmall))
	
graph export "$output\\Agent Baseline - `date'/16 - q_4d_hist.png", as(png) replace

* Box plot
set scheme jpalfull

su q_4d, detail
return list

local mean_rounded = round(`r(mean)', 1)	
local Q_1_rounded = round(`r(p25)', 1)
local Q_3_rounded = round(`r(p75)', 1)
local median_rounded = round(`r(p50)', 1)

graph box q_4d, yline(`r(mean)', lpattern(.)) ///
	ytitle("In percentage (%)", size(medsmall)) ///
    title("Estimated change in the number of agents in %", size(medsmall)) ///
    subtitle("{bf: Prior beliefs}", size(medsmall)) ///
	text(`r(p50)' 95 "Median=`median_rounded'", size(vsmall)) ///
	text(`r(p75)' 95 "Q3=`Q_3_rounded'", size(vsmall)) ///
    text(`r(p25)' 95 "Q1=`Q_1_rounded'", size(vsmall)) ///
    text(`r(mean)' 95 "Mean=`mean_rounded'", size(vsmall)) ///
	note("Note:" "Total agents = `r(N)'" "Outlier threshold = `ll' (lower) and `ul' (upper)" "Dropped outlier observation = `dropped_obs'", size(medsmall))
	
graph export "$output\\Agent Baseline - `date'/16 - q_4d_boxplot.png", as(png) replace

restore

*** q_4d (Prior Beliefs: By Treatment Status)
* Histogram
forval a = 0/4 {
    gen gr_4d_t`a' = q_4d if treatment_status == `a'
}

labvars gr_4d_t0 gr_4d_t1 gr_4d_t2 gr_4d_t3 gr_4d_t4 ///
"{bf: Prior beliefs (Pure Control)}" ///
"{bf: Prior beliefs (T1)}" ///
"{bf: Prior beliefs (T2)}" ///
"{bf: Prior beliefs (T3)}" ///
"{bf: Prior beliefs (T4)}"

local a = 0
foreach b of varlist gr_4d_t0 gr_4d_t1 gr_4d_t2 gr_4d_t3 gr_4d_t4 {
    preserve
	
	** Drop missing variable (if any)
	drop if `b' == .
	
	** Summary statistics
	qui summarize `b', detail
	return list
	
	** Store obs number before dropping outlier(s)
	local total_before = r(N)
	
	** Detect and drop outlier(s)
	generate iqr = r(p75) - r(p25)
	generate lower_limit = r(p25) - 1.5 * iqr
	generate upper_limit = r(p75) + 1.5 * iqr
	generate outlier = (`b' < lower_limit) | (`b' > upper_limit)
	drop if outlier == 1
	
	** Store obs number after dropping outlier(s) and compute the difference
	qui summarize `b', detail
	local total_after = r(N)
	local dropped_obs = `total_before' - `total_after'

	** Store lower and upper threshold
	qui su lower_limit, det
	local ll = round(`r(mean)', 1)
	qui su upper_limit, det
	local ul = round(`r(mean)', 1)
	
	** Histogram
    local z: var lab `b'
	set scheme plotplain
	
	histogram `b', percent color(brown) ///
		discrete ///
		xlabel(-100(10)100) ///
		ylabel(0(2)20) ///
		xtitle("Estimated change in the number of agents (in %)", size(medsmall)) ///
		ytitle("Percentage of agents", size(medsmall)) ///
		title("Estimated change in the number of agents in %", size(medsmall)) ///
		subtitle("`z'", size(medsmall)) ///
		note("Note:" "Total agents = `r(N)'" "Outlier threshold = `ll' (lower) and `ul' (upper)" "Dropped outlier observation = `dropped_obs'", size(medsmall))
		
	graph export "$output\\Agent Baseline - `date'/16 - q_4d_hist_T`a'.png", as(png) replace

	local a = `a' + 1
	
	restore
}

**# 5. Treatment randomization proportion
local a = 0
forval x = 1/5 {
	gen gr_tstat_`x' = 1 if treatment_status == `a'
	recode gr_tstat_`x' (. = 0)
	replace gr_tstat_`x' = . if treatment_status == .
	local a = `a' + 1
}

set scheme jpalfull

qui sum agents_n if treatment_status!=. 

graph bar gr_tstat_*, percentages /// percent is the default
	ytitle("In percentage (%)", size(medsmall) orientation(vertical)) ///
	ylabel(, labsize(medsmall)) ///
	blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
	title("Treatment arm randomization", size(medsmall)) ///
	subtitle(" ", size(medsmall)) ///
	legend(order(1 "Pure Control" 2 "T1" 3 "T2" 4 "T3" 5 "T4") size(medsmall) col(5)) ///
	note("Note:" "Total agents = `r(N)'", size(medsmall))
	
graph export "$output\\Agent Baseline - `date'/17 - treatment_randomization.png", as(png) replace

**# 6. Section 6 (Posterior Beliefs)
*** q_6 (Overall)
preserve

** Drop missing variable (if any)
drop if q_6 == .

** Summary statistics
qui summarize q_6, detail
return list

** Store obs number before dropping outlier(s)
local total_before = r(N)

** Detect and drop outlier(s)
generate iqr = r(p75) - r(p25)
generate lower_limit = r(p25) - 1.5 * iqr
generate upper_limit = r(p75) + 1.5 * iqr
generate outlier = (q_6 < lower_limit) | (q_6 > upper_limit)
drop if outlier == 1

** Store obs number after dropping outlier(s) and compute the difference
qui summarize q_6, detail
local total_after = r(N)
local dropped_obs = `total_before' - `total_after'

** Store lower and upper threshold
qui su lower_limit, det
local ll = round(`r(mean)', 1)
qui su upper_limit, det
local ul = round(`r(mean)', 1)

* Histogram
set scheme plotplain

histogram q_6, percent color(brown) ///
	discrete ///
	xlabel(-100(10)100) ///
	ylabel(0(3)30) ///
    xtitle("Estimated change in the number of agents (in %)", size(medsmall)) ///
    ytitle("Percentage of agents", size(medsmall)) ///
    title("Estimated change in the number of agents in %", size(medsmall)) ///
	subtitle("{bf: Posterior beliefs}", size(medsmall)) ///
	note("Note:" "Total agents = `r(N)'" "Outlier threshold = `ll' (lower) and `ul' (upper)" "Dropped outlier observation = `dropped_obs'", size(medsmall))
	
graph export "$output\\Agent Baseline - `date'/18 - q_6_hist.png", as(png) replace

* Box plot
set scheme jpalfull

su q_6, detail
return list

local mean_rounded = round(`r(mean)', 1)	
local Q_1_rounded = round(`r(p25)', 1)
local Q_3_rounded = round(`r(p75)', 1)
local median_rounded = round(`r(p50)', 1)

graph box q_6, yline(`r(mean)', lpattern(.)) ///
	ytitle("In percentage (%)", size(medsmall)) ///
    title("Estimated change in the number of agents in %", size(medsmall)) ///
    subtitle("{bf: Posterior beliefs}", size(medsmall)) ///
	text(`r(p50)' 95 "Median=`median_rounded'", size(vsmall)) ///
	text(`r(p75)' 95 "Q3=`Q_3_rounded'", size(vsmall)) ///
    text(`r(p25)' 95 "Q1=`Q_1_rounded'", size(vsmall)) ///
    text(`r(mean)' 95 "Mean=`mean_rounded'", size(vsmall)) ///
	note("Note:" "Total agents = `r(N)'" "Outlier threshold = `ll' (lower) and `ul' (upper)" "Dropped outlier observation = `dropped_obs'", size(medsmall))
	
graph export "$output\\Agent Baseline - `date'/18 - q_6_boxplot.png", as(png) replace

restore

*** q_6 (Posterior Beliefs: By Treatment Status)
* Histogram
forval a = 1(2)3 {
    gen gr_6_t`a' = q_6 if treatment_status == `a'
}

labvars gr_6_t1 gr_6_t3 ///
"{bf: Posterior beliefs (T1)}" ///
"{bf: Posterior beliefs (T3)}"

local a = 1
foreach b of varlist gr_6_t1 gr_6_t3 {
    preserve
	
	** Drop missing variable (if any)
	drop if `b' == .
	
	** Summary statistics
	qui summarize `b', detail
	return list
	
	** Store obs number before dropping outlier(s)
	local total_before = r(N)
	
	** Detect and drop outlier(s)
	generate iqr = r(p75) - r(p25)
	generate lower_limit = r(p25) - 1.5 * iqr
	generate upper_limit = r(p75) + 1.5 * iqr
	generate outlier = (`b' < lower_limit) | (`b' > upper_limit)
	drop if outlier == 1
	
	** Store obs number after dropping outlier(s) and compute the difference
	qui summarize `b', detail
	local total_after = r(N)
	local dropped_obs = `total_before' - `total_after'

	** Store lower and upper threshold
	qui su lower_limit, det
	local ll = round(`r(mean)', 1)
	qui su upper_limit, det
	local ul = round(`r(mean)', 1)
	
    local z: var lab `b'
	set scheme plotplain
	
	histogram `b', percent color(brown) ///
		discrete ///
		xlabel(-100(10)100) ///
		ylabel(0(3)30) ///
		xtitle("Estimated change in the number of agents (in %)", size(medsmall)) ///
		ytitle("Percentage of agents", size(medsmall)) ///
		title("Estimated change in the number of agents in %", size(medsmall)) ///
		subtitle("`z'", size(medsmall)) ///
		note("Note:" "Total agents = `r(N)'" "Outlier threshold = `ll' (lower) and `ul' (upper)" "Dropped outlier observation = `dropped_obs'", size(medsmall))
		
	graph export "$output\\Agent Baseline - `date'/18 - q_6_hist_T`a'.png", as(png) replace
	
	local a = `a' + 2
	
	restore
}

**# 7. Section 7 (Marketing Plans)
*** q_7a
* Bar chart
local x = 1
forval nmr = 1/2 {
	gen gr_7a_`nmr' = 1 if q_7a == `x'
	recode gr_7a_`nmr' (. = 0)
	replace gr_7a_`nmr' = . if q_7a == .
	local x = `x' - 1
}

set scheme jpalfull

qui sum agents_n if q_7a!=. 

graph bar gr_7a_*, percentages /// percent is the default
	ytitle("In percentage (%)", size(medsmall) orientation(vertical)) ///
	ylabel(, labsize(medsmall)) ///
	blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
	title("Marketing Plans", size(medsmall)) ///
	subtitle(" ", size(medsmall)) ///
	legend(order(1 "Plan A (agents receive the poster)" 2 "Plan B (clients receive the poster)") size(small) col(5)) ///
	note("Note:" "Total agents = `r(N)'", size(medsmall))
	
graph export "$output\\Agent Baseline - `date'/19 - q_7a.png", as(png) replace

* Bar chart (by treatment groups)
forval a = 2/3 {
    gen gr_7a_t`a' = 1 if treatment_status == `a' & q_7a == 1
	replace gr_7a_t`a' = 2 if treatment_status == `a' & q_7a == 0
}

labvars gr_7a_t2 gr_7a_t3 ///
"{bf:T2} (no info on competition)" ///
"{bf:T3} (info on competition)"

la def planab 1 "Plan A (agents receieve the poster)" 2 "Plan B (clients receive the poster)", replace
la val gr_7a_t2 gr_7a_t3 planab

set scheme jpalfull
foreach x of varlist gr_7a_t2 gr_7a_t3 {
				
	qui sum agents_n  if `x' !=.
	loc obs = `r(N)'

	loc	z: 	var lab 	`x'
	splitvallabels		`x'	
				
	graph bar, over(`x', label(labsize(medium)) relabel(`r(relabel)')) ytitle("%", size(medium) orientation(horizontal)) ylabel(0(25)100, grid labsize(medium)) ///
	asyvars ///
	title("`z'", size(medium)) bar(1) blabel(bar, size(medium) format(%4.1f)) ///
	note("Note:" "Total agents = `obs'", span size(medium)) name(`x', replace)
}


graph		combine gr_7a_t2 gr_7a_t3, ///
			col(2) iscale(0.7) xcommon xsize(30) ysize(15) imargin(0 0 0) ///
			title("{bf: Marketing Plans}", size(medium)) ///
			subtitle("By treatment groups", size(medium))
			
graph 		export "$output\\Agent Baseline - `date'/19 - q_7a_by_T2_T3.png", as(png) replace

* Randomization options check
recode q_7a_DO_1 q_7a_DO_0 (2 = 0)

set scheme jpalfull

qui sum agents_n if q_1a!=. 

graph bar q_7a_DO_1 q_7a_DO_0, percentages /// percent is the default
	ytitle("In percentage (%)", size(medsmall) orientation(vertical)) ///
	ylabel(, labsize(medsmall)) ///
	blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
	title("{bf: Marketing Plans}", size(medsmall)) ///
	subtitle("Option randomization: display order", size(medsmall)) ///
	legend(order(1 "Plan A displayed first" 2 "Plan B displayed first") size(medsmall) col(2)) ///
	note("Note:" "Total agents = `r(N)'", size(medsmall))
	
graph export "$output\\Agent Baseline - `date'/19 - q_7a_display_order.png", as(png) replace

**# 8. Section 8
*** q_8a
preserve

** Drop missing variable (if any)
drop if q_8a == .

** Summary statistics
qui summarize q_8a, detail
return list

** Store obs number before dropping outlier(s)
local total_before = r(N)

** Detect and drop outlier(s)
generate iqr = r(p75) - r(p25)
generate lower_limit = r(p25) - 1.5 * iqr
generate upper_limit = r(p75) + 1.5 * iqr
generate outlier = (q_8a < lower_limit) | (q_8a > upper_limit)
drop if outlier == 1

** Store obs number after dropping outlier(s) and compute the difference
qui summarize q_8a, detail
local total_after = r(N)
local dropped_obs = `total_before' - `total_after'

** Store lower and upper threshold
qui su lower_limit, det
local ll = round(`r(mean)', 1)
qui su upper_limit, det
local ul = round(`r(mean)', 1)

* Histogram
set scheme plotplain

histogram q_8a, percent color(brown) ///
	discrete ///
	xlabel(0(5)100) ///
	ylabel(0(2)15) ///
    xtitle("% of revenue share", size(medsmall)) ///
    ytitle("Percentage of agents", size(medsmall)) ///
    title("{bf:Revenues share} that came from {bf:branchless banking business} last month", size(medsmall)) ///
	subtitle(" ") ///
	note("Note:" "Total agents = `r(N)'" "Outlier threshold = `ll' (lower) and `ul' (upper)" "Dropped outlier observation = `dropped_obs'", size(medsmall))
	
graph export "$output\\Agent Baseline - `date'/20 - q_8a_hist.png", as(png) replace

* Box plot
set scheme jpalfull

su q_8a, det
return list

local mean_rounded = round(`r(mean)', 1)	
local Q_1_rounded = round(`r(p25)', 1)
local Q_3_rounded = round(`r(p75)', 1)
local median_rounded = round(`r(p50)', 1)

graph box q_8a, yline(`r(mean)', lpattern(.)) ///
	ytitle("In percentage (%)", size(medsmall)) ///
    title("{bf:Revenues share} that came from {bf:branchless banking business} last month", size(medsmall)) ///
    subtitle(" ", size(medsmall)) ///
	text(`r(p50)' 95 "Median=`median_rounded'", size(vsmall)) ///
	text(`r(p75)' 95 "Q3=`Q_3_rounded'", size(vsmall)) ///
    text(`r(p25)' 95 "Q1=`Q_1_rounded'", size(vsmall)) ///
    text(`r(mean)' 95 "Mean=`mean_rounded'", size(vsmall)) ///
	note("Note:" "Total agents = `r(N)'" "Outlier threshold = `ll' (lower) and `ul' (upper)" "Dropped outlier observation = `dropped_obs'", size(medsmall))
	
graph export "$output\\Agent Baseline - `date'/20 - q_8a_boxplot.png", as(png) replace

restore

*** q_8b
local x = 1
forval nmr = 1/2 {
	gen gr_8b_`nmr' = 1 if q_8b == `x'
	recode gr_8b_`nmr' (. = 0)
	replace gr_8b_`nmr' = . if q_8b == .
	local x = `x' - 1
}

set scheme jpalfull

qui sum agents_n if q_8b!=. 

graph bar gr_8b_*, percentages /// percent is the default
	ytitle("In percentage (%)", size(medsmall) orientation(vertical)) ///
	ylabel(, labsize(medsmall)) ///
	blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
	title("Do you also work as an agent for other banks, {bf:besides Bank Mandiri}?", size(medsmall)) ///
	subtitle(" ", size(medsmall)) ///
	legend(order(1 "Yes" 2 "No") size(medsmall) col(2)) ///
	note("Note:" "Total agents = `r(N)'", size(medsmall))
	
graph export "$output\\Agent Baseline - `date'/21 - q_8b.png", as(png) replace

*** q_8b_1
preserve

** Drop missing variable (if any)
drop if q_8b_1 == .

** Summary statistics
qui summarize q_8b_1, detail
return list

** Store obs number before dropping outlier(s)
local total_before = r(N)

** Detect and drop outlier(s)
generate iqr = r(p75) - r(p25)
generate lower_limit = r(p25) - 1.5 * iqr
generate upper_limit = r(p75) + 1.5 * iqr
generate outlier = (q_8b_1 < lower_limit) | (q_8b_1 > upper_limit)
drop if outlier == 1

** Store obs number after dropping outlier(s) and compute the difference
qui summarize q_8b_1, detail
local total_after = r(N)
local dropped_obs = `total_before' - `total_after'

** Store lower and upper threshold
qui su lower_limit, det
local ll = round(`r(mean)', 1)
qui su upper_limit, det
local ul = round(`r(mean)', 1)

* Histogram
set scheme plotplain

histogram q_8b_1, percent color(brown) ///
	discrete ///
	xlabel(0(5)100) ///
	ylabel(0(3)30) ///
    xtitle("% of revenue share", size(medsmall)) ///
    ytitle("Percentage of agents", size(medsmall)) ///
    title("{bf:Revenues share} that came from {bf:Bank Mandiri business} last month", size(medsmall)) ///
	subtitle(" ", size(medsmall)) ///
	note("Note:" "Total agents = `r(N)'" "Outlier threshold = `ll' (lower) and `ul' (upper)" "Dropped outlier observation = `dropped_obs'", size(medsmall))
	
graph export "$output\\Agent Baseline - `date'/22 - q_8b_1_hist.png", as(png) replace

* Box plot
set scheme jpalfull

su q_8b_1, det
return list

local mean_rounded = round(`r(mean)', 1)	
local Q_1_rounded = round(`r(p25)', 1)
local Q_3_rounded = round(`r(p75)', 1)
local median_rounded = round(`r(p50)', 1)

graph box q_8b_1, yline(`r(mean)', lpattern(.)) ///
	ytitle("In percentage (%)", size(medsmall)) ///
    title("{bf:Revenues share} that came from {bf:Bank Mandiri business} last month", size(medsmall)) ///
    subtitle(" ", size(medsmall)) ///
	text(`r(p50)' 95 "Median=`median_rounded'", size(vsmall)) ///
	text(`r(p75)' 95 "Q3=`Q_3_rounded'", size(vsmall)) ///
    text(`r(p25)' 95 "Q1=`Q_1_rounded'", size(vsmall)) ///
    text(`r(mean)' 95 "Mean=`mean_rounded'", size(vsmall)) ///
	note("Note:" "Total agents = `r(N)'" "Outlier threshold = `ll' (lower) and `ul' (upper)" "Dropped outlier observation = `dropped_obs'", size(medsmall))
	
graph export "$output\\Agent Baseline - `date'/22 - q_8b_1_boxplot.png", as(png) replace

restore

**# 9. Section 9
*** q_9a
preserve

** Drop missing variable (if any)
drop if q_9a == .

** Summary statistics
qui summarize q_9a, detail
return list

** Store obs number before dropping outlier(s)
local total_before = r(N)

** Detect and drop outlier(s)
generate iqr = r(p75) - r(p25)
generate lower_limit = r(p25) - 1.5 * iqr
generate upper_limit = r(p75) + 1.5 * iqr
generate outlier = (q_9a < lower_limit) | (q_9a > upper_limit)
drop if outlier == 1

** Store obs number after dropping outlier(s) and compute the difference
qui summarize q_9a, detail
local total_after = r(N)
local dropped_obs = `total_before' - `total_after'

** Store lower and upper threshold
qui su lower_limit, det
local ll = round(`r(mean)', 1)
qui su upper_limit, det
local ul = round(`r(mean)', 1)

* Histogram
set scheme plotplain

histogram q_9a, percent color(brown) ///
	discrete ///
	xlabel(0(5)50) ///
	ylabel(0(3)30) ///
    xtitle("Agent number", size(medsmall)) ///
    ytitle("Percentage of agents", size(medsmall)) ///
    title("Number of agents in the area", size(medsmall)) ///
	subtitle(" ", size(medsmall)) ///
	note("Note:" "Total agents = `r(N)'" "Outlier threshold = `ll' (lower) and `ul' (upper)" "Dropped outlier observation = `dropped_obs'", size(medsmall))
	
graph export "$output\\Agent Baseline - `date'/23 - q_9a_hist.png", as(png) replace

* Box plot
set scheme jpalfull

su q_9a, det
return list

local mean_rounded = round(`r(mean)', 1)	
local Q_1_rounded = round(`r(p25)', 1)
local Q_3_rounded = round(`r(p75)', 1)
local median_rounded = round(`r(p50)', 1)

graph box q_9a, yline(`r(mean)', lpattern(.)) ///
	ytitle("Agent number", size(medsmall)) ///
    title("Number of agents in the area", size(medsmall)) ///
    subtitle(" ", size(medsmall)) ///
	text(`r(p50)' 95 "Median=`median_rounded'", size(vsmall)) ///
	text(`r(p75)' 95 "Q3=`Q_3_rounded'", size(vsmall)) ///
    text(`r(p25)' 95 "Q1=`Q_1_rounded'", size(vsmall)) ///
    text(`r(mean)' 95 "Mean=`mean_rounded'", size(vsmall)) ///
	note("Note:" "Total agents = `r(N)'" "Outlier threshold = `ll' (lower) and `ul' (upper)" "Dropped outlier observation = `dropped_obs'", size(medsmall))
	
graph export "$output\\Agent Baseline - `date'/23 - q_9a_boxplot.png", as(png) replace

restore

*** q_9b
forval x = 1/3 {
	gen gr_9b_`x' = 1 if q_9b == `x'
	recode gr_9b_`x' (. = 0)
	replace gr_9b_`x' = . if q_9b == .
}

set scheme jpalfull

qui sum agents_n if q_9b!=. 

graph bar gr_9b_*, percentages /// percent is the default
	ytitle("In percentage (%)", size(medsmall) orientation(vertical)) ///
	ylabel(, labsize(medsmall)) ///
	blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
	title("Current {bf:level of competition} with other agents in the area", size(medsmall)) ///
	subtitle(" ", size(medsmall)) ///
	legend(order(1 "High" 2 "Neither high nor low" 3 "Low") size(medsmall) col(3)) ///
	note("Note:" "Total agents = `r(N)'", size(medsmall))
	
graph export "$output\\Agent Baseline - `date'/24 - q_9b.png", as(png) replace

*** q_9c
forval x = 1/3 {
	gen gr_9c_`x' = 1 if q_9c == `x'
	recode gr_9c_`x' (. = 0)
	replace gr_9c_`x' = . if q_9c == .
}

set scheme jpalfull

qui sum agents_n if q_9c!=. 

graph bar gr_9c_*, percentages /// percent is the default
	ytitle("In percentage (%)", size(medsmall) orientation(vertical)) ///
	ylabel(, labsize(medsmall)) ///
	blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
	title("How easy is it for you to {bf:attract new} branchless banking customers?", size(medsmall)) ///
	subtitle(" ", size(medsmall)) ///
	legend(order(1 "Easy" 2 "Neither easy nor difficult" 3 "Difficult") size(medsmall) col(3)) ///
	note("Note:" "Total agents = `r(N)'", size(medsmall))
	
graph export "$output\\Agent Baseline - `date'/25 - q_9c.png", as(png) replace

*** q_9d
local x = 1
forval nmr = 1/2 {
	gen gr_9d_`nmr' = 1 if q_9d == `x'
	recode gr_9d_`nmr' (. = 0)
	replace gr_9d_`nmr' = . if q_9d == .
	local x = `x' - 1
}

set scheme jpalfull

qui sum agents_n if q_9d!=. 

graph bar gr_9d_*, percentages /// percent is the default
	ytitle("In percentage (%)", size(medsmall) orientation(vertical)) ///
	ylabel(, labsize(medsmall)) ///
	blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
	title("Do you {bf:display} a price list with Bank Mandiri's official prices {bf:in your shop}?", size(medsmall)) ///
	subtitle(" ", size(medsmall)) ///
	legend(order(1 "Yes" 2 "No") size(medsmall) col(2)) ///
	note("Note:" "Total agents = `r(N)'", size(medsmall))
	
graph export "$output\\Agent Baseline - `date'/26 - q_9d.png", as(png) replace

*** q_9e
set scheme jpalfull

qui sum agents_n if q_9e_1 != .

graph bar q_9e_1 - q_9e_9,  ///
	ytitle("Proportion", size(medsmall) orientation(vertical)) ///
	ylabel(, labsize(medsmall)) ///
	blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
	title("Expectations on {bf:new competitor's main strategy}", size(medsmall)) ///
	subtitle("(agents can only select the answer up to 3 options)", size(medsmall)) ///
	legend(order(1 "Reduced transaction fees" 2 "Longer business hours" 3 "Offer buy on credit option" 4 "Offer complementary services/products" 5 "Having extra cash in hand" 6 "Cleanliness premises" 7 "Better customer service" 8 "Create more trust among cust" 9 "Proximity to cust") size(small) col(2)) ///
	note("Note:" "Total agents = `r(N)'", size(medsmall))
	
graph export "$output\\Agent Baseline - `date'/27 - q_9e.png", as(png) replace

*** q_9f
set scheme jpalfull

qui sum agents_n if q_9f_1 != .

graph bar q_9f_1 - q_9f_9,  ///
	ytitle("Proportion", size(medsmall) orientation(vertical)) ///
	ylabel(, labsize(medsmall)) ///
	blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
	title("{bf:Agent strategies used} to increase branchless banking business", size(medsmall)) ///
	subtitle("(agents can only select the answer up to 3 options)", size(medsmall)) ///
	legend(order(1 "Reduced transaction fees" 2 "Longer business hours" 3 "Offer buy on credit option" 4 "Offer complementary services/products" 5 "Having extra cash in hand" 6 "Cleanliness premises" 7 "Better customer service" 8 "Create more trust among cust" 9 "Proximity to cust") size(small) col(2)) ///
	note("Note:" "Total agents = `r(N)'", size(medsmall))
	
graph export "$output\\Agent Baseline - `date'/28 - q_9f.png", as(png) replace

*** q_9g
forval x = 1/3 {
	gen gr_9g_`x' = 1 if q_9g == `x'
	recode gr_9g_`x' (. = 0)
	replace gr_9g_`x' = . if q_9g == .
}

set scheme jpalfull

qui sum agents_n if q_9g!=. 

graph bar gr_9g_*, percentages /// percent is the default
	ytitle("In percentage (%)", size(medsmall) orientation(vertical)) ///
	ylabel(, labsize(medsmall)) ///
	blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
	title("Time spent to {bf:advertise the agent services}", size(medsmall)) ///
	subtitle("to increase the business over the last month", size(medsmall)) ///
	legend(order(1 "None at all" 2 "Some time" 3 "A lot of time") size(medsmall) col(3)) ///
	note("Note:" "Total agents = `r(N)'", size(medsmall))
	
graph export "$output\\Agent Baseline - `date'/29 - q_9g.png", as(png) replace

*** q_9h
forval x = 1/6 {
	gen gr_9h_`x' = 1 if q_9h == `x'
	recode gr_9h_`x' (. = 0)
	replace gr_9h_`x' = . if q_9h == .
}

set scheme jpalfull

qui sum agents_n if q_9h!=. 

graph bar gr_9h_*, percentages /// percent is the default
	ytitle("In percentage (%)", size(medsmall) orientation(vertical)) ///
	ylabel(, labsize(medsmall)) ///
	blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
	title("The frequency of approaching customers", size(medsmall)) ///
	subtitle("to {bf:do more branchless banking transactions}", size(medsmall)) ///
	legend(order(1 "Every day" 2 "A few times a week" 3 "Once a week" 4 "A few times per month" 5 "Once a month" 6 "Not at all") size(small) col(3)) ///
	note("Note:" "Total agents = `r(N)'", size(medsmall))
	
graph export "$output\\Agent Baseline - `date'/30 - q_9h.png", as(png) replace

*** q_9i
forval x = 1/6 {
	gen gr_9i_`x' = 1 if q_9i == `x'
	recode gr_9i_`x' (. = 0)
	replace gr_9i_`x' = . if q_9i == .
}

set scheme jpalfull

qui sum agents_n if q_9i!=. 

graph bar gr_9i_*, percentages /// percent is the default
	ytitle("In percentage (%)", size(medsmall) orientation(vertical)) ///
	ylabel(, labsize(medsmall)) ///
	blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
	title("The frequency of approaching customers", size(medsmall)) ///
	subtitle("to {bf:adopt new Bank Mandiri financial products}", size(medsmall)) ///
	legend(order(1 "Every day" 2 "A few times a week" 3 "Once a week" 4 "A few times per month" 5 "Once a month" 6 "Not at all") size(small) col(3)) ///
	note("Note:" "Total agents = `r(N)'", size(medsmall))

graph export "$output\\Agent Baseline - `date'/31 - q_9i.png", as(png) replace

*** q_9j
forval x = 1/6 {
	gen gr_9j_`x' = 1 if q_9j == `x'
	recode gr_9j_`x' (. = 0)
	replace gr_9j_`x' = . if q_9j == .
}

set scheme jpalfull

qui sum agents_n if q_9j!=. 

graph bar gr_9j_*, percentages /// percent is the default
	ytitle("In percentage (%)", size(medsmall) orientation(vertical)) ///
	ylabel(, labsize(medsmall)) ///
	blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
	title("The frequency of approaching customers", size(medsmall)) ///
	subtitle("to {bf:inform official transaction fees from Bank Mandiri}", size(medsmall)) ///
	legend(order(1 "Every day" 2 "A few times a week" 3 "Once a week" 4 "A few times per month" 5 "Once a month" 6 "Not at all") size(small) col(3)) ///
	note("Note:" "Total agents = `r(N)'", size(medsmall))
	
graph export "$output\\Agent Baseline - `date'/32 - q_9j.png", as(png) replace

**# 10. Section 10
*** q_10a_1
set scheme plotplain

qui sum q_10a_1

histogram q_10a_1, percent color(brown) ///
	discrete ///
 	xlabel(2013(1)2024) ///
	ylabel(0(3)30) ///
    xtitle("Year", size(medsmall)) ///
    ytitle("Percentage of agents", size(medsmall)) ///
    title("Since when have you been an agent for Bank Mandiri?", size(medsmall)) ///
	subtitle(" ", size(medsmall)) ///
	note("Note:" "Total agents = `r(N)'", size(medsmall))
	
graph export "$output\\Agent Baseline - `date'/33 - q_10a_1_hist.png", as(png) replace

*** q_10b (gender)
local x = 1
forval nmr = 1/2 {
	gen gr_gender_`nmr' = 1 if gender == `x'
	recode gr_gender_`nmr' (. = 0)
	replace gr_gender_`nmr' = . if gender == .
	local x = `x' - 1
}

set scheme jpalfull

qui sum agents_n if gender!=. 

graph bar gr_gender_*, percentages /// percent is the default
	ytitle("In percentage (%)", size(medsmall) orientation(vertical)) ///
	ylabel(, labsize(medsmall)) blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
	title("Gender", size(medsmall)) ///
	subtitle(" ", size(medsmall)) ///
	legend(order(1 "Female" 2 "Male") size(medsmall) col(2)) ///
	note("Note:" "Total agents = `r(N)'", size(medsmall))
	
graph export "$output\\Agent Baseline - `date'/34 - gender.png", as(png) replace

*** q_10c (birthyear)
set scheme plotplain

qui sum birthyear

histogram birthyear, percent color(brown) ///
	discrete ///
	ylabel(0(5)15) ///
    xtitle("Year", size(medsmall)) ///
    ytitle("Percentage of agents", size(medsmall)) ///
    title("Year of birth", size(medsmall)) ///
	subtitle(" ", size(medsmall)) ///
	note("Note:" "Total agents = `r(N)'", size(medsmall))
	
graph export "$output\\Agent Baseline - `date'/35 - birthyear_hist.png", as(png) replace

**# 11. Section 11
*** q_11a
forval x = 1/10 {
	gen gr_11a_`x' = 1 if q_11a == `x'
	recode gr_11a_`x' (. = 0)
	replace gr_11a_`x' = . if q_11a == .
}

set scheme jpalfull

qui sum agents_n if q_11a!=. 

graph bar gr_11a_*, percentages /// percent is the default
	ytitle("In percentage (%)", size(medsmall) orientation(vertical)) ///
	ylabel(, labsize(medsmall)) ///
	blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
	title("Compensation type", size(medsmall)) ///
	subtitle(" ", size(medsmall)) ///
	legend(order(1 "Pulsa Telkomsel" 2 "Pulsa 3" 3 "Pulsa XL" 4 "Pulsa Axis" 5 "Pulsa Indosat" 6 "E-Money OVO" 7 "E-Money GoPay" 8 "E-Money LinkAja" 9 "E-Money DANA" 10 "E-Money ShopeePay") size(small) col(2)) ///
	note("Note:" "Total agents = `r(N)'", size(medsmall))
	
graph export "$output\\Agent Baseline - `date'/36 - compensation_type.png", as(png) replace

*** q_11b_1
local x = 1
forval nmr = 1/2 {
	gen gr_11b_1_`nmr' = 1 if q_11b_1 == `x'
	recode gr_11b_1_`nmr' (. = 0)
	replace gr_11b_1_`nmr' = . if q_11b_1 == .
	local x = `x' - 1
}

set scheme jpalfull

qui sum agents_n if q_11b_1!=. 

graph bar gr_11b_1_*, percentages /// percent is the default
	ytitle("In percentage (%)", size(medsmall) orientation(vertical)) ///
	ylabel(, labsize(medsmall)) ///
	blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
	title("Are you sure your number is correct?", size(medsmall)) ///
	subtitle(" ", size(medsmall)) ///
	legend(order(1 "Yes" 2 "No") size(medsmall) col(2)) ///
	note("Note:" "Total agents = `r(N)'", size(medsmall))
	
graph export "$output\\Agent Baseline - `date'/37 - correct_number.png", as(png) replace

*** lot_comp_status
forval x = 1/2 {
	gen gr_lot_comp_status_`x' = 1 if lot_comp_status == `x'
	recode gr_lot_comp_status_`x' (. = 0)
	replace gr_lot_comp_status_`x' = . if lot_comp_status == .
}

set scheme jpalfull

qui sum agents_n if lot_comp_status!=. 

graph bar gr_lot_comp_status_*, percentages /// percent is the default
	ytitle("In percentage (%)", size(medsmall) orientation(vertical)) ///
	ylabel(, labsize(medsmall)) ///
	blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
	title("Lottery or Compensation Status Randomization", size(medsmall)) ///
	subtitle(" ", size(medsmall)) ///
	legend(order(1 "Lottery" 2 "Compensation") size(medsmall) col(2)) ///
	note("Note:" "Total agents = `r(N)'", size(medsmall))
	
graph export "$output\\Agent Baseline - `date'/38 - lot_comp_status.png", as(png) replace
