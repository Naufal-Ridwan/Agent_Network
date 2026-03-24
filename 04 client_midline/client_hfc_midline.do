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
local date : di %tdDNCY daily("$S_DATE", "DMY") //this is the default code, it will automatically capture the current date
//local date "DDMMYYYY" // only use this manual setting if you're running this code late than the supposed day

*************
*IMPORT DATA*
*************

    use "$dta/03 client_midline/client_midline_24032026.dta", clear
    local date : display %tdDNCY daily("$S_DATE", "DMY")
    capture shell mkdir -p "$output/03 client_midline/Client Midline - `date'"

***************
*DATA ANALYSIS*
***************

    *checking no consent and number of responses
    gen clients_n = _n  // for notes on total N agents
    drop if informed_consent == "0" // drop people who refuse to participate in the survey

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
    graph export "$output/03 client_midline/Client Midline - `date'/4 - q_1a.png", as(png) replace

    *q_1a_1 -- Histogram
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
		note("Note:" "Total clients = `: di %6.0fc `r(N)''" "Outlier threshold = `=string(`ll', "%15.0gc")' (lower) and `=string(`ul', "%15.0gc")' (upper)" "Dropped outlier observation = `dropped_obs'", size(small)) 
	
	graph export "$output/03 client_midline/Client Midline - `date'/4 - q_1a_1.png", as(png) replace

    *q_1a_1 -- Boxplot
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

	graph export "$output/03 client_midline/Client Midline - `date'/4 - q_1a_1_boxplot.png", as(png) replace

    

    





        

