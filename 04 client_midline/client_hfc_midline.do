*===================================================*
* Full-Scale - Client Survey (Midline)
* Author: Naufal Ridwan
* Last modified: 24 March 2026
* Last modified by: Naufal
* Stata version: 16
*===================================================*

clear all
set more off

*****************************************
**--------------DATA PATH--------------**
*****************************************
// gl user = c(username)

if "`c(username)'" == "jpals" {
        * Set 'path' to be main path
        gl  path "C:\Users\jpals\Dropbox\J-PAL IFII Agent Banking Network (BM)\06 Data\c Full-Scale"
 }
 
if "`c(username)'" == "athonaufalridwan" {
	gl path "/Users/athonaufalridwan/Library/CloudStorage/Dropbox/J-PAL IFII Agent Banking Network (BM)/06 Data/c Full-Scale"
}
 
* Set the path
gl do            "$path/06 Survey Data/dofiles"
gl dta           "$path/06 Survey Data/dtafiles"
gl log           "$path/06 Survey Data/logfiles"
gl output        "$path/06 Survey Data/output"
gl raw           "$path/06 Survey Data/rawresponses"


* Set local date
local date : di %tdDNCY daily("$S_DATE","DMY") //this is the default code, it will automatically capture the current date
//local date "DDMMYYYY" // only use this manual setting if you're running this code late than the supposed day

*************
*IMPORT DATA*
*************

    use "$dta/03 client_midline/client_midline_24032026.dta", clear
    local outfolder "$output/03 client_midline/Client Midline - `date'"
	capture mkdir "`outfolder'"

***************
*DATA ANALYSIS*
***************

    *checking no consent and number of responses
    gen clients_n = _n  // for notes on total N agents
    drop if informed_consent == "0" // drop people who refuse to participate in the survey
	preserve
	
