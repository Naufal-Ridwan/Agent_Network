*===================================================*
* Full-Scale - Client Survey (Baseline)
* HFC
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

* Muthia
    *gl path "C:\Users\jpals\Dropbox\J-PAL IFII Agent Banking Network (BM)\06 Data\c Full-Scale\06 Survey Data"
    gl path "/Users/auliamuthia/Desktop/J-PAL IFII Agent Banking Network (BM)/06 Data/c Full-Scale/06 Survey Data"

* Set the path
gl do            "$path/dofiles/client_baseline"
gl dta           "$path/dtafiles"
gl log           "$path/logfiles"
gl output        "$path/output"
gl raw           "$path/rawresponses/client_baseline"
	
***IMPORTANT***

* Set local date
loc date : di %tdDNCY daily("$S_DATE", "DMY") // this is the default code, it will automatically capture the current date
// loc date "DDMMYYYY" // only use this manual setting if you're running this code late than the supposed day

shell mkdir "$output/Client Baseline - `date'"

*************
*IMPORT DATA*
*************
use "$dta/cleaned_baseline_client_survey_`date'.dta", clear 

set more off
set scheme plotplain

ren externalreference unique_code

***************
*DATA ANALYSIS*
***************
gen clients_n = _n // for notes on total N clients

**# Survey duration (in minutes)
preserve

drop if consent_compensation == 0 | consent_lottery == 0 // drop people who refuse to participate in the survey

qui su total_duration, det
local total_before = r(N)

keep if total_duration < 100 // --Jibril: i keep any durations, just in case respondents take a break while filling out the survey

qui su total_duration, detail
return list

local total_after = r(N)
local dropped_obs = `total_before' - `total_after'

* Boxplot
set scheme jpalfull

qui su total_duration, detail
return list

