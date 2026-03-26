*===================================================*
* Full-Scale - Client Survey (Baseline)
* HFC
* Author: Riko
* Last modified: 2 Sep 2025
* Last modified by: Naufal
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
    //gl path "/Users/auliamuthia/Desktop/J-PAL IFII Agent Banking Network (BM)/06 Data/c Full-Scale/06 Survey Data"
	
*Naufal
	gl path "/Users/athonaufalridwan/Library/CloudStorage/Dropbox/J-PAL IFII Agent Banking Network (BM)/06 Data/c Full-Scale/06 Survey Data"

* Set the path
gl do            "$path/dofiles/client_baseline"
gl dta           "$path/dtafiles/01 client_baseline"
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
use "$dta/cleaned_baseline_client_survey_17032026.dta", clear 

set more off
set scheme plotplain


***************
*DATA ANALYSIS*
***************
gen clients_n = _n // for notes on total N clients


**# Survey duration (in minutes)
preserve 

	//drop if consent_compensation == 0 | consent_lottery == 0 // drop people who refuse to participate in the survey
	keep if progress == "100"
	
	qui su total_duration, det
	local total_before = r(N)

	keep if total_duration < 100 // --Jibril: i keep any durations, just in case respondents take a break while filling out the survey

	qui su total_duration, detail
	return list

	local total_after = r(N)
	local dropped_obs = `total_before' - `total_after'

	* Boxplot
	set scheme plotplain
	
	qui su total_duration, detail
	return list

	local mean_rounded = round(`r(mean)', 1)	
	local Q_1_rounded = round(`r(p25)', 1)
	local Q_3_rounded = round(`r(p75)', 1)
	local median_rounded = round(`r(p50)', 1)

	graph box total_duration, box(1, fcolor(maroon*0.75) lcolor(maroon*0.75)) yline(`r(mean)', lpattern(.) lcolor(maroon*0.75)) ///
		ytitle("Survey duration (in minutes)", size(medsmall)) ///
		title("Survey Duration (in minutes)", size(medsmall)) ///
		subtitle("Restricted to respondents who participate in the survey", size(medsmall)) ///
		text(`r(p50)' 95 "Median=`median_rounded'", size(vsmall)) ///
		text(`r(p75)' 95 "Q3=`Q_3_rounded'", size(vsmall)) ///
		text(`r(p25)' 95 "Q1=`Q_1_rounded'", size(vsmall)) ///
		text(`r(mean)' 95 "Mean=`mean_rounded'", size(vsmall)) ///
		note("Note:" "Total clients = `: di %6.0fc `r(N)''" "Survey duration above 100 minutes is dropped" "Number of dropped observations = `dropped_obs'", size(small)) /// 
	
graph export "$output/Client Baseline - `date'/1 - client_survey_duration.png", as(png) replace

	* Histogram
	** Round the total_duration
	gen td_hist = round(total_duration, 1)

	set scheme plotplain
	qui sum td_hist
	histogram td_hist, percent color(maroon) ///
		discrete ///
		ylabel(0(1)8) ///
		xlabel(0(20)100) ///
		xtitle(" ", size(medsmall)) ///
		ytitle("Percentage of clients (%)", size(medsmall)) ///
		title("Total Survey Duration (in minutes)", size(medsmall)) ///
		subtitle("Restricted to respondents who participate in the survey", size(medsmall)) ///
		note("Note:" "Total clients = `: di %6.0fc `r(N)''" "Survey duration above 100 minutes is dropped" "Number of dropped observations = `dropped_obs'", size(medsmall)) /// 
	
	graph export "$output/Client Baseline - `date'/1 - client_survey_duration_hist.png", as(png) replace


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
		
/**# Consent form (compensation and lottery)
	/*preserve

recode consent_compensation consent_lottery (0 = 2)

la def yesno 1 "Yes" 2 "No"
la val consent_compensation consent_lottery yesno

keep unique_code_client consent_compensation consent_lottery

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
*/
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
/*forval x = 1/2 {
	gen gr_comp_`x' = 1 if compensation_status == `x'
	recode gr_comp_`x' (. = 0)
	replace gr_comp_`x' = . if compensation_status == .
}

set scheme jpalfull

qui sum clients_n if compensation_status!=. 

graph bar gr_comp_*, percentages /// percent is the default
	ytitle("Percentage (%) of clients", size(medsmall) orientation(vertical)) ///
	ylabel(0(25)100) ///
	blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
	title("Compensation Status", size(medsmall)) ///
	subtitle(" ", size(medsmall)) ///
	legend(order(1 "Compensation" 2 "Lottery") size(medsmall) col(2)) ///
	note("Total clients = `: di %6.0fc `r(N)''", size(medsmall))
	
graph export "$output/Client Baseline - `date'/3 - compensation_status.png", as(png) replace
*/
*/


**# 1. SECTION 1
*** q_1a
	forval x = 1/6 {
		gen gr_1a_`x' = 1 if q_1a == `x'
		recode gr_1a_`x' (. = 0)
		replace gr_1a_`x' = . if q_1a == .
	}

	set scheme jpalfull

	qui sum clients_n 
	*if q_1a!=. 

	graph bar gr_1a_*, percentages /// percent is the default
		ytitle("Percentage (%) of clients", size(midsmall) orientation(vertical)) ///
		ylabel(0(5)35) ///
		blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
		title("When was the last time you did a{bf: cash deposit} with{bf: BM Agent}?", size(midsmall)) ///
		subtitle(" ", size(medsmall)) ///
		legend(order(1 "Within the past 7 days" 2 "8-15 days ago" 3 "16-30 days ago" 4 "More than one month ago" 5 "More than six month ago" 6 "I haven't done this transaction with BM Agent before") size(vsmall) col(2)) ///
		note("Total clients = `: di %6.0fc `r(N)''", size(vsmall))	
	
	graph export "$output/Client Baseline - `date'/4 - client_q_1a.png", as(png) replace

*** q_1a_1

	gen q_1a_1_dummy = q_1a_1 / 1000

	** Drop missing variable (if any)
	drop if missing(q_1a_1_dummy)
	drop if q_1a_1_dummy > 5000
	
	

	** Summary statistics
	qui summarize q_1a_1_dummy, detail
	return list

	** Store obs number before dropping outlier(s)
	local total_before = r(N)

	** Detect and drop outlier(s)
	generate iqr = r(p75) - r(p25)
	generate lower_limit = r(p25) - 1.5 * iqr
	generate upper_limit = r(p75) + 1.5 * iqr
	generate outlier = (q_1a_1_dummy < lower_limit) | (q_1a_1_dummy > upper_limit)
	drop if outlier == 1

	** Store obs number after dropping outlier(s) and compute the difference
	qui summarize q_1a_1_dummy, detail
	local total_after = r(N)
	local dropped_obs = `total_before' - `total_after'
	

	** Store lower and upper threshold
	qui su lower_limit, det
	local ll = round(`r(mean)', 1000)
	qui su upper_limit, det
	local ul = round(`r(mean)', 1000)

	* Histogram
	set scheme plotplain

	histogram q_1a_1_dummy, percent color(chocolate) ///
		ylabel(0(2)18) ///
		xlabel(, format(%15.0fc)) ///
		xtitle("Amount of deposit (thousands)", size(medsmall)) ///
		ytitle("Percentage (%) of clients", size(medsmall)) ///
		title("In your last transaction with{bf: BM Agent}, how much did you{bf: deposit}?", size(medsmall)) ///
		subtitle(" ", size(medsmall)) ///
		note("Note:" "Total clients = `: di %6.0fc `r(N)''" "Outlier threshold = `=string(`ll', "%15.0gc")' (lower) and `=string(`ul', "%15.0gc")' (upper)" "Dropped outlier observation = `dropped_obs'", size(small)) 
	
	graph export "$output/Client Baseline - `date'/5 - client_q_1a_1_hist.png", as(png) replace
	
	* Box plot
	set scheme plotplain
	
	qui su q_1a_1_dummy, det
	return list

	local mean_rounded = round(`r(mean)', 1000)	
	local Q_1_rounded = round(`r(p25)', 1000)
	local Q_3_rounded = round(`r(p75)', 1000)
	local median_rounded = round(`r(p50)', 1000)
	
	graph box q_1a_1_dummy, box(1, fcolor(chocolate*0.75) lcolor(chocolate*0.75)) yline(`r(mean)', lpattern(.) lcolor(chocolate*0.75)) ///
		ytitle("Amount of deposit", size(medsmall)) ///
		ylabel(, format(%15.0fc)) ///
		title("In your last transaction with{bf: BM Agent}, how much did you{bf: deposit} (thousand)?", size(medsmall)) ///
		subtitle(" ", size(medsmall)) ///
		text(`r(p50)' 95 "Median=`=string(`median_rounded', "%15.0gc")'", size(vsmall)) ///
		text(`r(p75)' 95 "Q3=`=string(`Q_3_rounded', "%15.0gc")'", size(vsmall)) ///
		text(`r(p25)' 95 "Q1=`=string(`Q_1_rounded', "%15.0gc")'", size(vsmall)) ///
		text(`r(mean)' 95 "Mean=`=string(`mean_rounded', "%15.0gc")'", size(vsmall)) ///
		note("Note:" "Total clients = `: di %6.0fc `r(N)''" "Outlier threshold = `=string(`ll', "%15.0gc")' (lower) and `=string(`ul', "%15.0gc")' (upper)" "Dropped outlier observation = `dropped_obs'" "The sumstat value is rounded to the nearest value of 1,000", size(small)) 

	graph export "$output/Client Baseline - `date'/5 - client_q_1a_1_boxplot.png", as(png) replace

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
	* Pastikan folder tersedia
	capture mkdir "$output/Client Baseline - `date'"

	set scheme plotplain
	histogram q_1a_2, percent color(navy*0.95) ///
    xlabel(0(1000)9500, format(%15.0fc) labsize(vsmall)) ///
    ylabel(0(5)35, gmax) ///
    xtitle("Transaction fee", size(medsmall)) ///
    ytitle("Percentage of clients", size(medsmall)) ///
    title("What was the {bf:transaction fee} charged by {bf:BM Agent}", size(medsmall)) ///
    subtitle("you use the last time you made {bf:a cash deposit}?", size(medsmall)) ///
    note("Note:" "Total clients = `: di %6.0fc `total_after''" ///
         "Outlier threshold = `ll' (lower) and `ul' (upper)" ///
         "Dropped outlier observation = `dropped_obs'", size(small))

	graph export "$output/Client Baseline - `date'/6 - client_q_1a_2_hist.png", replace

	* Box plot
	set scheme plotplain
	qui su q_1a_2, det
	return list
	local mean_rounded = round(`r(mean)', 100)	
	local Q_1_rounded = round(`r(p25)', 100)
	local Q_3_rounded = round(`r(p75)', 100)
	local median_rounded = round(`r(p50)', 100)

	graph box q_1a_2, box(1, fcolor(navy*0.75) lcolor(navy*0.75)) yline(`r(mean)', lpattern(.) lcolor(navy*0.75)) ///
		ytitle("Transaction fee", size(medsmall)) ///
		ylabel(, format(%15.0fc)) ///
		title("What was the{bf: transaction fee} charged by{bf: BM Agent}", size(medsmall)) ///
		subtitle("you use the last time you made{bf: a cash deposit}?", size(medsmall)) ///
		text(`r(p50)' 95 "Median=`=string(`median_rounded', "%15.0gc")'", size(small)) ///
		text(`r(p75)' 95 "Q3=`=string(`Q_3_rounded', "%15.0gc")'", size(small)) ///
		text(`r(p25)' 95 "Q1=`=string(`Q_1_rounded', "%15.0gc")'", size(small)) ///
		text(`r(mean)' 95 "Mean=`=string(`mean_rounded', "%15.0gc")'", size(small)) ///
		note("Note:" "Total clients = `: di %6.0fc `r(N)''" "Outlier threshold = `=string(`ll', "%15.0gc")' (lower) and `=string(`ul', "%15.0gc")' (upper)" "Dropped outlier observation = `dropped_obs'" "The sumstat value is rounded to the nearest value of 100", size(small))
	graph export "$output/Client Baseline - `date'/6 - client_q_1a_2_boxplot.png", as(png) replace

restore
*** q_1a_3
preserve

	drop if q_1a_3 == . 
	forval x = 1/8 {
		gen gr_1a_3_`x' = 1 if q_1a_3 == `x'
		recode gr_1a_3_`x' (. = 0)
		replace gr_1a_3_`x' = . if q_1a_3 == .
	}

	set scheme jpalfull 
	qui sum clients_n 
	
	graph bar gr_1a_3_*, percentages /// percent is the default
		ytitle("Percentage (%) of clients", size(medsmall) orientation(vertical)) ///
		ylabel(0(5)25) ///
		blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
		title("What was {bf:the approximate transaction fee} charged by {bf:BM Agent}", size(medsmall)) ///
		subtitle("you use the last time you made {bf:a cash deposit}?", size(medsmall)) ///
		legend(order(1 "Rp0 - 500" 2 "Rp500 - 1.500" 3 "Rp1.500 - 2.500" 4 "Rp2.500 - 3.500" 5 "Rp3.500 - 4.500" 6 "Rp4.500 - 5.500" 7 "Rp5.500 - 6.500" 8 "More than Rp6.500") size(small) col(3)) ///
		note("Total clients = `: di %6.0fc `r(N)''", size(medsmall)) 
	
	graph export "$output/Client Baseline - `date'/7 - client_q_1a_3.png", as(png) replace

restore
*** q_1a_4
preserve

	drop if q_1a_4 == .

	qui summarize q_1a_4, detail
	return list

	local total_before = r(N)

	generate iqr = r(p75) - r(p25)
	generate lower_limit = r(p25) - 1.5 * iqr
	generate upper_limit = r(p75) + 1.5 * iqr
	generate outlier = (q_1a_4 < lower_limit) | (q_1a_4 > upper_limit)
	drop if outlier == 1

	qui summarize q_1a_4, detail
	local total_after = r(N)
	local dropped_obs = `total_before' - `total_after'

	qui su lower_limit, det
	local ll = round(`r(mean)', 1)
	qui su upper_limit, det
	local ul = round(`r(mean)', 1)

	set scheme plotplain

	histogram q_1a_4, discrete percent color(maroon) ///
		xlabel(0(1)22) ///
		ylabel(0(5)30) ///
		xtitle("Number of deposit", size(medsmall)) ///
		ytitle("Percentage (%) of clients", size(medsmall)) ///
		title("Over {bf:the last 3 months}, how many deposits have you made", size(medsmall)) ///
		subtitle("with {bf:BM Agent}?", size(medsmall)) ///
		note("Note:" "Total clients = `: di %6.0fc `r(N)''" "Outlier threshold = `ll' (lower) and `ul' (upper)" "Dropped outlier observation = `dropped_obs'", size(medsmall))
		
	graph export "$output/Client Baseline - `date'/8 - client_q_1a_4_hist.png", as(png) replace

	set scheme plotplain
	qui su q_1a_4, det
	return list
	local mean_rounded = round(`r(mean)', 1)	
	local Q_1_rounded = round(`r(p25)', 1)
	local Q_3_rounded = round(`r(p75)', 1)
	local median_rounded = round(`r(p50)', 1)

	graph box q_1a_4, box(1, fcolor(maroon*0.75) lcolor(maroon*0.75)) yline(`r(mean)', lpattern(.) lcolor(maroon*0.75)) ///
		ytitle("Number of deposit", size(medsmall)) ///
		title("Over {bf:the last 3 months}, how many deposits have you made", size(medsmall)) ///
		subtitle("with {bf:BM Agent}?", size(medsmall)) ///
		text(`r(p50)' 95 "Median=`median_rounded'", size(vsmall)) ///
		text(`r(p75)' 95 "Q3=`Q_3_rounded'", size(vsmall)) ///
		text(`r(p25)' 95 "Q1=`Q_1_rounded'", size(vsmall)) ///
		text(`r(mean)' 95 "Mean=`mean_rounded'", size(vsmall)) ///
		note("Note:" "Total clients = `: di %6.0fc `r(N)''" "Outlier threshold = `ll' (lower) and `ul' (upper)" "Dropped outlier observation = `dropped_obs'", size(medsmall))
	
	graph export "$output/Client Baseline - `date'/8 - client_q_1a_4_boxplot.png", as(png) replace

restore
*** q_1b
preserve

	drop if q_1b ==. 
	forval x = 1/6 {
		gen gr_1b_`x' = 1 if q_1b == `x'
		recode gr_1b_`x' (. = 0)
		replace gr_1b_`x' = . if q_1b == .
	}

	set scheme jpalfull
	qui sum clients_n 
	
	graph bar gr_1b_*, percentages /// percent is the default
		ytitle("Percentage (%) of clients", size(medsmall) orientation(vertical)) ///
		ylabel(0(10)50) ///
		blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
		title("When was the last time you did a{bf: cash deposit} with{bf: a non-BM Agent}?", size(medsmall)) ///
		subtitle(" ", size(medsmall)) ///
		legend(order(1 "Within the past 7 days" 2 "8-15 days ago" 3 "16-30 days ago" 4 "More than one month ago" 5 "More than six month ago" 6 "I haven't done this transaction with BM Agent before") size(vsmall) col(2)) ///
	note("Total clients = `: di %6.0fc `r(N)''", size(medsmall))
	
	graph export "$output/Client Baseline - `date'/9 - client_q_1b.png", as(png) replace

restore
*** q_1b_1
preserve

	drop if q_1b_1 == .
	
	qui summarize q_1b_1, detail
	return list	
	
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

	histogram q_1b_1, percent color(emerald*0.95) ///
		ylabel(0(5)30) ///
		xlabel(, format(%12.0fc)) ///
		xtitle("Amount of deposit", size(medsmall)) ///
		ytitle("Percentage (%) of clients", size(medsmall)) ///
		title("In your last transaction with{bf: a non-BM Agent}, how much did you{bf: deposit} (thousand)?", size(medsmall)) ///
		subtitle(" ", size(medsmall)) ///
		note("Note:" "Total clients = `: di %6.0fc `r(N)''" "Dropped outlier observation = `dropped_obs'" "Outlier threshold = `=string(`ll', "%15.0gc")' (lower) and `=string(`ul', "%15.0gc")' (upper)" "Dropped outlier observation = `dropped_obs'" "The sumstat value is rounded to the nearest value of 1,000", size(small))
	
	graph export "$output/Client Baseline - `date'/10 - client_q_1b_1_hist.png", as(png) replace

	* Box plot
	set scheme plotplain
	qui su q_1b_1, det
	return list
	local mean_rounded = round(`r(mean)', 100)	
	local Q_1_rounded = round(`r(p25)', 100)
	local Q_3_rounded = round(`r(p75)', 1000)
	local median_rounded = round(`r(p50)', 100)

	graph box q_1b_1, box(1, fcolor(emerald*0.75) lcolor(emerald*0.75)) yline(`r(mean)', lpattern(.) lcolor(emerald*0.75)) ///
		ytitle("Amount of deposit", size(medsmall)) ///
		ylabel(, format(%15.0fc)) ///
		title("In your last transaction with{bf: a non-BM Agent}, how much did you{bf: deposit} (thousand)?", size(medsmall)) ///
		subtitle(" ", size(medsmall)) ///
		text(`r(p50)' 95 "Median=`=string(`median_rounded', "%15.0gc")'", size(vsmall)) ///
		text(`r(p75)' 95 "Q3=`=string(`Q_3_rounded', "%15.0gc")'", size(vsmall)) ///
		text(`r(p25)' 95 "Q1=`=string(`Q_1_rounded', "%15.0gc")'", size(vsmall)) ///
		text(`r(mean)' 95 "Mean=`=string(`mean_rounded', "%15.0gc")'", size(vsmall)) ///
		note("Note:" "Total clients = `: di %6.0fc `r(N)''" "Outlier threshold = `=string(`ll', "%15.0gc")' (lower) and `=string(`ul', "%15.0gc")' (upper)" "Dropped outlier observation = `dropped_obs'" "The sumstat value is rounded to the nearest value of 100", size(small))
		
	graph export "$output/Client Baseline - `date'/10 - client_q_1b_1_boxplot.png", as(png) replace
	
	
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

	histogram q_1b_2, discrete percent color(navy) ///
		xlabel(0(1)12) ///
		ylabel(0(5)25) ///
		xtitle("Number of deposit", size(medsmall)) ///
		ytitle("Percentage (%) of clients", size(medsmall)) ///
		title("Over {bf:the last 3 months}, how many deposits have you made", size(medsmall)) ///
		subtitle("with {bf:a non-BM Agent}?", size(medsmall)) ///
		note("Note:" "Total clients = `: di %6.0fc `r(N)''" "Outlier threshold = `ll' (lower) and `ul' (upper)" ///
		"Dropped outlier observation = `dropped_obs'", size(medsmall))
	
	graph export "$output/Client Baseline - `date'/11 - client_q_1b_2_hist.png", as(png) replace

	* Box plot
	set scheme plotplain
	qui su q_1b_2, det
	return list
	local mean_rounded = round(`r(mean)', 1)	
	local Q_1_rounded = round(`r(p25)', 1)
	local Q_3_rounded = round(`r(p75)', 1)
	local median_rounded = round(`r(p50)', 1)

	graph box q_1b_2, box(1, fcolor(navy*0.75) lcolor(navy*0.75)) yline(`r(mean)', lpattern(.) lcolor(navy*0.75)) ///
		ytitle("Number of deposit", size(medsmall)) ///
		title("Over {bf:the last 3 months}, how many deposits have you made", size(medsmall)) ///
		subtitle("with {bf:a non-BM Agent}?", size(medsmall)) ///
		text(`r(p50)' 95 "Median=`median_rounded'", size(vsmall)) ///
		text(`r(p75)' 95 "Q3=`Q_3_rounded'", size(vsmall)) ///
		text(`r(p25)' 95 "Q1=`Q_1_rounded'", size(vsmall)) ///
		text(`r(mean)' 95 "Mean=`mean_rounded'", size(vsmall)) ///
		note("Note:" "Total clients = `: di %6.0fc `r(N)''" "Outlier threshold = `ll' (lower) and `ul' (upper)" /// 
		"Dropped outlier observation = `dropped_obs'", size(medsmall))
	
	graph export "$output/Client Baseline - `date'/11 - client_q_1b_2_boxplot.png", as(png) replace

restore
**# 2. Section 2
preserve


*** q_2a
	drop if q_2a == . 
	forval x = 1/6 {
		gen gr_2a_`x' = 1 if q_2a == `x'
		recode gr_2a_`x' (. = 0)
		replace gr_2a_`x' = . if q_2a == .
	}

	set scheme jpalfull
	qui sum clients_n 
	
	graph bar gr_2a_*, percentages /// percent is the default
		ytitle("Percentage (%) of clients", size(small) orientation(vertical)) ///
		ylabel(0(5)35) ///
		blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
		title("When was the last time you did a{bf: cash withdrawal} with{bf: BM Agent}?", size(medsmall)) ///
		subtitle(" ", size(medsmall)) ///
		legend(order(1 "Within the past 7 days" 2 "8-15 days ago" 3 "16-30 days ago" 4 "More than one month ago" ///
		5 "More than six month ago" 6 "I haven't done this transaction with BM Agent before") size(vsmall) col(2)) ///
		note("Total clients = `: di %6.0fc `r(N)''", size(medsmall)) 
		
	graph export "$output/Client Baseline - `date'/12 - client_q_2a.png", as(png) replace

restore
*** q_2a_1
preserve
	
	gen q_2a_1_dummy = q_2a_1 / 1000

	drop if q_2a_1_dummy == .
	qui summarize q_2a_1_dummy, detail
	return list
	local total_before = r(N)

	** Detect and drop outlier(s)
	generate iqr = r(p75) - r(p25)
	generate lower_limit = r(p25) - 1.5 * iqr
	generate upper_limit = r(p75) + 1.5 * iqr
	generate outlier = (q_2a_1_dummy < lower_limit) | (q_2a_1_dummy > upper_limit)
	drop if outlier == 1
	
	** Store obs number after dropping outlier(s) and compute the difference
	qui summarize q_2a_1_dummy, detail
	local total_after = r(N)
	local dropped_obs = `total_before' - `total_after'

	** Store lower and upper threshold
	qui su lower_limit, det
	local ll = round(`r(mean)', 1000)
	qui su upper_limit, det
	local ul = round(`r(mean)', 1000)

	* Histogram
	set scheme plotplain

	histogram q_2a_1_dummy, percent color(chocolate) ///
		ylabel(0(5)20) ///
		xlabel(, format(%9.0fc)) ///
		xtitle("Amount of withdrawal", size(medsmall)) ///
		ytitle("Percentage (%) of clients", size(medsmall)) ///
		title("In your last transaction with{bf: BM Agent}, how much did you{bf: withdraw} (thousand)?", size(medsmall)) ///
		subtitle(" ", size(medsmall)) ///
		note("Note:" "Total clients = `: di %6.0fc `r(N)''" "Dropped outlier observation = `dropped_obs'" ///
		"Outlier threshold = `=string(`ll', "%15.0gc")' (lower) and `=string(`ul', "%15.0gc")' (upper)", size(medsmall))
	
	graph export "$output/Client Baseline - `date'/13 - client_q_2a_1_hist.png", as(png) replace

	* Box plot
	set scheme plotplain
	su q_2a_1_dummy, det
	return list
	local mean_rounded = round(`r(mean)', 1000)	
	local Q_1_rounded = round(`r(p25)', 1000)
	local Q_3_rounded = round(`r(p75)', 1000)
	local median_rounded = round(`r(p50)', 1000)


	graph box q_2a_1_dummy, box(1, fcolor(chocolate*0.75) lcolor(chocolate*0.75)) yline(`r(mean)', lpattern(.) lcolor(chocolate*0.75)) ///
		ytitle("Amount of withdrawal (in thousand)", size(medsmall)) ///
		ylabel(, format(%15.0fc)) ///
		title("In your last transaction with{bf: BM Agent}, how much did you{bf: withdraw} (thousand)?", size(medsmall)) ///
		subtitle(" ", size(medsmall)) ///
		text(`r(p50)' 95 "Median=`=string(`median_rounded', "%15.0gc")'", size(vsmall)) ///
		text(`r(p75)' 95 "Q3=`=string(`Q_3_rounded', "%15.0gc")'", size(vsmall)) ///
		text(`r(p25)' 95 "Q1=`=string(`Q_1_rounded', "%15.0gc")'", size(vsmall)) ///
		text(`r(mean)' 95 "Mean=`=string(`mean_rounded', "%15.0gc")'", size(vsmall)) ///
		note("Note:" "Total clients = `: di %6.0fc `r(N)''" "Outlier threshold = `=string(`ll', "%15.0gc")' (lower) and `=string(`ul', "%15.0gc")' (upper)" "Dropped outlier observation = `dropped_obs'" "The sumstat value is rounded to the nearest value of 1,000", size(medsmall))
		
	graph export "$output/Client Baseline - `date'/13 - client_q_2a_1_boxplot.png", as(png) replace

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
	
	histogram q_2a_2, percent color(maroon) ///
		xlabel(0(1000)9000) ///
		ylabel(0(5)40) ///
		xlabel(, format(%15.0fc)) ///
		xtitle("Transaction fee", size(medsmall)) ///
		ytitle("Percentage (%) of clients", size(medsmall)) ///
		title("What was the{bf: transaction fee} charged by{bf: BM Agent}", size(medsmall)) ///
		subtitle("you use the last time you made{bf: a cash withdrawal}?", size(medsmall)) ///
		note("Note:" "Total clients = `: di %6.0fc `r(N)''" "Outlier threshold = `=string(`ll', "%15.0gc")' (lower) and `=string(`ul', "%15.0gc")' (upper)" "Dropped outlier observation = `dropped_obs'", size(small))
	
	graph export "$output/Client Baseline - `date'/14 - client_q_2a_2_hist.png", as(png) replace


	* Box plot
	set scheme plotplain

	qui su q_2a_2, det
	return list
	
	local mean_rounded = round(`r(mean)', 100)	
	local Q_1_rounded = round(`r(p25)', 100)
	local Q_3_rounded = round(`r(p75)', 100)
	local median_rounded = round(`r(p50)', 100)

	graph box q_2a_2, box(1, fcolor(maroon*0.75) lcolor(maroon*0.75)) yline(`r(mean)', lpattern(.) lcolor(maroon*0.75)) ///
		ytitle("Transaction fee", size(medsmall)) ///
		ylabel(, format(%15.0fc)) ///
		title("What was the{bf: transaction fee} charged by{bf: BM Agent}", size(medsmall)) ///
		subtitle("you use the last time you made{bf: a cash withdrawal}?", size(medsmall)) ///
		text(`r(p50)' 95 "Median=`=string(`median_rounded', "%15.0gc")'", size(small)) ///
		text(`r(p75)' 95 "Q3=`=string(`Q_3_rounded', "%15.0gc")'", size(small)) ///
		text(`r(p25)' 95 "Q1=`=string(`Q_1_rounded', "%15.0gc")'", size(small)) ///
		text(`r(mean)' 95 "Mean=`=string(`mean_rounded', "%15.0gc")'", size(small)) ///
		note("Note:" "Total clients = `: di %6.0fc `r(N)''" "Outlier threshold = `=string(`ll', "%15.0gc")' (lower) and `=string(`ul', "%15.0gc")' (upper)" "Dropped outlier observation = `dropped_obs'" "The sumstat value is rounded to the nearest value of 100", size(small))
	
	graph export "$output/Client Baseline - `date'/14 - client_q_2a_2_boxplot.png", as(png) replace

	
restore
*** q_2a_3
preserve
	drop if q_2a_3 == . 
	forval x = 1/8 {
		gen gr_2a_3_`x' = 1 if q_2a_3 == `x'
		recode gr_2a_3_`x' (. = 0)
		replace gr_2a_3_`x' = . if q_2a_3 == .
	}

	set scheme jpalfull
	qui sum clients_n 

	graph bar gr_2a_3_*, percentages /// percent is the default
		ytitle("Percentage (%) of clients", size(medsmall) orientation(vertical)) ///
		ylabel(0(5)30) ///
		blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
		title("What was {bf:the approximate transaction fee} charged by {bf:BM Agent}", size(medsmall)) ///
		subtitle("you use the last time you made {bf:a cash withdrawal}?", size(medsmall)) ///
		legend(order(1 "Rp0 - 500" 2 "Rp500 - 1.500" 3 "Rp1.500 - 2.500" 4 "Rp2.500 - 3.500" 5 "Rp3.500 - 4.500" ///
		6 "Rp4.500 - 5.500" 7 "Rp5.500 - 6.500" 8 "More than Rp6.500") size(small) col(3)) ///
		note("Total clients = `: di %6.0fc `r(N)''", size(small)) 
		
	graph export "$output/Client Baseline - `date'/15 - client_q_2a_3.png", as(png) replace

restore
*** q_2a_4
preserve

	drop if q_2a_4 == .
	qui summarize q_2a_4, detail
	return list
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

	histogram q_2a_4, discrete percent color(chocolate*0.95) ///
		xlabel(0(1)17) ///
		ylabel(0(2)20) ///
		xtitle("Number of withdrawal", size(medsmall)) ///
		ytitle("Percentage (%) of clients", size(medsmall)) ///
		title("Over {bf:the last 3 months}, how many withdrawals have you made", size(medsmall)) ///
		subtitle("with {bf:BM Agent}?", size(medsmall)) ///
		note("Note:" "Total clients = `: di %6.0fc `r(N)''" "Outlier threshold = `ll' (lower) and `ul' (upper)" "Dropped outlier observation = `dropped_obs'", size(small))
	
	graph export "$output/Client Baseline - `date'/16 - client_q_2a_4_hist.png", as(png) replace

	* Box plot
	set scheme plotplain
	qui su q_2a_4, det
	return list
	local mean_rounded = round(`r(mean)', 1)	
	local Q_1_rounded = round(`r(p25)', 1)
	local Q_3_rounded = round(`r(p75)', 1)
	local median_rounded = round(`r(p50)', 1)

	graph box q_2a_4, box(1, fcolor(chocolate*0.75) lcolor(chocolate*0.75)) yline(`r(mean)', lpattern(.) lcolor(chocolate*0.75)) ///
		ytitle("Number of withdrawal", size(medsmall)) ///
		title("Over {bf:the last 3 months}, how many withdrawals have you made", size(medsmall)) ///
		subtitle("with {bf:BM Agent}?", size(medsmall)) ///
		text(`r(p50)' 95 "Median=`median_rounded'", size(vsmall)) ///
		text(`r(p75)' 95 "Q3=`Q_3_rounded'", size(vsmall)) ///
		text(`r(p25)' 95 "Q1=`Q_1_rounded'", size(vsmall)) ///
		text(`r(mean)' 95 "Mean=`mean_rounded'", size(vsmall)) ///
		note("Note:" "Total clients = `: di %6.0fc `r(N)''" "Outlier threshold = `ll' (lower) and `ul' (upper)" "Dropped outlier observation = `dropped_obs'", size(small))
	
	graph export "$output/Client Baseline - `date'/16 - client_q_2a_4_boxplot.png", as(png) replace

restore
*** q_2b
preserve

	drop if q_2b == . 
	forval x = 1/6 {
		gen gr_2b_`x' = 1 if q_2b == `x'
		recode gr_2b_`x' (. = 0)
		replace gr_2b_`x' = . if q_2b == .
	}
	set scheme jpalfull
	qui sum clients_n 

	graph bar gr_2b_*, percentages /// percent is the default
		ytitle("Percentage (%) of clients", size(medsmall) orientation(vertical)) ///
		ylabel(0(10)50) ///
		blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
		title("When was the last time you did a{bf: cash withdrawal} with{bf: a non-BM Agent}?", size(medsmall)) ///
		subtitle(" ", size(medsmall)) ///
		legend(order(1 "Within the past 7 days" 2 "8-15 days ago" 3 "16-30 days ago" 4 "More than one month ago" ///
		5 "More than six month ago" 6 "I haven't done this transaction with BM Agent before") size(vsmall) col(2)) ///
		note("Total clients = `: di %6.0fc `r(N)''", size(small)) 
	
	graph export "$output/Client Baseline - `date'/17 - client_q_2b.png", as(png) replace

restore
*** q_2b_1
preserve

	drop if q_2b_1 == .
	qui summarize q_2b_1, detail
	return list
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
	local ll = round(`r(mean)', 100)
	qui su upper_limit, det
	local ul = round(`r(mean)', 100)
	
	* Histogram
	set scheme plotplain

	histogram q_2b_1, percent color(emerald*0.95) ///
		ylabel(0(5)25) ///
		xlabel(, format(%7.0fc)) ///
		xtitle("Amount of withdrawal (thousand)", size(medsmall)) ///
		ytitle("Percentage (%) of clients", size(medsmall)) ///
		title("In your last transaction with{bf: a non-BM Agent}, how much did you{bf: withdraw}?", size(medsmall)) ///
		subtitle(" ", size(medsmall)) ///
	note("Note:" "Total clients = `: di %6.0fc `r(N)''" "Outlier threshold = `=string(`ll', "%15.0gc")' (lower) and `=string(`ul', "%15.0gc")' (upper)" "Dropped outlier observation = `dropped_obs'" "The sumstat value is rounded to the nearest value of 1,000", size(small))
	
graph export "$output/Client Baseline - `date'/18 - client_q_2b_1_hist.png", as(png) replace

	* Box plot
	set scheme plotplain
	qui su q_2b_1, det
	return list
	local mean_rounded = round(`r(mean)', 1000)	
	local Q_1_rounded = round(`r(p25)', 1000)
	local Q_3_rounded = round(`r(p75)', 1000)
	local median_rounded = round(`r(p50)', 1000)

	graph box q_2b_1, box(1, fcolor(emerald*0.75) lcolor(emerald*0.75)) yline(`r(mean)', lpattern(.) lcolor(emerald*0.75)) ///
		ytitle("Amount of withdrawal (thousand)", size(medsmall)) ///
		ylabel(, format(%15.0fc)) ///
		title("In your last transaction with{bf: a non-BM Agent}, how much did you{bf: withdraw}?", size(medsmall)) ///
		subtitle(" ", size(medsmall)) ///
		text(`r(p50)' 95 "Median=`=string(`median_rounded', "%15.0gc")'", size(vsmall)) ///
		text(`r(p75)' 95 "Q3=`=string(`Q_3_rounded', "%15.0gc")'", size(vsmall)) ///
		text(`r(p25)' 95 "Q1=`=string(`Q_1_rounded', "%15.0gc")'", size(vsmall)) ///
		text(`r(mean)' 95 "Mean=`=string(`mean_rounded', "%15.0gc")'", size(vsmall)) ///
	note("Note:" "Total clients = `: di %6.0fc `r(N)''" "Outlier threshold = `=string(`ll', "%15.0gc")' (lower) and `=string(`ul', "%15.0gc")' (upper)" "Dropped outlier observation = `dropped_obs'" "The sumstat value is rounded to the nearest value of 1,000", size(small))
	graph export "$output/Client Baseline - `date'/18 - client_q_2b_1_boxplot.png", as(png) replace

restore
*** q_2b_2
preserve

	drop if q_2b_2 == .
	qui summarize q_2b_2, detail
	return list
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

	histogram q_2b_2, discrete percent color(maroon) ///
		xlabel(0(1)12) ///
		ylabel(0(5)22) ///
		xtitle("Number of withdrawal", size(medsmall)) ///
		ytitle("Percentage (%) of clients", size(medsmall)) ///
		title("Over {bf:the last 3 months}, how many withdrawals have you made", size(medsmall)) ///
		subtitle("with {bf:a non-BM Agent}?", size(medsmall)) ///
		note("Note:" "Total clients = `: di %6.0fc `r(N)''" "Outlier threshold = `ll' (lower) and `ul' (upper)" "Dropped outlier observation = `dropped_obs'", size(small))
		
	graph export "$output/Client Baseline - `date'/19 - client_q_2b_2_hist.png", as(png) replace

	* Box plot
	set scheme plotplain

	qui su q_2b_2, det
	return list

	local mean_rounded = round(`r(mean)', 1)	
	local Q_1_rounded = round(`r(p25)', 1)
	local Q_3_rounded = round(`r(p75)', 1)
	local median_rounded = round(`r(p50)', 1)

	graph box q_2b_2, box(1, fcolor(maroon*0.75) lcolor(maroon*0.75)) yline(`r(mean)', lpattern(.) lcolor(maroon*0.75)) ///
		ytitle("Number of withdrawal", size(medsmall)) ///
		title("Over {bf:the last 3 months}, how many withdrawals have you made", size(medsmall)) ///
		subtitle("with {bf:a non-BM Agent}?", size(medsmall)) ///
		text(`r(p50)' 95 "Median=`median_rounded'", size(vsmall)) ///
		text(`r(p75)' 95 "Q3=`Q_3_rounded'", size(vsmall)) ///
		text(`r(p25)' 95 "Q1=`Q_1_rounded'", size(vsmall)) ///
		text(`r(mean)' 95 "Mean=`mean_rounded'", size(vsmall)) ///
		note("Note:" "Total clients = `: di %6.0fc `r(N)''" "Outlier threshold = `ll' (lower) and `ul' (upper)" "Dropped outlier observation = `dropped_obs'", size(medsmall))
		
	graph export "$output/Client Baseline - `date'/19 - client_q_2b_2_boxplot.png", as(png) replace

restore
**# 3. Section 3
preserve

*** q_3a
	
	local date : display %tdDNCY daily("$S_DATE", "DMY")
	capture shell mkdir -p "$output/Client Baseline - `date'"
	
	drop if q_3a == . 
	forval x = 1/5 {
		gen gr_3a_`x' = 1 if q_3a == `x'
		recode gr_3a_`x' (. = 0)
		replace gr_3a_`x' = . if q_3a == .
}

	set scheme jpalfull
	qui sum clients_n 
	
	graph bar gr_3a_*, percentages /// percent is the default
		ytitle("Percentage (%) of clients", size(medsmall) orientation(vertical)) ///
		ylabel(0(5)40) ///
		blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
		title("Banking agents {bf:charge a fee} for each transaction made with them.", size(medsmall)) ///
		subtitle("How do you think these fees {bf:are set}?", size(medsmall)) ///
		legend(order(1 "There's an official price and the agent has to stick with it" ///
		2 "There's an official price, but agent can charge more/less" 3 "No official price and agent can decide the price" ///
		4 "The government sets the prices" 5 "I do not know") size(small) col(1)) ///
		note("Total clients = `: di %6.0fc `r(N)''", size(small)) 
	
	graph export "$output/Client Baseline - `date'/20 - client_q_3a.png", as(png) replace


restore
*** q_3a_1
preserve
	
	drop if q_3a_1 == . 
	local date : display %tdDNCY daily("$S_DATE", "DMY")
	capture shell mkdir -p "$output/Agent Baseline - `date'"
	forval x = 1/3 {
		gen gr_3a_1_`x' = 1 if q_3a_1 == `x'
		recode gr_3a_1_`x' (. = 0)
		replace gr_3a_1_`x' = . if q_3a_1 == .
	}
	set scheme jpalfull
	qui sum clients_n 

	graph bar gr_3a_1_*, percentages /// percent is the default
		ytitle("Percentage (%) of clients", size(medsmall) orientation(vertical)) ///
		ylabel(0(10)60) ///
		blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
		title("Does the agent typically {bf:charge more or less} than official price?", size(medsmall)) ///
		subtitle(" ", size(medsmall)) ///
		legend(order(1 "More" 2 "Less" 3 "Depends on the client (sometimes more/less)") size(medsmall) col(1)) ///
		note("Total clients = `: di %6.0fc `r(N)''", size(small)) 
		
	graph export "$output/Client Baseline - `date'/21 - client_q_3a_1.png", as(png) replace

restore
*** q_3b
preserve
	
	drop if q_3b == . 
	local date : display %tdDNCY daily("$S_DATE", "DMY")
	capture shell mkdir -p "$output/Agent Baseline - `date'"
	local x = 1
	forval nmr = 1/2 {
		gen gr_3b_`nmr' = 1 if q_3b == `x'
		recode gr_3b_`nmr' (. = 0)
		replace gr_3b_`nmr' = . if q_3b == .
		local x = `x' - 1
	}

	set scheme jpalfull
	qui sum clients_n 

	graph bar gr_3b_*, percentages /// percent is the default
		ytitle("Percentage (%) of clients", size(medsmall) orientation(vertical)) ///
		ylabel(0(25)75) ///
		blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
		title("Display of BM official price list in shop", size(medsmall)) ///
		subtitle("", size(medsmall)) ///
		legend(order(1 "Yes" 2 "No") size(medsmall) col(2)) ///
		note("Total clients = `: di %6.0fc `r(N)''", size(small)) 
	
graph export "$output/Client Baseline - `date'/22 - client_q_3b.png", as(png) replace

restore
*** q_3c
preserve

	drop if q_3c == . 
	local x = 1
	forval nmr = 1/2 {
		gen gr_3c_`nmr' = 1 if q_3c == `x'
		recode gr_3c_`nmr' (. = 0)
		replace gr_3c_`nmr' = . if q_3c == .
		local x = `x' - 1
	}

	set scheme jpalfull
	qui sum clients_n 

	graph bar gr_3c_*, percentages /// percent is the default
		ytitle("Percentage (%) of clients", size(medsmall) orientation(vertical)) ///
		ylabel(0(25)100) ///
		blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
		title("Does your {bf:BM Agent} set the {bf:same price} for everyone?", size(medsmall)) ///
		subtitle(" ", size(medsmall)) ///
		legend(order(1 "Yes" 2 "No") size(medsmall) col(2)) ///
		note("Total clients = `: di %6.0fc `r(N)''", size(medsmall)) 
	
	graph export "$output/Client Baseline - `date'/23 - client_q_3c.png", as(png) replace

restore
*** q_3c_1
preserve
	drop if q_3c_1 == . 
	local x = 1
	forval nmr = 1/2 {
		gen gr_3c_1_`nmr' = 1 if q_3c_1 == `x'
		recode gr_3c_1_`nmr' (. = 0)
		replace gr_3c_1_`nmr' = . if q_3c_1 == .
		local x = `x' - 1
	}
	set scheme jpalfull
	qui sum clients_n 
	
	graph bar gr_3c_1_*, percentages /// percent is the default
		ytitle("Percentage (%) of clients", size(medsmall) orientation(vertical)) ///
		ylabel(0(25)90) ///
		blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
		title("If not, do you think there is a specific type of customer", size(medsmall)) ///
		subtitle("that your {bf:BM Agent} charge {bf:less}?", size(medsmall)) ///
		legend(order(1 "Yes" 2 "No") size(medsmall) col(2)) ///
		note("Total clients = `: di %6.0fc `r(N)''", size(small)) 
	
	graph export "$output/Client Baseline - `date'/24 - client_q_3c_1.png", as(png) replace

restore
*** q_3c_1_1
preserve
	drop if q_3c_1_1_1 == .
	
	qui sum clients_n
	return list
	
	foreach y in 1 2 4 5 6 7 8 {
		gen q_3c_1_1_new_`y' = ///
        (q_3c_1_1_1 == `y' | q_3c_1_1_2 == `y' | q_3c_1_1_4 == `y' | ///
         q_3c_1_1_5 == `y' | q_3c_1_1_6 == `y' | q_3c_1_1_7 == `y' | ///
         q_3c_1_1_8 == `y')
}
	set scheme jpalfull
	qui sum clients_n 
	
	graph bar q_3c_1_1_new_1 q_3c_1_1_new_2 q_3c_1_1_new_4 q_3c_1_1_new_5 q_3c_1_1_new_6 q_3c_1_1_new_7 q_3c_1_1_new_8, percentages ///
		ytitle("Percentage (%) of clients", size(small) orientation(vertical)) ///
		ylabel(, labsize(small)) ///
		blabel(bar, pos(center) size(vsmall) format(%15.1fc)) ///
		title("Type of client charge with low fees", size(medsmall)) ///
		legend(order(1 "Friends & Family" 2 "High-value customers" 3 "New customers" ///
                 4 "Long-term customers" 5 "Lower-income customers" ///
                 6 "Local customers" 7 "Can switch agents") ///
           size(small) col(2)) ///
		note("Total clients = `: di %6.0fc `r(N)''", size(small)) 
	
	graph export "$output/Client Baseline - `date'/25 - q_3c_1_1.png", as(png) replace

restore
**# 4. Section 4
preserve

*** q_4


	local date : display %tdDNCY daily("$S_DATE", "DMY")
	capture shell mkdir -p "$output/Agent Baseline - `date'"

	destring q_4, replace
	drop if q_4 == .
	qui summarize q_4, detail
	return list
	local total_before = r(N)

	** Detect and drop outlier(s)
	generate iqr = r(p75) - r(p25)
	generate lower_limit = 0
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

	histogram q_4, percent color(chocolate*0.95) ///
		discrete ///
		xlabel(0(1)10) ///
		ylabel(0(5)40) ///
		xtitle("Satisfaction level", size(medsmall)) ///
		ytitle("Percentage (%) of clients", size(medsmall)) ///
		title("For the latest transaction you did with your {bf:BM Agent},", size(medsmall)) ///
		subtitle("on a scale of 1 to 10, {bf:how satisfied} were you with the service?", size(medsmall)) ///
		note("Note:" "Total clients = `: di %6.0fc `r(N)''" "Outlier threshold = `ll' (lower) and `ul' (upper)" "Dropped outlier observation = `dropped_obs'", size(medsmall))
	
	graph export "$output/Client Baseline - `date'/26 - client_q_4_hist.png", as(png) replace

restore
*** q_4_a
preserve

	drop if q_4_a == . 
	forval nmr = 1/2 {
		gen gr_4_a`nmr' = (q_4_a == `nmr') * 100 if !missing(q_4_a)
	}

	set scheme jpalfull
	qui sum clients_n 

	graph bar (mean) gr_4_a1 gr_4_a2, ///
		ytitle("Percentage (%) of clients", size(medsmall)) ///
		ylabel(0(10)100) /// 
		blabel(bar, pos(outside) size(medsmall) format(%15.1f)) ///
		title("Was the agent present when you first attempted the transaction?", size(medsmall)) ///
		legend(order(1 "Yes" 2 "No") size(medsmall) col(2)) ///
		note("Total clients = `: display %6.0fc `r(N)''", size(small)) 

	graph export "$output/Client Baseline - `date'/26 - client_q_4a.png", as(png) replace

restore
*** q_4b
preserve

	drop if q_4_b == . 
	forval nmr = 1/2 {
		gen gr_4_b`nmr' = (q_4_b == `nmr') * 100 if !missing(q_4_b)
	}

	set scheme jpalfull
	qui sum clients_n 
	

	graph bar (mean) gr_4_b1 gr_4_b2, ///
		ytitle("Percentage (%) of clients", size(medsmall)) ///
		ylabel(0(25)100) /// 
		blabel(bar, pos(outside) size(medsmall) format(%15.1f)) ///
		title("Was the agent able to complete the exact transaction you wanted to do?", size(medsmall)) ///
		legend(order(1 "Yes" 2 "No") size(medsmall) col(2)) ///
		note("Total clients = `: display %6.0fc `r(N)''", size(small)) 
		
	graph export "$output/Client Baseline - `date'/26 - client_q_4b.png", as(png) replace

restore
*** q_4c
preserve

	drop if q_4_c == .
	forval nmr = 1/6 {
		gen gr_4c_`nmr' = (q_4_c == `nmr') if q_4_c < .
	}


	set scheme jpalfull
	qui sum clients_n 

	graph bar gr_4c_*, percentages /// percent is the default
		ytitle("Percentage (%) of clients", size(medsmall) orientation(vertical)) ///
		ylabel(0(10)60) ///
		blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
		title("Was the agent able to complete the exact transaction you wanted to do?", size(medsmall)) ///
		subtitle("", size(medsmall)) ///
		legend(order(1 "No wait time" 2 " 5-10 minutes" 3 "10-15 minutes" 4 "15-30 minutes" 5 " 30-45 minutes" ///
		6 "More than 45 minutes") ///
		size(medsmall) col(2)) ///
		note("Total clients = `: di %6.0fc `r(N)''", size(small))

	graph export "$output/Client Baseline - `date'/26 - client_q_4c_.png", as(png) replace

restore
*** q_4d 
preserve

	drop if q_4_d == .
	forval nmr = 1/5 {
		gen gr_4d_`nmr' = (q_4_d == `nmr') if q_4_d < .
	}


	set scheme jpalfull
	qui sum clients_n 
 
	graph bar gr_4d_*, percentages /// percent is the default
		ytitle("Percentage (%) of clients", size(medsmall) orientation(vertical)) ///
		ylabel(0(25)90) ///
		blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
		title("How many times did you have to visit the agent ", size(medsmall)) ///
		subtitle("until the transaction you wanted to make was successful?", size(medsmall)) ///
		legend(order(1 "First visit" 2 "2 times" 3 "3 times" 4 "4 times" 5 "5 or more times") ///
		size(medsmall) col(2)) ///
		note("Total clients = `: di %6.0fc `r(N)''", size(small))

	graph export "$output/Client Baseline - `date'/26 - client_q_4d_.png", as(png) replace

restore
***q_4e 
preserve

	drop if q_4_e == .
	forval nmr = 1/2 {
		gen gr_4_e`nmr' = (q_4_e == `nmr') * 100 if !missing(q_4_e)
	}

	set scheme jpalfull
	qui sum clients_n

	graph bar (mean) gr_4_e1 gr_4_e2, ///
		ytitle("Percentage (%) of clients", size(medsmall)) ///
		ylabel(0(25)100) /// 
		blabel(bar, pos(outside) size(medsmall) format(%15.1f)) ///
		title("Did the agent clearly tell you the amount of the fee they would charge", size(medsmall)) ///
		subtitle("in addition to the transaction amount?", size(medsmall)) ///
		legend(order(1 "Yes" 2 "No") size(medsmall) col(2)) ///
		note("Total clients = `: display %6.0fc `r(N)''", size(small)) 
		
	graph export "$output/Client Baseline - `date'/26 - client_q_4e.png", as(png) replace

restore
**# 5. Section 5
preserve

*** q_5a
	drop if q_5a_11 == .
	local date : display %tdDNCY daily("$S_DATE", "DMY")
	capture shell mkdir -p "$output/Agent Baseline - `date'"
	
	forval y = 1/10 {
		g q_5a_1_`y' = q_5a_11==`y' | q_5a_12==`y' | q_5a_13==`y'
		}
	
	set scheme jpalfull
	qui sum clients_n 

	
	graph bar q_5a_1_*, percentages ///
	ytitle("Percentage (%) of clients", size(small) orientation(vertical)) ylabel(0(5)20, labsize(small)) blabel(bar, pos(center) size(vsmall) format(%15.1fc)) ///
		title("Most important characteristics of an agent", size(medsmall)) ///
		subtitle("", size(medsmall)) ///
		legend(order(1 "Prior customer" 2 "Answers clearly" 3 "Close proximity" 4 "Sufficient cash" 5 "Price transparency" 6 "Always available" 7 "Lowest price" 8 "Bank-affiliated " 9 "Trusted agent" 10 "Same price for all") size(vsmall) col(3)) ///
		note("Total clients = `: di %6.0fc `r(N)''", size(small)) 
		
		graph export "$output/Client Baseline - `date'/27 - client_q_5a.png", as(png) replace
restore
*** q_5b
preserve

	drop if q_5b == . 
	forval x = 1/2 {
		gen gr_5b_`x' = 1 if q_5b == `x'
		recode gr_5b_`x' (. = 0)
		replace gr_5b_`x' = . if q_5b == .
	}

	set scheme jpalfull
	qui sum clients_n 


	graph bar gr_5b_*, percentages /// percent is the default
		ytitle("Percentage (%) of clients", size(medsmall) orientation(vertical)) ///
		ylabel(0(20)60) ///
		blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
		title("Which of the following statements do you {bf:agree with most}?", size(medsmall)) ///
		subtitle(" ", size(medsmall)) ///
		legend(order(1 "Continue doing business w/ regular agent, even if others offer lower prices" ///
		2 "Change to other agents who offer lower prices") size(small) col(1)) ///
		note("Total clients = `: di %6.0fc `r(N)''", size(small))

	graph export "$output/Client Baseline - `date'/28 - client_q_5b.png", as(png) replace

restore
**# 6. Section 6
preserve

*** q_6a

	drop if q_6a == .
	forval x = 1/4 {
		gen gr_6a_`x' = 1 if q_6a == `x'
		recode gr_6a_`x' (. = 0)
		replace gr_6a_`x' = . if q_6a == .
	}

	set scheme jpalfull
	qui sum clients_n 

	graph bar gr_6a_*, percentages /// percent is the default
		ytitle("Percentage (%) of clients", size(medsmall) orientation(vertical)) ///
		ylabel(0(10)50) ///
		blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
		title("Client reaction to being overcharged – {bf:other client}", size(medsmall)) ///
		subtitle("How would you react?", size(medsmall)) ///
		legend(order(1 "Indifferent" 2 "Unfair, switch" 3 "Unfair, stay" 4 "Fair") size(small) col(4)) ///
		note("Total clients = `: di %6.0fc `r(N)''", size(small)) 
		
	graph export "$output/Client Baseline - `date'/29 -  client_q_6a.png", as(png) replace

restore
*** q_6b
preserve

	drop if q_6b == . 
	forval x = 1/4 {
		gen gr_6b_`x' = 1 if q_6b == `x'
		recode gr_6b_`x' (. = 0)
		replace gr_6b_`x' = . if q_6b == .
	}

	set scheme jpalfull
	qui sum clients_n 
	
	graph bar gr_6b_*, percentages /// percent is the default
		ytitle("Percentage (%) of clients", size(medsmall) orientation(vertical)) ///
		ylabel(0(10)50) ///
		blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
		title("Client reaction to being overcharged – {bf:official fees}", size(medsmall)) ///
		subtitle("How would you react?", size(medsmall)) ///
		legend(order(1 "Indifferent" 2 "Unfair, switch" 3 "Unfair, stay" 4 "Fair") size(small) col(4)) ///
		note("Total clients = `: di %6.0fc `r(N)''", size(small)) 
	
	graph export "$output/Client Baseline - `date'/30 - client_q_6b.png", as(png) replace
restore
*** q_6c
preserve

	drop if q_6c == . 
	forval x = 1/3 {
		gen gr_6c_`x' = 1 if q_6c == `x'
		recode gr_6c_`x' (. = 0)
		replace gr_6c_`x' = . if q_6c == .
	}

	set scheme jpalfull
	qui sum clients_n 
	
	graph bar gr_6c_*, percentages /// percent is the default
		ytitle("Percentage (%) of clients", size(medsmall) orientation(vertical)) ///
		ylabel(0(10)75) ///
		blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
		title("Two Agents with the same fee of Rp3.000 for a cash withdrawal.", size(medsmall)) ///
		subtitle("Which agent would you prefer to {bf:regularly} do transactions with?", size(medsmall)) ///
		legend(order(1 "Agent A" 2 "Agent B" 3 "Indifferent") size(medsmall) col(3)) ///
		note("Total clients = `: di %6.0fc `r(N)''", size(small)) 
	
	graph export "$output/Client Baseline - `date'/31 - client_q_6c.png", as(png) replace
	
restore 
**# 7. Section 7
preserve

*** q_7

	local date : display %tdDNCY daily("$S_DATE", "DMY")
	capture shell mkdir -p "$output/Agent Baseline - `date'"

	keep unique_code_client q_7a q_7b q_7c q_7d
	drop if q_7a == .

	local st7 = 1
	foreach a of varlist q_7a q_7b q_7c q_7d {
		rename `a' q_7_`st7'
		local st7 = `st7' + 1
	}

	gen num = _n
	qui sum num
	local obs7 = `r(N)'

	reshape long q_7_, i(unique_code_client num) j(q_7)

	la def q_7 ///
	1 "Banks" ///
	2 "Bank Mandiri" ///
	3 "BM Agent" ///
	4 "BM Agent will givebest price"
	la val q_7 q_7

	tab q_7_, gen(answer)
	set scheme jpalfull

	graph bar (sum) answer*, stack percentage over(q_7, label(angle(0) labsize(small))) ///		
		ytitle("Percentage (%) of clients", size(medsmall) orientation(vertical)) ///
		ylabel(0(20)100) ///
		blabel(bar, pos(center) size(vsmall) format(%15.1fc)) ///
		title("Views regarding {bf:BM Agent} and {bf:Bank Mandiri}", size(medsmall)) ///
		subtitle(" ", size(medsmall)) ////
		legend(order(1 "A great deal of confidence" 2 "Quite a lot of confidence" 3 "Not very much confidence" ///
		4 "No confidence at all") size(small) col(2)) ///
		note("Note:" "Total clients = `: di %6.0fc `obs7''", size(small)) 

	graph export "$output/Client Baseline - `date'/32 - client_q_7.png", as(png) replace

restore
**# 8. Section 8
preserve

*** q_8

	keep unique_code_client q_8a q_8b q_8c q_8d q_8e q_8f
	drop if q_8a == .

	local st8 = 1
	foreach a of varlist q_8a q_8b q_8c q_8d q_8e q_8f {
		rename `a' q_8_`st8'
		local st8 = `st8' + 1
	}

	gen num = _n
	qui sum num
	local obs8 = `r(N)'
	reshape long q_8_, i(unique_code_client num) j(q_8)

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
	
	graph hbar (sum) answer*, stack percentage over(q_8, label(labsize(vsmall))) ///
		title("Do you agree with each of the following statements about ", size(medsmall)) ///
		subtitle("{bf:BM Agent}?", size(medsmall)) ///
		legend(order(1 "Strongly disagree" 2 "Disagree" 3 "Agree" 4 "Strongly agree") size(small) col(2)) ///
		note("Note:" "Total clients = `: di %6.0fc `obs8''", size(small)) ///
		ytitle("Percentage (%) of clients", size(small) orientation(horizontal)) ///
		ylabel(0(25)100) ///
		blabel(bar, pos(center) size(vsmall) format(%15.1fc)) 

	graph export "$output/Client Baseline - `date'/33 - client_q_8.png", as(png) replace

restore
**# 9. Section 9
preserve

*** q_9


	keep unique_code_client q_9a q_9b q_9c q_9d q_9e
	drop if q_9a == .

	local st9 = 1
	foreach a of varlist q_9a q_9b q_9c q_9d q_9e {
		rename `a' q_9_`st9'
		local st9 = `st9' + 1
	}

	gen num = _n
	qui sum num
	local obs9 = `r(N)'
	reshape long q_9_, i(unique_code_client num) j(q_9)

	la def q_9 ///
	1 "Honest and trustworthy" ///
	2 "Cust well-being above profits" ///
	3 "Treats all equally well" ///
	4 "Transparent about pricing" ///
	5 "Offers reliable service"
	la val q_9 q_9

	tab q_9_, gen(answer)
	set scheme jpalfull

	graph hbar (sum) answer*, stack percentage over(q_9, label( labsize(vsmall))) ///
		title("Do you agree with each of the following statements about", size(medsmall)) ///
		subtitle(" {bf:Bank Mandiri}?", size(medsmall)) ///
		legend(order(1 "Strongly disagree" 2 "Disagree" 3 "Agree" 4 "Strongly agree") size(small) col(2)) ///
		note("Note:" "Total clients = `: di %6.0fc `obs9''", size(small)) ///
		ytitle("Percentage (%) of clients", size(small) orientation(horizontal)) ///
		ylabel(0(25)100) ///
		blabel(bar, pos(center) size(vsmall) format(%15.1fc)) 

	graph export "$output/Client Baseline - `date'/34 - client_q_9.png", as(png) replace

restore
**# 10. Section 10
preserve

*** q_10a

	drop if q_10a == . 
	local date : display %tdDNCY daily("$S_DATE", "DMY")
	capture shell mkdir -p "$output/Agent Baseline - `date'"
	
	forval x = 1/3 {
		gen gr_10a_`x' = 1 if q_10a == `x'
		recode gr_10a_`x' (. = 0)
		replace gr_10a_`x' = . if q_10a == .
	}

	set scheme jpalfull
	qui sum clients_n 
	
	graph bar gr_10a_*, percentages /// percent is the default
		ytitle("Percentage (%) of clients", size(medsmall) orientation(vertical)) ///
		ylabel(0(10)70) ///
		blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
		title("Last month, how much {bf:time} do you think your BM Agent spent", size(medsmall)) ///
		subtitle("{bf:advertising} his/her services to people in the village?", size(medsmall)) ///
		legend(order(1 "None at all" 2 "Some time" 3 "A lot of time") size(medsmall) col(3)) ///
		note("Total clients = `: di %6.0fc `r(N)''", size(small))

	graph export "$output/Client Baseline - `date'/35 - client_q_10a.png", as(png) replace

restore
*** q_10b
preserve
	
	drop if q_10b == . 
	forval x = 1/4 {
		gen gr_10b_`x' = 1 if q_10b == `x'
		recode gr_10b_`x' (. = 0)
		replace gr_10b_`x' = . if q_10b == .
	}

	set scheme jpalfull
	qui sum clients_n 
	
	graph bar gr_10b_*, percentages /// percent is the default
		ytitle("Percentage (%) of clients", size(medsmall) orientation(vertical)) ///
		ylabel(0(10)80) ///
		blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
		title("Do you agree with this statement?", size(small)) ///
		subtitle("Last month, BM Agent did all he/she could {bf:to convince village people to adopt the agent products}", size(small)) ///
		legend(order(1 "Disagree completely" 2 "Disagree" 3 "Agree" 4 "Fully agree") size(medsmall) col(2)) ///
		note("Total clients = `: di %6.0fc `r(N)''", size(small))
	
	graph export "$output/Client Baseline - `date'/36 - client_q_10b.png", as(png) replace

restore
*** q_10c
preserve

	drop if q_10c == .
	forval x = 1/6 {
		gen gr_10c_`x' = 1 if q_10c == `x'
		recode gr_10c_`x' (. = 0)
		replace gr_10c_`x' = . if q_10c == .
	}

	set scheme jpalfull
	qui sum clients_n 

	graph bar gr_10c_*, percentages /// percent is the default
		ytitle("Percentage (%) of clients", size(medsmall) orientation(vertical)) ///
		ylabel(0(10)60) ///
		blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
		title("Last month, has your BM Agent {bf:approached you} to encourage you to", size(medsmall)) ///
		subtitle("{bf:do more branchless banking transactions}?", size(medsmall)) ///
		legend(order(1 "Every day" 2 "A few times a week" 3 "Once a week" 4 "A few times per month" 5 "Once a month" ///
		6 "Not at all") size(small) col(2)) ///
		note("Total clients = `: di %6.0fc `r(N)''", size(small))

	graph export "$output/Client Baseline - `date'/37 - client_q_10c.png", as(png) replace

restore
*** q_10d
preserve

	drop if q_10d == . 
	forval x = 1/6 {
		gen gr_10d_`x' = 1 if q_10d == `x'
		recode gr_10d_`x' (. = 0)
		replace gr_10d_`x' = . if q_10d == .
	}

	set scheme jpalfull
	qui sum clients_n 
	

	graph bar gr_10d_*, percentages /// percent is the default
		ytitle("Percentage (%) of clients", size(medsmall) orientation(vertical)) ///
		ylabel(0(10)60) ///
		blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
		title("Last month, has your BM Agent {bf:approached you} to encourage you to", size(medsmall)) ///
		subtitle("{bf:adopt new Bank Mandiri financial products}?", size(medsmall)) ///
		legend(order(1 "Every day" 2 "A few times a week" 3 "Once a week" 4 "A few times per month" ///
		5 "Once a month" 6 "Not at all") size(small) col(2)) ///
		note("Total clients = `: di %6.0fc `r(N)''", size(small))

	graph export "$output/Client Baseline - `date'/38 - client_q_10d.png", as(png) replace

restore
*** q_10e
preserve

	drop if q_10e == .
	local x = 1
	forval nmr = 1/2 {
		gen gr_10e_`nmr' = 1 if q_10e == `x'
		recode gr_10e_`nmr' (. = 0)
		replace gr_10e_`nmr' = . if q_10e == .
		local x = `x' - 1
	}

	set scheme jpalfull
	qui sum clients_n 
	 
	graph bar gr_10e_*, percentages /// percent is the default
		ytitle("Percentage (%) of clients", size(medsmall) orientation(vertical)) ///
		ylabel(0(10)60) ///
		blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
		title("Last month, has the agent approached you with", size(medsmall)) ///
		subtitle("{bf:new information about prices} for Bank Mandiri transactions?", size(medsmall)) ///
		legend(order(1 "Yes" 2 "No") size(medsmall) col(2)) ///
		note("Total clients = `: di %6.0fc `r(N)''", size(small))

	graph export "$output/Client Baseline - `date'/39 - client_q_10e.png", as(png) replace

restore
*** q_10f
preserve

	drop if q_10f == " "
	destring q_10f, replace
	local x = 1
	forval nmr = 1/2 {
		gen gr_10f_`nmr' = 1 if q_10f == `x'
		recode gr_10f_`nmr' (. = 0)
		replace gr_10f_`nmr' = . if q_10f == .
		local x = `x' - 1
	}

	set scheme jpalfull
	qui sum clients_n 
	
	graph bar gr_10f_*, percentages /// percent is the default
		ytitle("Percentage (%) of clients", size(medsmall) orientation(vertical)) ///
		ylabel(0(10)60) ///
		blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
		title("Have you ever taken any {bf:benefits} from your agent ", size(medsmall)) ///
		subtitle("that are not related to their branchless banking business?", size(medsmall)) ///
		legend(order(1 "Yes" 2 "No") size(medsmall) col(2)) ///
		note("Total clients = `: di %6.0fc `r(N)''", size(small))

	graph export "$output/Client Baseline - `date'/40 - client_q_10f.png", as(png) replace

restore
*** q_10g
preserve

	drop if q_10g == "Transfer "
	local date : display %tdDNCY daily("$S_DATE", "DMY")
	capture shell mkdir -p "$output/Agent Baseline - `date'"

	** Drop missing variable (if any)
	destring q_10g, replace
	

	** Summary statistics
	qui summarize q_10g, detail
	return list

	** Store obs number before dropping outlier(s)
	local total_before = r(N)

	** Detect and drop outlier(s)
	generate iqr = r(p75) - r(p25)
	generate lower_limit = r(p25) - 1.5 * iqr
	generate upper_limit = r(p75) + 1.5 * iqr
	generate outlier = (q_10g < lower_limit) | (q_10g > upper_limit)
	drop if outlier == 1

	** Store obs number after dropping outlier(s) and compute the difference
	qui summarize q_10g, detail
	local total_after = r(N)
	local dropped_obs = `total_before' - `total_after'
	
	** Store lower and upper threshold
	qui su lower_limit, det
	local ll = round(`r(mean)', 1)
	qui su upper_limit, det
	local ul = round(`r(mean)', 1)

	* Histogram
	set scheme plotplain

	histogram q_10g, percent color(navy) ///
		discrete ///
		xlabel(0(5)25) ///
		ylabel(0(5)25) ///
		xtitle("Visit frequency", size(medsmall)) ///
		ytitle("Percentage (%) of clients", size(medsmall)) ///
		title("In the past month, how many times have you visited the BM agent", size(medsmall)) ///
		subtitle("to purchase items/services other than financial services?", size(medsmall)) ///
		note("Note:" "Total clients = `: di %6.0fc `r(N)''" "Outlier threshold = `ll' (lower) and `ul' (upper)" "Dropped outlier observation = `dropped_obs'", size(small))
		//
	
	graph export "$output/Client Baseline - `date'/41 - client_q_10g_hist.png", as(png) replace

	* Box plot
	set scheme plotplain

	qui su q_10g, det
	return list

	local mean_rounded = round(`r(mean)', 1)	
	local Q_1_rounded = round(`r(p25)', 1)
	local Q_3_rounded = round(`r(p75)', 1)
	local median_rounded = round(`r(p50)', 1)

	graph box q_10g, box(1, fcolor(navy*0.75) lcolor(navy*0.75)) yline(`r(mean)', lpattern(.) lcolor(navy*0.75)) ///
		ytitle("Visit frequency", size(medsmall)) ///
		title("In the past month, how many times have you visited the BM agent", size(medsmall)) ///
		subtitle("to purchase items/services other than financial services?", size(medsmall)) ///
		text(`r(p50)' 95 "Median=`median_rounded'", size(vsmall)) ///
		text(`r(p75)' 95 "Q3=`Q_3_rounded'", size(vsmall)) ///
		text(`r(p25)' 95 "Q1=`Q_1_rounded'", size(vsmall)) ///
		text(`r(mean)' 95 "Mean=`mean_rounded'", size(vsmall)) ///
		note("Note:" "Total clients = `: di %6.0fc `r(N)''" "Outlier threshold = `ll' (lower) and `ul' (upper)" "Dropped outlier observation = `dropped_obs'", size(small))
	
	graph export "$output/Client Baseline - `date'/42 - client_q_10g_boxplot.png", as(png) replace

restore
**# 11. Section 11
preserve

*** q_11a

	drop if q_11a == .
	destring q_11a, replace
	local date : display %tdDNCY daily("$S_DATE", "DMY")
	capture shell mkdir -p "$output/Agent Baseline - `date'"
	
	forval x = 1/2 {
		gen gr_11a_`x' = 1 if q_11a == `x'
		recode gr_11a_`x' (. = 0)
		replace gr_11a_`x' = . if q_11a == .
	}

	set scheme jpalfull
	qui sum clients_n 
	
	graph bar gr_11a_*, percentages /// percent is the default
		ytitle("Percentage (%) of clients", size(medsmall) orientation(vertical)) ///
		ylabel(0(10)60) ///
		blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
		title("Which of the following statements do you agree with most?", size(medsmall)) ///
		subtitle(" ", size(medsmall)) ///
		legend(order(1 "There are many agents in my area" 2 "There are limited agents in my area") size(medsmall) col(1)) ///
		note("Total clients = `: di %6.0fc `r(N)''", size(small))

	graph export "$output/Client Baseline - `date'/43 - client_q_11a.png", as(png) replace

restore
*** q_11b
preserve

	destring q_11b, replace
	drop if q_11b == .
	qui summarize q_11b, detail
	return list	
	local total_before = r(N)

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

	histogram q_11b, percent color(maroon) ///
		discrete ///
		xlabel(0(1)10) ///
		ylabel(0(5)30) ///
		xtitle("Number of agent", size(medsmall)) ///
		ytitle("Percentage (%) of clients", size(medsmall)) ///
		title("How many {bf:branchless banking agents} are in your area?", size(medsmall)) ///
		subtitle(" ", size(medsmall)) ///
		note("Note:" "Total clients = `: di %6.0fc `r(N)''" "Outlier threshold = `ll' (lower) and `ul' (upper)" "Dropped outlier observation = `dropped_obs'", size(small))
		//
	graph export "$output/Client Baseline - `date'/44 - client_q_11b_hist.png", as(png) replace

* Box plot
	set scheme plotplain

	qui su q_11b, det
	return list

	local mean_rounded = round(`r(mean)', 1)	
	local Q_1_rounded = round(`r(p25)', 1)
	local Q_3_rounded = round(`r(p75)', 1)
	local median_rounded = round(`r(p50)', 1)

	graph box q_11b, box(1, fcolor(maroon*0.75) lcolor(maroon*0.75)) yline(`r(mean)', lpattern(.) lcolor(maroon*0.75)) ///
		ytitle("Number of agent", size(medsmall)) ///
		title("How many {bf:branchless banking agents} are in your area?", size(medsmall)) ///
		subtitle(" ", size(medsmall)) ///
		text(`r(p50)' 95 "Median=`median_rounded'", size(vsmall)) ///
		text(`r(p75)' 95 "Q3=`Q_3_rounded'", size(vsmall)) ///
		text(`r(p25)' 95 "Q1=`Q_1_rounded'", size(vsmall)) ///
		text(`r(mean)' 95 "Mean=`mean_rounded'", size(vsmall)) ///
		note("Note:" "Total clients = `: di %6.0fc `r(N)''" "Outlier threshold = `ll' (lower) and `ul' (upper)" "Dropped outlier observation = `dropped_obs'", size(small))
		// 
	
	graph export "$output/Client Baseline - `date'/45 - client_q_11b_boxplot.png", as(png) replace

restore
**# 12. Section 12
preserve

*** q_12a

	local date : display %tdDNCY daily("$S_DATE", "DMY")
	capture shell mkdir -p "$output/Agent Baseline - `date'"
	
	drop if q_12a == .
	qui summarize q_12a, detail
	local total_after = r(N)
	set scheme plotplain

	histogram q_12a, percent color(emerald*0.95) ///
		discrete ///
		xlabel(2013(1)2025) ///
		ylabel(0(3)30) ///
		xtitle("Year", size(medsmall)) ///
		ytitle("Percentage (%) of clients", size(medsmall)) ///
		title("{bf:Since when} have you been doing transactions with your {bf:BM Agent}?", size(medsmall)) ///
		subtitle(" ", size(medsmall)) ///
		note("Total clients = `: di %6.0fc `r(N)''", size(small))

	graph export "$output/Client Baseline - `date'/46 - client_q_12a_hist.png", as(png) replace

restore
*** q_12b
preserve

	drop if q_12b == . 
	forval x = 1/4 {
		gen gr_12b_`x' = 1 if q_12b == `x'
		recode gr_12b_`x' (. = 0)
		replace gr_12b_`x' = . if q_12b == .
	}

	set scheme jpalfull
	qui sum clients_n 

	graph bar gr_12b_*, percentages /// percent is the default
		ytitle("Percentage (%) of clients", size(medsmall) orientation(vertical)) ///
		ylabel(0(5)40) ///
		blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
		title("{bf:For how long} have you known your {bf:BM Agent}?", size(medsmall)) ///
		subtitle(" ", size(medsmall)) ///
		legend(order(1 "A few months" 2 "For about a year" 3 "Between 1-5 years" 4 "Longer than 5 years") size(small) col(2)) ///
		note("Total clients = `: di %6.0fc `r(N)''", size(small))

	graph export "$output/Client Baseline - `date'/47 - client_q_12b.png", as(png) replace

restore
*** q_12c
preserve

	drop if q_12c == . 
	forval x = 1/8 {
		gen gr_12c_`x' = 1 if q_12c == `x'
		recode gr_12c_`x' (. = 0)
		replace gr_12c_`x' = . if q_12c == .
	}

	set scheme jpalfull
	qui sum clients_n 
	
	graph bar gr_12c_*, percentages /// percent is the default
		ytitle("Percentage (%) of clients", size(medsmall) orientation(vertical)) ///
		ylabel(0(10)40) ///
		blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
		title("How often do you {bf:talk} with your {bf:BM Agent}?", size(medsmall)) ///
		subtitle(" ", size(medsmall)) ///
		legend(order(1 "Every day" 2 "A few times a week" 3 "Once a week" 4 "A few times per month" 5 "Once a month" ///
		6 "Every 3 months" 7 "Every 6 months" 8 "Once a year") size(small) col(3)) ///
		note("Total clients = `: di %6.0fc `r(N)''", size(small)) 

	graph export "$output/Client Baseline - `date'/48 - client_q_12c.png", as(png) replace

restore
*** q_12d
preserve

	local date : display %tdDNCY daily("$S_DATE", "DMY")
	capture shell mkdir -p "$output/Agent Baseline - `date'"

	destring q_12d, replace
	drop if q_12d == .
	qui summarize q_12d, detail
	return list
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
	*/

	* Histogram
	set scheme plotplain
	
	histogram q_12d, percent color(emerald*0.95) ///
		xlabel(0(10)100) ///
		ylabel(0(5)10) ///
		xtitle("Percentage of overall branchless banking transactions with BM Agent", size(medsmall)) ///
		ytitle("Percentage (%) of clients", size(medsmall)) ///
		title("What % {bf:of your overall branchless banking transactions}", size(medsmall)) ///
		subtitle("do you do with your {bf:BM Agent}?", size(medsmall)) ///
		note("Note:" "Total clients = `: di %6.0fc `r(N)''" "Outlier threshold = `ll' (lower) and `ul' (upper)" "Dropped outlier observation = `dropped_obs'", size(small))
		
	graph export "$output/Client Baseline - `date'/49 - q_12d_hist.png", as(png) replace

	* Box plot
	set scheme plotplain

	qui su q_12d, det
	return list
	
	local mean_rounded = round(`r(mean)', 1)	
	local Q_1_rounded = round(`r(p25)', 1)
	local Q_3_rounded = round(`r(p75)', 1)
	local median_rounded = round(`r(p50)', 1)

	graph box q_12d, box(1, fcolor(emerald*0.75) lcolor(emerald*0.75)) yline(`r(mean)', lpattern(.) lcolor(emerald*0.75)) ///
		ytitle("Percentage (%) of clients", size(medsmall)) ///
		title("What % {bf:of your overall branchless banking transactions}", size(medsmall)) ///
		subtitle("do you do with your {bf:BM Agent}?", size(medsmall)) ///
		text(`r(p50)' 95 "Median=`median_rounded'", size(vsmall)) ///
		text(`r(p75)' 95 "Q3=`Q_3_rounded'", size(vsmall)) ///
		text(`r(p25)' 95 "Q1=`Q_1_rounded'", size(vsmall)) ///
		text(`r(mean)' 95 "Mean=`mean_rounded'", size(vsmall)) ///
		note("Note:" "Total clients = `: di %6.0fc `r(N)''" "Outlier threshold = `ll' (lower) and `ul' (upper)" "Dropped outlier observation = `dropped_obs'", size(small))

	graph export "$output/Client Baseline - `date'/50 - client_q_12d_boxplot.png", as(png) replace

restore
*** q_12e
preserve

	drop if q_12e == .

	local x = 1
	forval nmr = 1/2 {
		gen gr_12e_`nmr' = 1 if q_12e == `x'
		recode gr_12e_`nmr' (. = 0)
		replace gr_12e_`nmr' = . if q_12e == .
		local x = `x' - 1
	}

	set scheme jpalfull
	qui sum clients_n  

	graph bar gr_12e_*, percentages /// percent is the default
		ytitle("Percentage (%) of clients", size(medsmall) orientation(vertical)) ///
		ylabel(0(25)100) ///
		blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
		title("Which of the following best describes your opinion about", size(medsmall)) ///
		subtitle("{bf:banking agents in general}?", size(medsmall)) ///
		legend(order(1 "Not honest and often overcharge customers" 2 "Honest and charge the correct prices") size(small) col(1)) ///
		note("Total clients = `: di %6.0fc `r(N)''", size(small)) 

graph export "$output/Client Baseline - `date'/51 - client_q_12e.png", as(png) replace


restore
*** q_12f
preserve

	
	destring q_12f, replace
	drop if q_12f == .
	qui summarize q_12f, detail
	return list
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
	
	histogram q_12f, percent color(navy) ///
		discrete ///
		xlabel(0(1)10) ///
		ylabel(0(5)25) ///
		xtitle("Step", size(medsmall)) ///
		ytitle("Percentage (%) of clients", size(medsmall)) ///
		title("Imagine a ladder with 10 steps. Richest 10th step and poorest 1st step.", size(medsmall)) ///
		subtitle("{bf:In which step} do you think you are?", size(medsmall)) ///
	note("Note:" "Total clients = `: di %6.0fc `r(N)''" "Outlier threshold = `ll' (lower) and `ul' (upper)" "Dropped outlier observation = `dropped_obs'", size(small))

graph export "$output/Client Baseline - `date'/52 - client_q_12f_hist.png", as(png) replace

* Box plot
set scheme plotplain

	qui su q_12f, det
	return list

	local mean_rounded = round(`r(mean)', 1)	
	local Q_1_rounded = round(`r(p25)', 1)
	local Q_3_rounded = round(`r(p75)', 1)
	local median_rounded = round(`r(p50)', 1)

	graph box q_12f, box(1, fcolor(navy*0.75) lcolor(navy*0.75)) yline(`r(mean)', lpattern(.) lcolor(navy*0.75)) ///
		ytitle("Step", size(medsmall)) ///
		title("Imagine a ladder with 10 steps. Richest 10th step and poorest 1st step.", size(medsmall)) ///
		subtitle("{bf:In which step} do you think you are?", size(medsmall)) ///
		text(`r(p50)' 95 "Median=`median_rounded'", size(vsmall)) ///
		text(`r(p75)' 95 "Q3=`Q_3_rounded'", size(vsmall)) ///
		text(`r(p25)' 95 "Q1=`Q_1_rounded'", size(vsmall)) ///
		text(`r(mean)' 95 "Mean=`mean_rounded'", size(vsmall)) ///
		note("Note:" "Total clients = `: di %6.0fc `r(N)''" "Outlier threshold = `ll' (lower) and `ul' (upper)" "Dropped outlier observation = `dropped_obs'", size(small))
		//

	graph export "$output/Client Baseline - `date'/53 - client_q_12f_boxplot.png", as(png) replace

restore
*** q_12g
preserve

	drop if q_12g == .

	forval x = 1/4 {
		gen gr_12g_`x' = 1 if q_12g == `x'
		recode gr_12g_`x' (. = 0)
		replace gr_12g_`x' = . if q_12g == .
	}

	set scheme jpalfull
	qui sum clients_n 
	
	graph bar gr_12g_*, percentages /// percent is the default
		ytitle("Percentage (%) of clients", size(medsmall) orientation(vertical)) ///
		ylabel(0(5)40) ///
		blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
		title("How would you describe your {bf:customer profile} when it comes to", size(medsmall)) ///
		subtitle("the use of financial services?", size(medsmall)) ///
		legend(order(1 "New & don't know much about products and prices" ///
		2 "Somewhat new, and still learning about products and prices" ///
		3 "Somewhat experienced, and familiar with products and prices" ///
		4 "Very experienced, and fully informed about products and prices") size(vsmall) col(1)) ///
		note("Total clients = `: di %6.0fc `r(N)''", size(small)) 

	graph export "$output/Client Baseline - `date'/54 - client_q_12g.png", as(png) replace

restore
*** q_12h
preserve

	drop if q_12h == . 

	local x = 1
	forval nmr = 1/2 {
		gen gr_12h_`nmr' = 1 if q_12h == `x'
		recode gr_12h_`nmr' (. = 0)
		replace gr_12h_`nmr' = . if q_12h == .
		local x = `x' - 1
	}

	set scheme jpalfull
	qui sum clients_n 

	graph bar gr_12h_*, percentages /// percent is the default
		ytitle("Percentage (%) of clients", size(medsmall) orientation(vertical)) ///
		ylabel(0(10)70) ///
		blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
		title("Do you use Mandiri Agen {bf:to send or receive business payments}?", size(medsmall)) ///
		subtitle(" ", size(medsmall)) ///
		legend(order(1 "Yes" 2 "No") size(medsmall) col(2)) ///
		note("Total clients = `: di %6.0fc `r(N)''", size(small))  

	graph export "$output/Client Baseline - `date'/55 - client_q_12h.png", as(png) replace


restore
*** q_12i
preserve

	drop if q_12i == . 
	local x = 1
	forval nmr = 1/2 {
		gen gr_12i_`nmr' = 1 if q_12i == `x'
		recode gr_12i_`nmr' (. = 0)
		replace gr_12i_`nmr' = . if q_12i == .
		local x = `x' - 1
	}

	set scheme jpalfull
	qui sum clients_n 
	
	graph bar gr_12i_*, percentages /// percent is the default
		ytitle("Percentage (%) of clients", size(medsmall) orientation(vertical)) ///
		ylabel(0(10)70) ///
		blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
		title("Do you use Mandiri Agen {bf:to receive salary payments}?", size(medsmall)) ///
		subtitle(" ", size(medsmall)) ///
		legend(order(1 "Yes" 2 "No") size(medsmall) col(2)) ///
		note("Total clients = `: di %6.0fc `r(N)''", size(small)) 

	graph export "$output/Client Baseline - `date'/56 - client_q_12i.png", as(png) replace

restore
*** q_12j
preserve

	drop if gender == .
	local x = 1
	forval nmr = 1/2 {
		gen gr_gender_`nmr' = 1 if gender == `x'
		recode gr_gender_`nmr' (. = 0)
		replace gr_gender_`nmr' = . if gender == .
		local x = `x' - 1
	}

	set scheme jpalfull
	qui sum clients_n 

	graph bar gr_gender_*, percentages /// percent is the default
		ytitle("Percentage (%) of clients", size(medsmall) orientation(vertical)) ///
		ylabel(0(10)60) ///
		blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
		title("What is your {bf:gender}?", size(medsmall)) ///
		subtitle(" ", size(medsmall)) ///
		legend(order(1 "Female" 2 "Male") size(medsmall) col(2)) ///
		note("Total clients = `: di %6.0fc `r(N)''", size(small)) 

	graph export "$output/Client Baseline - `date'/57 - client_gender.png", as(png) replace


restore
*** q_12k (birthyear)
preserve

	qui count if birthyear < .
	local total_before = r(N)

	* Drop outliers
	drop if birthyear < 1960 & birthyear < .
	drop if birthyear > 2020

	* Obs after dropping outliers
	qui count if birthyear < .
	local total_after = r(N)

	* Dropped observations
	local dropped_obs = `total_before' - `total_after'
	set scheme plotplain
	
	* Histogram
	histogram birthyear, percent color(emerald*0.90) //////
		ylabel(0(5)10) ///
		xlabel(1960(10)2020) ///
		xtitle("Year", size(medsmall)) ///
		ytitle("Percentage of clients (%)", size(medsmall)) ///
		title("Year of birth", size(medsmall)) ///
		note("Total clients = `: di %6.0fc `total_after''" ///
			"Outlier threshold = birthyear < 1960  >2020" ///
			"Dropped observations = `dropped_obs'", size(small))

	graph export "$output/Client Baseline - `date'/58 - client_birthyear_hist.png", as(png) replace

restore
/*** q_13a (compensation type)
preserve

	drop if q_13a == .
	forval x = 1/3 {
		gen gr_13a_`x' = 1 if q_13a == `x'
		recode gr_13a_`x' (. = 0)
		replace gr_13a_`x' = . if q_13a == .
	}

	set scheme jpalfull
	qui sum clients_n
	
	graph bar gr_13a_*, percentages /// percent is the default
		ytitle("Percentage (%)", size(medsmall) orientation(vertical)) ///
		ylabel(0(25)100) ///
		blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
		title("Compensation type", size(medsmall)) ///
		subtitle(" ", size(medsmall)) ///
		legend(order(1 "Pulsa Telkomsel" 2 "Pulsa 3 (Tri)" 3 "Pulsa XL") size(small) col(2)) /// --> BELUM DIUPDATE
		note("Total clients = `: di %6.0fc `r(N)''", size(medsmall))

	graph export "$output/Client Baseline - `date'/53 - compensation_type.png", as(png) replace

restore
*** q_13c_1 (are you sure your number is corect) */
preserve

	drop if q_13c_1 == .
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
		ytitle("Percentage (%)", size(medsmall) orientation(vertical)) ///
		ylabel(0(25)100) ///
		blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
		title("Are you sure your number is correct?", size(medsmall)) ///
		subtitle(" ", size(medsmall)) ///
		legend(order(1 "Yes" 2 "No") size(medsmall) col(2)) ///
		note("Total clients = `: di %6.0fc `r(N)''", size(medsmall))

	graph export "$output/Client Baseline - `date'/54 - correct_number.png", as(png) replace