***# SECTION 1: Last Cash Deposit Transaction #***

    *q_1a
    forval nmr = 1/6 {
        gen gr_1a_`nmr' = (q_1a == `nmr')
        replace gr_1a_`nmr' = . if missing(q_1a)
    }       

    set scheme jpalfull
    qui sum clients_n if q_1a !=.

    graph bar gr_1a_*, percentages /// 
        ytitle("Perc of agents", size(medsmall) orientation(vertical)) ///
        ylabel(0(25)100) ///
        blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
        title("When was the last time you did a {bf:cash deposit} with your Mandiri Agen?", size(small)) ///
        subtitle(" ", size(small)) ///
        legend(order(1 "Within past 7 days" 2 "8-15 days ago" 3 "16-30 days ago" 4 "More than 1 (one) month ago" ///
        5 "More than 6 (six) months ago" 6 "Have not done it") size(small) col(3)) ///
        note("Total agents = `: di %6.0fc `r(N)''", size(medsmall))
    graph export "$output/03 client_midline/Client Midline - `date'/1 - q_1a.png", as(png) replace
	
	restore
    *q_1a_1
	preserve

	** -- Histogram

    destring q_1a_1, replace
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

	set scheme plotplain

	histogram q_1a_1_dummy, percent color(chocolate) ///
		ylabel(0(5)25) ///
		xlabel(, format(%15.0fc)) ///
		xtitle("Amount of deposit (thousands)", size(medsmall)) ///
		ytitle("Percentage (%) of clients", size(medsmall)) ///
		title("In your last transaction with{bf: BM Agent}, how much did you{bf: deposit}?", size(medsmall)) ///
		subtitle(" ", size(medsmall)) ///
		note("Note:" "Total clients = `: di %6.0fc `r(N)''" "Outlier threshold = `=string(`ll', "%15.0gc")' (lower) and `=string(`ul', "%15.0gc")' (upper)" ///
			"Dropped outlier observation = `dropped_obs'", size(small)) 
	graph export "$output/03 client_midline/Client Midline - `date'/2 - q_1a_1.png", as(png) replace

    ** -- Boxplot
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
		note("Note:" "Total clients = `: di %6.0fc `r(N)''" "Outlier threshold = `=string(`ll', "%15.0gc")' (lower) and `=string(`ul', "%15.0gc")' (upper)" ///
			"Dropped outlier observation = `dropped_obs'" "The sumstat value is rounded to the nearest value of 1,000", size(small)) 
	graph export "$output/03 client_midline/Client Midline - `date'/3 - q_1a_1_boxplot.png", as(png) replace

	restore
    *q_1a_2
	preserve

	** -- Histogram
	destring q_1a_2, replace
	drop if q_1a_2 == .
	qui summarize q_1a_2, detail
	return list
	local total_before = r(N)
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
	
	set scheme plotplain
	histogram q_1a_2, percent color(navy*0.95) ///
   		xlabel(0(1000)9500, format(%15.0fc) labsize(vsmall)) ylabel(0(5)35, gmax) ///
    	xtitle("Transaction fee", size(medsmall)) ///
    	ytitle("Percentage of clients", size(medsmall)) ///
    	title("What was the {bf:transaction fee} charged by {bf:BM Agent}", size(medsmall)) ///
    	subtitle("you use the last time you made {bf:a cash deposit}?", size(medsmall)) ///
    	note("Note:" "Total clients = `: di %6.0fc `total_after''" ///
         "Outlier threshold = `ll' (lower) and `ul' (upper)" ///
         "Dropped outlier observation = `dropped_obs'", size(small))
	graph export "$output/03 client_midline/Client Midline - `date'/4 - client_q_1a_2_hist.png", replace

	** -- Boxplot
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
	graph export "$output/03 client_midline/Client Midline - `date'/5 - client_q_1a_2_boxplot.png", as(png) replace

	restore
	*q_1a_3
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
	graph export "$output/03 client_midline/Client Midline - `date'/6 - client_q_1a_3.png", as(png) replace

	restore
	*q_1a_4
	preserve

	destring q_1a_4, replace
	drop if q_1a_4 == .
	qui sum q_1a_4, detail
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
	graph export "$output/03 client_midline/Client Midline - `date'/7 - client_q_1a_4_hist.png", as(png) replace

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
	graph export "$output/03 client_midline/Client Midline - `date'/8 - client_q_1a_4_boxplot.png", as(png) replace

	restore
	*q_1b_1
	preserve

	drop if q_1b_1 ==. 
	forval x = 1/6 {
		gen gr_1b_1_`x' = 1 if q_1b_1 == `x'
		recode gr_1b_1_`x' (. = 0)
		replace gr_1b_1_`x' = . if q_1b_1 == .
	}

	set scheme jpalfull
	qui sum clients_n 
	
	graph bar gr_1b_1_*, percentages /// percent is the default
		ytitle("Percentage (%) of clients", size(medsmall) orientation(vertical)) ///
		ylabel(0(10)50) ///
		blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
		title("When was the last time you did a{bf: cash deposit} with{bf: a non-BM Agent}?", size(medsmall)) ///
		subtitle(" ", size(medsmall)) ///
		legend(order(1 "Within the past 7 days" 2 "8-15 days ago" 3 "16-30 days ago" 4 "More than one month ago" 5 "More than six month ago" 6 "I haven't done this transaction with BM Agent before") size(vsmall) col(2)) ///
	note("Total clients = `: di %6.0fc `r(N)''", size(medsmall))
	
	graph export "$output/03 client_midline/Client Midline - `date'/9 - client_q_1b_1.png", as(png) replace

	restore
	*q_1b_2
	preserve

	destring q_1b_2, replace
	drop if q_1b_2 == .
	qui summarize q_1b_2, detail
	return list	
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
	local ll = round(`r(mean)', 1000)
	qui su upper_limit, det
	local ul = round(`r(mean)', 1000)
	
	* Histogram
	set scheme plotplain

	histogram q_1b_2, percent color(emerald*0.95) ///
		ylabel(0(5)30) ///
		xlabel(, format(%12.0fc)) ///
		xtitle("Amount of deposit", size(medsmall)) ///
		ytitle("Percentage (%) of clients", size(medsmall)) ///
		title("In your last transaction with{bf: a non-BM Agent}, how much did you{bf: deposit} (thousand)?", size(medsmall)) ///
		subtitle(" ", size(medsmall)) ///
		note("Note:" "Total clients = `: di %6.0fc `r(N)''" "Dropped outlier observation = `dropped_obs'" "Outlier threshold = `=string(`ll', "%15.0gc")' (lower) and `=string(`ul', "%15.0gc")' (upper)" ///
			"Dropped outlier observation = `dropped_obs'" "The sumstat value is rounded to the nearest value of 1,000", size(small))
	graph export "$output/03 client_midline/Client Midline - `date'/10 - client_q_1b_2_hist.png", as(png) replace

	* Box plot
	set scheme plotplain
	qui su q_1b_2, det
	return list
	local mean_rounded = round(`r(mean)', 100)	
	local Q_1_rounded = round(`r(p25)', 100)
	local Q_3_rounded = round(`r(p75)', 1000)
	local median_rounded = round(`r(p50)', 100)

	graph box q_1b_2, box(1, fcolor(emerald*0.75) lcolor(emerald*0.75)) yline(`r(mean)', lpattern(.) lcolor(emerald*0.75)) ///
		ytitle("Amount of deposit", size(medsmall)) ///
		ylabel(, format(%15.0fc)) ///
		title("In your last transaction with{bf: a non-BM Agent}, how much did you{bf: deposit} (thousand)?", size(medsmall)) ///
		subtitle(" ", size(medsmall)) ///
		text(`r(p50)' 95 "Median=`=string(`median_rounded', "%15.0gc")'", size(vsmall)) ///
		text(`r(p75)' 95 "Q3=`=string(`Q_3_rounded', "%15.0gc")'", size(vsmall)) ///
		text(`r(p25)' 95 "Q1=`=string(`Q_1_rounded', "%15.0gc")'", size(vsmall)) ///
		text(`r(mean)' 95 "Mean=`=string(`mean_rounded', "%15.0gc")'", size(vsmall)) ///
		note("Note:" "Total clients = `: di %6.0fc `r(N)''" "Outlier threshold = `=string(`ll', "%15.0gc")' (lower) and `=string(`ul', "%15.0gc")' (upper)" "Dropped outlier observation = `dropped_obs'" "The sumstat value is rounded to the nearest value of 100", size(small))		
	graph export "$output/03 client_midline/Client Midline - `date'/11 - client_q_1b_2_boxplot.png", as(png) replace

	restore
	*q_1b_3
	preserve

	destring q_1b_3, replace
	drop if q_1b_3 == .
	qui summarize q_1b_3, detail
	return list
	local total_before = r(N)

	** Detect and drop outlier(s)
	generate iqr = r(p75) - r(p25)
	generate lower_limit = r(p25) - 1.5 * iqr
	generate upper_limit = r(p75) + 1.5 * iqr
	generate outlier = (q_1b_3 < lower_limit) | (q_1b_3 > upper_limit)
	drop if outlier == 1

	** Store obs number after dropping outlier(s) and compute the difference
	qui summarize q_1b_3, detail
	local total_after = r(N)
	local dropped_obs = `total_before' - `total_after'
	
	** Store lower and upper threshold
	qui su lower_limit, det
	local ll = round(`r(mean)', 1)
	qui su upper_limit, det
	local ul = round(`r(mean)', 1)
	
	* Histogram
	set scheme plotplain

	histogram q_1b_3, discrete percent color(navy) ///
		xlabel(0(1)12) ///
		ylabel(0(5)25) ///
		xtitle("Number of deposit", size(medsmall)) ///
		ytitle("Percentage (%) of clients", size(medsmall)) ///
		title("Over {bf:the last 3 months}, how many deposits have you made", size(medsmall)) ///
		subtitle("with {bf:a non-BM Agent}?", size(medsmall)) ///
		note("Note:" "Total clients = `: di %6.0fc `r(N)''" "Outlier threshold = `ll' (lower) and `ul' (upper)" ///
		"Dropped outlier observation = `dropped_obs'", size(medsmall))
	
	graph export "$output/03 client_midline/Client Midline - `date'/12 - client_q_1b_2_hist.png", as(png) replace

	* Box plot
	set scheme plotplain
	qui su q_1b_3, det
	return list
	local mean_rounded = round(`r(mean)', 1)	
	local Q_1_rounded = round(`r(p25)', 1)
	local Q_3_rounded = round(`r(p75)', 1)
	local median_rounded = round(`r(p50)', 1)

	graph box q_1b_3, box(1, fcolor(navy*0.75) lcolor(navy*0.75)) yline(`r(mean)', lpattern(.) lcolor(navy*0.75)) ///
		ytitle("Number of deposit", size(medsmall)) ///
		title("Over {bf:the last 3 months}, how many deposits have you made", size(medsmall)) ///
		subtitle("with {bf:a non-BM Agent}?", size(medsmall)) ///
		text(`r(p50)' 95 "Median=`median_rounded'", size(vsmall)) ///
		text(`r(p75)' 95 "Q3=`Q_3_rounded'", size(vsmall)) ///
		text(`r(p25)' 95 "Q1=`Q_1_rounded'", size(vsmall)) ///
		text(`r(mean)' 95 "Mean=`mean_rounded'", size(vsmall)) ///
		note("Note:" "Total clients = `: di %6.0fc `r(N)''" "Outlier threshold = `ll' (lower) and `ul' (upper)" /// 
		"Dropped outlier observation = `dropped_obs'", size(medsmall))
	
	graph export "$output/03 client_midline/Client Midline - `date'/13 - client_q_1b_3_boxplot.png", as(png) replace

***# SECTION 2: Last Cash Withdrawal Transaction #***

	restore
	*q_2a
	preserve

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
	graph export "$output/03 client_midline/Client Midline - `date'/14 - client_q_2a.png", as(png) replace

	restore
	*q_2a_1
	preserve

	destring q_2a_1, replace
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
	graph export "$output/03 client_midline/Client Midline - `date'/15 - client_q_2a_1_hist.png", as(png) replace

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
		note("Note:" "Total clients = `: di %6.0fc `r(N)''" "Outlier threshold = `=string(`ll', "%15.0gc")' (lower) and `=string(`ul', "%15.0gc")' (upper)" ///
			"Dropped outlier observation = `dropped_obs'" "The sumstat value is rounded to the nearest value of 1,000", size(medsmall))
	graph export "$output/03 client_midline/Client Midline - `date'/16 - client_q_2a_1_boxplot.png", as(png) replace

	restore
	*q_2a_2
	preserve

	destring q_2a_2, replace
	drop if q_2a_2 == .
	qui summarize q_2a_2, detail
	return list
	local total_before = r(N)

	*Detect and drop outlier(s)
	generate iqr = r(p75) - r(p25)
	generate lower_limit = r(p25) - 1.5 * iqr
	generate upper_limit = r(p75) + 1.5 * iqr
	generate outlier = (q_2a_2 < lower_limit) | (q_2a_2 > upper_limit)
	drop if outlier == 1

	*Store obs number after dropping outlier(s) and compute the difference
	qui summarize q_2a_2, detail
	local total_after = r(N)
	local dropped_obs = `total_before' - `total_after'

	** Store lower and upper threshold
	qui su lower_limit, det
	local ll = round(`r(mean)', 100)
	qui su upper_limit, det
	local ul = round(`r(mean)', 100)
	
	set scheme plotplain
	
	histogram q_2a_2, percent color(maroon) ///
		xlabel(0(1000)9000) ///
		ylabel(0(5)40) ///
		xlabel(, format(%15.0fc)) ///
		xtitle("Transaction fee", size(medsmall)) ///
		ytitle("Percentage (%) of clients", size(medsmall)) ///
		title("What was the{bf: transaction fee} charged by{bf: BM Agent}", size(medsmall)) ///
		subtitle("you use the last time you made{bf: a cash withdrawal}?", size(medsmall)) ///
		note("Note:" "Total clients = `: di %6.0fc `r(N)''" "Outlier threshold = `=string(`ll', "%15.0gc")' (lower) and `=string(`ul', "%15.0gc")' (upper)" ///
			"Dropped outlier observation = `dropped_obs'", size(small))
	graph export "$output/03 client_midline/Client Midline - `date'/17 - client_q_2a_2_hist.png", as(png) replace

	** -- Boxplot
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
		note("Note:" "Total clients = `: di %6.0fc `r(N)''" "Outlier threshold = `=string(`ll', "%15.0gc")' (lower) and `=string(`ul', "%15.0gc")' (upper)" ///
			"Dropped outlier observation = `dropped_obs'" "The sumstat value is rounded to the nearest value of 100", size(small))
	graph export "$output/03 client_midline/Client Midline - `date'/18 - client_q_2a_2_boxplot.png", as(png) replace

	restore
	*q_2a_3
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
	graph export "$output/03 client_midline/Client Midline - `date'/19 - client_q_2a_3.png", as(png) replace

	restore
	*q_2a_4
	preserve

	destring q_2a_4
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
		note("Note:" "Total clients = `: di %6.0fc `r(N)''" "Outlier threshold = `ll' (lower) and `ul' (upper)" ///
			"Dropped outlier observation = `dropped_obs'", size(small))
	graph export "$output/03 client_midline/Client Midline - `date'/20 - client_q_2a_4_hist.png", as(png) replace

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
		note("Note:" "Total clients = `: di %6.0fc `r(N)''" "Outlier threshold = `ll' (lower) and `ul' (upper)" ///
			"Dropped outlier observation = `dropped_obs'", size(small))
	graph export "$output/03 client_midline/Client Midline - `date'/21 - client_q_2a_4_boxplot.png", as(png) replace

	restore
	*q_2b
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
	graph export "$output/03 client_midline/Client Midline - `date'/22 - client_q_2b.png", as(png) replace

	restore
	*q_2b_1
	preserve

	destring q_2b_1, replace
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
		note("Note:" "Total clients = `: di %6.0fc `r(N)''" "Outlier threshold = `=string(`ll', "%15.0gc")' (lower) and `=string(`ul', "%15.0gc")' (upper)" ///
			"Dropped outlier observation = `dropped_obs'" "The sumstat value is rounded to the nearest value of 1,000", size(small))
	graph export "$output/03 client_midline/Client Midline - `date'/23 - client_q_2b_1_hist.png", as(png) replace

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
	note("Note:" "Total clients = `: di %6.0fc `r(N)''" "Outlier threshold = `=string(`ll', "%15.0gc")' (lower) and `=string(`ul', "%15.0gc")' (upper)" ///
		"Dropped outlier observation = `dropped_obs'" "The sumstat value is rounded to the nearest value of 1,000", size(small))
	graph export "$output/03 client_midline/Client Midline - `date'/24 - client_q_2b_1_boxplot.png", as(png) replace

	restore
	*q_2b_2
	preserve

	destring q_2b_2, replace
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
		note("Note:" "Total clients = `: di %6.0fc `r(N)''" "Outlier threshold = `ll' (lower) and `ul' (upper)" ///
			"Dropped outlier observation = `dropped_obs'", size(small))
	graph export "$output/03 client_midline/Client Midline - `date'/25 - client_q_2b_2_hist.png", as(png) replace

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
		note("Note:" "Total clients = `: di %6.0fc `r(N)''" "Outlier threshold = `ll' (lower) and `ul' (upper)" ///
			"Dropped outlier observation = `dropped_obs'", size(medsmall))
	graph export "$output/03 client_midline/Client Midline - `date'/26 - client_q_2b_2_boxplot.png", as(png) replace

***# SECTION 3: Trust BM and Agent #***
	
	restore
	*q_3a_*
	preserve

	keep unique_code_client q_3a_*
	drop if q_3a_1 == .

	gen num = _n
	qui count
	local obs3a = r(N)

	reshape long q_3a_, i(unique_code_client num) j(item)

	label define item ///
	1 "Banks" ///
	2 "Bank Mandiri" ///
	3 "BM Agent" ///
	4 "BM Agent will give best price"

	label values item item

	tab q_3a_, gen(answer)

	set scheme jpalfull

	graph hbar (sum) answer*, stack percentage ///
	    over(item, label(angle(0) labsize(small))) ///
	    ytitle("Percentage (%) of clients", size(medsmall)) ///
	    ylabel(0(20)100) ///
	    blabel(bar, pos(center) size(vsmall) format(%15.1fc)) ///
	    title("Views regarding {bf:BM Agent} and {bf:Bank Mandiri}", size(medsmall)) ///
	    legend(order(1 "A great deal of confidence" ///
	                 2 "Quite a lot of confidence" ///
	                 3 "Not very much confidence" ///
	                 4 "No confidence at all") ///
	           size(small) col(2)) ///
	    note("Note:" "Total clients = `: di %6.0fc `obs3a''", size(small))

	graph export "$output/03 client_midline/Client Midline - `date'/32 - client_q_3a.png", as(png) replace

***# SECTION 4: Belief About Banks versus Agents #***

	restore
	*q_4a_*
	preserve
	
	keep unique_code_client q_4a_1 q_4a_2 q_4a_3 q_4a_4 q_4a_5 q_4a_6
	drop if q_4a_1 == .

	local st4 = 1
	foreach a of varlist q_4a_1 q_4a_2 q_4a_3 q_4a_4 q_4a_5 q_4a_6 {
		rename `a' q_4_`st4'
		local st4 = `st4' + 1
	}

	gen num = _n
	qui sum num
	local obs4 = `r(N)'
	reshape long q_4_, i(unique_code_client num) j(q_4)

	la def q_4 ///
	1 "Honest and trustworthy" ///
	2 "Cust well-being above profits" ///
	3 "Treats all equally well" ///
	4 "Transparent about pricing" ///
	5 "Does his/her job well" ///
	6 "Offers reliable service"
	la val q_4 q_4

	tab q_8_, gen(answer)
	set scheme jpalfull
	
	graph hbar (sum) answer*, stack percentage over(q_4, label(labsize(vsmall))) ///
		title("Do you agree with each of the following statements about ", size(medsmall)) ///
		subtitle("{bf:BM Agent}?", size(medsmall)) ///
		legend(order(1 "Strongly disagree" 2 "Disagree" 3 "Agree" 4 "Strongly agree") size(small) col(2)) ///
		note("Note:" "Total clients = `: di %6.0fc `obs8''", size(small)) ///
		ytitle("Percentage (%) of clients", size(small) orientation(horizontal)) ///
		ylabel(0(25)100) ///
		blabel(bar, pos(center) size(vsmall) format(%15.1fc)) 
	graph export "$output/03 client_midline/Client Midline - `date'/33 - client_q_4.png", as(png) replace

	restore
	*q_4b_*
	preserve

	keep unique_code_client q_4b_1 q_4b_2 q_4b_3 q_4b_4 q_4b_5 q_4b_6
	drop if q_4b_1 == .
	local st4b = 1
	foreach a of varlist q_4b_1 q_4b_2 q_4b_3 q_4b_4 q_4b_5 q_4b_6 {
		rename `a' q_4b_`st4b'
		local st4b = `st4b' + 1
	}

	gen num = _n
	qui sum num
	local obs4b = `r(N)'
	reshape long q_4b_, i(unique_code_client num) j(q_4b)

	la def q_4b ///
	1 "Honest and trustworthy" ///
	2 "Cust well-being above profits" ///
	3 "Treats all equally well" ///
	4 "Transparent about pricing" ///
	5 "Does his/her job well" ///
	6 "Offers reliable service"
	la val q_4b q_4b

	tab q_4b_, gen(answer)
	set scheme jpalfull

	graph hbar (sum) answer*, stack percentage over(q_4b, label(labsize(vsmall))) ///
		title("Do you agree with each of the following statements about ", size(medsmall)) ///
		subtitle("{bf:Bank Mandiri}?", size(medsmall)) ///
		legend(order(1 "Strongly disagree" 2 "Disagree" 3 "Agree" 4 "Strongly agree") size(small) col(2)) ///
		note("Note:" "Total clients = `: di %6.0fc `obs4b''", size(small)) ///
		ytitle("Percentage (%) of clients", size(small) orientation(horizontal)) ///
		ylabel(0(25)100) ///
		blabel(bar, pos(center) size(vsmall) format(%15.1fc))
	graph export "$output/03 client_midline/Client Midline - `date'/34 - client_q_4b.png", as(png) replace

***# SECTION 5: Agent Effort #***

	restore
	*q_5a
	preserve

	drop if q_5a == .
	forval x = 1/3 {
		gen gr_5a_`x' = 1 if q_5a == `x'
		recode gr_5a_`x' (. = 0)
		replace gr_5a_`x' = . if q_5a == .
	}

	set scheme jpalfull
	qui sum clients_n

	graph bar gr_5a_*, percentages /// percent is the default
		ytitle("Percentage (%) of clients", size(medsmall) orientation(vertical)) ///
		ylabel(0(10)50) ///
		blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
		title("How much time do you think your branchless banking agent spent", size(medsmall)) ///
		subtitle("advertising her branchless banking services to people in the village?", size(medsmall)) ///
		legend(order(1 "None at all" 2 "Some time" 3 "A lot of time") size(vsmall) col(1)) ///
		note("Total clients = `: di %6.0fc `r(N)''", size(small))
	graph export "$output/03 client_midline/Client Midline - `date'/35 - client_q_5a.png", as(png) replace

	restore
	*q_5b
	preserve

	drop if q_5b == .
	forval x = 1/4 {
		gen gr_5b_`x' = 1 if q_5b == `x'
		recode gr_5b_`x' (. = 0)
		replace gr_5b_`x' = . if q_5b == .
	}

	set scheme jpalfull
	qui sum clients_n

	graph bar gr_5b_*, percentages /// percent is the default
		ytitle("Percentage (%) of clients", size(medsmall) orientation(vertical)) ///
		ylabel(0(10)50) ///
		blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
		title("Do you agree with this statement “over the last month, the BM agent did absolutely all she/he", size(small)) ///
		subtitle("could to convince people in the village to adopt Branchless banking products?", size(small)) ///
		legend(order(1 "None at all" 2 "Some time" 3 "A lot of time" 4 "I don't know") size(vsmall) col(1)) ///
		note("Total clients = `: di %6.0fc `r(N)''", size(small))
	graph export "$output/03 client_midline/Client Midline - `date'/36 - client_q_5b.png", as(png) replace

	restore
	*q_5c
	preserve

	drop if q_5c == .
	forval x = 1/6 {
		gen gr_5c_`x' = 1 if q_5c == `x'
		recode gr_5c_`x' (. = 0)
		replace gr_5c_`x' = . if q_5c == .
	}

	set scheme jpalfull
	qui sum clients_n

	graph bar gr_5c_*, percentages /// percent is the default
		ytitle("Percentage (%) of clients", size(medsmall) orientation(vertical)) ///
		ylabel(0(10)50) ///
		blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
		title("In the last month, has the agent approached you", size(small)) ///
		subtitle("to encourage you to do more branchless banking transactions? ", size(small)) ///
		legend(order(1 "Every day" 2 "A few times a week" 3 "Once a week" 4 "A few times per month" 5 "Once a month" 6 "Not at all") size(vsmall) col(2)) ///
		note("Total clients = `: di %6.0fc `r(N)''", size(small))
	graph export "$output/03 client_midline/Client Midline - `date'/37 - client_q_5c.png", as(png) replace

	restore
	*q_5d
	preserve

	drop if q_5d == .
	forval x = 1/6 {
		gen gr_5d_`x' = 1 if q_5d == `x'
		recode gr_5d_`x' (. = 0)
		replace gr_5d_`x' = . if q_5d == .
	}

	set scheme jpalfull
	qui sum clients_n

	graph bar gr_5d_*, percentages /// percent is the default
		ytitle("Percentage (%) of clients", size(medsmall) orientation(vertical)) ///
		ylabel(0(10)50) ///
		blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
		title("In the last month, has the agent approached you to encourage you", size(small)) ///
		subtitle("to adopt new bank mandiri financial products?", size(small)) ///
		legend(order(1 "Every day" 2 "A few times a week" 3 "Once a week" 4 "A few times per month" 5 "Once a month" 6 "Not at all") size(vsmall) col(2)) ///
		note("Total clients = `: di %6.0fc `r(N)''", size(small))
	graph export "$output/03 client_midline/Client Midline - `date'/38 - client_q_5d.png", as(png) replace

	restore
	*q_5e
	preserve

	drop if q_5e == .
	forval x = 0/1 {
		gen gr_5e_`x' = 1 if q_5e == `x'
		recode gr_5e_`x' (. = 0)
		replace gr_5e_`x' = . if q_5e == .
	}

	set scheme jpalfull
	qui sum clients_n

	graph bar gr_5e_*, percentages /// percent is the default
		ytitle("Percentage (%) of clients", size(medsmall) orientation(vertical)) ///
		ylabel(0(10)50) ///
		blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
		title("In the last month, has the agent approached you", size(small)) ///
		subtitle("with new information about prices for BM transactions?", size(small)) ///
		legend(order(0 "No" 1 "Yes") size(vsmall) col(2)) ///
		note("Total clients = `: di %6.0fc `r(N)''", size(small))
	graph export "$output/03 client_midline/Client Midline - `date'/39 - client_q_5e.png", as(png) replace

***# SECTION 6: Price Transparency #***

	restore
	*q_6a_1
	preserve

	drop if q_6a_1 == .
	forval x = 1/5 {
		gen gr_6a_1_`x' = 1 if q_6a_1 == `x'
		recode gr_6a_1_`x' (. = 0)
		replace gr_6a_1_`x' = . if q_6a_1 == .
	}

	set scheme jpalfull
	qui sum clients_n

	graph bar gr_6a_1_*, percentages /// percent is the default
		ytitle("Percentage (%) of clients", size(medsmall) orientation(vertical)) ///
		ylabel(0(10)50) ///
		blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
		title("Branchless banking agents charge a fee for each transaction made with them", size(medsmall)) ///
		subtitle("How do you think these fees are set?", size(medsmall)) ///
		legend(order(1 "There is an official price set by the bank and the agent has to stick to that price," ///
					2 "There is an official price set by the bank, but the agent can charge more or less than this price " ///
					3 "There is no official price and the agent can decide what price to charge" ///
					4 "The government or banking regulator sets the prices" ///
					5 "Never") size(vsmall) col(1)) ///
		note("Total clients = `: di %6.0fc `r(N)''", size(small))
	graph export "$output/03 client_midline/Client Midline - `date'/40 - client_q_6a_1.png", as(png) replace

	restore
	*q_6a_2
	preserve

	drop if q_6a_2 == .
	forval x = 1/3 {
		gen gr_6a_2_`x' = 1 if q_6a_2 == `x'
		recode gr_6a_2_`x' (. = 0)
		replace gr_6a_2_`x' = . if q_6a_2 == .
	}

	set scheme jpalfull
	qui sum clients_n

	graph bar gr_6a_2_*, percentages /// percent is the default
		ytitle("Percentage (%) of clients", size(medsmall) orientation(vertical)) ///
		ylabel(0(10)50) ///
		blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
		title("Branchless banking agents charge a fee for each transaction made with them", size(medsmall)) ///
		subtitle("Do you think the fees charged by your agent are fair?", size(medsmall)) ///
		legend(order(1 "More" 2 "Less" 3 "It depends on the client") size(vsmall) col(1)) ///
		note("Total clients = `: di %6.0fc `r(N)''", size(small))
	graph export "$output/03 client_midline/Client Midline - `date'/41 - client_q_6a_2.png", as(png) replace

	restore
	*q_6b
	preserve

	drop if q_6b == .
	forval x = 0/1 {
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
		title("Does your current, most frequent Mandiri Agen", size(medsmall)) ///
		subtitle("{bf:display} a list of prices for transactions at her shop?", size(medsmall)) ///
		legend(order(0 "No" 1 "Yes") size(vsmall) col(2)) ///
		note("Total clients = `: di %6.0fc `r(N)''", size(small))
	graph export "$output/03 client_midline/Client Midline - `date'/42 - client_q_6b.png", as(png) replace

	restore
	*q_6c
	preserve

	drop if q_6c == .
	forval x = 0/1 {
		gen gr_6c_`x' = 1 if q_6c == `x'
		recode gr_6c_`x' (. = 0)
		replace gr_6c_`x' = . if q_6c == .
	}

	set scheme jpalfull
	qui sum clients_n

	graph bar gr_6c_*, percentages /// percent is the default
		ytitle("Percentage (%) of clients", size(medsmall) orientation(vertical)) ///
		ylabel(0(10)50) ///
		blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
		title("Does you agent set the same price for everyone or not?", size(medsmall)) ///
		subtitle(" ", size(medsmall)) ///
		legend(order(0 "No" 1 "Yes") size(vsmall) col(2)) ///
		note("Total clients = `: di %6.0fc `r(N)''", size(small))
	graph export "$output/03 client_midline/Client Midline - `date'/43 - client_q_6c.png", as(png) replace

	restore
	*q_6c_1
	preserve

	forval y = 1/7 {
	        gen q_6c_1_new_`y' = ///
            q_6c_1_1_1==`y' | ///
	        q_6c_1_1_2==`y' | ///
            q_6c_1_1_3==`y'
    }

    set scheme jpalfull
    qui sum agents_n if q_6c_1_new_1 !=.

    graph bar q_6c_1_new_*, percentages ///
            ytitle("%", size(small)) ///
            ylabel(, labsize(small)) ///
            blabel(bar, pos(center) size(vsmall) format(%15.1fc)) ///
            title("Type of client charge with low fees?", size(medsmall)) ///
            legend(order(1 "Friends and Family" 2 "High-value customers" 3 "New customers" 4 "Long-term customers" ///
						5 "Lower-income customers" 6 "Local customers" 7 "Can switch agents") ///
            size(small) col(3)) ///
            note("Total agents = `: di %6.0fc `r(N)''", size(medsmall))
    graph export "$output/04 agent_endline/Client Midline - `date'/1 - q_6c_1.png", as(png) replace

***# SECTION 7: Latest Transaction Experience with BM Agent #***

	restore
	*q_7a
	preserve

	
	destring q_7a, replace
	drop if q_7a == .
	qui summarize q_7a, detail
	return list
	local total_before = r(N)

	** Detect and drop outlier(s)
	generate iqr = r(p75) - r(p25)
	generate lower_limit = 0
	generate upper_limit = r(p75) + 1.5 * iqr
	generate outlier = (q_7a < lower_limit) | (q_7a > upper_limit)
	drop if outlier == 1

	** Store obs number after dropping outlier(s) and compute the difference
	qui summarize q_7a, detail
	local total_after = r(N)
	local dropped_obs = `total_before' - `total_after'
	
	** Store lower and upper threshold
	qui su lower_limit, det
	local ll = round(`r(mean)', 1)
	qui su upper_limit, det
	local ul = round(`r(mean)', 1)

	* Histogram
	set scheme plotplain

	histogram q_7a, percent color(chocolate*0.95) ///
		discrete ///
		xlabel(0(1)10) ///
		ylabel(0(5)40) ///
		xtitle("Satisfaction level", size(medsmall)) ///
		ytitle("Percentage (%) of clients", size(medsmall)) ///
		title("For the latest transaction you did with your {bf:BM Agent},", size(medsmall)) ///
		subtitle("on a scale of 1 to 10, {bf:how satisfied} were you with the service?", size(medsmall)) ///
		note("Note:" "Total clients = `: di %6.0fc `r(N)''" "Outlier threshold = `ll' (lower) and `ul' (upper)" "Dropped outlier observation = `dropped_obs'", size(medsmall))
	
	graph export "$output/03 client_midline/Client Midline - `date'/26 - client_q_7a_hist.png", as(png) replace

	restore
	*q_7b
	preserve

	drop if q_7b == .
	forval x = 0/1 {
		gen gr_7b_`x' = 1 if q_7b == `x'
		recode gr_7b_`x' (. = 0)
		replace gr_7b_`x' = . if q_7b == .
	}

	set scheme jpalfull
	qui sum clients_n

	graph bar gr_7b_*, percentages /// percent is the default
		ytitle("Percentage (%) of clients", size(medsmall) orientation(vertical)) ///
		ylabel(0(10)50) ///
		blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
		title("Was the agent present when you first attempted the transaction?", size(medsmall)) ///
		subtitle(" ", size(medsmall)) ///
		legend(order(0 "No, agent was not present and i had to come back" 1 "Yes, agent was present and helped me") size(vsmall) col(1)) ///
		note("Total clients = `: di %6.0fc `r(N)''", size(small))
	graph export "$output/03 client_midline/Client Midline - `date'/27 - client_q_7b.png", as(png) replace

	restore
	*q_7c
	preserve

	drop if q_7c == .
	forval x = 0/1 {
		gen gr_7c_`x' = 1 if q_7c == `x'
		recode gr_7c_`x' (. = 0)
		replace gr_7c_`x' = . if q_7c == .
	}

	set scheme jpalfull
	qui sum clients_n

	graph bar gr_7c_*, percentages /// percent is the default
		ytitle("Percentage (%) of clients", size(medsmall) orientation(vertical)) ///
		ylabel(0(10)50) ///
		blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
		title("Did you have to come back another day to complete the transaction?", size(medsmall)) ///
		subtitle(" ", size(medsmall)) ///
		legend(order(0 "No" 1 "Yes") size(vsmall) col(2)) ///
		note("Total clients = `: di %6.0fc `r(N)''", size(small))
	graph export "$output/03 client_midline/Client Midline - `date'/28 - client_q_7c.png", as(png) replace
	
	restore
	*q_7d
	preserve

	drop if q_7d == .
	forval x = 1/5 {
		gen gr_7d_`x' = 1 if q_7d == `x'
		recode gr_7d_`x' (. = 0)
		replace gr_7d_`x' = . if q_7d == .
	}

	set scheme jpalfull
	qui sum clients_n

	graph bar gr_7d_*, percentages /// percent is the default
		ytitle("Percentage (%) of clients", size(medsmall) orientation(vertical)) ///
		ylabel(0(10)50) ///
		blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
		title("How long did you have to wait at the agent until your transaction was processed?", size(medsmall)) ///
		subtitle(" ", size(medsmall)) ///
		legend(order(1 "There was no wait time, agent helped me right away" 2 "5-10 minutes" 3 "10-15 minutes" ///
					4 "15-30 minutes" 5 "30-45 minutes") size(vsmall) col(2)) ///
		note("Total clients = `: di %6.0fc `r(N)''", size(small))
	graph export "$output/03 client_midline/Client Midline - `date'/29 - client_q_7d.png", as(png) replace

	restore
	*q_7e
	preserve

	drop if q_7e == .
	forval x = 1/4 {
		gen gr_7e_`x' = 1 if q_7e == `x'
		recode gr_7e_`x' (. = 0)
		replace gr_7e_`x' = . if q_7e == .
	}

	set scheme jpalfull
	qui sum clients_n

	graph bar gr_7e_*, percentages /// percent is the default
		ytitle("Percentage (%) of clients", size(medsmall) orientation(vertical)) ///
		ylabel(0(10)50) ///
		blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
		title("How many times did you have to visit the agent", size(medsmall)) ///
		subtitle("until the transaction you wanted to make was successful?", size(medsmall)) ///
		legend(order(1 "Transaction was processed on first visit" 2 "2 times" 3 "3 times" 4 "4 times") size(vsmall) col(2)) ///
		note("Total clients = `: di %6.0fc `r(N)''", size(small))
	graph export "$output/03 client_midline/Client Midline - `date'/30 - client_q_7e.png", as(png) replace

	restore
	*q_7f
	preserve

	drop if q_7f == .
	forval x = 0/1 {
		gen gr_7f_`x' = 1 if q_7f == `x'
		recode gr_7f_`x' (. = 0)
		replace gr_7f_`x' = . if q_7f == .
	}

	set scheme jpalfull
	qui sum clients_n

	graph bar gr_7f_*, percentages /// percent is the default
		ytitle("Percentage (%) of clients", size(medsmall) orientation(vertical)) ///
		ylabel(0(10)50) ///
		blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
		title("Did the agent clearly tell you the amount of the fee", size(medsmall)) ///
		subtitle("they would charged in addition to the transaction amount?", size(medsmall)) ///
		legend(order(0 "No" 1 "Yes") size(vsmall) col(2)) ///
		note("Total clients = `: di %6.0fc `r(N)''", size(small))
	graph export "$output/03 client_midline/Client Midline - `date'/31 - client_q_7f.png", as(png) replace

***# SECTION 8: Important agent characteristic #***

	restore
	*q_8a
	preserve

	drop if q_8a_1_1 == .
	
	forval y = 1/10 {
		g q_8a_1_1_`y' = q_8a_1_1==`y' | q_8a_1_2==`y' | q_8a_1_3==`y'
		}
	
	set scheme jpalfull
	qui sum clients_n 

	graph bar q_8a_1_1_*, percentages ///
		ytitle("Percentage (%) of clients", size(small) orientation(vertical)) ylabel(0(5)20, labsize(small)) blabel(bar, pos(center) size(vsmall) format(%15.1fc)) ///
		title("Most important characteristics of an agent", size(medsmall)) ///
		subtitle("", size(medsmall)) ///
		legend(order(1 "Prior customer" 2 "Answers clearly" 3 "Close proximity" 4 "Sufficient cash" 5 "Price transparency" 6 "Always available" 7 "Lowest price" ///
					 8 "Bank-affiliated " 9 "Trusted agent" 10 "Same price for all") size(vsmall) col(3)) ///
		note("Total clients = `: di %6.0fc `r(N)''", size(small)) 
	graph export "$output/03 client_midline/Client Midline - `date'/27 - client_q_8a.png", as(png) replace

	restore
	*q_8b
	preserve

	drop if q_8b == . 
	forval x = 1/2 {
		gen gr_8b_`x' = 1 if q_8b == `x'
		recode gr_8b_`x' (. = 0)
		replace gr_8b_`x' = . if q_8b == .
	}

	set scheme jpalfull
	qui sum clients_n 

	graph bar gr_8b_*, percentages /// percent is the default
		ytitle("Percentage (%) of clients", size(medsmall) orientation(vertical)) ///
		ylabel(0(20)60) ///
		blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
		title("Which of the following statements do you {bf:agree with most}?", size(medsmall)) ///
		subtitle(" ", size(medsmall)) ///
		legend(order(1 "Continue doing business w/ regular agent, even if others offer lower prices" ///
		2 "Change to other agents who offer lower prices") size(small) col(1)) ///
		note("Total clients = `: di %6.0fc `r(N)''", size(small))
	graph export "$output/03 client_midline/Client Midline - `date'/28 - client_q_8b.png", as(png) replace

***# SECTION 9: Client Perception on Fairness #***

	restore
	*q_9a_1
	preserve

	drop if q_9a_1 == .
	forval x = 1/4 {
		gen gr_9a_1_`x' = 1 if q_9a_1 == `x'
		recode gr_9a_1_`x' (. = 0)
		replace gr_9a_1_`x' = . if q_9a_1 == .
	}

	set scheme jpalfull
	qui sum clients_n 

	graph bar gr_9a_1_*, percentages /// percent is the default
		ytitle("Percentage (%) of clients", size(medsmall) orientation(vertical)) ///
		ylabel(0(10)50) ///
		blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
		title("Client reaction to being overcharged – {bf:other client}", size(medsmall)) ///
		subtitle("How would you react?", size(medsmall)) ///
		legend(order(1 "Indifferent" 2 "Unfair, switch" 3 "Unfair, stay" 4 "Fair") size(small) col(4)) ///
		note("Total clients = `: di %6.0fc `r(N)''", size(small)) 
	graph export "$output/03 client_midline/Client Midline - `date'/29 -  client_q_9a_1.png", as(png) replace

	restore
	*q_9a_2
	preserve

	drop if q_9a_2 == . 
	forval x = 1/4 {
		gen gr_9a_2_`x' = 1 if q_9a_2 == `x'
		recode gr_9a_2_`x' (. = 0)
		replace gr_9a_2_`x' = . if q_9a_2 == .
	}

	set scheme jpalfull
	qui sum clients_n 
	
	graph bar gr_9a_2_*, percentages /// percent is the default
		ytitle("Percentage (%) of clients", size(medsmall) orientation(vertical)) ///
		ylabel(0(10)50) ///
		blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
		title("Client reaction to being overcharged – {bf:official fees}", size(medsmall)) ///
		subtitle("How would you react?", size(medsmall)) ///
		legend(order(1 "Indifferent" 2 "Unfair, switch" 3 "Unfair, stay" 4 "Fair") size(small) col(4)) ///
		note("Total clients = `: di %6.0fc `r(N)''", size(small)) 
	graph export "$output/03 client_midline/Client Midline - `date'/30 - client_q_9a_2.png", as(png) replace

	restore
	*q_9b
	preserve

	drop if q_9b == .
	forval x = 1/3 {
		gen gr_9b_`x' = 1 if q_9b == `x'
		recode gr_9b_`x' (. = 0)
		replace gr_9b_`x' = . if q_9b == .
	}

	set scheme jpalfull
	qui sum clients_n

	graph bar gr_9b_*, percentages /// percent is the default
		ytitle("Percentage (%) of clients", size(medsmall) orientation(vertical)) ///
		ylabel(0(10)50) ///
		blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
		title("Which agent would you prefer to regularly do transactions with?", size(medsmall)) ///
		subtitle("How would you react?", size(medsmall)) ///
		legend(order(1 " Agent A works for a bank that sets an official price of IRP3,000 and the agent follows that price." ///
					2 " Agent A works for a bank that sets an official price of IRP3,000 but he charges IRP 1,500." ///
					3 "Indifferent") size(small) col(1)) ///
		note("Total clients = `: di %6.0fc `r(N)''", size(small)) 
	graph export "$output/03 client_midline/Client Midline - `date'/31 - client_q_9b.png", as(png) replace

***# SECTION 10: Agent Competition #***

	restore
	*q_10a
	preserve

	drop if q_10a == .
	forval x = 1/2 {
		gen gr_10a_`x' = 1 if q_10a == `x'
		recode gr_10a_`x' (. = 0)
		replace gr_10a_`x' = . if q_10a == .
	}

	set scheme jpalfull
	qui sum clients_n

	graph bar gr_10a_*, percentages /// percent is the default
		ytitle("Percentage (%) of clients", size(medsmall) orientation(vertical)) ///
		ylabel(0(20)60) ///
		blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
		title("If another agent in your village offered lower prices than your regular agent, what would you do?", size(medsmall)) ///
		subtitle(" ", size(medsmall)) ///
		legend(order(1 "Many branchless banking agents in my area and I have a lot of options which one I want to use" ///
					2 "Limited branchless banking agents and I do not have many options which one I want to use") size(small) col(1)) ///
		note("Total clients = `: di %6.0fc `r(N)''", size(small))
	graph export "$output/03 client_midline/Client Midline - `date'/32 - client_q_10a.png", as(png) replace

	restore
	*q_10b
	preserve

	destring q_10b, replace
	drop if q_10b == .
	qui summarize q_10b, detail
	return list	
	local total_before = r(N)

	generate iqr = r(p75) - r(p25)
	generate lower_limit = r(p25) - 1.5 * iqr
	generate upper_limit = r(p75) + 1.5 * iqr
	generate outlier = (q_10b < lower_limit) | (q_10b > upper_limit)
	drop if outlier == 1

	** Store obs number after dropping outlier(s) and compute the difference
	qui summarize q_10b, detail
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
	graph export "$output/03 client_midline/Client Midline - `date'/44 - client_q_10b_hist.png", as(png) replace

***# SECTION 11: Transaction Profile with Agent #***

	restore
	*q_11a
	preserve

	local date : display %tdDNCY daily("$S_DATE", "DMY")
	capture shell mkdir -p "$output/Agent Baseline - `date'"
	
	drop if q_11a == .
	qui summarize q_11a, detail
	local total_after = r(N)
	set scheme plotplain

	histogram q_11a, percent color(emerald*0.95) ///
		discrete ///
		xlabel(2013(1)2025) ///
		ylabel(0(3)30) ///
		xtitle("Year", size(medsmall)) ///
		ytitle("Percentage (%) of clients", size(medsmall)) ///
		title("{bf:Since when} have you been doing transactions with your {bf:BM Agent}?", size(medsmall)) ///
		subtitle(" ", size(medsmall)) ///
		note("Total clients = `: di %6.0fc `r(N)''", size(small))
	graph export "$output/Client Baseline - `date'/46 - client_q_11a_hist.png", as(png) replace

	restore
	*q_11b
	preserve

	drop if q_11b == . 
	forval x = 1/4 {
		gen gr_11b_`x' = 1 if q_11b == `x'
		recode gr_11b_`x' (. = 0)
		replace gr_11b_`x' = . if q_11b == .
	}

	set scheme jpalfull
	qui sum clients_n 

	graph bar gr_11b_*, percentages /// percent is the default
		ytitle("Percentage (%) of clients", size(medsmall) orientation(vertical)) ///
		ylabel(0(5)40) ///
		blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
		title("{bf:For how long} have you known your {bf:BM Agent}?", size(medsmall)) ///
		subtitle(" ", size(medsmall)) ///
		legend(order(1 "A few months" 2 "For about a year" 3 "Between 1-5 years" 4 "Longer than 5 years") size(small) col(2)) ///
		note("Total clients = `: di %6.0fc `r(N)''", size(small))
	graph export "$output/Client Baseline - `date'/47 - client_q_11b.png", as(png) replace

	restore
	*q_11c
	preserve

	drop if q_11c == . 
	forval x = 1/8 {
		gen gr_11c_`x' = 1 if q_11c == `x'
		recode gr_11c_`x' (. = 0)
		replace gr_11c_`x' = . if q_11c == .
	}

	set scheme jpalfull
	qui sum clients_n 
	
	graph bar gr_11c_*, percentages /// percent is the default
		ytitle("Percentage (%) of clients", size(medsmall) orientation(vertical)) ///
		ylabel(0(10)40) ///
		blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
		title("How often do you {bf:talk} with your {bf:BM Agent}?", size(medsmall)) ///
		subtitle(" ", size(medsmall)) ///
		legend(order(1 "Every day" 2 "A few times a week" 3 "Once a week" 4 "A few times per month" 5 "Once a month" ///
		6 "Every 3 months" 7 "Every 6 months" 8 "Once a year") size(small) col(3)) ///
		note("Total clients = `: di %6.0fc `r(N)''", size(small)) 
	graph export "$output/Client Baseline - `date'/48 - client_q_11c.png", as(png) replace

	restore
	*q_11d
	preserve

	destring q_11d, replace
	drop if q_11d == .
	qui summarize q_11d, detail
	return list
	local total_before = r(N)

	** Detect and drop outlier(s)
	generate iqr = r(p75) - r(p25)
	generate lower_limit = r(p25) - 1.5 * iqr
	generate upper_limit = r(p75) + 1.5 * iqr
	generate outlier = (q_11d < lower_limit) | (q_11d > upper_limit)
	drop if outlier == 1

	** Store obs number after dropping outlier(s) and compute the difference
	qui summarize q_11d, detail
	local total_after = r(N)
	local dropped_obs = `total_before' - `total_after'

	** Store lower and upper threshold
	qui su lower_limit, det
	local ll = round(`r(mean)', 1)
	qui su upper_limit, det
	local ul = round(`r(mean)', 1)

	set scheme plotplain
	
	histogram q_11d, percent color(emerald*0.95) ///
		xlabel(0(10)100) ///
		ylabel(0(5)10) ///
		xtitle("Percentage of overall branchless banking transactions with BM Agent", size(medsmall)) ///
		ytitle("Percentage (%) of clients", size(medsmall)) ///
		title("What % {bf:of your overall branchless banking transactions}", size(medsmall)) ///
		subtitle("do you do with your {bf:BM Agent}?", size(medsmall)) ///
		note("Note:" "Total clients = `: di %6.0fc `r(N)''" "Outlier threshold = `ll' (lower) and `ul' (upper)" "Dropped outlier observation = `dropped_obs'", size(small))
	graph export "$output/03 client_midline/Client Midline - `date'/49 - q_11d_hist.png", as(png) replace

	* Box plot
	set scheme plotplain

	qui su q_11d, det
	return list
	
	local mean_rounded = round(`r(mean)', 1)	
	local Q_1_rounded = round(`r(p25)', 1)
	local Q_3_rounded = round(`r(p75)', 1)
	local median_rounded = round(`r(p50)', 1)

	graph box q_11d, box(1, fcolor(emerald*0.75) lcolor(emerald*0.75)) yline(`r(mean)', lpattern(.) lcolor(emerald*0.75)) ///
		ytitle("Percentage (%) of clients", size(medsmall)) ///
		title("What % {bf:of your overall branchless banking transactions}", size(medsmall)) ///
		subtitle("do you do with your {bf:BM Agent}?", size(medsmall)) ///
		text(`r(p50)' 95 "Median=`median_rounded'", size(vsmall)) ///
		text(`r(p75)' 95 "Q3=`Q_3_rounded'", size(vsmall)) ///
		text(`r(p25)' 95 "Q1=`Q_1_rounded'", size(vsmall)) ///
		text(`r(mean)' 95 "Mean=`mean_rounded'", size(vsmall)) ///
		note("Note:" "Total clients = `: di %6.0fc `r(N)''" "Outlier threshold = `ll' (lower) and `ul' (upper)" "Dropped outlier observation = `dropped_obs'", size(small))

	graph export "$output/Client Baseline - `date'/50 - client_q_11d_boxplot.png", as(png) replace

	restore
	*q_11e
	preserve

	drop if q_11e == .

	local x = 1
	forval nmr = 1/2 {
		gen gr_11e_`nmr' = 1 if q_11e == `x'
		recode gr_11e_`nmr' (. = 0)
		replace gr_11e_`nmr' = . if q_11e == .
		local x = `x' - 1
	}

	set scheme jpalfull
	qui sum clients_n  

	graph bar gr_11e_*, percentages /// percent is the default
		ytitle("Percentage (%) of clients", size(medsmall) orientation(vertical)) ///
		ylabel(0(25)100) ///
		blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
		title("Which of the following best describes your opinion about", size(medsmall)) ///
		subtitle("{bf:banking agents in general}?", size(medsmall)) ///
		legend(order(1 "Not honest and often overcharge customers" 2 "Honest and charge the correct prices") size(small) col(1)) ///
		note("Total clients = `: di %6.0fc `r(N)''", size(small)) 
	graph export "$output/Client Baseline - `date'/51 - client_q_11e.png", as(png) replace

	restore
	*q_11g
	preserve

	destring q_11g, replace
	drop if q_11g == .
	qui summarize q_11g, detail
	return list
	local total_before = r(N)

	** Detect and drop outlier(s)
	generate iqr = r(p75) - r(p25)
	generate lower_limit = r(p25) - 1.5 * iqr
	generate upper_limit = r(p75) + 1.5 * iqr
	generate outlier = (q_11g < lower_limit) | (q_11g > upper_limit)
	drop if outlier == 1
	
	** Store obs number after dropping outlier(s) and compute the difference
	qui summarize q_11g, detail
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
	graph export "$output/03 client_midline/Client Midline - `date'/52 - client_q_11g_hist.png", as(png) replace

	restore
	*q_11h
	preserve

	drop if q_11h == .
	forval x = 1/4 {
		gen gr_11h_`x' = 1 if q_11h == `x'
		recode gr_11h_`x' (. = 0)
		replace gr_11h_`x' = . if q_11h == .
	}

	set scheme jpalfull
	qui sum clients_n 
	
	graph bar gr_11h_*, percentages /// percent is the default
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
	graph export "$output/03 client_midline/Client Midline - `date'/54 - client_q_11h.png", as(png) replace

	restore
	*q_11i
	preserve

	drop if q_11i == .
	forval x = 0/1 {
		gen gr_11i_`x' = 1 if q_11i == `x'
		recode gr_11i_`x' (. = 0)
		replace gr_11i_`x' = . if q_11i == .
	}

	set scheme jpalfull
	qui sum clients_n

	graph bar gr_11i_*, percentages /// percent is the default
		ytitle("Percentage (%) of clients", size(medsmall) orientation(vertical)) ///
		ylabel(0(10)50) ///
		blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
		title("Do you use Mandiri Agen to send or receive business payments?", size(medsmall)) ///
		subtitle(" ", size(medsmall)) ///
		legend(order(0 "No" 1 "Yes") size(vsmall) col(2)) ///
		note("Total clients = `: di %6.0fc `r(N)''", size(small)) 
	graph export "$output/03 client_midline/Client Midline - `date'/55 - client_q_11i.png", as(png) replace

	restore
	*q_11j
	preserve

	drop if q_11j == .
	forval x = 0/1 {
		gen gr_11j_`x' = 1 if q_11j == `x'
		recode gr_11j_`x' (. = 0)
		replace gr_11j_`x' = . if q_11j == .
	}

	set scheme jpalfull
	qui sum clients_n

	graph bar gr_11j_*, percentages /// percent is the default
		ytitle("Percentage (%) of clients", size(medsmall) orientation(vertical)) ///
		ylabel(0(10)50) ///
		blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
		title("Do you use Mandiri Agen to receive salary payments?", size(medsmall)) ///
		subtitle(" ", size(medsmall)) ///
		legend(order(0 "No" 1 "Yes") size(vsmall) col(2)) ///
		note("Total clients = `: di %6.0fc `r(N)''", size(small)) 
	graph export "$output/03 client_midline/Client Midline - `date'/56 - client_q_11j.png", as(png) replace

	restore
	*q_12a
	preserve

	drop if q_12a == .
	forval x = 1/2 {
		gen gr_12a_`x' = 1 if q_12a == `x'
		recode gr_12a_`x' (. = 0)
		replace gr_12a_`x' = . if q_12a == .
	}

	set scheme jpalfull
	qui sum clients_n

	graph bar gr_12a_*, percentages /// percent is the default
		ytitle("Percentage (%) of clients", size(medsmall) orientation(vertical)) ///
		ylabel(0(20)60) ///
		blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
		title("Do you have other agents in your area that you can do transactions with?", size(medsmall)) ///
		subtitle(" ", size(medsmall)) ///
		legend(order(1 "Female" 2 "Male") size(vsmall) col(1)) ///
		note("Total clients = `: di %6.0fc `r(N)''", size(small)) 
	graph export "$output/03 client_midline/Client Midline - `date'/57 - client_q_12a.png", as(png) replace

	restore
	*q_12b
	preserve

	rename q_12b birthyear
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

	graph export "$output/03 client_midline/Client Midline - `date'/58 - client_birthyear_hist.png", as(png) replace