local mean_rounded = round(`r(mean)', 1)	
local Q_1_rounded = round(`r(p25)', 1)
local Q_3_rounded = round(`r(p75)', 1)
local median_rounded = round(`r(p50)', 1)

graph box total_duration, yline(`r(mean)', lpattern(.)) ///
	ytitle("Survey duration (in minutes)", size(medsmall)) ///
    title("Survey Duration (in minutes)", size(medsmall)) ///
	subtitle("Restricted to respondents who participate in the survey", size(medsmall)) ///
	text(`r(p50)' 95 "Median=`median_rounded'", size(vsmall)) ///
	text(`r(p75)' 95 "Q3=`Q_3_rounded'", size(vsmall)) ///
    text(`r(p25)' 95 "Q1=`Q_1_rounded'", size(vsmall)) ///
    text(`r(mean)' 95 "Mean=`mean_rounded'", size(vsmall)) ///
	note("Note:" "Total clients = `: di %6.0fc `r(N)''" "Survey duration above 100 minutes is dropped" "Number of dropped observations = `dropped_obs'", size(medsmall))
	
graph export "$output/Client Baseline - `date'/1 - survey_duration.png", as(png) replace

* Histogram
** Round the total_duration
gen td_hist = round(total_duration, 1)

set scheme plotplain

qui sum td_hist

histogram td_hist, percent color("255 158 128") ///
	discrete ///
	ylabel(0(5)30) ///
    xtitle(" ", size(medsmall)) ///
    ytitle("Percentage of clients", size(medsmall)) ///
    title("Total Survey Duration (in minutes)", size(medsmall)) ///
	subtitle("Restricted to respondents who participate in the survey", size(medsmall)) ///
	note("Note:" "Total clients = `: di %6.0fc `r(N)''" "Survey duration above 100 minutes is dropped" "Number of dropped observations = `dropped_obs'", size(medsmall))
	
graph export "$output/Client Baseline - `date'/1 - survey_duration_hist.png", as(png) replace

restore

**# Summary table
la var q_1a_1 "Amount of last cash deposit w/ BM Agent"
la var q_1a_2 "Last charged cash deposit fee w/ BM Agent"
la var q_1a_4 "Number of deposits w/ BM Agent last 3 months"
la var q_1b_1 "Amount of last cash deposit w/ non-BM Agent"
la var q_1b_2 "Number of deposits w/ non-BM Agent last 3 months"

la var q_2a_1 "Amount of last cash withdrawal w/ BM Agent"
la var q_2a_2 "Last charged cash withdrawal fee w/ BM Agent"
la var q_2a_4 "Number of withdrawals w/ BM Agent last 3 months"
la var q_2b_1 "Amount of last cash withdrawal w/ non-BM Agent"
la var q_2b_2 "Number of withdrawals w/ non-BM Agent last 3 months"

la var q_4    "Level of satisfaction w/ BM Agent service"
la var q_11b  "Number of agents in the area"
la var q_12d  "Pc of overall agent transactions w/ BM Agent"
la var q_12f  "Economic ladder position"

eststo clear
eststo a: estpost summarize ///
		q_1a_1 q_1a_2 q_1a_4 q_1b_1 q_1b_2 q_2a_1 q_2a_2 q_2a_4 q_2b_1 q_2b_2 q_4 q_11b q_12d q_12f
esttab a using "$output/Client Baseline - `date'/summary_stats_client_baseline.tex", replace ///
		tex cells("count(fmt(%13.0fc)) mean(fmt(%13.2fc)) sd(fmt(%13.2fc)) min(fmt(%13.0fc)) max(fmt(%13.0fc))") ///
		nonumber nomtitle noobs label collabels("N" "Mean" "SD" "Min" "Max") note("Note: pc refers to percent. Current date: `date'")
		
**# Consent form (compensation and lottery)
preserve

recode consent_compensation consent_lottery (0 = 2)

la def yesno 1 "Yes" 2 "No"
la val consent_compensation consent_lottery yesno

keep unique_code consent_compensation consent_lottery

ren consent_compensation consent_1
ren consent_lottery consent_2

qui sum consent_1
local obs_consent_comp = `r(N)'
qui sum consent_2
local obs_consent_lot = `r(N)'

reshape long consent_, i(unique_code) j(consent)

la def consent 1 "Compensation [N = `: di %6.0fc `obs_consent_comp'']" 2 "Lottery [N = `: di %6.0fc `obs_consent_lot'']"
la val consent consent

tab consent_, gen(answer)

set scheme jpalfull

graph bar (sum) answer*, stack percentage over(consent, label(angle(0) labsize(medsmall))) ///
	title("{bf:Consent Form}", size(medsmall)) ///
	subtitle("By compensation status", size(medsmall)) ///
	legend(order(1 "Yes" 2 "No") size(medsmall)) ///
	note(" ", size(medsmall)) ///
	ytitle("%", size(medsmall) orientation(horizontal)) ///
	ylabel(0(25)100) ///
	blabel(bar, pos(center) size(medsmall) format(%15.1fc))
	
graph export "$output/Client Baseline - `date'/2 - consent_form_dist.png", as(png) replace

restore

// recode consent_compensation consent_lottery (0 = 2)
// la def yesno 1 "Yes" 2 "No"
// la val consent_compensation consent_lottery yesno
//
// set scheme jpalfull
// foreach x of varlist consent_compensation consent_lottery {
//				
// 	qui sum clients_n  if `x' !=.
// 	loc obs = `r(N)'
//
// 	loc	z: 	var lab 	`x'
// 	splitvallabels		`x'	
//				
// 	graph bar, over(`x', label(labsize(small)) relabel(`r(relabel)')) ytitle("%", size(small) orientation(horizontal)) ylabel(0(25)100, grid labsize(small)) ///
// 	asyvars  ///
// 	title("`z'", size(medsmall)) bar(1) blabel(bar, size(small) format(%4.1f)) ///
// 	note("Note:" "Total clients = `obs'", span size(small)) name(`x', replace)
// }
//
//
// graph		combine consent_compensation consent_lottery, ///
// 			col(2) iscale(0.7) xcommon xsize(30) ysize(15) imargin(0 0 0) ///
// 			title("{bf: Consent Form}", size(small)) ///
// 			subtitle("By Compensation Status", size(small))
// graph 		export "$output/Client Baseline - `date'/2 - consent_form_dist.png", as(png) replace

**# Compensation and lottery randomization
forval x = 1/2 {
	gen gr_comp_`x' = 1 if compensation_status == `x'
	recode gr_comp_`x' (. = 0)
	replace gr_comp_`x' = . if compensation_status == .
}

set scheme jpalfull

qui sum clients_n if compensation_status!=. 

graph bar gr_comp_*, percentages /// percent is the default
	ytitle("In percentage (%)", size(medsmall) orientation(vertical)) ///
	ylabel(0(25)100) ///
	blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
	title("Compensation Status", size(medsmall)) ///
	subtitle(" ", size(medsmall)) ///
	legend(order(1 "Compensation" 2 "Lottery") size(medsmall) col(2)) ///
	note("Total clients = `: di %6.0fc `r(N)''", size(medsmall))
	
graph export "$output/Client Baseline - `date'/3 - compensation_status.png", as(png) replace

**# 1. Section 1
*** q_1a
forval x = 1/6 {
	gen gr_1a_`x' = 1 if q_1a == `x'
	recode gr_1a_`x' (. = 0)
	replace gr_1a_`x' = . if q_1a == .
}

set scheme jpalfull

qui sum clients_n if q_1a!=. 

graph bar gr_1a_*, percentages /// percent is the default
	ytitle("In percentage (%)", size(medsmall) orientation(vertical)) ///
	ylabel(0(25)100) ///
	blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
	title("When was the last time you did a{bf: cash deposit} with{bf: BM Agent}?", size(medsmall)) ///
	subtitle(" ", size(medsmall)) ///
	legend(order(1 "Within the past 7 days" 2 "8-15 days ago" 3 "16-30 days ago" 4 "More than one month ago" 5 "More than six month ago" 6 "I haven't done this transaction with BM Agent before") size(small) col(1)) ///
	note("Total clients = `: di %6.0fc `r(N)''", size(medsmall))
	
graph export "$output/Client Baseline - `date'/4 - q_1a.png", as(png) replace

*** q_1a_1
preserve

** Drop missing variable (if any)
drop if q_1a_1 == .

** Summary statistics
qui summarize q_1a_1, detail
return list

** Store obs number before dropping outlier(s)
local total_before = r(N)

** Detect and drop outlier(s)
generate iqr = r(p75) - r(p25)
generate lower_limit = r(p25) - 1.5 * iqr
generate upper_limit = r(p75) + 1.5 * iqr
generate outlier = (q_1a_1 < lower_limit) | (q_1a_1 > upper_limit)
drop if outlier == 1

** Store obs number after dropping outlier(s) and compute the difference
qui summarize q_1a_1, detail
local total_after = r(N)
local dropped_obs = `total_before' - `total_after'

** Store lower and upper threshold
qui su lower_limit, det
local ll = round(`r(mean)', 1000)
qui su upper_limit, det
local ul = round(`r(mean)', 1000)

* Histogram
set scheme plotplain

histogram q_1a_1, percent color(brown) ///
	discrete ///
	ylabel(0(2)15) ///
	xlabel(, format(%15.0fc)) ///
    xtitle("Amount of deposit", size(medsmall)) ///
    ytitle("Percentage of clients", size(medsmall)) ///
    title("In your last transaction with{bf: BM Agent}, how much did you{bf: deposit}?", size(medsmall)) ///
	subtitle(" ", size(medsmall)) ///
	note("Note:" "Total clients = `: di %6.0fc `r(N)''" "Outlier threshold = `=string(`ll', "%15.0gc")' (lower) and `=string(`ul', "%15.0gc")' (upper)" "Dropped outlier observation = `dropped_obs'", size(medsmall))
	
graph export "$output/Client Baseline - `date'/5 - q_1a_1_hist.png", as(png) replace

* Box plot
set scheme jpalfull

qui su q_1a_1, det
return list

local mean_rounded = round(`r(mean)', 1000)	
local Q_1_rounded = round(`r(p25)', 1000)
local Q_3_rounded = round(`r(p75)', 1000)
local median_rounded = round(`r(p50)', 1000)

graph box q_1a_1, yline(`r(mean)', lpattern(.)) ///
	ytitle("Amount of deposit", size(medsmall)) ///
	ylabel(, format(%15.0fc)) ///
    title("In your last transaction with{bf: BM Agent}, how much did you{bf: deposit}?", size(medsmall)) ///
    subtitle(" ", size(medsmall)) ///
	text(`r(p50)' 95 "Median=`=string(`median_rounded', "%15.0gc")'", size(vsmall)) ///
	text(`r(p75)' 95 "Q3=`=string(`Q_3_rounded', "%15.0gc")'", size(vsmall)) ///
    text(`r(p25)' 95 "Q1=`=string(`Q_1_rounded', "%15.0gc")'", size(vsmall)) ///
    text(`r(mean)' 95 "Mean=`=string(`mean_rounded', "%15.0gc")'", size(vsmall)) ///
	note("Note:" "Total clients = `: di %6.0fc `r(N)''" "Outlier threshold = `=string(`ll', "%15.0gc")' (lower) and `=string(`ul', "%15.0gc")' (upper)" "Dropped outlier observation = `dropped_obs'" "The sumstat value is rounded to the nearest value of 1,000", size(medsmall))

graph export "$output/Client Baseline - `date'/5 - q_1a_1_boxplot.png", as(png) replace

restore

*** q_1a_2
preserve

** Drop missing variable (if any)
drop if q_1a_2 == .

** Summary statistics
qui summarize q_1a_2, detail
return list

** Store obs number before dropping outlier(s)
local total_before = r(N)

** Detect and drop outlier(s)
generate iqr = r(p75) - r(p25)
generate lower_limit = r(p25) - 1.5 * iqr
generate upper_limit = r(p75) + 1.5 * iqr
generate outlier = (q_1a_2 < lower_limit) | (q_1a_2 > upper_limit)
drop if outlier == 1

** Store obs number after dropping outlier(s) and compute the difference
qui summarize q_1a_2, detail
local total_after = r(N)
local dropped_obs = `total_before' - `total_after'

** Store lower and upper threshold
qui su lower_limit, det
local ll = round(`r(mean)', 100)
qui su upper_limit, det
local ul = round(`r(mean)', 100)

* Histogram
set scheme plotplain

histogram q_1a_2, percent color(brown) ///
	discrete ///
	xlabel(0(2000)20000) ///
	ylabel(0(2)20) ///
	xlabel(, format(%15.0fc)) ///
    xtitle("Transaction fee", size(medsmall)) ///
    ytitle("Percentage of clients", size(medsmall)) ///
    title("What was the{bf: transaction fee} charged by{bf: BM Agent}", size(medsmall)) ///
	subtitle("you use the last time you made{bf: a cash deposit}?", size(medsmall)) ///
	note("Note:" "Total clients = `: di %6.0fc `r(N)''" "Outlier threshold = `=string(`ll', "%15.0gc")' (lower) and `=string(`ul', "%15.0gc")' (upper)" "Dropped outlier observation = `dropped_obs'", size(medsmall))
	
graph export "$output/Client Baseline - `date'/6 - q_1a_2_hist.png", as(png) replace

* Box plot
set scheme jpalfull

qui su q_1a_2, det
return list

local mean_rounded = round(`r(mean)', 100)	
local Q_1_rounded = round(`r(p25)', 100)
local Q_3_rounded = round(`r(p75)', 100)
local median_rounded = round(`r(p50)', 100)

graph box q_1a_2, yline(`r(mean)', lpattern(.)) ///
	ytitle("Transaction fee", size(medsmall)) ///
	ylabel(, format(%15.0fc)) ///
    title("What was the{bf: transaction fee} charged by{bf: BM Agent}", size(medsmall)) ///
    subtitle("you use the last time you made{bf: a cash deposit}?", size(medsmall)) ///
	text(`r(p50)' 95 "Median=`=string(`median_rounded', "%15.0gc")'", size(vsmall)) ///
	text(`r(p75)' 95 "Q3=`=string(`Q_3_rounded', "%15.0gc")'", size(vsmall)) ///
    text(`r(p25)' 95 "Q1=`=string(`Q_1_rounded', "%15.0gc")'", size(vsmall)) ///
    text(`r(mean)' 95 "Mean=`=string(`mean_rounded', "%15.0gc")'", size(vsmall)) ///
	note("Note:" "Total clients = `: di %6.0fc `r(N)''" "Outlier threshold = `=string(`ll', "%15.0gc")' (lower) and `=string(`ul', "%15.0gc")' (upper)" "Dropped outlier observation = `dropped_obs'" "The sumstat value is rounded to the nearest value of 100", size(medsmall))

graph export "$output/Client Baseline - `date'/6 - q_1a_2_boxplot.png", as(png) replace

restore

*** q_1a_3
forval x = 1/8 {
	gen gr_1a_3_`x' = 1 if q_1a_3 == `x'
	recode gr_1a_3_`x' (. = 0)
	replace gr_1a_3_`x' = . if q_1a_3 == .
}

set scheme jpalfull

qui sum clients_n if q_1a_3!=. 

graph bar gr_1a_3_*, percentages /// percent is the default
	ytitle("In percentage (%)", size(medsmall) orientation(vertical)) ///
	ylabel(0(25)100) ///
	blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
	title("What was {bf:the approximate transaction fee} charged by {bf:BM Agent}", size(medsmall)) ///
	subtitle("you use the last time you made {bf:a cash deposit}?", size(medsmall)) ///
	legend(order(1 "Rp0 - 500" 2 "Rp500 - 1.500" 3 "Rp1.500 - 2.500" 4 "Rp2.500 - 3.500" 5 "Rp3.500 - 4.500" 6 "Rp4.500 - 5.500" 7 "Rp5.500 - 6.500" 8 "More than Rp6.500") size(small) col(2)) ///
	note("Total clients = `: di %6.0fc `r(N)''", size(medsmall))
	
graph export "$output/Client Baseline - `date'/7 - q_1a_3.png", as(png) replace

*** q_1a_4
preserve

** Drop missing variable (if any)
drop if q_1a_4 == .

** Summary statistics
qui summarize q_1a_4, detail
return list

** Store obs number before dropping outlier(s)
local total_before = r(N)

** Detect and drop outlier(s)
generate iqr = r(p75) - r(p25)
generate lower_limit = r(p25) - 1.5 * iqr
generate upper_limit = r(p75) + 1.5 * iqr
generate outlier = (q_1a_4 < lower_limit) | (q_1a_4 > upper_limit)
drop if outlier == 1

** Store obs number after dropping outlier(s) and compute the difference
qui summarize q_1a_4, detail
local total_after = r(N)
local dropped_obs = `total_before' - `total_after'

** Store lower and upper threshold
qui su lower_limit, det
local ll = round(`r(mean)', 1)
qui su upper_limit, det
local ul = round(`r(mean)', 1)

* Histogram
set scheme plotplain

histogram q_1a_4, percent color(brown) ///
	discrete ///
	xlabel(0(2)30) ///
	ylabel(0(2)20) ///
    xtitle("Number of deposit", size(medsmall)) ///
    ytitle("Percentage of clients", size(medsmall)) ///
    title("Over {bf:the last 3 months}, how many deposits have you made", size(medsmall)) ///
	subtitle("with {bf:BM Agent}?", size(medsmall)) ///
	note("Note:" "Total clients = `: di %6.0fc `r(N)''" "Outlier threshold = `ll' (lower) and `ul' (upper)" "Dropped outlier observation = `dropped_obs'", size(medsmall))
	
graph export "$output/Client Baseline - `date'/8- q_1a_4_hist.png", as(png) replace

* Box plot
set scheme jpalfull

qui su q_1a_4, det
return list

local mean_rounded = round(`r(mean)', 1)	
local Q_1_rounded = round(`r(p25)', 1)
local Q_3_rounded = round(`r(p75)', 1)
local median_rounded = round(`r(p50)', 1)

graph box q_1a_4, yline(`r(mean)', lpattern(.)) ///
	ytitle("Number of deposit", size(medsmall)) ///
    title("Over {bf:the last 3 months}, how many deposits have you made", size(medsmall)) ///
    subtitle("with {bf:BM Agent}?", size(medsmall)) ///
	text(`r(p50)' 95 "Median=`median_rounded'", size(vsmall)) ///
	text(`r(p75)' 95 "Q3=`Q_3_rounded'", size(vsmall)) ///
    text(`r(p25)' 95 "Q1=`Q_1_rounded'", size(vsmall)) ///
    text(`r(mean)' 95 "Mean=`mean_rounded'", size(vsmall)) ///
	note("Note:" "Total clients = `: di %6.0fc `r(N)''" "Outlier threshold = `ll' (lower) and `ul' (upper)" "Dropped outlier observation = `dropped_obs'", size(medsmall))
	
graph export "$output/Client Baseline - `date'/8 - q_1a_4_boxplot.png", as(png) replace

restore

*** q_1b
forval x = 1/6 {
	gen gr_1b_`x' = 1 if q_1b == `x'
	recode gr_1b_`x' (. = 0)
	replace gr_1b_`x' = . if q_1b == .
}

set scheme jpalfull

qui sum clients_n if q_1b!=. 

graph bar gr_1b_*, percentages /// percent is the default
	ytitle("In percentage (%)", size(medsmall) orientation(vertical)) ///
	ylabel(0(25)100) ///
	blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
	title("When was the last time you did a{bf: cash deposit} with{bf: a non-BM Agent}?", size(medsmall)) ///
	subtitle(" ", size(medsmall)) ///
	legend(order(1 "Within the past 7 days" 2 "8-15 days ago" 3 "16-30 days ago" 4 "More than one month ago" 5 "More than six month ago" 6 "I haven't done this transaction with BM Agent before") size(small) col(1)) ///
	note("Total clients = `: di %6.0fc `r(N)''", size(medsmall))
	
graph export "$output/Client Baseline - `date'/9 - q_1b.png", as(png) replace

*** q_1b_1
preserve

** Drop missing variable (if any)
drop if q_1b_1 == .

** Summary statistics
qui summarize q_1b_1, detail
return list

** Store obs number before dropping outlier(s)
local total_before = r(N)

** Detect and drop outlier(s)
generate iqr = r(p75) - r(p25)
generate lower_limit = r(p25) - 1.5 * iqr
generate upper_limit = r(p75) + 1.5 * iqr
generate outlier = (q_1b_1 < lower_limit) | (q_1b_1 > upper_limit)
drop if outlier == 1

** Store obs number after dropping outlier(s) and compute the difference
qui summarize q_1b_1, detail
local total_after = r(N)
local dropped_obs = `total_before' - `total_after'

** Store lower and upper threshold
qui su lower_limit, det
local ll = round(`r(mean)', 1000)
qui su upper_limit, det
local ul = round(`r(mean)', 1000)

* Histogram
set scheme plotplain

histogram q_1b_1, percent color(brown) ///
	discrete ///
	ylabel(0(2)15) ///
	xlabel(, format(%15.0fc)) ///
    xtitle("Amount of deposit", size(medsmall)) ///
    ytitle("Percentage of clients", size(medsmall)) ///
    title("In your last transaction with{bf: a non-BM Agent}, how much did you{bf: deposit}?", size(medsmall)) ///
	subtitle(" ", size(medsmall)) ///
	note("Note:" "Total clients = `: di %6.0fc `r(N)''" "Outlier threshold = `=string(`ll', "%15.0gc")' (lower) and `=string(`ul', "%15.0gc")' (upper)" "Dropped outlier observation = `dropped_obs'", size(medsmall))
	
graph export "$output/Client Baseline - `date'/10 - q_1b_1_hist.png", as(png) replace

* Box plot
set scheme jpalfull

qui su q_1b_1, det
return list

local mean_rounded = round(`r(mean)', 1000)	
local Q_1_rounded = round(`r(p25)', 1000)
local Q_3_rounded = round(`r(p75)', 1000)
local median_rounded = round(`r(p50)', 1000)

graph box q_1b_1, yline(`r(mean)', lpattern(.)) ///
	ytitle("Amount of deposit", size(medsmall)) ///
	ylabel(, format(%15.0fc)) ///
    title("In your last transaction with{bf: a non-BM Agent}, how much did you{bf: deposit}?", size(medsmall)) ///
    subtitle(" ", size(medsmall)) ///
	text(`r(p50)' 95 "Median=`=string(`median_rounded', "%15.0gc")'", size(vsmall)) ///
	text(`r(p75)' 95 "Q3=`=string(`Q_3_rounded', "%15.0gc")'", size(vsmall)) ///
    text(`r(p25)' 95 "Q1=`=string(`Q_1_rounded', "%15.0gc")'", size(vsmall)) ///
    text(`r(mean)' 95 "Mean=`=string(`mean_rounded', "%15.0gc")'", size(vsmall)) ///
	note("Note:" "Total clients = `: di %6.0fc `r(N)''" "Outlier threshold = `=string(`ll', "%15.0gc")' (lower) and `=string(`ul', "%15.0gc")' (upper)" "Dropped outlier observation = `dropped_obs'" "The sumstat value is rounded to the nearest value of 1,000", size(medsmall))
	
graph export "$output/Client Baseline - `date'/10 - q_1b_1_boxplot.png", as(png) replace

restore

*** q_1b_2
preserve

** Drop missing variable (if any)
drop if q_1b_2 == .

** Summary statistics
qui summarize q_1b_2, detail
return list

** Store obs number before dropping outlier(s)
local total_before = r(N)

** Detect and drop outlier(s)
generate iqr = r(p75) - r(p25)
generate lower_limit = r(p25) - 1.5 * iqr
generate upper_limit = r(p75) + 1.5 * iqr
generate outlier = (q_1b_2 < lower_limit) | (q_1b_2 > upper_limit)
drop if outlier == 1

** Store obs number after dropping outlier(s) and compute the difference
qui summarize q_1b_2, detail
local total_after = r(N)
local dropped_obs = `total_before' - `total_after'

** Store lower and upper threshold
qui su lower_limit, det
local ll = round(`r(mean)', 1)
qui su upper_limit, det
local ul = round(`r(mean)', 1)

* Histogram
set scheme plotplain

histogram q_1b_2, percent color(brown) ///
	discrete ///
	xlabel(0(2)30) ///
	ylabel(0(2)20) ///
    xtitle("Number of deposit", size(medsmall)) ///
    ytitle("Percentage of clients", size(medsmall)) ///
    title("Over {bf:the last 3 months}, how many deposits have you made", size(medsmall)) ///
	subtitle("with {bf:a non-BM Agent}?", size(medsmall)) ///
	note("Note:" "Total clients = `: di %6.0fc `r(N)''" "Outlier threshold = `ll' (lower) and `ul' (upper)" "Dropped outlier observation = `dropped_obs'", size(medsmall))
	
graph export "$output/Client Baseline - `date'/11 - q_1b_2_hist.png", as(png) replace

* Box plot
set scheme jpalfull

qui su q_1b_2, det
return list

local mean_rounded = round(`r(mean)', 1)	
local Q_1_rounded = round(`r(p25)', 1)
local Q_3_rounded = round(`r(p75)', 1)
local median_rounded = round(`r(p50)', 1)

graph box q_1b_2, yline(`r(mean)', lpattern(.)) ///
	ytitle("Number of deposit", size(medsmall)) ///
    title("Over {bf:the last 3 months}, how many deposits have you made", size(medsmall)) ///
    subtitle("with {bf:a non-BM Agent}?", size(medsmall)) ///
	text(`r(p50)' 95 "Median=`median_rounded'", size(vsmall)) ///
	text(`r(p75)' 95 "Q3=`Q_3_rounded'", size(vsmall)) ///
    text(`r(p25)' 95 "Q1=`Q_1_rounded'", size(vsmall)) ///
    text(`r(mean)' 95 "Mean=`mean_rounded'", size(vsmall)) ///
	note("Note:" "Total clients = `: di %6.0fc `r(N)''" "Outlier threshold = `ll' (lower) and `ul' (upper)" "Dropped outlier observation = `dropped_obs'", size(medsmall))
	
graph export "$output/Client Baseline - `date'/11 - q_1b_2_boxplot.png", as(png) replace

restore

**# 2. Section 2
*** q_2a
forval x = 1/6 {
	gen gr_2a_`x' = 1 if q_2a == `x'
	recode gr_2a_`x' (. = 0)
	replace gr_2a_`x' = . if q_2a == .
}

set scheme jpalfull

qui sum clients_n if q_2a!=. 

	graph bar gr_2a_*, percentages /// percent is the default
	ytitle("In percentage (%)", size(small) orientation(vertical)) ///
	ylabel(0(25)100) ///
	blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
	title("When was the last time you did a{bf: cash withdrawal} with{bf: BM Agent}?", size(medsmall)) ///
	subtitle(" ", size(medsmall)) ///
	legend(order(1 "Within the past 7 days" 2 "8-15 days ago" 3 "16-30 days ago" 4 "More than one month ago" 5 "More than six month ago" 6 "I haven't done this transaction with BM Agent before") size(small) col(1)) ///
	note("Total clients = `: di %6.0fc `r(N)''", size(medsmall))
	
graph export "$output/Client Baseline - `date'/12 - q_2a.png", as(png) replace

*** q_2a_1
preserve

** Drop missing variable (if any)
drop if q_2a_1 == .

** Summary statistics
qui summarize q_2a_1, detail
return list

** Store obs number before dropping outlier(s)
local total_before = r(N)

** Detect and drop outlier(s)
generate iqr = r(p75) - r(p25)
generate lower_limit = r(p25) - 1.5 * iqr
generate upper_limit = r(p75) + 1.5 * iqr
generate outlier = (q_2a_1 < lower_limit) | (q_2a_1 > upper_limit)
drop if outlier == 1

** Store obs number after dropping outlier(s) and compute the difference
qui summarize q_2a_1, detail
local total_after = r(N)
local dropped_obs = `total_before' - `total_after'

** Store lower and upper threshold
qui su lower_limit, det
local ll = round(`r(mean)', 1000)
qui su upper_limit, det
local ul = round(`r(mean)', 1000)

* Histogram
set scheme plotplain

histogram q_2a_1, percent color(brown) ///
	discrete ///
	ylabel(0(2)15) ///
	xlabel(, format(%15.0fc)) ///
    xtitle("Amount of withdrawal", size(medsmall)) ///
    ytitle("Percentage of clients", size(medsmall)) ///
    title("In your last transaction with{bf: BM Agent}, how much did you{bf: withdraw}?", size(medsmall)) ///
	subtitle(" ", size(medsmall)) ///
	note("Note:" "Total clients = `: di %6.0fc `r(N)''" "Outlier threshold = `=string(`ll', "%15.0gc")' (lower) and `=string(`ul', "%15.0gc")' (upper)" "Dropped outlier observation = `dropped_obs'", size(medsmall))
	
graph export "$output/Client Baseline - `date'/13 - q_2a_1_hist.png", as(png) replace

* Box plot
set scheme jpalfull

su q_2a_1, det
return list

local mean_rounded = round(`r(mean)', 1000)	
local Q_1_rounded = round(`r(p25)', 1000)
local Q_3_rounded = round(`r(p75)', 1000)
local median_rounded = round(`r(p50)', 1000)


graph box q_2a_1, yline(`r(mean)', lpattern(.)) ///
	ytitle("Amount of withdrawal", size(medsmall)) ///
	ylabel(, format(%15.0fc)) ///
    title("In your last transaction with{bf: BM Agent}, how much did you{bf: withdraw}?", size(medsmall)) ///
    subtitle(" ", size(medsmall)) ///
	text(`r(p50)' 95 "Median=`=string(`median_rounded', "%15.0gc")'", size(vsmall)) ///
	text(`r(p75)' 95 "Q3=`=string(`Q_3_rounded', "%15.0gc")'", size(vsmall)) ///
    text(`r(p25)' 95 "Q1=`=string(`Q_1_rounded', "%15.0gc")'", size(vsmall)) ///
    text(`r(mean)' 95 "Mean=`=string(`mean_rounded', "%15.0gc")'", size(vsmall)) ///
	note("Note:" "Total clients = `: di %6.0fc `r(N)''" "Outlier threshold = `=string(`ll', "%15.0gc")' (lower) and `=string(`ul', "%15.0gc")' (upper)" "Dropped outlier observation = `dropped_obs'" "The sumstat value is rounded to the nearest value of 1,000", size(medsmall))
	
graph export "$output/Client Baseline - `date'/13 - q_2a_1_boxplot.png", as(png) replace

restore

*** q_2a_2
preserve

** Drop missing variable (if any)
drop if q_2a_2 == .

** Summary statistics
qui summarize q_2a_2, detail
return list

** Store obs number before dropping outlier(s)
local total_before = r(N)

** Detect and drop outlier(s)
generate iqr = r(p75) - r(p25)
generate lower_limit = r(p25) - 1.5 * iqr
generate upper_limit = r(p75) + 1.5 * iqr
generate outlier = (q_2a_2 < lower_limit) | (q_2a_2 > upper_limit)
drop if outlier == 1

** Store obs number after dropping outlier(s) and compute the difference
qui summarize q_2a_2, detail
local total_after = r(N)
local dropped_obs = `total_before' - `total_after'

** Store lower and upper threshold
qui su lower_limit, det
local ll = round(`r(mean)', 100)
qui su upper_limit, det
local ul = round(`r(mean)', 100)

* Histogram
set scheme plotplain

histogram q_2a_2, percent color(brown) ///
	discrete ///
	xlabel(0(2000)20000) ///
	ylabel(0(2)20) ///
	xlabel(, format(%15.0fc)) ///
    xtitle("Transaction fee", size(medsmall)) ///
    ytitle("Percentage of clients", size(medsmall)) ///
    title("What was the{bf: transaction fee} charged by{bf: BM Agent}", size(medsmall)) ///
	subtitle("you use the last time you made{bf: a cash withdrawal}?", size(medsmall)) ///
	note("Note:" "Total clients = `: di %6.0fc `r(N)''" "Outlier threshold = `=string(`ll', "%15.0gc")' (lower) and `=string(`ul', "%15.0gc")' (upper)" "Dropped outlier observation = `dropped_obs'", size(medsmall))
	
graph export "$output/Client Baseline - `date'/14 - q_2a_2_hist.png", as(png) replace


* Box plot
set scheme jpalfull

qui su q_2a_2, det
return list

local mean_rounded = round(`r(mean)', 100)	
local Q_1_rounded = round(`r(p25)', 100)
local Q_3_rounded = round(`r(p75)', 100)
local median_rounded = round(`r(p50)', 100)

graph box q_2a_2, yline(`r(mean)', lpattern(.)) ///
	ytitle("Transaction fee", size(medsmall)) ///
	ylabel(, format(%15.0fc)) ///
    title("What was the{bf: transaction fee} charged by{bf: BM Agent}", size(medsmall)) ///
    subtitle("you use the last time you made{bf: a cash withdrawal}?", size(medsmall)) ///
	text(`r(p50)' 95 "Median=`=string(`median_rounded', "%15.0gc")'", size(vsmall)) ///
	text(`r(p75)' 95 "Q3=`=string(`Q_3_rounded', "%15.0gc")'", size(vsmall)) ///
    text(`r(p25)' 95 "Q1=`=string(`Q_1_rounded', "%15.0gc")'", size(vsmall)) ///
    text(`r(mean)' 95 "Mean=`=string(`mean_rounded', "%15.0gc")'", size(vsmall)) ///
	note("Note:" "Total clients = `: di %6.0fc `r(N)''" "Outlier threshold = `=string(`ll', "%15.0gc")' (lower) and `=string(`ul', "%15.0gc")' (upper)" "Dropped outlier observation = `dropped_obs'" "The sumstat value is rounded to the nearest value of 100", size(medsmall))
	
graph export "$output/Client Baseline - `date'/14 - q_2a_2_boxplot.png", as(png) replace

restore

*** q_2a_3
forval x = 1/8 {
	gen gr_2a_3_`x' = 1 if q_2a_3 == `x'
	recode gr_2a_3_`x' (. = 0)
	replace gr_2a_3_`x' = . if q_2a_3 == .
}

set scheme jpalfull

qui sum clients_n if q_2a_3!=. 

graph bar gr_2a_3_*, percentages /// percent is the default
	ytitle("In percentage (%)", size(medsmall) orientation(vertical)) ///
	ylabel(0(25)100) ///
	blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
	title("What was {bf:the approximate transaction fee} charged by {bf:BM Agent}", size(medsmall)) ///
	subtitle("you use the last time you made {bf:a cash withdrawal}?", size(medsmall)) ///
	legend(order(1 "Rp0 - 500" 2 "Rp500 - 1.500" 3 "Rp1.500 - 2.500" 4 "Rp2.500 - 3.500" 5 "Rp3.500 - 4.500" 6 "Rp4.500 - 5.500" 7 "Rp5.500 - 6.500" 8 "More than Rp6.500") size(medsmall) col(2)) ///
	note("Total clients = `: di %6.0fc `r(N)''", size(medsmall))
	
graph export "$output/Client Baseline - `date'/15 - q_2a_3.png", as(png) replace

*** q_2a_4
preserve

** Drop missing variable (if any)
drop if q_2a_4 == .

** Summary statistics
qui summarize q_2a_4, detail
return list

** Store obs number before dropping outlier(s)
local total_before = r(N)

** Detect and drop outlier(s)
generate iqr = r(p75) - r(p25)
generate lower_limit = r(p25) - 1.5 * iqr
generate upper_limit = r(p75) + 1.5 * iqr
generate outlier = (q_2a_4 < lower_limit) | (q_2a_4 > upper_limit)
drop if outlier == 1

** Store obs number after dropping outlier(s) and compute the difference
qui summarize q_2a_4, detail
local total_after = r(N)
local dropped_obs = `total_before' - `total_after'

** Store lower and upper threshold
qui su lower_limit, det
local ll = round(`r(mean)', 1)
qui su upper_limit, det
local ul = round(`r(mean)', 1)

* Histogram
set scheme plotplain

histogram q_2a_4, percent color(brown) ///
	discrete ///
	xlabel(0(2)30) ///
	ylabel(0(5)40) ///
    xtitle("Number of withdrawal", size(medsmall)) ///
    ytitle("Percentage of clients", size(medsmall)) ///
    title("Over {bf:the last 3 months}, how many withdrawals have you made", size(medsmall)) ///
	subtitle("with {bf:BM Agent}?", size(medsmall)) ///
	note("Note:" "Total clients = `: di %6.0fc `r(N)''" "Outlier threshold = `ll' (lower) and `ul' (upper)" "Dropped outlier observation = `dropped_obs'", size(medsmall))
	
graph export "$output/Client Baseline - `date'/16 - q_2a_4_hist.png", as(png) replace

* Box plot
set scheme jpalfull

qui su q_2a_4, det
return list

local mean_rounded = round(`r(mean)', 1)	
local Q_1_rounded = round(`r(p25)', 1)
local Q_3_rounded = round(`r(p75)', 1)
local median_rounded = round(`r(p50)', 1)

graph box q_2a_4, yline(`r(mean)', lpattern(.)) ///
	ytitle("Number of withdrawal", size(medsmall)) ///
    title("Over {bf:the last 3 months}, how many withdrawals have you made", size(medsmall)) ///
    subtitle("with {bf:BM Agent}?", size(medsmall)) ///
	text(`r(p50)' 95 "Median=`median_rounded'", size(vsmall)) ///
	text(`r(p75)' 95 "Q3=`Q_3_rounded'", size(vsmall)) ///
    text(`r(p25)' 95 "Q1=`Q_1_rounded'", size(vsmall)) ///
    text(`r(mean)' 95 "Mean=`mean_rounded'", size(vsmall)) ///
	note("Note:" "Total clients = `: di %6.0fc `r(N)''" "Outlier threshold = `ll' (lower) and `ul' (upper)" "Dropped outlier observation = `dropped_obs'", size(medsmall))
	
graph export "$output/Client Baseline - `date'/16 - q_2a_4_boxplot.png", as(png) replace

restore

*** q_2b
forval x = 1/6 {
	gen gr_2b_`x' = 1 if q_2b == `x'
	recode gr_2b_`x' (. = 0)
	replace gr_2b_`x' = . if q_2b == .
}

set scheme jpalfull

qui sum clients_n if q_2b!=. 

graph bar gr_2b_*, percentages /// percent is the default
	ytitle("In percentage (%)", size(medsmall) orientation(vertical)) ///
	ylabel(0(25)100) ///
	blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
	title("When was the last time you did a{bf: cash withdrawal} with{bf: a non-BM Agent}?", size(medsmall)) ///
	subtitle(" ", size(medsmall)) ///
	legend(order(1 "Within the past 7 days" 2 "8-15 days ago" 3 "16-30 days ago" 4 "More than one month ago" 5 "More than six month ago" 6 "I haven't done this transaction with BM Agent before") size(small) col(1)) ///
	note("Total clients = `: di %6.0fc `r(N)''", size(medsmall))
	
graph export "$output/Client Baseline - `date'/17 - q_2b.png", as(png) replace

*** q_2b_1
preserve

** Drop missing variable (if any)
drop if q_2b_1 == .

** Summary statistics
qui summarize q_2b_1, detail
return list

** Store obs number before dropping outlier(s)
local total_before = r(N)

** Detect and drop outlier(s)
generate iqr = r(p75) - r(p25)
generate lower_limit = r(p25) - 1.5 * iqr
generate upper_limit = r(p75) + 1.5 * iqr
generate outlier = (q_2b_1 < lower_limit) | (q_2b_1 > upper_limit)
drop if outlier == 1

** Store obs number after dropping outlier(s) and compute the difference
qui summarize q_2b_1, detail
local total_after = r(N)
local dropped_obs = `total_before' - `total_after'

** Store lower and upper threshold
qui su lower_limit, det
local ll = round(`r(mean)', 1000)
qui su upper_limit, det
local ul = round(`r(mean)', 1000)

* Histogram
set scheme plotplain

histogram q_2b_1, percent color(brown) ///
	discrete ///
	ylabel(0(2)15) ///
	xlabel(, format(%15.0fc)) ///
    xtitle("Amount of withdrawal", size(medsmall)) ///
    ytitle("Percentage of clients", size(medsmall)) ///
    title("In your last transaction with{bf: a non-BM Agent}, how much did you{bf: withdraw}?", size(medsmall)) ///
	subtitle(" ", size(medsmall)) ///
	note("Note:" "Total clients = `: di %6.0fc `r(N)''" "Outlier threshold = `=string(`ll', "%15.0gc")' (lower) and `=string(`ul', "%15.0gc")' (upper)" "Dropped outlier observation = `dropped_obs'", size(medsmall))
	
graph export "$output/Client Baseline - `date'/18 - q_2b_1_hist.png", as(png) replace

* Box plot
set scheme jpalfull

qui su q_2b_1, det
return list

local mean_rounded = round(`r(mean)', 1000)	
local Q_1_rounded = round(`r(p25)', 1000)
local Q_3_rounded = round(`r(p75)', 1000)
local median_rounded = round(`r(p50)', 1000)

graph box q_2b_1, yline(`r(mean)', lpattern(.)) ///
	ytitle("Amount of withdrawal", size(medsmall)) ///
	ylabel(, format(%15.0fc)) ///
    title("In your last transaction with{bf: a non-BM Agent}, how much did you{bf: withdraw}?", size(medsmall)) ///
    subtitle(" ", size(medsmall)) ///
	text(`r(p50)' 95 "Median=`=string(`median_rounded', "%15.0gc")'", size(vsmall)) ///
	text(`r(p75)' 95 "Q3=`=string(`Q_3_rounded', "%15.0gc")'", size(vsmall)) ///
    text(`r(p25)' 95 "Q1=`=string(`Q_1_rounded', "%15.0gc")'", size(vsmall)) ///
    text(`r(mean)' 95 "Mean=`=string(`mean_rounded', "%15.0gc")'", size(vsmall)) ///
	note("Note:" "Total clients = `: di %6.0fc `r(N)''" "Outlier threshold = `=string(`ll', "%15.0gc")' (lower) and `=string(`ul', "%15.0gc")' (upper)" "Dropped outlier observation = `dropped_obs'" "The sumstat value is rounded to the nearest value of 1,000", size(medsmall))
	
graph export "$output/Client Baseline - `date'/18 - q_2b_1_boxplot.png", as(png) replace

restore

*** q_2b_2
preserve

** Drop missing variable (if any)
drop if q_2b_2 == .

** Summary statistics
qui summarize q_2b_2, detail
return list

** Store obs number before dropping outlier(s)
local total_before = r(N)

** Detect and drop outlier(s)
generate iqr = r(p75) - r(p25)
generate lower_limit = r(p25) - 1.5 * iqr
generate upper_limit = r(p75) + 1.5 * iqr
generate outlier = (q_2b_2 < lower_limit) | (q_2b_2 > upper_limit)
drop if outlier == 1

** Store obs number after dropping outlier(s) and compute the difference
qui summarize q_2b_2, detail
local total_after = r(N)
local dropped_obs = `total_before' - `total_after'

** Store lower and upper threshold
qui su lower_limit, det
local ll = round(`r(mean)', 1)
qui su upper_limit, det
local ul = round(`r(mean)', 1)

* Histogram
set scheme plotplain

histogram q_2b_2, percent color(brown) ///
	discrete ///
	xlabel(0(2)30) ///
	ylabel(0(2)20) ///
    xtitle("Number of withdrawal", size(medsmall)) ///
    ytitle("Percentage of clients", size(medsmall)) ///
    title("Over {bf:the last 3 months}, how many withdrawals have you made", size(medsmall)) ///
	subtitle("with {bf:a non-BM Agent}?", size(medsmall)) ///
	note("Note:" "Total clients = `: di %6.0fc `r(N)''" "Outlier threshold = `ll' (lower) and `ul' (upper)" "Dropped outlier observation = `dropped_obs'", size(medsmall))
graph export "$output/Client Baseline - `date'/19 - q_2b_2_hist.png", as(png) replace

* Box plot
set scheme jpalfull

qui su q_2b_2, det
return list

local mean_rounded = round(`r(mean)', 1)	
local Q_1_rounded = round(`r(p25)', 1)
local Q_3_rounded = round(`r(p75)', 1)
local median_rounded = round(`r(p50)', 1)

graph box q_2b_2, yline(`r(mean)', lpattern(.)) ///
	ytitle("Number of withdrawal", size(medsmall)) ///
    title("Over {bf:the last 3 months}, how many withdrawals have you made", size(medsmall)) ///
    subtitle("with {bf:a non-BM Agent}?", size(medsmall)) ///
	text(`r(p50)' 95 "Median=`median_rounded'", size(vsmall)) ///
	text(`r(p75)' 95 "Q3=`Q_3_rounded'", size(vsmall)) ///
    text(`r(p25)' 95 "Q1=`Q_1_rounded'", size(vsmall)) ///
    text(`r(mean)' 95 "Mean=`mean_rounded'", size(vsmall)) ///
	note("Note:" "Total clients = `: di %6.0fc `r(N)''" "Outlier threshold = `ll' (lower) and `ul' (upper)" "Dropped outlier observation = `dropped_obs'", size(medsmall))
graph export "$output/Client Baseline - `date'/19 - q_2b_2_boxplot.png", as(png) replace

restore

**# 3. Section 3
*** q_3a
forval x = 1/5 {
	gen gr_3a_`x' = 1 if q_3a == `x'
	recode gr_3a_`x' (. = 0)
	replace gr_3a_`x' = . if q_3a == .
}

set scheme jpalfull

qui sum clients_n if q_3a!=. 

graph bar gr_3a_*, percentages /// percent is the default
	ytitle("In percentage (%)", size(medsmall) orientation(vertical)) ///
	ylabel(0(25)100) ///
	blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
	title("Banking agents {bf:charge a fee} for each transaction made with them.", size(medsmall)) ///
	subtitle("How do you think these fees {bf:are set}?", size(medsmall)) ///
	legend(order(1 "There's an official price and the agent has to stick with it" 2 "There's an official price, but agent can charge more/less" 3 "No official price and agent can decide the price" 4 "The government sets the prices" 5 "I do not know") size(small) col(1)) ///
	note("Total clients = `: di %6.0fc `r(N)''", size(medsmall))
	
graph export "$output/Client Baseline - `date'/20 - q_3a.png", as(png) replace

*** q_3a_1
forval x = 1/3 {
	gen gr_3a_1_`x' = 1 if q_3a_1 == `x'
	recode gr_3a_1_`x' (. = 0)
	replace gr_3a_1_`x' = . if q_3a_1 == .
}

set scheme jpalfull

qui sum clients_n if q_3a_1!=. 

graph bar gr_3a_1_*, percentages /// percent is the default
	ytitle("In percentage (%)", size(medsmall) orientation(vertical)) ///
	ylabel(0(25)100) ///
	blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
	title("Does the agent typically {bf:charge more or less} than official price?", size(medsmall)) ///
	subtitle(" ", size(medsmall)) ///
	legend(order(1 "More" 2 "Less" 3 "Depends on the client (sometimes more/less)") size(medsmall) col(1)) ///
	note("Total clients = `: di %6.0fc `r(N)''", size(medsmall))
	
graph export "$output/Client Baseline - `date'/21 - q_3a_1.png", as(png) replace

*** q_3b
local x = 1
forval nmr = 1/2 {
	gen gr_3b_`nmr' = 1 if q_3b == `x'
	recode gr_3b_`nmr' (. = 0)
	replace gr_3b_`nmr' = . if q_3b == .
	local x = `x' - 1
}

set scheme jpalfull

qui sum clients_n if q_3b!=. 

graph bar gr_3b_*, percentages /// percent is the default
	ytitle("In percentage (%)", size(medsmall) orientation(vertical)) ///
	ylabel(0(25)100) ///
	blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
	title("Does your {bf:BM Agent display} the official list of transaction fees", size(medsmall)) ///
	subtitle("from the bank at his/her shop?", size(medsmall)) ///
	legend(order(1 "Yes" 2 "No") size(medsmall) col(2)) ///
	note("Total clients = `: di %6.0fc `r(N)''", size(medsmall))
	
graph export "$output/Client Baseline - `date'/22 - q_3b.png", as(png) replace

*** q_3c
local x = 1
forval nmr = 1/2 {
	gen gr_3c_`nmr' = 1 if q_3c == `x'
	recode gr_3c_`nmr' (. = 0)
	replace gr_3c_`nmr' = . if q_3c == .
	local x = `x' - 1
}

set scheme jpalfull

qui sum clients_n if q_3c!=. 

graph bar gr_3c_*, percentages /// percent is the default
	ytitle("In percentage (%)", size(medsmall) orientation(vertical)) ///
	ylabel(0(25)100) ///
	blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
	title("Does your {bf:BM Agent} set the {bf:same price} for everyone?", size(medsmall)) ///
	subtitle(" ", size(medsmall)) ///
	legend(order(1 "Yes" 2 "No") size(medsmall) col(2)) ///
	note("Total clients = `: di %6.0fc `r(N)''", size(medsmall))
	
graph export "$output/Client Baseline - `date'/23 - q_3c.png", as(png) replace

*** q_3c_1
local x = 1
forval nmr = 1/2 {
	gen gr_3c_1_`nmr' = 1 if q_3c_1 == `x'
	recode gr_3c_1_`nmr' (. = 0)
	replace gr_3c_1_`nmr' = . if q_3c_1 == .
	local x = `x' - 1
}

set scheme jpalfull

qui sum clients_n if q_3c_1!=. 

graph bar gr_3c_1_*, percentages /// percent is the default
	ytitle("In percentage (%)", size(medsmall) orientation(vertical)) ///
	ylabel(0(25)100) ///
	blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
	title("If not, do you think there is a specific type of customer", size(medsmall)) ///
	subtitle("that your {bf:BM Agent} charge {bf:less}?", size(medsmall)) ///
	legend(order(1 "Yes" 2 "No") size(medsmall) col(2)) ///
	note("Total clients = `: di %6.0fc `r(N)''", size(medsmall))
	
graph export "$output/Client Baseline - `date'/24 - q_3c_1.png", as(png) replace

*** q_3c_1_1
preserve

keep unique_code q_3c_1_1_*
drop q_3c_1_1_DO
drop if q_3c_1_1_a == .

local st3c = 1
foreach a of varlist q_3c_1_1_a q_3c_1_1_b q_3c_1_1_c q_3c_1_1_d q_3c_1_1_e q_3c_1_1_f q_3c_1_1_g {
    rename `a' q_3c_1_1_`st3c'
	local st3c = `st3c' + 1
}

gen num = _n
qui sum num
local obs3c_1_1 = `r(N)'

reshape long q_3c_1_1_, i(unique_code) j(q_3c_1_1)

la def q_3c_1_1 ///
1 "Friends and family" ///
2 "High-value cust" ///
3 "New cust" ///
4 "Long-time cust" ///
5 "Poorer cust" ///
6 "Cust from local area" ///
7  "Cust can easily do bus w/ other agents"
la val q_3c_1_1 q_3c_1_1

tab q_3c_1_1_, gen(answer)

set scheme jpalfull

graph bar (sum) answer2 answer1, stack percentage over(q_3c_1_1, label(angle(30) labsize(small))) ///
	title("If your {bf:BM Agent} does not set the same price for everyone,", size(medsmall)) ///
	subtitle("who pays {bf:less}?", size(medsmall)) ///
	legend(order(1 "Yes" 2 "No") size(medsmall)) ///
	note("Note:" "Total clients = `obs3c_1_1'", size(medsmall)) ///
	ytitle("%", size(small) orientation(horizontal)) ///
	ylabel(0(25)100) ///
	blabel(bar, pos(center) size(medsmall) format(%15.1fc))
	
graph export "$output/Client Baseline - `date'/25 - q_3c_1_1.png", as(png) replace

restore

// recode q_3c_1_1_a - q_3c_1_1_g (0 = 2)
// la def yesno_3c 1 "Yes" 2 "No"
// la val q_3c_1_1_a - q_3c_1_1_g yesno_3c
//
// labvars q_3c_1_1_a - q_3c_1_1_g ///
// "Friends and family" ///
// "High-value cust" ///
// "New cust" ///
// "Long-time cust" ///
// "Poorer cust" ///
// "Cust from local area" ///
// "Cust who can easily do business w/ other agents"
//
// set scheme jpalfull
// foreach x of varlist q_3c_1_1_a q_3c_1_1_b q_3c_1_1_c q_3c_1_1_d q_3c_1_1_e q_3c_1_1_f q_3c_1_1_g {
//				
// 	qui sum clients_n  if `x' !=.
// 	loc obs = `r(N)'
//
// 	loc	z: 	var lab 	`x'
// 	splitvallabels		`x'	
//				
// 	graph bar, over(`x', label(labsize(vsmall)) relabel(`r(relabel)')) ytitle("%", size(small) orientation(horizontal)) ylabel(0(25)100, grid labsize(vsmall)) ///
// 	title("`z'", size(medsmall)) bar(1) blabel(bar, size(vsmall) format(%4.1f)) ///
// 	note("Note:" "Total clients = `obs'", span size(small)) name(`x', replace)
// }
//
//
// graph		combine q_3c_1_1_a q_3c_1_1_b q_3c_1_1_c q_3c_1_1_d q_3c_1_1_e q_3c_1_1_f q_3c_1_1_g, ///
// 			col(2) iscale(0.5) xcommon xsize(20) ysize(20) imargin(0 0 0) ///
// 			title("If your {bf:BM Agent} does not set the same price for everyone,", size(small)) ///
// 			subtitle("who pays {bf:less}?", size(small))
// graph 		export "$output/Client Baseline - `date'/25 - q_3c_1_1.png", as(png) replace

**# 4. Section 4
*** q_4
preserve

** Drop missing variable (if any)
drop if q_4 == .

** Summary statistics
qui summarize q_4, detail
return list

** Store obs number before dropping outlier(s)
local total_before = r(N)

** Detect and drop outlier(s)
generate iqr = r(p75) - r(p25)
generate lower_limit = r(p25) - 1.5 * iqr
generate upper_limit = r(p75) + 1.5 * iqr
generate outlier = (q_4 < lower_limit) | (q_4 > upper_limit)
drop if outlier == 1

** Store obs number after dropping outlier(s) and compute the difference
qui summarize q_4, detail
local total_after = r(N)
local dropped_obs = `total_before' - `total_after'

** Store lower and upper threshold
qui su lower_limit, det
local ll = round(`r(mean)', 1)
qui su upper_limit, det
local ul = round(`r(mean)', 1)

* Histogram
set scheme plotplain

histogram q_4, percent color(brown) ///
	discrete ///
	xlabel(0(1)10) ///
	ylabel(0(3)30) ///
    xtitle("Satisfaction level", size(medsmall)) ///
    ytitle("Percentage of clients", size(medsmall)) ///
    title("For the latest transaction you did with your {bf:BM Agent},", size(medsmall)) ///
	subtitle("on a scale of 1 to 10, {bf:how satisfied} were you with the service?", size(medsmall)) ///
	note("Note:" "Total clients = `: di %6.0fc `r(N)''" "Outlier threshold = `ll' (lower) and `ul' (upper)" "Dropped outlier observation = `dropped_obs'", size(medsmall))
	
graph export "$output/Client Baseline - `date'/26 - q_4_hist.png", as(png) replace

* Box plot
set scheme jpalfull

qui su q_4, det
return list

local mean_rounded = round(`r(mean)', 1)	
local Q_1_rounded = round(`r(p25)', 1)
local Q_3_rounded = round(`r(p75)', 1)
local median_rounded = round(`r(p50)', 1)

graph box q_4, yline(`r(mean)', lpattern(.)) ///
	ytitle("Satisfaction level", size(medsmall)) ///
    title("For the latest transaction you did with your {bf:BM Agent},", size(medsmall)) ///
    subtitle("on a scale of 1 to 10, {bf:how satisfied} were you with the service??", size(medsmall)) ///
	text(`r(p50)' 95 "Median=`median_rounded'", size(vsmall)) ///
	text(`r(p75)' 95 "Q3=`Q_3_rounded'", size(vsmall)) ///
    text(`r(p25)' 95 "Q1=`Q_1_rounded'", size(vsmall)) ///
    text(`r(mean)' 95 "Mean=`mean_rounded'", size(vsmall)) ///
	note("Note:" "Total clients = `: di %6.0fc `r(N)''" "Outlier threshold = `ll' (lower) and `ul' (upper)" "Dropped outlier observation = `dropped_obs'", size(medsmall))
	
graph export "$output/Client Baseline - `date'/26 - q_4_boxplot.png", as(png) replace

restore

**# 5. Section 5
*** q_5a
preserve

keep unique_code q_5a_*
drop q_5a_DO
drop if q_5a_1 == .

gen num = _n
qui sum num
local obs5a = `r(N)'

reshape long q_5a_, i(unique_code) j(q_5a)

la def q_5a 1 "Prior customer" ///
2 "Agent can answer question" ///
3 "Agent proximity to home" ///
4 "Agent sufficient cash balance" ///
5 "Price transparent" ///
6 "Agent always available" ///
7 "Agent offers the lowest price" ///
8 "Agent works w/ the bank whr I want to open acc" ///
9 "I trust the agent" ///
10 "Agent charges everyone the same prices"
la val q_5a q_5a

tab q_5a_, gen(answer)

set scheme jpalfull

graph bar (sum) answer*, stack percentage over(q_5a, label(angle(30) labsize(vsmall))) ///
	title("Which characteristics {bf:are most important} to determine which agent", size(medsmall)) ///
	subtitle("you are going {bf:to be a regular to?}", size(medsmall)) ///
	legend(order(1 "Not important at all" 2 "Not very important" 3 "Important" 4 "Very important") size(medsmall) col(2)) ///
	note("Total clients = `: di %6.0fc `obs5a''", size(medsmall)) ///
	ytitle("%", size(medsmall) orientation(horizontal)) ///
	ylabel(0(25)100) ///
	blabel(bar, pos(center) size(vsmall) format(%15.1fc))
	
graph export "$output/Client Baseline - `date'/27 - q_5a.png", as(png) replace

restore

// labvars q_5a_1 - q_5a_10 ///
// "I've been a prior customer" ///
// "Agent can clearly answer question" ///
// "Agent proximity to home or workplace" ///
// "Agent has sufficient cash balance" ///
// "Price transparent and displayed on the store" ///
// "Agent always available every time needed" ///
// "Agent offers the lowest price" ///
// "Agent works w/ the bank whr I want to open acc" ///
// "I trust the agent" ///
// "Agent charges everyone the same prices"
//
// set scheme jpalfull
// foreach x of varlist q_5a_1 q_5a_2 q_5a_3 q_5a_4 q_5a_5 q_5a_6 q_5a_7 q_5a_8 q_5a_9 q_5a_10 {
//				
// 	qui sum clients_n  if `x' !=.
// 	loc obs = `r(N)'
//
// 	loc	z: 	var lab 	`x'
// 	splitvallabels		`x'	
//				
// 	graph bar, over(`x', label(labsize(vsmall)) relabel(`r(relabel)')) ytitle("%", size(small) orientation(horizontal)) ylabel(0(25)100, grid labsize(vsmall)) ///
// 	title("`z'", size(medsmall)) bar(1) blabel(bar, size(vsmall) format(%4.1f)) ///
// 	note("Note:" "Total clients = `obs'", span size(small)) name(`x', replace)
// }
//
//
// graph		combine q_5a_1 q_5a_2 q_5a_3 q_5a_4 q_5a_5 q_5a_6 q_5a_7 q_5a_8 q_5a_9 q_5a_10, ///
// 			col(2) iscale(0.55) xcommon xsize(30) ysize(30) imargin(0 0 0) ///
// 			title("The most important characteristics to determine a regular agent", size(small)) ///
// 			subtitle("", size(small))
// graph 		export "$output/Client Baseline - `date'/27 - q_5a.png", as(png) replace

*** q_5b
forval x = 1/2 {
	gen gr_5b_`x' = 1 if q_5b == `x'
	recode gr_5b_`x' (. = 0)
	replace gr_5b_`x' = . if q_5b == .
}

set scheme jpalfull

qui sum clients_n if q_5b!=. 

graph bar gr_5b_*, percentages /// percent is the default
	ytitle("In percentage (%)", size(medsmall) orientation(vertical)) ///
	ylabel(0(25)100) ///
	blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
	title("Which of the following statements do you {bf:agree with most}?", size(medsmall)) ///
	subtitle(" ", size(medsmall)) ///
	legend(order(1 "Continue doing business w/ regular agent, even if others offer lower prices" 2 "Change to other agents who offer lower prices") size(small) col(1)) ///
	note("Total clients = `: di %6.0fc `r(N)''", size(medsmall))

graph export "$output/Client Baseline - `date'/28 - q_5b.png", as(png) replace

**# 6. Section 6
*** q_6a
forval x = 1/4 {
	gen gr_6a_`x' = 1 if q_6a == `x'
	recode gr_6a_`x' (. = 0)
	replace gr_6a_`x' = . if q_6a == .
}

set scheme jpalfull

qui sum clients_n if q_6a!=.

graph bar gr_6a_*, percentages /// percent is the default
	ytitle("In percentage (%)", size(medsmall) orientation(vertical)) ///
	ylabel(0(25)100) ///
	blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
	title("Your regular agent has charged another cust {bf:a lower fee} than you ", size(medsmall)) ///
	subtitle("for the same transaction. How would you react?", size(medsmall)) ///
	legend(order(1 "Indifferent" 2 "Unfair, and start transacting with another agent" 3 "Unfair, but would continue making transactions with the same agent" 4 "Fair") size(small) col(1)) ///
	note("Total clients = `: di %6.0fc `r(N)''", size(medsmall))

graph export "$output/Client Baseline - `date'/29 - q_6a.png", as(png) replace

*** q_6b
forval x = 1/4 {
	gen gr_6b_`x' = 1 if q_6b == `x'
	recode gr_6b_`x' (. = 0)
	replace gr_6b_`x' = . if q_6b == .
}

set scheme jpalfull

qui sum clients_n if q_6b!=. 

graph bar gr_6b_*, percentages /// percent is the default
	ytitle("In percentage (%)", size(medsmall) orientation(vertical)) ///
	ylabel(0(25)100) ///
	blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
	title("Your regular agent has charged another cust {bf:50% higher} than another cust.", size(medsmall)) ///
	subtitle("How would you react?", size(medsmall)) ///
	legend(order(1 "Indifferent" 2 "Unfair, and start transacting with another agent" 3 "Unfair, but would continue making transactions with the same agent" 4 "Fair") size(small) col(1)) ///
	note("Total clients = `: di %6.0fc `r(N)''", size(medsmall))

graph export "$output/Client Baseline - `date'/30 - q_6b.png", as(png) replace

*** q_6c
forval x = 1/3 {
	gen gr_6c_`x' = 1 if q_6c == `x'
	recode gr_6c_`x' (. = 0)
	replace gr_6c_`x' = . if q_6c == .
}

set scheme jpalfull

qui sum clients_n if q_6c!=. 

graph bar gr_6c_*, percentages /// percent is the default
	ytitle("In percentage (%)", size(medsmall) orientation(vertical)) ///
	ylabel(0(25)100) ///
	blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
	title("Two Agents with the same fee of Rp3.000 for a cash withdrawal.", size(medsmall)) ///
	subtitle("Which agent would you prefer to {bf:regularly} do transactions with?", size(medsmall)) ///
	legend(order(1 "Agent A" 2 "Agent B" 3 "Indifferent") size(medsmall) col(3)) ///
	note("Total clients = `: di %6.0fc `r(N)''", size(medsmall))

graph export "$output/Client Baseline - `date'/31 - q_6c.png", as(png) replace

**# 7. Section 7
*** q_7
preserve

keep unique_code q_7a q_7b q_7c q_7d
drop if q_7a == .

local st7 = 1
foreach a of varlist q_7a q_7b q_7c q_7d {
    rename `a' q_7_`st7'
	local st7 = `st7' + 1
}

gen num = _n
qui sum num
local obs7 = `r(N)'

reshape long q_7_, i(unique_code) j(q_7)

la def q_7 ///
1 "Banks" ///
2 "Bank Mandiri" ///
3 "BM Agent" ///
4 "BM Agent will give best price"
la val q_7 q_7

tab q_7_, gen(answer)

set scheme jpalfull

graph bar (sum) answer*, stack percentage over(q_7, label(angle(30) labsize(small))) ///
	title("Views regarding {bf:BM Agent} and {bf:Bank Mandiri}", size(medsmall)) ///
	subtitle(" ", size(medsmall)) ///
	legend(order(1 "A great deal of confidence" 2 "Quite a lot of confidence" 3 "Not very much confidence" 4 "No confidence at all") size(medsmall) col(2)) ///
	note("Note:" "Total clients = `: di %6.0fc `obs7''", size(medsmall)) ///
	ytitle("%", size(medsmall) orientation(horizontal)) ///
	ylabel(0(25)100) ///
	blabel(bar, pos(center) size(vsmall) format(%15.1fc))

graph export "$output/Client Baseline - `date'/32 - q_7.png", as(png) replace

restore

// labvars q_7a - q_7d ///
// "Confidence in {bf:banks}" ///
// "Confidence in {bf:Bank Mandiri}" ///
// "Confidence in {bf:BM Agent}" ///
// "Confidence that BM {bf:Agent} will {bf:give the best price}"
//
// set scheme jpalfull
// foreach x of varlist q_7a q_7b q_7c q_7d {
//				
// 	qui sum clients_n  if `x' !=.
// 	loc obs = `r(N)'
//
// 	loc	z: 	var lab 	`x'
// 	splitvallabels		`x'	
//				
// 	graph bar, over(`x', label(labsize(vsmall)) relabel(`r(relabel)')) ytitle("%", size(small) orientation(horizontal)) ylabel(0(25)100, grid labsize(vsmall)) ///
// 	title("`z'", size(medsmall)) bar(1) blabel(bar, size(vsmall) format(%4.1f)) ///
// 	note("Note:" "Total clients = `obs'", span size(small)) name(`x', replace)
// }
//
//
// graph		combine q_7a q_7b q_7c q_7d, ///
// 			col(2) iscale(0.6) xcommon xsize(20) ysize(15) imargin(0 0 0) ///
// 			title("Views regarding {bf:BM Agent} and {bf:Bank Mandiri}", size(small)) ///
// 			subtitle(" ", size(small))
// graph 		export "$output/Client Baseline - `date'/32 - q_7.png", as(png) replace

**# 8. Section 8
*** q_8
preserve

keep unique_code q_8a q_8b q_8c q_8d q_8e q_8f
drop if q_8a == .

local st8 = 1
foreach a of varlist q_8a q_8b q_8c q_8d q_8e q_8f {
    rename `a' q_8_`st8'
	local st8 = `st8' + 1
}

gen num = _n
qui sum num
local obs8 = `r(N)'

reshape long q_8_, i(unique_code) j(q_8)

la def q_8 ///
1 "Honest and trustworthy" ///
2 "Cust well-being above profits" ///
3 "Treats all equally well" ///
4 "Transparent about pricing" ///
5 "Does his/her job well" ///
6 "Offers reliable service"
la val q_8 q_8

tab q_8_, gen(answer)

set scheme jpalfull

graph bar (sum) answer*, stack percentage over(q_8, label(angle(30) labsize(small))) ///
	title("Do you agree with each of the following statements about {bf:BM Agent}?", size(medsmall)) ///
	subtitle(" ", size(medsmall)) ///
	legend(order(1 "Strongly disagree" 2 "Disagree" 3 "Agree" 4 "Strongly agree") size(small) col(2)) ///
	note("Note:" "Total clients = `: di %6.0fc `obs8''", size(medsmall)) ///
	ytitle("%", size(medsmall) orientation(horizontal)) ///
	ylabel(0(25)100) ///
	blabel(bar, pos(center) size(vsmall) format(%15.1fc))

graph export "$output/Client Baseline - `date'/33 - q_8.png", as(png) replace

restore

// labvars q_8a q_8b q_8c q_8d q_8e q_8f ///
// "My BM Agent is {bf:honest and trustworthy}" ///
// "My BM Agent {bf:puts cust well-being above profits}" ///
// "My BM Agent {bf:treats all cust equally well}" ////
// "My BM Agent {bf:is transparent} about pricing" ///
// "My BM Agent {bf:does his/her job well}" ///
// "My BM Agent {bf:offers reliable service}"
//
// set scheme jpalfull
// foreach x of varlist q_8a q_8b q_8c q_8d q_8e q_8f {
//				
// 	qui sum clients_n  if `x' !=.
// 	loc obs = `r(N)'
//
// 	loc	z: 	var lab 	`x'
// 	splitvallabels		`x'	
//				
// 	graph bar, over(`x', label(labsize(vsmall)) relabel(`r(relabel)')) ytitle("%", size(small) orientation(horizontal)) ylabel(0(25)100, grid labsize(vsmall)) ///
// 	title("`z'", size(medsmall)) bar(1) blabel(bar, size(vsmall) format(%4.1f)) ///
// 	note("Note:" "Total clients = `obs'", span size(small)) name(`x', replace)
// }
//
//
// graph		combine q_8a q_8b q_8c q_8d q_8e q_8f, ///
// 			col(2) iscale(0.6) xcommon xsize(20) ysize(15) imargin(0 0 0) ///
// 			title("Do you agree with each of the following statements about {bf:BM Agent}?", size(small)) ///
// 			subtitle(" ", size(small))
// graph 		export "$output/Client Baseline - `date'/33 - q_8.png", as(png) replace

**# 9. Section 9
*** q_9
preserve

keep unique_code q_9a q_9b q_9c q_9d q_9e
drop if q_9a == .

local st9 = 1
foreach a of varlist q_9a q_9b q_9c q_9d q_9e {
    rename `a' q_9_`st9'
	local st9 = `st9' + 1
}

gen num = _n
qui sum num
local obs9 = `r(N)'

reshape long q_9_, i(unique_code) j(q_9)

la def q_9 ///
1 "Honest and trustworthy" ///
2 "Cust well-being above profits" ///
3 "Treats all equally well" ///
4 "Transparent about pricing" ///
5 "Offers reliable service"
la val q_9 q_9

tab q_9_, gen(answer)

set scheme jpalfull

graph bar (sum) answer*, stack percentage over(q_9, label(angle(30) labsize(small))) ///
	title("Do you agree with each of the following statements about {bf:Bank Mandiri}?", size(medsmall)) ///
	subtitle(" ", size(medsmall)) ///
	legend(order(1 "Strongly disagree" 2 "Disagree" 3 "Agree" 4 "Strongly agree") size(medsmall) col(2)) ///
	note("Note:" "Total clients = `: di %6.0fc `obs9''", size(medsmall)) ///
	ytitle("%", size(medsmall) orientation(horizontal)) ///
	ylabel(0(25)100) ///
	blabel(bar, pos(center) size(vsmall) format(%15.1fc))

graph export "$output/Client Baseline - `date'/34 - q_9.png", as(png) replace

restore

// labvars q_9a q_9b q_9c q_9d q_9e ///
// "BM is {bf:honest and trustworthy}" ///
// "BM {bf:puts cust well-being above profits}" ///
// "BM {bf:treats all cust equally well}" ///
// "BM {bf:is transparent} about pricing" ///
// "BM {bf:offers reliable service}"
//
// set scheme jpalfull
// foreach x of varlist q_9a q_9b q_9c q_9d q_9e {
//				
// 	qui sum clients_n  if `x' !=.
// 	loc obs = `r(N)'
//
// 	loc	z: 	var lab 	`x'
// 	splitvallabels		`x'	
//				
// 	graph bar, over(`x', label(labsize(vsmall)) relabel(`r(relabel)')) ytitle("%", size(small) orientation(horizontal)) ylabel(0(25)100, grid labsize(vsmall)) ///
// 	title("`z'", size(medsmall)) bar(1) blabel(bar, size(vsmall) format(%4.1f)) ///
// 	note("Note:" "Total clients = `obs'", span size(small)) name(`x', replace)
// }
//
//
// graph		combine q_9a q_9b q_9c q_9d q_9e, ///
// 			col(2) iscale(0.6) xcommon xsize(20) ysize(15) imargin(0 0 0) ///
// 			title("Do you agree with each of the following statements about {bf:Bank Mandiri?}", size(small)) ///
// 			subtitle(" ", size(small))
// graph 		export "$output/Client Baseline - `date'/34 - q_9.png", as(png) replace

**# 10. Section 10
*** q_10a
forval x = 1/3 {
	gen gr_10a_`x' = 1 if q_10a == `x'
	recode gr_10a_`x' (. = 0)
	replace gr_10a_`x' = . if q_10a == .
}

set scheme jpalfull

qui sum clients_n if q_10a!=. 

graph bar gr_10a_*, percentages /// percent is the default
	ytitle("In percentage (%)", size(medsmall) orientation(vertical)) ///
	ylabel(0(25)100) ///
	blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
	title("Last month, how much {bf:time} do you think your BM Agent spent", size(medsmall)) ///
	subtitle("{bf:advertising} his/her services to people in the village?", size(medsmall)) ///
	legend(order(1 "None at all" 2 "Some time" 3 "A lot of time") size(medsmall) col(3)) ///
	note("Total clients = `: di %6.0fc `r(N)''", size(medsmall))

graph export "$output/Client Baseline - `date'/35 - q_10a.png", as(png) replace

*** q_10b
forval x = 1/4 {
	gen gr_10b_`x' = 1 if q_10b == `x'
	recode gr_10b_`x' (. = 0)
	replace gr_10b_`x' = . if q_10b == .
}

set scheme jpalfull

qui sum clients_n if q_10b!=. 

graph bar gr_10b_*, percentages /// percent is the default
	ytitle("In percentage (%)", size(medsmall) orientation(vertical)) ///
	ylabel(0(25)100) ///
	blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
	title("Do you agree with this statement?", size(small)) ///
	subtitle("Last month, BM Agent did all he/she could {bf:to convince village people to adopt the agent products}", size(small)) ///
	legend(order(1 "Disagree completely" 2 "Disagree" 3 "Agree" 4 "Fully agree") size(medsmall) col(2)) ///
	note("Total clients = `: di %6.0fc `r(N)''", size(medsmall))
	
graph export "$output/Client Baseline - `date'/36 - q_10b.png", as(png) replace

*** q_10c
forval x = 1/6 {
	gen gr_10c_`x' = 1 if q_10c == `x'
	recode gr_10c_`x' (. = 0)
	replace gr_10c_`x' = . if q_10c == .
}

set scheme jpalfull

qui sum clients_n if q_10c!=. 

graph bar gr_10c_*, percentages /// percent is the default
	ytitle("In percentage (%)", size(medsmall) orientation(vertical)) ///
	ylabel(0(25)100) ///
	blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
	title("Last month, has your BM Agent {bf:approached you} to encourage you to", size(medsmall)) ///
	subtitle("{bf:do more branchless banking transactions}?", size(medsmall)) ///
	legend(order(1 "Every day" 2 "A few times a week" 3 "Once a week" 4 "A few times per month" 5 "Once a month" 6 "Not at all") size(small) col(2)) ///
	note("Total clients = `: di %6.0fc `r(N)''", size(medsmall))

graph export "$output/Client Baseline - `date'/37 - q_10c.png", as(png) replace

*** q_10d
forval x = 1/6 {
	gen gr_10d_`x' = 1 if q_10d == `x'
	recode gr_10d_`x' (. = 0)
	replace gr_10d_`x' = . if q_10d == .
}

set scheme jpalfull

qui sum clients_n if q_10d!=. 

graph bar gr_10d_*, percentages /// percent is the default
	ytitle("In percentage (%)", size(medsmall) orientation(vertical)) ///
	ylabel(0(25)100) ///
	blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
	title("Last month, has your BM Agent {bf:approached you} to encourage you to", size(medsmall)) ///
	subtitle("{bf:adopt new Bank Mandiri financial products}?", size(medsmall)) ///
	legend(order(1 "Every day" 2 "A few times a week" 3 "Once a week" 4 "A few times per month" 5 "Once a month" 6 "Not at all") size(small) col(2)) ///
	note("Total clients = `: di %6.0fc `r(N)''", size(medsmall))

graph export "$output/Client Baseline - `date'/38 - q_10d.png", as(png) replace

*** q_10e
local x = 1
forval nmr = 1/2 {
	gen gr_10e_`nmr' = 1 if q_10e == `x'
	recode gr_10e_`nmr' (. = 0)
	replace gr_10e_`nmr' = . if q_10e == .
	local x = `x' - 1
}

set scheme jpalfull

qui sum clients_n if q_10e!=. 

graph bar gr_10e_*, percentages /// percent is the default
	ytitle("In percentage (%)", size(medsmall) orientation(vertical)) ///
	ylabel(0(25)100) ///
	blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
	title("Last month, has the agent approached you with", size(medsmall)) ///
	subtitle("{bf:new information about prices} for Bank Mandiri transactions?", size(medsmall)) ///
	legend(order(1 "Yes" 2 "No") size(medsmall) col(2)) ///
	note("Total clients = `: di %6.0fc `r(N)''", size(medsmall))

graph export "$output/Client Baseline - `date'/39 - q_10e.png", as(png) replace

**# 11. Section 11
*** q_11a
forval x = 1/2 {
	gen gr_11a_`x' = 1 if q_11a == `x'
	recode gr_11a_`x' (. = 0)
	replace gr_11a_`x' = . if q_11a == .
}

set scheme jpalfull

qui sum clients_n if q_11a!=.

graph bar gr_11a_*, percentages /// percent is the default
	ytitle("In percentage (%)", size(medsmall) orientation(vertical)) ///
	ylabel(0(25)100) ///
	blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
	title("Which of the following statements do you agree with most?", size(medsmall)) ///
	subtitle(" ", size(medsmall)) ///
	legend(order(1 "There are many agents in my area" 2 "There are limited agents in my area") size(medsmall) col(1)) ///
	note("Total clients = `: di %6.0fc `r(N)''", size(medsmall))

graph export "$output/Client Baseline - `date'/40 - q_11a.png", as(png) replace

*** q_11b
preserve

** Drop missing variable (if any)
drop if q_11b == .

** Summary statistics
qui summarize q_11b, detail
return list

** Store obs number before dropping outlier(s)
local total_before = r(N)

** Detect and drop outlier(s)
generate iqr = r(p75) - r(p25)
generate lower_limit = r(p25) - 1.5 * iqr
generate upper_limit = r(p75) + 1.5 * iqr
generate outlier = (q_11b < lower_limit) | (q_11b > upper_limit)
drop if outlier == 1

** Store obs number after dropping outlier(s) and compute the difference
qui summarize q_11b, detail
local total_after = r(N)
local dropped_obs = `total_before' - `total_after'

** Store lower and upper threshold
qui su lower_limit, det
local ll = round(`r(mean)', 1)
qui su upper_limit, det
local ul = round(`r(mean)', 1)

* Histogram
set scheme plotplain

histogram q_11b, percent color(brown) ///
	discrete ///
	xlabel(0(2)50) ///
	ylabel(0(3)30) ///
    xtitle("Number of agent", size(medsmall)) ///
    ytitle("Percentage of clients", size(medsmall)) ///
    title("How many {bf:branchless banking agents} are in your area?", size(medsmall)) ///
	subtitle(" ", size(medsmall)) ///
	note("Note:" "Total clients = `: di %6.0fc `r(N)''" "Outlier threshold = `ll' (lower) and `ul' (upper)" "Dropped outlier observation = `dropped_obs'", size(medsmall))
graph export "$output/Client Baseline - `date'/41 - q_11b_hist.png", as(png) replace

* Box plot
set scheme jpalfull

qui su q_11b, det
return list

local mean_rounded = round(`r(mean)', 1)	
local Q_1_rounded = round(`r(p25)', 1)
local Q_3_rounded = round(`r(p75)', 1)
local median_rounded = round(`r(p50)', 1)

graph box q_11b, yline(`r(mean)', lpattern(.)) ///
	ytitle("Number of agent", size(medsmall)) ///
    title("How many {bf:branchless banking agents} are in your area?", size(medsmall)) ///
    subtitle(" ", size(medsmall)) ///
	text(`r(p50)' 95 "Median=`median_rounded'", size(vsmall)) ///
	text(`r(p75)' 95 "Q3=`Q_3_rounded'", size(vsmall)) ///
    text(`r(p25)' 95 "Q1=`Q_1_rounded'", size(vsmall)) ///
    text(`r(mean)' 95 "Mean=`mean_rounded'", size(vsmall)) ///
	note("Note:" "Total clients = `: di %6.0fc `r(N)''" "Outlier threshold = `ll' (lower) and `ul' (upper)" "Dropped outlier observation = `dropped_obs'", size(medsmall))
	
graph export "$output/Client Baseline - `date'/41 - q_11b_boxplot.png", as(png) replace

restore

**# 12. Section 12
*** q_12a
set scheme plotplain

histogram q_12a, percent color(brown) ///
	discrete ///
 	xlabel(2013(1)2024) ///
	ylabel(0(3)30) ///
    xtitle("Year", size(medsmall)) ///
    ytitle("Percentage of clients", size(medsmall)) ///
    title("{bf:Since when} have you been doing transactions with your {bf:BM Agent}?", size(medsmall)) ///
	subtitle(" ", size(medsmall)) ///
	note("Total clients = `: di %6.0fc `r(N)''", size(medsmall))

graph export "$output/Client Baseline - `date'/42 - q_12a_hist.png", as(png) replace

*** q_12b
forval x = 1/4 {
	gen gr_12b_`x' = 1 if q_12b == `x'
	recode gr_12b_`x' (. = 0)
	replace gr_12b_`x' = . if q_12b == .
}

set scheme jpalfull

qui sum clients_n if q_12b!=. 

graph bar gr_12b_*, percentages /// percent is the default
	ytitle("In percentage (%)", size(medsmall) orientation(vertical)) ///
	ylabel(0(25)100) ///
	blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
	title("{bf:For how long} have you known your {bf:BM Agent}?", size(medsmall)) ///
	subtitle(" ", size(medsmall)) ///
	legend(order(1 "A few months" 2 "For about a year" 3 "Between 1-5 years" 4 "Longer than 5 years") size(small) col(2)) ///
	note("Total clients = `: di %6.0fc `r(N)''", size(medsmall))

graph export "$output/Client Baseline - `date'/43 - q_12b.png", as(png) replace

*** q_12c
forval x = 1/8 {
	gen gr_12c_`x' = 1 if q_12c == `x'
	recode gr_12c_`x' (. = 0)
	replace gr_12c_`x' = . if q_12c == .
}

set scheme jpalfull

qui sum clients_n if q_12c!=. 

graph bar gr_12c_*, percentages /// percent is the default
	ytitle("In percentage (%)", size(medsmall) orientation(vertical)) ///
	ylabel(0(25)100) ///
	blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
	title("How often do you {bf:talk} with your {bf:BM Agent}?", size(medsmall)) ///
	subtitle(" ", size(medsmall)) ///
	legend(order(1 "Every day" 2 "A few times a week" 3 "Once a week" 4 "A few times per month" 5 "Once a month" 6 "Every 3 months" 7 "Every 6 months" 8 "Once a year") size(small) col(2)) ///
	note("Total clients = `: di %6.0fc `r(N)''", size(medsmall))

graph export "$output/Client Baseline - `date'/44 - q_12c.png", as(png) replace

*** q_12d
preserve

** Drop missing variable (if any)
drop if q_12d == .

** Summary statistics
qui summarize q_12d, detail
return list

** Store obs number before dropping outlier(s)
local total_before = r(N)

** Detect and drop outlier(s)
generate iqr = r(p75) - r(p25)
generate lower_limit = r(p25) - 1.5 * iqr
generate upper_limit = r(p75) + 1.5 * iqr
generate outlier = (q_12d < lower_limit) | (q_12d > upper_limit)
drop if outlier == 1

** Store obs number after dropping outlier(s) and compute the difference
qui summarize q_12d, detail
local total_after = r(N)
local dropped_obs = `total_before' - `total_after'

** Store lower and upper threshold
qui su lower_limit, det
local ll = round(`r(mean)', 1)
qui su upper_limit, det
local ul = round(`r(mean)', 1)

* Histogram
set scheme plotplain

histogram q_12d, percent color(brown) ///
	discrete ///
	xlabel(0(5)100) ///
	ylabel(0(2)15) ///
    xtitle("Percentage of overall branchless banking transactions with BM Agent", size(medsmall)) ///
    ytitle("Percentage of clients", size(medsmall)) ///
    title("What % {bf:of your overall branchless banking transactions}", size(medsmall)) ///
	subtitle("do you do with your {bf:BM Agent}?", size(medsmall)) ///
	note("Note:" "Total clients = `: di %6.0fc `r(N)''" "Outlier threshold = `ll' (lower) and `ul' (upper)" "Dropped outlier observation = `dropped_obs'", size(medsmall))

graph export "$output/Client Baseline - `date'/45 - q_12d_hist.png", as(png) replace

* Box plot
set scheme jpalfull

qui su q_12d, det
return list

local mean_rounded = round(`r(mean)', 1)	
local Q_1_rounded = round(`r(p25)', 1)
local Q_3_rounded = round(`r(p75)', 1)
local median_rounded = round(`r(p50)', 1)

graph box q_12d, yline(`r(mean)', lpattern(.)) ///
	ytitle("In percentage (%)", size(medsmall)) ///
    title("What % {bf:of your overall branchless banking transactions}", size(medsmall)) ///
    subtitle("do you do with your {bf:BM Agent}?", size(medsmall)) ///
	text(`r(p50)' 95 "Median=`median_rounded'", size(vsmall)) ///
	text(`r(p75)' 95 "Q3=`Q_3_rounded'", size(vsmall)) ///
    text(`r(p25)' 95 "Q1=`Q_1_rounded'", size(vsmall)) ///
    text(`r(mean)' 95 "Mean=`mean_rounded'", size(vsmall)) ///
	note("Note:" "Total clients = `: di %6.0fc `r(N)''" "Outlier threshold = `ll' (lower) and `ul' (upper)" "Dropped outlier observation = `dropped_obs'", size(medsmall))

graph export "$output/Client Baseline - `date'/45 - q_12d_boxplot.png", as(png) replace

restore

*** q_12e
local x = 1
forval nmr = 1/2 {
	gen gr_12e_`nmr' = 1 if q_12e == `x'
	recode gr_12e_`nmr' (. = 0)
	replace gr_12e_`nmr' = . if q_12e == .
	local x = `x' - 1
}

set scheme jpalfull

qui sum clients_n if q_12e!=. 

graph bar gr_12e_*, percentages /// percent is the default
	ytitle("In percentage (%)", size(medsmall) orientation(vertical)) ///
	ylabel(0(25)100) ///
	blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
	title("Which of the following best describes your opinion about", size(medsmall)) ///
	subtitle("{bf:banking agents in general}?", size(medsmall)) ///
	legend(order(1 "Not honest and often overcharge customers" 2 "Honest and charge the correct prices") size(small) col(1)) ///
	note("Total clients = `: di %6.0fc `r(N)''", size(medsmall))

graph export "$output/Client Baseline - `date'/46 - q_12e.png", as(png) replace

*** q_12f
preserve

** Drop missing variable (if any)
drop if q_12f == .

** Summary statistics
qui summarize q_12f, detail
return list

** Store obs number before dropping outlier(s)
local total_before = r(N)

** Detect and drop outlier(s)
generate iqr = r(p75) - r(p25)
generate lower_limit = r(p25) - 1.5 * iqr
generate upper_limit = r(p75) + 1.5 * iqr
generate outlier = (q_12f < lower_limit) | (q_12f > upper_limit)
drop if outlier == 1

** Store obs number after dropping outlier(s) and compute the difference
qui summarize q_12f, detail
local total_after = r(N)
local dropped_obs = `total_before' - `total_after'

** Store lower and upper threshold
qui su lower_limit, det
local ll = round(`r(mean)', 1)
qui su upper_limit, det
local ul = round(`r(mean)', 1)

* Histogram
set scheme plotplain

histogram q_12f, percent color(brown) ///
	discrete ///
	xlabel(0(1)10) ///
	ylabel(0(3)30) ///
    xtitle("Step", size(medsmall)) ///
    ytitle("Percentage of clients", size(medsmall)) ///
    title("Imagine a ladder with 10 steps. Richest 10th step and poorest 1st step.", size(medsmall)) ///
	subtitle("{bf:In which step} do you think you are?", size(medsmall)) ///
	note("Note:" "Total clients = `: di %6.0fc `r(N)''" "Outlier threshold = `ll' (lower) and `ul' (upper)" "Dropped outlier observation = `dropped_obs'", size(medsmall))

graph export "$output/Client Baseline - `date'/47 - q_12f_hist.png", as(png) replace

* Box plot
set scheme jpalfull

qui su q_12f, det
return list

local mean_rounded = round(`r(mean)', 1)	
local Q_1_rounded = round(`r(p25)', 1)
local Q_3_rounded = round(`r(p75)', 1)
local median_rounded = round(`r(p50)', 1)

graph box q_12f, yline(`r(mean)', lpattern(.)) ///
	ytitle("Step", size(medsmall)) ///
    title("Imagine a ladder with 10 steps. Richest 10th step and poorest 1st step.", size(medsmall)) ///
    subtitle("{bf:In which step} do you think you are?", size(medsmall)) ///
	text(`r(p50)' 95 "Median=`median_rounded'", size(vsmall)) ///
	text(`r(p75)' 95 "Q3=`Q_3_rounded'", size(vsmall)) ///
    text(`r(p25)' 95 "Q1=`Q_1_rounded'", size(vsmall)) ///
    text(`r(mean)' 95 "Mean=`mean_rounded'", size(vsmall)) ///
	note("Note:" "Total clients = `: di %6.0fc `r(N)''" "Outlier threshold = `ll' (lower) and `ul' (upper)" "Dropped outlier observation = `dropped_obs'", size(medsmall))

graph export "$output/Client Baseline - `date'/47 - q_12f_boxplot.png", as(png) replace

restore

*** q_12g
forval x = 1/4 {
	gen gr_12g_`x' = 1 if q_12g == `x'
	recode gr_12g_`x' (. = 0)
	replace gr_12g_`x' = . if q_12g == .
}

set scheme jpalfull

qui sum clients_n if q_12g!=. 

graph bar gr_12g_*, percentages /// percent is the default
	ytitle("In percentage (%)", size(medsmall) orientation(vertical)) ///
	ylabel(0(25)100) ///
	blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
	title("How would you describe your {bf:customer profile} when it comes to", size(medsmall)) ///
	subtitle("the use of financial services?", size(medsmall)) ///
	legend(order(1 "New & don't know much about products and prices" 2 "Somewhat new, and still learning about products and prices" 3 "Somewhat experienced, and familiar with products and prices" 4 "Very experienced, and fully informed about products and prices") size(small) col(1)) ///
	note("Total clients = `: di %6.0fc `r(N)''", size(medsmall))

graph export "$output/Client Baseline - `date'/48 - q_12g.png", as(png) replace

*** q_12h
local x = 1
forval nmr = 1/2 {
	gen gr_12h_`nmr' = 1 if q_12h == `x'
	recode gr_12h_`nmr' (. = 0)
	replace gr_12h_`nmr' = . if q_12h == .
	local x = `x' - 1
}

set scheme jpalfull

qui sum clients_n if q_12h!=. 

graph bar gr_12h_*, percentages /// percent is the default
	ytitle("In percentage (%)", size(medsmall) orientation(vertical)) ///
	ylabel(0(25)100) ///
	blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
	title("Do you use Mandiri Agen {bf:to send or receive business payments}?", size(medsmall)) ///
	subtitle(" ", size(medsmall)) ///
	legend(order(1 "Yes" 2 "No") size(medsmall) col(2)) ///
	note("Total clients = `: di %6.0fc `r(N)''", size(medsmall))

graph export "$output/Client Baseline - `date'/49 - q_12h.png", as(png) replace

*** q_12i
local x = 1
forval nmr = 1/2 {
	gen gr_12i_`nmr' = 1 if q_12i == `x'
	recode gr_12i_`nmr' (. = 0)
	replace gr_12i_`nmr' = . if q_12i == .
	local x = `x' - 1
}

set scheme jpalfull

qui sum clients_n if q_12i!=. 

graph bar gr_12i_*, percentages /// percent is the default
	ytitle("In percentage (%)", size(medsmall) orientation(vertical)) ///
	ylabel(0(25)100) ///
	blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
	title("Do you use Mandiri Agen {bf:to receive salary payments}?", size(medsmall)) ///
	subtitle(" ", size(medsmall)) ///
	legend(order(1 "Yes" 2 "No") size(medsmall) col(2)) ///
	note("Total clients = `: di %6.0fc `r(N)''", size(medsmall))

graph export "$output/Client Baseline - `date'/50 - q_12i.png", as(png) replace

*** q_12j
local x = 1
forval nmr = 1/2 {
	gen gr_gender_`nmr' = 1 if gender == `x'
	recode gr_gender_`nmr' (. = 0)
	replace gr_gender_`nmr' = . if gender == .
	local x = `x' - 1
}

set scheme jpalfull

qui sum clients_n if gender!=. 

graph bar gr_gender_*, percentages /// percent is the default
	ytitle("In percentage (%)", size(medsmall) orientation(vertical)) ///
	ylabel(0(25)100) ///
	blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
	title("What is your {bf:gender}?", size(medsmall)) ///
	subtitle(" ", size(medsmall)) ///
	legend(order(1 "Female" 2 "Male") size(medsmall) col(2)) ///
	note("Total clients = `: di %6.0fc `r(N)''", size(medsmall))

graph export "$output/Client Baseline - `date'/51 - gender.png", as(png) replace

*** q_12k (birthyear)
set scheme plotplain

qui sum birthyear

histogram birthyear, percent color(brown) ///
	discrete ///
	ylabel(0(5)15) ///
    xtitle("Year", size(medsmall)) ///
    ytitle("Percentage of clients", size(medsmall)) ///
    title("Year of birth", size(medsmall)) ///
	subtitle(" ", size(medsmall)) ///
	note("Total clients = `: di %6.0fc `r(N)''", size(medsmall))

graph export "$output/Client Baseline - `date'/52 - birthyear_hist.png", as(png) replace

*** q_13a (compensation type)
forval x = 1/10 {
	gen gr_13a_`x' = 1 if q_13a == `x'
	recode gr_13a_`x' (. = 0)
	replace gr_13a_`x' = . if q_13a == .
}

set scheme jpalfull

qui sum clients_n if q_13a!=. 

graph bar gr_13a_*, percentages /// percent is the default
	ytitle("In percentage (%)", size(medsmall) orientation(vertical)) ///
	ylabel(0(25)100) ///
	blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
	title("Compensation type", size(medsmall)) ///
	subtitle(" ", size(medsmall)) ///
	legend(order(1 "Pulsa Telkomsel" 2 "Pulsa 3 (Tri)" 3 "Pulsa XL" 4 "Pulsa Axis" 5 "Pulsa Indosat" 6 "E-Money OVO" 7 "E-Money GoPay" 8 "E-Money LinkAja" 9 "E-Money DANA" 10 "E-Money ShopeePay") size(small) col(2)) ///
	note("Total clients = `: di %6.0fc `r(N)''", size(medsmall))

graph export "$output/Client Baseline - `date'/53 - compensation_type.png", as(png) replace

*** q_13c_1 (are you sure your number is corect)
local x = 1
forval nmr = 1/2 {
	gen gr_13c_1_`nmr' = 1 if q_13c_1 == `x'
	recode gr_13c_1_`nmr' (. = 0)
	replace gr_13c_1_`nmr' = . if q_13c_1 == .
	local x = `x' - 1
}

set scheme jpalfull

qui sum clients_n if q_13c_1!=. 

graph bar gr_13c_*, percentages /// percent is the default
	ytitle("In percentage (%)", size(medsmall) orientation(vertical)) ///
	ylabel(0(25)100) ///
	blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
	title("Are you sure your number is correct?", size(medsmall)) ///
	subtitle(" ", size(medsmall)) ///
	legend(order(1 "Yes" 2 "No") size(medsmall) col(2)) ///
	note("Total clients = `: di %6.0fc `r(N)''", size(medsmall))

graph export "$output/Client Baseline - `date'/54 - correct_number.png", as(png) replace

