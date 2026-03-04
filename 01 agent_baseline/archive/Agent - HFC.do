*===================================================*
* Full-Scale - Agent Survey (Baseline)
* HFC
* Author: Riko
* Last modified: 17 August 2025
* Last modified by: Muthia
* Stata version: 16
*===================================================*

/*
Notes (Mon Sep 8):
1. tambahin GENERAL response rate without breakdown ke treatment arms
2. tambahin table buat response rate
3. Graph for breakdown finished and unfinished
4. bikin graph/table buat show di pertanyaan keberapa orang2 pada cabut (per section aja)

*/

clear all
set more off

*****************************************
**--------------DATA PATH--------------**
*****************************************
* Muthia
    gl path "/Users/auliamuthia/Desktop/J-PAL IFII Agent Banking Network (BM)/06 Data/c Full-Scale/06 Survey Data"

* Set the path
	gl do            "$path/dofiles/agent_baseline"
	gl dta           "$path/dtafiles"
	gl log           "$path/logfiles"
	gl output        "$path/output"
	gl raw           "$path/rawresponses/agent_baseline"
	
***IMPORTANT***

* Set local date
	loc date : di %tdDNCY daily("$S_DATE", "DMY") // this is the default code, it will automatically capture the current date
	shell mkdir "$output/Agent Baseline - `date'"
	

*************
*IMPORT DATA*
*************
	use "$dta/cleaned_baseline_agent_survey_03092025.dta", clear 	
	
*************
*HFC*
*************

*--------------------------------------------------------------------------
** Survey duration
*--------------------------------------------------------------------------
preserve

	sum total_duration

	qui su total_duration, det
	local total_before = r(N)

	keep if total_duration > 10  & total_duration < 120 // M: we only keep the durations above 10 minutes and below two hours just to keep those agents who take a break during filling out the questionaire

	qui su total_duration, detail
	return list

	local total_after = r(N)
	local dropped_obs = `total_before' - `total_after'

	* Boxplot
	set scheme jpalfull

	local mean_rounded = round(`r(mean)', 1)
	local Q_1_rounded = round(`r(p5)', 1)
	local Q_3_rounded = round(`r(p95)', 1)
	local median_rounded = round(`r(p50)', 1)

	graph box total_duration, yline(`r(mean)', lpattern(.)) ///
		ytitle("Survey duration (in minutes)", size(small)) ///
		title("Survey Duration (in minutes)", size(medsmall)) ///
		subtitle("Restricted to respondents who participate in the survey", size(medsmall)) ///
		text(`r(p50)' 95 "Median=`median_rounded'", size(vsmall)) ///
		text(`r(p95)' 95 "Q3=`Q_3_rounded'", size(vsmall)) ///
		text(`r(p5)' 95 "Q1=`Q_1_rounded'", size(vsmall)) ///
		text(`r(mean)' 95 "Mean=`mean_rounded'", size(vsmall)) ///
		note("Note:" "Total agents = `: di %6.0fc `r(N)''" "Survey duration above 100 minutes is dropped" "Number of dropped observations = `dropped_obs'", size(small))
		
	graph export "$output/Agent Baseline - `date'/1 - survey_duration_boxplot.png", as(png) replace

	* Histogram
	gen td_hist = round(total_duration, 1)
	qui sum td_hist,det
	*ssc install blindschemes // if plotplain error
	set scheme plotplain

	histogram td_hist, percent color("255 158 128") ///
		discrete ///
		xlabel(0(10)100) ///
		ylabel(0(5)30) ///
		xtitle(" ", size(small)) ///
		ytitle("Percentage of agents", size(small)) ///
		title("Survey Duration (in minutes)") ///
		subtitle("Restricted to respondents who participate in the survey") ///
		note("Note:" "Total agents = `: di %6.0fc `r(N)''" "Survey duration above 100 minutes is dropped" "Number of dropped observations = `dropped_obs'", size(small))
		
	graph export "$output/Agent Baseline - `date'/1 - survey_duration_hist.png", as(png) replace

restore


*--------------------------------------------------------------------------
** Overall Productivity  (no batch in data) + GENERAL response rate + Graph for breakdown finished and unfinished
*--------------------------------------------------------------------------
preserve

	* Build days_since
	bys treatment_status: egen launch = min(startdate)
	gen days_since = startdate - launch
	label var days_since "Days since launch of full scale RCT"

	* One row per unique_code × (treatment_status, days_since)
	egen byte tag = tag(unique_code treatment_status days_since)
	keep if tag

	* Ensure finished is numeric 0/1
	destring finished, replace force

	* Collapse to Arm × Day
	collapse (sum) N_daily = tag ///
			 (sum)   finished = finished, ///
			 by(treatment_status days_since)

	gen not_finished = N_daily - finished
	label var N_daily       "Daily responses (N)"
	label var finished      "Finished"
	label var not_finished  "Not finished"

	* Fill missing days and cumulative N
	sort treatment_status days_since
	xtset treatment_status days_since
	tsfill, full
	replace N_daily      = 0 if missing(N_daily)
	replace finished     = 0 if missing(finished)
	replace not_finished = 0 if missing(not_finished)
	bys treatment_status (days_since): gen N_cum = sum(N_daily)
	label var N_cum "Cumulative responses (N)"

	* Plots — robust for string or labeled-numeric treatment_status
	levelsof treatment_status, local(arms)

	local colors "red blue green orange purple"
	local cumplots ""
	local dayplots ""
	local legendorder ""
	local i 1
	foreach a of local arms {
		capture confirm string variable treatment_status
		if _rc {
			local lbl : label (treatment_status) `a'
			if "`lbl'"=="" local lbl = "Arm `a'"
			local cond treatment_status==`a'
		}
		else {
			local lbl "`a'"
			local cond treatment_status=="`a'"
		}

		local col : word `i' of `colors'
		local cumplots `cumplots' (connected N_cum  days_since if `cond', msymbol(o) msize(small) lcolor(`col') lwidth(medthick))
		local dayplots  `dayplots'  (connected N_daily days_since if `cond', msymbol(o) msize(small) lcolor(`col') lwidth(medthick))
		local legendorder `legendorder' `i' "`lbl'"
		local ++i
	}
	
	***# DAILY N plot
	twoway `dayplots', ///
		legend(order(`legendorder') cols(3) pos(6) ring(1)) ///
		ytitle("Responses per day (N)") xtitle("Days since launch of group") ///
		title("Daily Responses by Treatment") ///
		ylabel(, grid) ///
		xline(1 3 7 14 21, lpattern(dash) lcolor(gs12))
	graph export "$output/Agent Baseline - `date'/2 - daily_response_plot.png", as(png) replace
	
	***# CUMULATIVE N plot
	twoway `cumplots', ///
		legend(order(`legendorder') cols(3) pos(6) ring(1)) ///
		ytitle("Responses (N)") xtitle("Days since launch of group") ///
		title("Cumulative Responses by Treatment Arms") ///
		ylabel(, grid) ///
		xline(1 3 7 14 21, lpattern(dash) lcolor(gs12))
	graph export "$output/Agent Baseline - `date'/2 - cumulative_response_plot.png", as(png) replace

	***# DAILY N table
	capture confirm string variable treatment_status
	if _rc {
		decode treatment_status, gen(_treat_str)
	}
	else gen _treat_str = treatment_status

	sort _treat_str days_since
	gen str80 rowlab = trim(_treat_str) + " — Day " + string(days_since)
	
	* Label variables
	label var N_daily      "Total N (daily sum)"
	label var N_cum        "Total N (cumulative)"
	label var finished     "Total finished"
	label var not_finished "Total not finished"

	* Collect stats
	estpost tabstat N_daily N_cum finished not_finished, by(rowlab) statistics(sum) columns(statistics)

	* Export to LaTeX
	esttab using "$output/Agent Baseline - `date'/summary_breakdown_by_treatment_day.tex", ///
		cells("sum(fmt(%9.0f))") ///
		replace booktabs nonumber nomtitle noobs label ///
		title("Breakdown by Treatment and Day (Days since launch)") ///
		alignment(c) collabels(none)

	***# CUMULATIVE OVERALL N table
	bys treatment_status: egen N_cum_last = max(N_cum)
	collapse (sum) N_daily finished not_finished ///
			 (max) N_cum_last, by(treatment_status)

	label var N_daily      "Total N (daily sum)"
	label var N_cum_last   "Final N (cumulative)"
	label var finished     "Total finished"
	label var not_finished "Total not finished"

	* 1) Susun tabstat: variabel sebagai KOLOM, statistik (sum) sebagai baris
	estpost tabstat N_daily N_cum_last finished not_finished, ///
		by(treatment_status) statistics(sum) columns(variables)

	* 2) Export: unstack = jadikan tiap variabel sebagai kolom
	esttab using "$output/Agent Baseline - 04092025/summary_overall_by_treatment.tex", ///
		cells("sum(fmt(%9.0f))") ///
		unstack ///
		collabels("Total N (daily sum)" "Final N (cumulative)" "Total finished" "Total not finished") ///
		eqlabels(none) label noobs nonumber nomtitle booktabs replace alignment(c)


restore

*--------------------------------------------------------------------------
** Duplicates in unique_code
*--------------------------------------------------------------------------

	*Finding the number of duplicates in unique_code

	sort unique_code, stable
	qui by unique_code: gen dup = cond(_N==1,0,_n) // --duplicates tag `unique', gen(dup)-- would essentially work similarly but dup would be a binary 
		count if dup > 0 

	di "Surveys with duplicates:" 
	list unique_code `enum' startdate dup if dup > 0 & !missing(unique_code), sepby(unique_code) abbr(16)

	*isid `unique'  // This line should run successfully once all duplicates are fixed
	
*--------------------------------------------------------------------------
** Treatment arms distribution & outlier check
*--------------------------------------------------------------------------

	destring q_3b q_3d q_3e q_4c q_4d q_6 q_8b q_8c_1 q_9a, replace force
**# Summary table
	lab var q_3b   "Estd reduced rev if 50pc higher than official fees"
	lab var q_3d   "Estd reduced rev if 50pc higher to other customer"
	lab var q_3e   "Estd reduced rev if withdrawal fees increase 1,5K"
	lab var q_4c   "Estd reduced rev if new agent charges 50pc less"
	lab var q_4d   "Prior: Estd pc change in agent number"
	lab var q_6    "Posterior: Estd pc change in agent number"
	lab var q_8b   "Pc of rev from branchless banking last month"
	lab var q_8c_1 "Pc of rev from BM last month"
	lab var q_9a   "Number of agents in the area"

	*** Sumstat (general)
	eststo clear
	eststo a: estpost summarize ///
			q_3b q_3d q_3e q_4c q_4d q_6 q_8b q_8c_1 q_9a, detail
	esttab a using "$output/Agent Baseline - `date'/sumstat_overall.tex", replace ///
			tex cells("count(fmt(%13.0fc)) min(fmt(%13.0fc)) p1(fmt(%13.0fc)) p5(fmt(%13.0fc)) p25(fmt(%13.0fc)) p50(fmt(%13.0fc)) mean(fmt(%13.2fc)) p75(fmt(%13.0fc)) p95(fmt(%13.0fc)) p99(fmt(%13.0fc)) max(fmt(%13.0fc))") ///
			nonumber nomtitle noobs label collabels("N" "Min" "p1" "p5" "p25" "p50" "Mean" "p75" "p95" "p99" "Max") note("Note: pc refers to percent. Current date: `date'")
		
	*** Sumstat (by treatment groups)
	local num = 0
	local tgroups Pure_Control T1 T2 T3 T4

	forval t = 1/5 {
		local tgroup : word `t' of `tgroups'
		
		eststo clear
		eststo z: estpost summarize ///
				q_4d q_6 q_7a if treatment_status == `num', det
		esttab z using "$output/Agent Baseline - `date'/sumstat_by_treatment_groups_`tgroup'.tex", replace ///
				tex cells("count(fmt(%13.0fc)) min(fmt(%13.0fc)) p1(fmt(%13.0fc)) p5(fmt(%13.0fc)) p25(fmt(%13.0fc)) p50(fmt(%13.0fc)) mean(fmt(%13.2fc)) p75(fmt(%13.0fc)) p95(fmt(%13.0fc)) p99(fmt(%13.0fc)) max(fmt(%13.0fc))") ///
				nonumber nomtitle noobs label collabels("N" "Min" "p1" "p5" "p25" "p50" "Mean" "p75" "p95" "p99" "Max") title("Treatment Group: `tgroup'") note("Current date: `date'")
			
		local num = `num' + 1
	}

	
*--------------------------------------------------------------------------
** Number of distinct values
*--------------------------------------------------------------------------

// Pay attention to variables with very few distinct values. 
// Lack of variation in variables is an important flag to be raised and discussed with the PIs. 

*******NOTE: Focus ke pertanyaan awal2
preserve
	tempfile varsum
	capture postutil clear
	postfile H str64 varname uniq total using `varsum'

	foreach v of varlist _all {
		quietly tab `v'
		local uniq  = r(r)
		local total = r(N)
		* only post if we have observations
		if `total' > 0 post H ("`v'") (`uniq') (`total')
	}
	postclose H

	use `varsum', clear
	sort varname
	label var varname "Variable"
	label var uniq    "Unique values"
	label var total   "Total obs"

	* Export to LaTeX (requires estout)
	capture which esttab
	if _rc ssc install estout

	estpost tabstat uniq total, by(varname) statistics(mean) columns(statistics)
	esttab using "$output/Agent Baseline - 04092025/variable_uniques.tex", ///
		tex cells("mean(fmt(%9.0f))") ///
		replace booktabs nonumber nomtitle noobs label ///
		title("Unique Values and Observations per Variable")

restore

***************
*DATA ANALYSIS*
***************
	gen agents_n = _n  // for notes on total N agents
	drop if informed_consent == 0 // drop people who refuse to participate in the survey
	drop if responseid == "R_9e95c2yD7btS7SJ"

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
		ylabel(0(25)100) ///
		blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
		title("Banking agents charge {bf:a fee} for each transaction made with them.", size(medsmall)) ///
		subtitle("How do you {bf:set these fees}?", size(medsmall)) ///
		legend(order(1 "I follow the official list" 2 "I set my own prices") size(medsmall) col(2)) ///
		note("Total agents = `: di %6.0fc `r(N)''", size(medsmall))
		
	graph export "$output/Agent Baseline - `date'/3 - q_1a.png", as(png) replace

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
		ylabel(0(25)100) ///
		blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
		title("Do you charge {bf:all} clients {bf:the same fee}?", size(medsmall)) ///
		subtitle(" ", size(medsmall)) ///
		legend(order(1 "Yes" 2 "No") size(medsmall) col(2)) ///
		note("Total agents = `: di %6.0fc `r(N)''", size(medsmall))
		
	graph export "$output/Agent Baseline - `date'/4 - q_1b.png", as(png) replace

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
		ylabel(0(25)100) ///
		blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
		title("Do you have {bf:a specific type of customers} that you charge", size(medsmall)) ///
		subtitle("{bf:the lowest fees} from?", size(medsmall)) ///
		legend(order(1 "Yes" 2 "No") size(medsmall) col(2)) ///
		note("Total agents = `: di %6.0fc `r(N)''", size(medsmall))

	graph export "$output/Agent Baseline - `date'/4 - q_1b_1.png", as(png) replace

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

	graph bar gr_1c_*, percentages /// percent is the default
		ytitle("In percentage (%)", size(medsmall) orientation(vertical)) ///
		ylabel(0(25)100) ///
		blabel(bar, pos(top) size(small) format(%15.1fc)) ///
		title("How well do you think customers in your area are {bf:informed about}", size(small)) ///
		subtitle("{bf:the official fees} for transactions set by Bank Mandiri?", size(small)) ///
legend(order(1 "Most clients know the fees well" 2 "Most clients do not know the fees") ///
       size(small) rows(2) cols(1)) ///
	   note("Total agents = `: di %6.0fc `r(N)''", size(small))
		
	graph export "$output/Agent Baseline - `date'/5 - q_1c.png", as(png) replace

**# 2. Section 2 (WAIT FOR MARTIN'S FEEDBACK)
*** q_2a
	preserve

	keep unique_code q_2a_*
	drop q_2a_do
	drop if missing(q_2a_1)

	gen num = _n
	qui sum num
	local obs2a = `r(N)'

	reshape long q_2a_, i(unique_code) j(q_2a)

	la def q_2a ///
	1 "Client is a prior customer" ///
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

	graph hbar (sum) answer*, stack percentage over(q_2a, label(angle(0) labsize(small))) ///
		title("Important characteristics to be {bf:a regular customer}", size(medsmall)) ///
		subtitle(" ", size(medsmall)) ///
		legend(order(1 "Not important at all" 2 "Not very important" 3 "Important" 4 "Very important") size(small) col(2)) ///
		note("Total agents = `: di %6.0fc `obs2a''", size(medsmall)) ///
		ytitle("In percentage (%)", size(medsmall) orientation(horizontal)) ///
		ylabel(0(25)100) ///
		blabel(bar, pos(center) size(small) format(%15.1fc))
		
	graph export "$output/Agent Baseline - `date'/6 - q_2a.png", as(png) replace

	restore

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
		ytitle("In percentage (%)", size(small) orientation(vertical)) ///
		ylabel(, labsize(medsmall)) ///
		blabel(bar, pos(top) size(small) format(%15.1fc)) ///
		title("Client reaction if the agent charges {bf:50% higher than the official fees}", size(medsmall)) ///
		subtitle(" ", size(medsmall)) ///
		legend(order(1 "Indifferent" 2 "Unfair, and start transacting with another agent" 3 "Unfair, but would continue making transactions with the same agent" 4 "Fair") size(small) col(1)) ///
		note("Note:" "Total agents = `r(N)'", size(small))

	graph export "$output/Agent Baseline - `date'/7 - q_3a.png", as(png) replace

*** q_3b
preserve

    // Ensure numeric and drop missings
    destring q_3b, replace force
    drop if missing(q_3b)

    // Baseline stats
    quietly summarize q_3b, detail
    local N_before = r(N)

    // Tukey fences using Q1/Q3 (recommended)
    local q1  = r(p5)
    local q3  = r(p95)
    local iqr = `q3' - `q1'
    local ll  = `q1' - 1.5*`iqr'
    local ul  = `q3' + 1.5*`iqr'

    // Flag & drop outliers (using constants, not variables)
    generate byte outlier = (q_3b < `ll') | (q_3b > `ul')
    drop if outlier

    // After-drop stats
    quietly count
    local N_after   = r(N)
    local dropped_obs = `N_before' - `N_after'

    // Round thresholds for annotation
    local ll_round = round(`ll', 0.1)
    local ul_round = round(`ul', 0.1)
	
	set scheme jpalfull

    // Histogram
    histogram q_3b, percent color("255 158 128") ///
        discrete ///
        xlabel(0(5)100) ///
        ylabel(0(2)15) ///
        xtitle("% of reduced revenue", size(medsmall)) ///
        ytitle("Percentage of agents", size(medsmall)) ///
        title("{bf:Estimated agent reduced revenue}", size(medsmall)) ///
        subtitle("if the agent charges {bf:50% higher than the official fees}", size(medsmall)) ///
        note("Note:" ///
             "Total agents = `: di %6.0fc `N_after''" ///
             "Outlier threshold = `ll_round' (lower) and `ul_round' (upper)" ///
             "Dropped outlier observations = `dropped_obs'", size(small))

    graph export "$output/Agent Baseline - `date'/8 - q_3b_hist.png", as(png) replace

    // Box plot with readable annotations
    sum q_3b, detail
    local mean   = r(mean)
    local med    = r(p50)
    local q1p    = r(p5)
    local q3p    = r(p95)

    local mean_r = round(`mean', 0.1)
    local med_r  = round(`med', 0.1)
    local q1_r   = round(`q1p', 0.1)
    local q3_r   = round(`q3p', 0.1)
	
	set scheme jpalfull

    // Put text slightly to the right of the single box (x ~ 1)
	graph box q_3b, ///
		yline(`mean', lpattern(dash) lcolor(gs8)) ///
		ytitle("In percentage (%)", size(medsmall)) ///
		title("{bf:Estimated agent reduced revenue}", size(medsmall)) ///
		subtitle("if the agent charges {bf:50% higher than the official fees}", size(medsmall)) ///
		text(`med'  1.45 "Median = `med_r'",  size(vsmall)) ///
		text(`q3p'  1.45 "Q3 = `q3_r'",      size(vsmall)) ///
		text(`q1p'  1.45 "Q1 = `q1_r'",      size(vsmall)) ///
		text(`mean' 1.45 "Mean = `mean_r'",  size(vsmall)) ///
		note("Note:" ///
			 "Total agents = `: di %6.0fc `N_after''" ///
			 "Outlier threshold = `ll_round' (lower) and `ul_round' (upper)" ///
			 "Dropped outlier observations = `dropped_obs'", size(small))

    graph export "$output/Agent Baseline - `date'/8 - q_3b_boxplot.png", as(png) replace

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
		ylabel(0(25)100) ///
		blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
		title("Client reaction if the agent charges {bf:50% higher to another customer}", size(medsmall)) ///
		subtitle(" ", size(medsmall)) ///
		legend(order(1 "Indifferent" 2 "Unfair, and start transacting with another agent" 3 "Unfair, but would continue making transactions with the same agent" 4 "Fair") size(small) col(1)) ///
		note("Total agents = `: di %6.0fc `r(N)''", size(medsmall))
		
	graph export "$output/Agent Baseline - `date'/9 - q_3c.png", as(png) replace

*** q_3d
preserve

	destring q_3d, replace force
	** Drop missing variable (if any)
	drop if missing(q_3d)

	** Summary statistics
	qui summarize q_3d, detail
	return list

	** Store obs number before dropping outlier(s)
	local total_before = r(N)

	** Detect and drop outlier(s)
	generate iqr = r(p95) - r(p5)
	generate lower_limit = r(p5) - 1.5 * iqr
	generate upper_limit = r(p95) + 1.5 * iqr
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
	
	set scheme jpalfull

	* Histogram
	histogram q_3d, percent color("255 158 128") ///
		discrete ///
		xlabel(0(5)100) ///
		ylabel(0(2)15) ///
		xtitle("% of reduced revenue", size(medsmall)) ///
		ytitle("Percentage of agents", size(medsmall)) ///
		title("{bf:Estimated agent reduced revenue}", size(medsmall)) ///
		subtitle("if the agent charges {bf:50% higher to another customer}", size (medsmall)) ///
		note("Note:" "Total agents = `: di %6.0fc `r(N)''" "Outlier threshold = `ll' (lower) and `ul' (upper)" "Dropped outlier observation = `dropped_obs'", size(medsmall))
		
	graph export "$output/Agent Baseline - `date'/10 - q_3d_hist.png", as(png) replace

	* Box plot
	qui su q_3d, det
	return list

	local mean_rounded = round(`r(mean)', 1)	
	local Q_1_rounded = round(`r(p5)', 1)
	local Q_3_rounded = round(`r(p95)', 1)
	local median_rounded = round(`r(p50)', 1)
	
	graph box q_3d, yline(`r(mean)', lpattern(.)) ///
		ytitle("In percentage (%)", size(medsmall)) ///
		title("{bf:Estimated agent reduced revenue}", size(medsmall)) ///
		subtitle("if the agent charges {bf:50% higher to another customer}", size(medsmall)) ///
		text(`r(p50)' 95 "Median=`median_rounded'", size(vsmall)) ///
		text(`r(p95)' 95 "Q3=`Q_3_rounded'", size(vsmall)) ///
		text(`r(p5)' 95 "Q1=`Q_1_rounded'", size(vsmall)) ///
		text(`r(mean)' 95 "Mean=`mean_rounded'", size(vsmall)) ///
		note("Note:" "Total agents = `: di %6.0fc `r(N)''" "Outlier threshold = `ll' (lower) and `ul' (upper)" "Dropped outlier observation = `dropped_obs'", size(medsmall))
		
	graph export "$output/Agent Baseline - `date'/10 - q_3d_boxplot.png", as(png) replace

restore

*** q_3e
preserve

	destring q_3e, replace force
	** Drop missing variable (if any)
	drop if missing(q_3e)

	** Summary statistics
	qui summarize q_3e, detail
	return list

	** Store obs number before dropping outlier(s)
	local total_before = r(N)

	** Detect and drop outlier(s)
	generate iqr = r(p95) - r(p5)
	generate lower_limit = r(p5) - 1.5 * iqr
	generate upper_limit = r(p95) + 1.5 * iqr
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
	
	set scheme jpalfull

	* Histogram
	histogram q_3e, percent color("255 158 128") ///
		discrete ///
		xlabel(0(5)100) ///
		ylabel(0(2)15) ///
		xtitle("% of reduced revenue", size(medsmall)) ///
		ytitle("Percentage of agents", size(medsmall)) ///
		title("{bf:Estimated agent reduced revenue}", size(medsmall)) ///
		subtitle("if the withdrawal transaction fees {bf:increased from IDR 3K to 4,5K}", size(medsmall)) ///
		note("Note:" "Total agents = `: di %6.0fc `r(N)''" "Outlier threshold = `ll' (lower) and `ul' (upper)" "Dropped outlier observation = `dropped_obs'", size(medsmall))
		
	graph export "$output/Agent Baseline - `date'/11 - q_3e_hist.png", as(png) replace

	* Box plot
	su q_3e, det
	return list

	local mean_rounded = round(`r(mean)', 1)	
	local Q_1_rounded = round(`r(p5)', 1)
	local Q_3_rounded = round(`r(p95)', 1)
	local median_rounded = round(`r(p50)', 1)
	
	graph box q_3e, yline(`r(mean)', lpattern(.)) ///
		ytitle("In percentage (%)", size(medsmall)) ///
		title("{bf:Estimated agent reduced revenue}", size(medsmall)) ///
		subtitle("if the withdrawal transaction fees {bf:increased from IDR 3K to 4,5K}", size(medsmall)) ///
		text(`r(p50)' 95 "Median=`median_rounded'", size(vsmall)) ///
		text(`r(p95)' 95 "Q3=`Q_3_rounded'", size(vsmall)) ///
		text(`r(p5)' 95 "Q1=`Q_1_rounded'", size(vsmall)) ///
		text(`r(mean)' 95 "Mean=`mean_rounded'", size(vsmall)) ///
		note("Note:" "Total agents = `: di %6.0fc `r(N)''" "Outlier threshold = `ll' (lower) and `ul' (upper)" "Dropped outlier observation = `dropped_obs'", size(medsmall))
		
	graph export "$output/Agent Baseline - `date'/11 - q_3e_boxplot.png", as(png) replace

restore

**# 4. Section 4
*** q_4a
	forval x = 1/2 {
		gen gr_4a_`x' = 1 if q_4a == `x'
		recode gr_4a_`x' (. = 0)
		replace gr_4a_`x' = . if q_4a == .
	}

	qui sum agents_n if q_4a!=. 
	
	set scheme jpalfull

	graph bar gr_4a_*, percentages /// percent is the default
		ytitle("In percentage (%)", size(medsmall) orientation(vertical)) ///
		ylabel(0(25)100) ///
		blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
		title("Which of the following statements do you {bf:agree with most}?", size(medsmall)) ///
		subtitle(" ", size(medsmall)) ///
		legend(order(1 "Many agents in my area" 2 "A limited number of agents in my area") size(small) col(1)) ///
		note("Total agents = `: di %6.0fc `r(N)''", size(medsmall))
		
	graph export "$output/Agent Baseline - `date'/12 - q_4a.png", as(png) replace

*** q_4b
	forval x = 1/2 {
		gen gr_4b_`x' = 1 if q_4b == `x'
		recode gr_4b_`x' (. = 0)
		replace gr_4b_`x' = . if q_4b == .
	}

	qui sum agents_n if q_4b!=. 
	
	set scheme jpalfull

	graph bar gr_4b_*, percentages /// percent is the default
		ytitle("In percentage (%)", size(medsmall) orientation(vertical)) ///
		ylabel(0(25)100) ///
		blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
		title("Which of the following statements do you {bf:agree with most}?", size(medsmall)) ///
		subtitle(" ", size(medsmall)) ///
		legend(order(1 "Continue doing business with me, even if other agents offer lower price" 2 "Change to other agents who offer lower prices and can easily switch") size(small) col(1)) ///
		note("Total agents = `: di %6.0fc `r(N)''", size(medsmall))
		
	graph export "$output/Agent Baseline - `date'/13 - q_4b.png", as(png) replace

*** q_4c
preserve

	destring q_4c, replace force
	** Drop missing variable (if any)
	drop if missing(q_4c)

	** Summary statistics
	qui summarize q_4c, detail
	return list

	** Store obs number before dropping outlier(s)
	local total_before = r(N)

	** Detect and drop outlier(s)
	generate iqr = r(p95) - r(p5)
	generate lower_limit = r(p5) - 1.5 * iqr
	generate upper_limit = r(p95) + 1.5 * iqr
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
	set scheme jpalfull

	histogram q_4c, percent color("255 158 128") ///
		discrete ///
		xlabel(0(5)100) ///
		ylabel(0(2)15) ///
		xtitle("% of reduced revenue", size(medsmall)) ///
		ytitle("Percentage of agents", size(medsmall)) ///
		title("{bf:Estimated agent reduced revenue}", size(medsmall)) ///
		subtitle("if a {bf:new agent charges 50% less}", size(medsmall)) ///
		note("Note:" "Total agents = `: di %6.0fc `r(N)''" "Outlier threshold = `ll' (lower) and `ul' (upper)" "Dropped outlier observation = `dropped_obs'", size(medsmall))
		
	graph export "$output/Agent Baseline - `date'/14 - q_4c_hist.png", as(png) replace

	* Box plot
	su q_4c, det
	return list

	local mean_rounded = round(`r(mean)', 1)	
	local Q_1_rounded = round(`r(p5)', 1)
	local Q_3_rounded = round(`r(p95)', 1)
	local median_rounded = round(`r(p50)', 1)

	graph box q_4c, yline(`r(mean)', lpattern(.)) ///
		ytitle("In percentage (%)", size(medsmall)) ///
		title("{bf:Estimated agent reduced revenue}", size(medsmall)) ///
		subtitle("if a {bf:new agent charges 50% less}", size(medsmall)) ///
		text(`r(p50)' 95 "Median=`median_rounded'", size(vsmall)) ///
		text(`r(p95)' 95 "Q3=`Q_3_rounded'", size(vsmall)) ///
		text(`r(p5)' 95 "Q1=`Q_1_rounded'", size(vsmall)) ///
		text(`r(mean)' 95 "Mean=`mean_rounded'", size(vsmall)) ///
		note("Note:" "Total agents = `: di %6.0fc `r(N)''" "Outlier threshold = `ll' (lower) and `ul' (upper)" "Dropped outlier observation = `dropped_obs'", size(medsmall))
		
	graph export "$output/Agent Baseline - `date'/14 - q_4c_boxplot.png", as(png) replace

restore

*** q_4d (Prior Beliefs: Overall)
preserve

	destring q_4d, replace force
	** Drop missing variable (if any)
	drop if missing(q_4d)

	** Summary statistics
	qui summarize q_4d, detail
	return list

	** Store obs number before dropping outlier(s)
	local total_before = r(N)

	** Detect and drop outlier(s)
	generate iqr = r(p95) - r(p5)
	generate lower_limit = r(p5) - 1.5 * iqr
	generate upper_limit = r(p95) + 1.5 * iqr
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
	set scheme jpalfull

	histogram q_4d, percent color("255 158 128") ///
		discrete ///
		xlabel(-100(10)100) ///
		ylabel(0(2)10) ///
		xtitle("Estimated change in the number of agents (in %)", size(medsmall)) ///
		ytitle("Percentage of agents", size(medsmall)) ///
		title("Estimated change in the number of agents in %", size(medsmall)) ///
		subtitle("{bf: Prior beliefs}", size(medsmall)) ///
		note("Note:" "Total agents = `: di %6.0fc `r(N)''" "Outlier threshold = `ll' (lower) and `ul' (upper)" "Dropped outlier observation = `dropped_obs'", size(medsmall))
		
	graph export "$output/Agent Baseline - `date'/15 - q_4d_hist.png", as(png) replace

	* Box plot
	su q_4d, detail
	return list

	local mean_rounded = round(`r(mean)', 1)	
	local Q_1_rounded = round(`r(p5)', 1)
	local Q_3_rounded = round(`r(p95)', 1)
	local median_rounded = round(`r(p50)', 1)
	
	set scheme jpalfull

	graph box q_4d, yline(`r(mean)', lpattern(.)) ///
		ytitle("In percentage (%)", size(medsmall)) ///
		title("Estimated change in the number of agents in %", size(medsmall)) ///
		subtitle("{bf: Prior beliefs}", size(medsmall)) ///
		text(`r(p50)' 95 "Median=`median_rounded'", size(vsmall)) ///
		text(`r(p95)' 95 "Q3=`Q_3_rounded'", size(vsmall)) ///
		text(`r(p5)' 95 "Q1=`Q_1_rounded'", size(vsmall)) ///
		text(`r(mean)' 95 "Mean=`mean_rounded'", size(vsmall)) ///
		note("Note:" "Total agents = `: di %6.0fc `r(N)''" "Outlier threshold = `ll' (lower) and `ul' (upper)" "Dropped outlier observation = `dropped_obs'", size(medsmall))
		
	graph export "$output/Agent Baseline - `date'/15 - q_4d_boxplot.png", as(png) replace

restore

*** q_4d (Prior Beliefs: By Treatment Status)
* Histogram
	destring q_4d, replace force 
	
	forval a = 0/4 {
		gen gr_4d_t`a' = q_4d if treatment_status == `a'
	}

	label var gr_4d_t0 "{bf: Prior beliefs (Pure Control)}"
	forvalues i = 1/4 {
		label var gr_4d_t`i' "{bf: Prior beliefs (T`i')}"
	}

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
		generate iqr = r(p95) - r(p5)
		generate lower_limit = r(p5) - 1.5 * iqr
		generate upper_limit = r(p95) + 1.5 * iqr
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
		
		histogram `b', percent color("255 158 128") ///
			discrete ///
			xlabel(-100(10)100) ///
			ylabel(0(2)20) ///
			xtitle("Estimated change in the number of agents (in %)", size(medsmall)) ///
			ytitle("Percentage of agents", size(medsmall)) ///
			title("Estimated change in the number of agents in %", size(medsmall)) ///
			subtitle("`z'", size(medsmall)) ///
			note("Note:" "Total agents = `: di %6.0fc `r(N)''" "Outlier threshold = `ll' (lower) and `ul' (upper)" "Dropped outlier observation = `dropped_obs'", size(medsmall))
			
		graph export "$output/Agent Baseline - `date'/15 - q_4d_hist_T`a'.png", as(png) replace

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

	qui sum agents_n if treatment_status!=. 
	
	set scheme jpalfull

	graph bar gr_tstat_*, percentages /// percent is the default
		ytitle("In percentage (%)", size(medsmall) orientation(vertical)) ///
		ylabel(0(25)100) ///
		blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
		title("Treatment arm randomization", size(medsmall)) ///
		subtitle(" ", size(medsmall)) ///
		legend(order(1 "Pure Control" 2 "T1" 3 "T2" 4 "T3" 5 "T4") size(medsmall) col(1)) ///
		note("Total agents = `: di %6.0fc `r(N)''", size(medsmall))
		
	graph export "$output/Agent Baseline - `date'/16 - treatment_randomization.png", as(png) replace

**# 6. Section 6 (Posterior Beliefs)
*** q_6 (Overall)
preserve

	destring q_6, replace force
	** Drop missing variable (if any)
	drop if q_6 == .

	** Summary statistics
	qui summarize q_6, detail
	return list

	** Store obs number before dropping outlier(s)
	local total_before = r(N)

	** Detect and drop outlier(s)
	generate iqr = r(p95) - r(p5)
	generate lower_limit = r(p5) - 1.5 * iqr
	generate upper_limit = r(p95) + 1.5 * iqr
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
	histogram q_6, percent color("255 158 128") ///
		discrete ///
		xlabel(-100(10)100) ///
		ylabel(0(3)30) ///
		xtitle("Estimated change in the number of agents (in %)", size(medsmall)) ///
		ytitle("Percentage of agents", size(medsmall)) ///
		title("Estimated change in the number of agents in %", size(medsmall)) ///
		subtitle("{bf: Posterior beliefs}", size(medsmall)) ///
		note("Note:" "Total agents = `: di %6.0fc `r(N)''" "Outlier threshold = `ll' (lower) and `ul' (upper)" "Dropped outlier observation = `dropped_obs'", size(medsmall))
		
	graph export "$output/Agent Baseline - `date'/17 - q_6_hist.png", as(png) replace

	* Box plot
	su q_6, detail
	return list

	local mean_rounded = round(`r(mean)', 1)	
	local Q_1_rounded = round(`r(p5)', 1)
	local Q_3_rounded = round(`r(p95)', 1)
	local median_rounded = round(`r(p50)', 1)

	graph box q_6, yline(`r(mean)', lpattern(.)) ///
		ytitle("In percentage (%)", size(medsmall)) ///
		title("Estimated change in the number of agents in %", size(medsmall)) ///
		subtitle("{bf: Posterior beliefs}", size(medsmall)) ///
		text(`r(p50)' 95 "Median=`median_rounded'", size(vsmall)) ///
		text(`r(p95)' 95 "Q3=`Q_3_rounded'", size(vsmall)) ///
		text(`r(p5)' 95 "Q1=`Q_1_rounded'", size(vsmall)) ///
		text(`r(mean)' 95 "Mean=`mean_rounded'", size(vsmall)) ///
		note("Note:" "Total agents = `: di %6.0fc `r(N)''" "Outlier threshold = `ll' (lower) and `ul' (upper)" "Dropped outlier observation = `dropped_obs'", size(medsmall))
		
	graph export "$output/Agent Baseline - `date'/17 - q_6_boxplot.png", as(png) replace

restore

*** q_6 (Posterior Beliefs: By Treatment Status)
* Histogram
	destring q_6, replace force 
	
	forval a = 1(2)3 {
		gen gr_6_t`a' = q_6 if treatment_status == `a'
	}
	
	label var gr_6_t1 "{bf: Posterior beliefs (T1)}"
	label var gr_6_t3 "{bf: Posterior beliefs (T3)}"

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
		generate iqr = r(p95) - r(p5)
		generate lower_limit = r(p5) - 1.5 * iqr
		generate upper_limit = r(p95) + 1.5 * iqr
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
		
		histogram `b', percent color("255 158 128") ///
			discrete ///
			xlabel(-100(10)100) ///
			ylabel(0(3)30) ///
			xtitle("Estimated change in the number of agents (in %)", size(medsmall)) ///
			ytitle("Percentage of agents", size(medsmall)) ///
			title("Estimated change in the number of agents in %", size(medsmall)) ///
			subtitle("`z'", size(medsmall)) ///
			note("Note:" "Total agents = `: di %6.0fc `r(N)''" "Outlier threshold = `ll' (lower) and `ul' (upper)" "Dropped outlier observation = `dropped_obs'", size(medsmall))
			
		graph export "$output/Agent Baseline - `date'/17 - q_6_hist_T`a'.png", as(png) replace
		
		local a = `a' + 2
		
		restore
	}

**# 7. Section 7 (Marketing Plans)
*** q_7a
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

	graph bar gr_7a_*, percentages /// percent is the default
		ytitle("In percentage (%)", size(medsmall) orientation(vertical)) ///
		ylabel(0(25)100) ///
		blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
		title("Marketing Plans", size(medsmall)) ///
		subtitle(" ", size(medsmall)) ///
		legend(order(1 "Plan A (agents receive the poster)" 2 "Plan B (clients receive the poster)") size(small) col(1)) ///
		note("Total agents = `: di %6.0fc `r(N)''", size(medsmall))
		
	graph export "$output/Agent Baseline - `date'/18 - q_7a.png", as(png) replace

* Bar chart (by treatment groups)
	forval a = 2/3 {
		gen gr_7a_t`a' = 1 if treatment_status == `a' & q_7a == 1
		replace gr_7a_t`a' = 2 if treatment_status == `a' & q_7a == 0
	}

	label var gr_7a_t2 "{bf:T2} (no info on competition)"
	label var gr_7a_t3 "{bf:T3} (info on competition)"

	la def planab 1 "Plan A (agents receieve the poster)" 2 "Plan B (clients receive the poster)", replace
	la val gr_7a_t2 gr_7a_t3 planab

	foreach x of varlist gr_7a_t2 gr_7a_t3 {
					
		qui sum agents_n  if `x' !=.
		loc obs = `r(N)'

		loc	z: 	var lab 	`x'
		splitvallabels		`x'	
		
		set scheme jpalfull
					
		graph bar, over(`x', label(labsize(medium)) relabel(`r(relabel)')) ytitle("In percentage (%)", size(medium) orientation(vertical)) ylabel(0(25)100, grid labsize(medium)) ///
		asyvars ///
		title("`z'", size(medium)) bar(1) blabel(bar, size(medium) format(%4.1f)) ///
		note("Total agents = `: di %6.0fc `obs''", span size(medium)) name(`x', replace)
	}


	graph combine gr_7a_t2 gr_7a_t3, ///
		col(2) iscale(0.7) xcommon ///
		xsize(16) ysize(9) imargin(0 0 0 0) ///
		title("{bf: Marketing Plans}", size(medium)) ///
		subtitle("By treatment groups", size(medium))
		
	graph export "$output/Agent Baseline - `date'/18 - q_7a_by_T2_T3.png", as(png) replace

* Randomization options check
	recode q_7a_do_1 q_7a_do_2 (2 = 0)

	qui sum agents_n if q_1a!=. 
	
	set scheme jpalfull

	graph bar q_7a_do_1 q_7a_do_2, percentages /// percent is the default
		ytitle("In percentage (%)", size(medsmall) orientation(vertical)) ///
		ylabel(0(25)100) ///
		blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
		title("{bf: Marketing Plans}", size(medsmall)) ///
		subtitle("Option randomization: display order", size(medsmall)) ///
		legend(order(1 "Plan A displayed first" 2 "Plan B displayed first") size(medsmall) col(1)) ///
		note("Total agents = `: di %6.0fc `r(N)''", size(medsmall))
		
	graph export "$output/Agent Baseline - `date'/18 - q_7a_display_order.png", as(png) replace

**# 8. Section 8
*** q_8a
	forval x = 1/2 {
		gen gr_8a_`x' = 1 if q_8a == `x'
		recode gr_8a_`x' (. = 0)
		replace gr_8a_`x' = . if q_8a == .
	}

	qui sum agents_n if q_8a!=. 
	
	set scheme jpalfull

	graph bar gr_8a_*, percentages /// percent is the default
		ytitle("In percentage (%)", size(medsmall) orientation(vertical)) ///
		ylabel(0(25)100) ///
		blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
		title("Offer additional benefits to your customers?", size(medsmall)) ///
		subtitle(" ", size(medsmall)) ///
		legend(order(1 "Yes" 2 "No") size(small) col(1)) ///
		note("Total agents = `: di %6.0fc `r(N)''", size(medsmall))
		
	graph export "$output/Agent Baseline - `date'/19 - q_8a.png", as(png) replace

*** q_8a_1
	qui sum agents_n if q_8a_1_a != .

	foreach var in q_8a_1_a q_8a_1_b q_8a_1_c q_8a_1_d q_8a_1_e q_8a_1_f q_8a_1_g q_8a_1_h {
		gen `var'_100 = `var' * 100
	}
	
	set scheme jpalfull
	
	graph bar q_8a_1_a_100 - q_8a_1_h_100, ///
		ytitle("In percentage (%)", size(medsmall)) ///
		ylabel(0(25)100) ///
		blabel(bar, pos(top) size(medsmall) format(%9.1f)) ///
		title("To whom do you offer {bf:additional benefits}?", size(medsmall)) ///
		legend( ///
			order( ///
				1 "Friends" ///
				2 "Family" ///
				3 "High-value customer" ///
				4 "New customer" ///
				5 "Long-time customer" ///
				6 "Poorer customer" ///
				7 "Customer from local" ///
				8 `"Customer who can easily do business with other agents"' ///
			) ///
			rows(1) cols(2) position(6) ring(0) size(vsmall) symxsize(6) ///
			region(lstyle(none)) ///
		) ///
		xsize(9) ysize(5) ///
		note("Total agents = `: di %6.0fc `r(N)''", size(medsmall))
		
	graph export "$output/Agent Baseline - `date'/19 - q_8a_1.png", as(png) replace

		
		
	/*	
	gen label = ""
	replace label = "Friends" if q_8a_1_a == 1
	replace label = "Family" if q_8a_1_b == 1
	replace label = "High-value cust" if q_8a_1_c == 1
	replace label = "New cust" if q_8a_1_d == 1
	replace label = "Long-time cust" if q_8a_1_e == 1
	replace label = "Poorer cust" if q_8a_1_f == 1
	replace label = "Cust from local" if q_8a_1_g == 1
	replace label = "Cust who can easily do business with other agents" if q_8a_1_h == 1

graph hbar q_8a_1_a - q_8a_1_h, over(label, label(angle(0))) ///
		bar(1, color(black%50)) ///
		blabel(bar, format(%4.0f)) ///
    ytitle("") ///
    title("To whom do you offer {bf:additional benefits}?", size(medsmall) span) ///
    note("Total agents = `N'", size(medsmall)) ///
    scheme(s1color) ///
	legend(off)
    bar(1, color(black%50)) bar(2, color(black%50)) bar(3, color(black%50)) bar(4, color(black%50)) ///
    bar(5, color(black%50)) bar(6, color(black%50)) bar(7, color(black%50)) bar(8, color(black%50))
*/

*** q_8a_2
preserve

	** Drop missing variable (if any)
	drop if missing(q_8a)
	destring q_8a_2, replace force 
	drop if missing(q_8a_2)

	** Summary statistics
	qui summarize q_8a_2, detail
	return list

	** Store obs number before dropping outlier(s)
	local total_before = r(N)

	** Detect and drop outlier(s)
	generate iqr = r(p95) - r(p5)
	generate lower_limit = r(p5) - 1.5 * iqr
	generate upper_limit = r(p95) + 1.5 * iqr
	generate outlier = (q_8a_2 < lower_limit) | (q_8a_2 > upper_limit)
	drop if outlier == 1

	** Store obs number after dropping outlier(s) and compute the difference
	qui summarize q_8a_2, detail
	local total_after = r(N)
	local dropped_obs = `total_before' - `total_after'

	** Store lower and upper threshold
	qui su lower_limit, det
	local ll = round(`r(mean)', 1)
	qui su upper_limit, det
	local ul = round(`r(mean)', 1)

	* Histogram
	histogram q_8a_2, percent color("255 158 128") ///
		discrete ///
		xlabel(0(5)100) ///
		ylabel(0(2)15) ///
		xtitle("Number of customers", size(medsmall)) ///
		ytitle("Percentage of agents", size(medsmall)) ///
		title("Over the past month, {bf:how many customers} did you offer {bf:additional benefits*} to?", size(medsmall)) ///
		subtitle(" ") ///
		note("Note:" "Total agents = `: di %6.0fc `r(N)''" "Outlier threshold = `ll' (lower) and `ul' (upper)" "Dropped outlier observation = `dropped_obs'", size(medsmall))
		
	graph export "$output/Agent Baseline - `date'/20 - q_8a_2_hist.png", as(png) replace

	* Box plot
	su q_8a_2, det
	return list

	local mean_rounded = round(`r(mean)', 1)	
	local Q_1_rounded = round(`r(p5)', 1)
	local Q_3_rounded = round(`r(p95)', 1)
	local median_rounded = round(`r(p50)', 1)

	graph box q_8a_2, yline(`r(mean)', lpattern(.)) ///
		ytitle("Number of customers", size(medsmall)) ///
		title("Over the past month, {bf:how many customers} did you offer {bf:additional benefits*} to?", size(medsmall)) ///
		subtitle(" ", size(medsmall)) ///
		text(`r(p50)' 95 "Median=`median_rounded'", size(vsmall)) ///
		text(`r(p95)' 95 "Q3=`Q_3_rounded'", size(vsmall)) ///
		text(`r(p5)' 95 "Q1=`Q_1_rounded'", size(vsmall)) ///
		text(`r(mean)' 95 "Mean=`mean_rounded'", size(vsmall)) ///
		note("Note:" "Total agents = `: di %6.0fc `r(N)''" "Outlier threshold = `ll' (lower) and `ul' (upper)" "Dropped outlier observation = `dropped_obs'", size(medsmall))
		
	graph export "$output/Agent Baseline - `date'/20 - q_8a_2_boxplot.png", as(png) replace

restore

*** q_8b
preserve

	** Drop missing variable (if any)
	destring q_8b, replace force
	drop if missing(q_8b)

	** Summary statistics
	qui sum q_8b, detail
	return list

	** Store obs number before dropping outlier(s)
	local total_before = r(N)

	** Detect and drop outlier(s)
	generate iqr = r(p95) - r(p5)
	generate lower_limit = r(p5) - 1.5 * iqr
	generate upper_limit = r(p95) + 1.5 * iqr
	generate outlier = (q_8b < lower_limit) | (q_8b > upper_limit)
	drop if outlier == 1

	** Store obs number after dropping outlier(s) and compute the difference
	qui sum q_8b, detail
	local total_after = r(N)
	local dropped_obs = `total_before' - `total_after'

	** Store lower and upper threshold
	qui su lower_limit, det
	local ll = round(`r(mean)', 1)
	qui su upper_limit, det
	local ul = round(`r(mean)', 1)

	* Histogram
	histogram q_8b, percent color("255 158 128") ///
		discrete ///
		xlabel(0(5)100) ///
		ylabel(0(2)15) ///
		xtitle("% of revenue share", size(medsmall)) ///
		ytitle("Percentage of agents", size(medsmall)) ///
		title("{bf:Revenues share} that came from {bf:branchless banking business} last month", size(medsmall)) ///
		subtitle(" ") ///
		note("Note:" "Total agents = `: di %6.0fc `r(N)''" "Outlier threshold = `ll' (lower) and `ul' (upper)" "Dropped outlier observation = `dropped_obs'", size(medsmall))
		
	graph export "$output/Agent Baseline - `date'/21 - q_8b_hist.png", as(png) replace

	* Box plot
	su q_8b, det
	return list

	local mean_rounded = round(`r(mean)', 1)	
	local Q_1_rounded = round(`r(p5)', 1)
	local Q_3_rounded = round(`r(p95)', 1)
	local median_rounded = round(`r(p50)', 1)

	graph box q_8b, yline(`r(mean)', lpattern(.)) ///
		ytitle("In percentage (%)", size(medsmall)) ///
		title("{bf:Revenues share} that came from {bf:branchless banking business} last month", size(medsmall)) ///
		subtitle(" ", size(medsmall)) ///
		text(`r(p50)' 95 "Median=`median_rounded'", size(vsmall)) ///
		text(`r(p95)' 95 "Q3=`Q_3_rounded'", size(vsmall)) ///
		text(`r(p5)' 95 "Q1=`Q_1_rounded'", size(vsmall)) ///
		text(`r(mean)' 95 "Mean=`mean_rounded'", size(vsmall)) ///
		note("Note:" "Total agents = `: di %6.0fc `r(N)''" "Outlier threshold = `ll' (lower) and `ul' (upper)" "Dropped outlier observation = `dropped_obs'", size(medsmall))
		
	graph export "$output/Agent Baseline - `date'/21 - q_8b_boxplot.png", as(png) ///
	replace

restore

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
		ytitle("In percentage (%)", size(medsmall) orientation(vertical)) ///
		ylabel(0(25)100) ///
		blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
		title("Do you also work as an agent for other banks, {bf:besides Bank Mandiri}?", size(medsmall)) ///
		subtitle(" ", size(medsmall)) ///
		legend(order(1 "Yes" 2 "No") size(medsmall) col(2)) ///
		note("Total agents = `: di %6.0fc `r(N)''", size(medsmall))
		
	graph export "$output/Agent Baseline - `date'/22 - q_8c.png", as(png) replace

	*** q_8c_1
preserve

	** Drop missing variable (if any)
	destring q_8c_1, replace
	drop if missing(q_8c_1)

	** Summary statistics
	qui summarize q_8c_1, detail
	return list

	** Store obs number before dropping outlier(s)
	local total_before = r(N)

	** Detect and drop outlier(s)
	generate iqr = r(p95) - r(p5)
	generate lower_limit = r(p5) - 1.5 * iqr
	generate upper_limit = r(p95) + 1.5 * iqr
	generate outlier = (q_8c_1 < lower_limit) | (q_8c_1 > upper_limit)
	drop if outlier == 1

	** Store obs number after dropping outlier(s) and compute the difference
	qui summarize q_8c_1, detail
	local total_after = r(N)
	local dropped_obs = `total_before' - `total_after'

	** Store lower and upper threshold
	qui su lower_limit, det
	local ll = round(`r(mean)', 1)
	qui su upper_limit, det
	local ul = round(`r(mean)', 1)

	* Histogram
	histogram q_8c_1, percent color("255 158 128") ///
		discrete ///
		xlabel(0(5)100) ///
		ylabel(0(20)100) ///
		xtitle("% of revenue share", size(medsmall)) ///
		ytitle("Percentage of agents", size(medsmall)) ///
		title("{bf:Revenues share} that came from {bf:Bank Mandiri business} last month", size(medsmall)) ///
		subtitle(" ", size(medsmall)) ///
		note("Note:" "Total agents = `: di %6.0fc `r(N)''" "Outlier threshold = `ll' (lower) and `ul' (upper)" "Dropped outlier observation = `dropped_obs'", size(medsmall))
		
	graph export "$output/Agent Baseline - `date'/22 - q_8c_1_hist.png", as(png) replace

	* Box plot
	su q_8c_1, det
	return list

	local mean_rounded = round(`r(mean)', 1)	
	local Q_1_rounded = round(`r(p5)', 1)
	local Q_3_rounded = round(`r(p95)', 1)
	local median_rounded = round(`r(p50)', 1)

	graph box q_8c_1, yline(`r(mean)', lpattern(.)) ///
		ytitle("In percentage (%)", size(medsmall)) ///
		title("{bf:Revenues share} that came from {bf:Bank Mandiri business} last month", size(medsmall)) ///
		subtitle(" ", size(medsmall)) ///
		text(`r(p50)' 95 "Median=`median_rounded'", size(vsmall)) ///
		text(`r(p95)' 95 "Q3=`Q_3_rounded'", size(vsmall)) ///
		text(`r(p5)' 95 "Q1=`Q_1_rounded'", size(vsmall)) ///
		text(`r(mean)' 95 "Mean=`mean_rounded'", size(vsmall)) ///
		note("Note:" "Total agents = `: di %6.0fc `r(N)''" "Outlier threshold = `ll' (lower) and `ul' (upper)" "Dropped outlier observation = `dropped_obs'", size(medsmall))
		
	graph export "$output/Agent Baseline - `date'/22 - q_8c_1_boxplot.png", as(png) replace

restore

**# 9. Section 9
*** q_9a
preserve

	** Drop missing variable (if any)
	destring q_9a, force replace
	drop if missing(q_9a)

	** Summary statistics
	qui summarize q_9a, detail
	return list

	** Store obs number before dropping outlier(s)
	local total_before = r(N)

	** Detect and drop outlier(s)
	generate iqr = r(p95) - r(p5)
	generate lower_limit = r(p5) - 1.5 * iqr
	generate upper_limit = r(p95) + 1.5 * iqr
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
	histogram q_9a, percent color("255 158 128") ///
		discrete ///
		xlabel(0(5)50) ///
		ylabel(0(3)30) ///
		xtitle("Agent numbers", size(medsmall)) ///
		ytitle("Percentage of agents", size(medsmall)) ///
		title("Number of agents in the area", size(medsmall)) ///
		subtitle(" ", size(medsmall)) ///
		note("Note:" "Total agents = `: di %6.0fc `r(N)''" "Outlier threshold = `ll' (lower) and `ul' (upper)" "Dropped outlier observation = `dropped_obs'", size(medsmall))
		
	graph export "$output/Agent Baseline - `date'/23 - q_9a_hist.png", as(png) replace

	* Box plot
	su q_9a, det
	return list

	local mean_rounded = round(`r(mean)', 1)	
	local Q_1_rounded = round(`r(p5)', 1)
	local Q_3_rounded = round(`r(p95)', 1)
	local median_rounded = round(`r(p50)', 1)

	graph box q_9a, yline(`r(mean)', lpattern(.)) ///
		ytitle("Agent numbers", size(medsmall)) ///
		title("Number of agents in the area", size(medsmall)) ///
		subtitle(" ", size(medsmall)) ///
		text(`r(p50)' 95 "Median=`median_rounded'", size(vsmall)) ///
		text(`r(p95)' 95 "Q3=`Q_3_rounded'", size(vsmall)) ///
		text(`r(p5)' 95 "Q1=`Q_1_rounded'", size(vsmall)) ///
		text(`r(mean)' 95 "Mean=`mean_rounded'", size(vsmall)) ///
		note("Note:" "Total agents = `: di %6.0fc `r(N)''" "Outlier threshold = `ll' (lower) and `ul' (upper)" "Dropped outlier observation = `dropped_obs'", size(medsmall))
		
	graph export "$output/Agent Baseline - `date'/23 - q_9a_boxplot.png", as(png) replace

restore

*** q_9b
	forval x = 1/3 {
		gen gr_9b_`x' = 1 if q_9b == `x'
		recode gr_9b_`x' (. = 0)
		replace gr_9b_`x' = . if q_9b == .
	}

	qui sum agents_n if q_9b!=. 
	
	set scheme jpalfull

	graph bar gr_9b_*, percentages /// percent is the default
		ytitle("In percentage (%)", size(medsmall) orientation(vertical)) ///
		ylabel(0(25)100) ///
		blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
		title("Current {bf:level of competition} with other agents in the area", size(medsmall)) ///
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
		ytitle("In percentage (%)", size(medsmall) orientation(vertical)) ///
		ylabel(0(25)100) ///
		blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
		title("How easy is it for you to {bf:attract new} branchless banking customers?", size(medsmall)) ///
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
		ytitle("In percentage (%)", size(medsmall) orientation(vertical)) ///
		ylabel(0(25)100) ///
		blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
		title("Do you {bf:display} a price list with Bank Mandiri's official prices {bf:in your shop}?", size(medsmall)) ///
		subtitle(" ", size(medsmall)) ///
		legend(order(1 "Yes" 2 "No") size(medsmall) col(2)) ///
		note("Total agents = `: di %6.0fc `r(N)''", size(medsmall))
		
	graph export "$output/Agent Baseline - `date'/26 - q_9d.png", as(png) replace

*** q_9e
	qui sum agents_n if q_9e_1 != .

	foreach var in q_9e_1 q_9e_2 q_9e_3 {
		gen `var'_100 = `var' * 100
	}
	
	set scheme jpalfull

	graph bar q_9e_1_100 - q_9e_3_100,  ///
		ytitle("In percentage (%)", size(medsmall) orientation(vertical)) ///
		ylabel(0(25)100) ///
		blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
		title("Expectations on {bf:new competitor's main strategy}", size(medsmall)) ///
		subtitle("(agents can only select the answer up to 3 options)", size(medsmall)) ///
		legend(order(1 "Reduced transaction fees" 2 "Longer business hours" 3 "Offer buy on credit option" 4 "Offer complementary services/products" 5 "Having extra cash in hand" 6 "Cleanliness premises" 7 "Better customer service" 8 "Create more trust among customer" 9 "Proximity to customer") size(small) col(2)) ///
		note("Total agents = `: di %6.0fc `r(N)''", size(medsmall))
		
	graph export "$output/Agent Baseline - `date'/27 - q_9e.png", as(png) replace

*** q_9f
	qui sum agents_n if q_9f_1 != .

	foreach var in q_9f_1 q_9f_2 q_9f_3 {
		gen `var'_100 = `var' * 100
	}
	
	set scheme jpalfull

	graph bar q_9f_1_100 - q_9f_3_100,  ///
		ytitle("In percentage (%)", size(medsmall) orientation(vertical)) ///
		ylabel(0(25)100) ///
		blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
		title("{bf:Agent strategies used} to increase branchless banking business", size(medsmall)) ///
		subtitle("(agents can only select the answer up to 3 options)", size(medsmall)) ///
		legend(order(1 "Reduced transaction fees" 2 "Longer business hours" 3 "Offer buy on credit option" 4 "Offer complementary services/products" 5 "Having extra cash in hand" 6 "Cleanliness premises" 7 "Better customer service" 8 "Create more trust among customer" 9 "Proximity to customer") size(small) col(2)) ///
		note("Total agents = `: di %6.0fc `r(N)''", size(medsmall))
		
	graph export "$output/Agent Baseline - `date'/28 - q_9f.png", as(png) replace

*** q_9g
	forval x = 1/3 {
		gen gr_9g_`x' = 1 if q_9g == `x'
		recode gr_9g_`x' (. = 0)
		replace gr_9g_`x' = . if q_9g == .
	}

	qui sum agents_n if !missing(q_9g)
	
	set scheme jpalfull

	graph bar gr_9g_*, percentages /// percent is the default
		ytitle("In percentage (%)", size(medsmall) orientation(vertical)) ///
		ylabel(0(25)100) ///
		blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
		title("Time spent to {bf:advertise the agent services}", size(medsmall)) ///
		subtitle("to increase the business over the last month", size(medsmall)) ///
		legend(order(1 "None at all" 2 "Some time" 3 "A lot of time") size(medsmall) col(3)) ///
		note("Total agents = `: di %6.0fc `r(N)''", size(medsmall))
		
	graph export "$output/Agent Baseline - `date'/29 - q_9g.png", as(png) replace

*** q_9h
	forval x = 1/6 {
		gen gr_9h_`x' = 1 if q_9h == `x'
		recode gr_9h_`x' (. = 0)
		replace gr_9h_`x' = . if q_9h == .
	}

	qui sum agents_n if !missing(q_9h)
	
	set scheme jpalfull

	graph bar gr_9h_*, percentages /// percent is the default
		ytitle("In percentage (%)", size(medsmall) orientation(vertical)) ///
		ylabel(0(25)100) ///
		blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
		title("The frequency of approaching customers", size(medsmall)) ///
		subtitle("to {bf:do more branchless banking transactions}", size(medsmall)) ///
		legend(order(1 "Every day" 2 "A few times a week" 3 "Once a week" 4 "A few times per month" 5 "Once a month" 6 "Not at all") size(small) col(3)) ///
		note("Total agents = `: di %6.0fc `r(N)''", size(medsmall))
		
	graph export "$output/Agent Baseline - `date'/30 - q_9h.png", as(png) replace

*** q_9i
	forval x = 1/6 {
		gen gr_9i_`x' = 1 if q_9i == `x'
		recode gr_9i_`x' (. = 0)
		replace gr_9i_`x' = . if q_9i == .
	}

	qui sum agents_n if !missing(q_9i)
	
	set scheme jpalfull

	graph bar gr_9i_*, percentages /// percent is the default
		ytitle("In percentage (%)", size(medsmall) orientation(vertical)) ///
		ylabel(0(25)100) ///
		blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
		title("The frequency of approaching customers", size(medsmall)) ///
		subtitle("to {bf:adopt new Bank Mandiri financial products}", size(medsmall)) ///
		legend(order(1 "Every day" 2 "A few times a week" 3 "Once a week" 4 "A few times per month" 5 "Once a month" 6 "Not at all") size(small) col(3)) ///
		note("Total agents = `: di %6.0fc `r(N)''", size(medsmall))

	graph export "$output/Agent Baseline - `date'/31 - q_9i.png", as(png) replace

*** q_9j
	forval x = 1/6 {
		gen gr_9j_`x' = 1 if q_9j == `x'
		recode gr_9j_`x' (. = 0)
		replace gr_9j_`x' = . if missing(q_9j)
	}

	qui sum agents_n if !missing(q_9j)
	
	set scheme jpalfull

	graph bar gr_9j_*, percentages /// percent is the default
		ytitle("In percentage (%)", size(medsmall) orientation(vertical)) ///
		ylabel(0(25)100) ///
		blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
		title("The frequency of approaching customers", size(medsmall)) ///
		subtitle("to {bf:inform official transaction fees from Bank Mandiri}", size(medsmall)) ///
		legend(order(1 "Every day" 2 "A few times a week" 3 "Once a week" 4 "A few times per month" 5 "Once a month" 6 "Not at all") size(small) col(3)) ///
		note("Total agents = `: di %6.0fc `r(N)''", size(medsmall))
		
	graph export "$output/Agent Baseline - `date'/32 - q_9j.png", as(png) replace

**# 10. Section 10
*** q_10a_1
	qui sum q_10a_1

	histogram q_10a_1, percent color("255 158 128") ///
		discrete ///
		xlabel(2013(1)2025) ///
		ylabel(0(3)30) ///
		xtitle("Year", size(medsmall)) ///
		ytitle("Percentage of agents", size(medsmall)) ///
		title("Since when have you been an agent for Bank Mandiri?", size(medsmall)) ///
		subtitle(" ", size(medsmall)) ///
		note("Total agents = `: di %6.0fc `r(N)''", size(medsmall))
		
	graph export "$output/Agent Baseline - `date'/33 - q_10a_1_hist.png", as(png) replace

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
		ytitle("In percentage (%)", size(medsmall) orientation(vertical)) ///
		ylabel(0(25)100) ///
		blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
		title("Gender", size(medsmall)) ///
		subtitle(" ", size(medsmall)) ///
		legend(order(1 "Female" 2 "Male") size(medsmall) col(2)) ///
		note("Total agents = `: di %6.0fc `r(N)''", size(medsmall))
		
	graph export "$output/Agent Baseline - `date'/34 - gender.png", as(png) replace

*** q_10c (birthyear)
	set scheme plotplain

	qui sum birthyear

	histogram birthyear, percent color("255 158 128") ///
		discrete ///
		ylabel(0(5)15) ///
		xtitle("Year", size(medsmall)) ///
		ytitle("Percentage of agents", size(medsmall)) ///
		title("Year of birth", size(medsmall)) ///
		subtitle(" ", size(medsmall)) ///
		note("Total agents = `: di %6.0fc `r(N)''", size(medsmall))
		
	graph export "$output/Agent Baseline - `date'/35 - birthyear_hist.png", as(png) replace

**# 11. Section 11
	*** q_11a
	forval x = 1/10 {
		gen gr_11a_`x' = 1 if q_11a == `x'
		recode gr_11a_`x' (. = 0)
		replace gr_11a_`x' = . if q_11a == .
	}

	qui sum agents_n if !missing(q_11a) 

	set scheme jpalfull

	graph bar gr_11a_*, percentages /// percent is the default
		ytitle("In percentage (%)", size(medsmall) orientation(vertical)) ///
		ylabel(0(25)100) ///
		blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
		title("Compensation type", size(medsmall)) ///
		subtitle(" ", size(medsmall)) ///
		legend(order(1 "Pulsa Telkomsel" 2 "Pulsa 3" 3 "Pulsa XL" 4 "Pulsa Axis" 5 "Pulsa Indosat" 6 "E-Money OVO" 7 "E-Money GoPay" 8 "E-Money LinkAja" 9 "E-Money DANA" 10 "E-Money ShopeePay") size(small) col(2)) ///
		note("Total agents = `: di %6.0fc `r(N)''", size(medsmall))
		
	graph export "$output/Agent Baseline - `date'/36 - compensation_type.png", as(png) replace

*** q_11b_1
	local x = 1
	forval nmr = 1/2 {
		// 1 if q_11b_1 equals x, 0 otherwise; missing stays missing
		gen byte gr_11b_1_`nmr' = (real(q_11b_1) == `x') if !missing(q_11b_1)
		local x = `x' - 1
	}
	qui sum agents_n if !missing(q_11b_1)

	set scheme jpalfull

	graph bar gr_11b_1_*, percentages /// percent is the default
		ytitle("In percentage (%)", size(medsmall) orientation(vertical)) ///
		ylabel(0(25)100) ///
		blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
		title("Are you sure your number is correct?", size(medsmall)) ///
		subtitle(" ", size(medsmall)) ///
		legend(order(1 "Yes" 2 "No") size(medsmall) col(2)) ///
		note("Total agents = `: di %6.0fc `r(N)''", size(medsmall))
		
	graph export "$output/Agent Baseline - `date'/37 - correct_number.png", as(png) replace
