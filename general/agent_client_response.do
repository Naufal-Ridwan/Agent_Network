*===================================================*
* Agent - Client Survey (Baseline) -- Match
* Last modified: 05 Feb 2026
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

*Naufal
	gl path "/Users/athonaufalridwan/Library/CloudStorage/Dropbox/J-PAL IFII Agent Banking Network (BM)/06 Data/c Full-Scale/06 Survey Data"

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

*************
*IMPORT DATA*
*************

/*# MODEL 1 --> Anchoring from Agent, then to client, if client response but agent do not response then delete
use "$dta/01 client_baseline/cleaned_baseline_client_survey_09022026.dta", clear 
	duplicates drop unique_code, force // 6,460 observations deleted -- anomali, harusnya tidak ada duplicates unique code
	rename unique_code unique_code_nasabah
	tempfile client_response
	save `client_response'
*/


*** Using Client dataset
use "$dta/02 agent_baseline/cleaned_baseline_agent_survey_16032026.dta", clear 
	duplicates drop unique_code_agent, force
	tempfile agent_response
	save `agent_response'
	
use "$dta/01 client_baseline/cleaned_baseline_client_survey_17032026.dta", clear

	rename unique_code_client unique_code_nasabah
	duplicates drop unique_code_nasabah, force
	tempfile client_response
	save `client_response'
	
	
import delimited "/Users/athonaufalridwan/Library/CloudStorage/Dropbox/J-PAL IFII Agent Banking Network (BM)/06 Data/c Full-Scale/09 Contact List/contact_list_clients_final_v2.csv", clear    
	rename kode_unik_survei_agen unique_code_agent
	rename externaldatareference unique_code_client
	keep unique_code_agent unique_code_client cust_code_agen cust_code_nasabah
	rename unique_code_client unique_code_nasabah
	merge 1:1 unique_code_nasabah using `client_response'
	keep if _merge ==3
	drop _merge

	
	merge m:1 unique_code_agent using `agent_response', force
	drop if _merge== 1
	rename _merge agent_status
	keep agent_status unique_code_agent unique_code_nasabah treatment_status strata
	
	bysort unique_code_agent: egen total_respon_per_agen = count(unique_code_nasabah)
	duplicates drop unique_code_agent, force
	capture mkdir "$output/Agent-Client_`date'"
	
save "$output/Agent-Client_`date'/agent-client response.dta", replace
	
preserve
*** Generating Agnet - Client distribution 
	
	set scheme plotplain

	histogram total_respon_per_agen, percent color(maroon) ///
		discrete ///
		xlabel(0(1)20) ///
		ylabel(0(10)40) ///
		xtitle("Number of client response per agent", size(medsmall)) ///
		ytitle("Percentage (%) of agents", size(medsmall)) ///
		title("Client response distribution per agent", size(medsmall)) ///
		subtitle(" ", size(medsmall))
	capture mkdir "$output/Agent-Client_`date'"
	graph export "$output/Agent-Client_`date'/Agent level client distribution.png", as(png) replace

restore
***Checking Agent-client distribution per treatment status
preserve

	gen client_responses_min_3 = (total_respon_per_agen >=3)
	tab client_responses_min_3
	tab treatment_status if client_responses_min_3 == 1
	gen client_responses_min_2 = (total_respon_per_agen >=2)
	tab client_responses_min_2
	tab treatment_status if client_responses_min_2 == 1
	

restore
***Generating the distribution of client-agent per treatment_status
preserve
set scheme plotplain
histogram total_respon_per_agen, ///
    discrete /// 
    by(treatment_status, ///
        title("Distribution of total response per agent per treatment status") ///
        legend(off) /// 
        rows(1) /// 
    ) ///
    percent /// 
    color(navy%80) ///
    fcolor(navy%60) lcolor(navy) ///
    xlabel(1(3)20) /// 
    xtitle("Total responses")

restore
*** q_treatment_status
preserve

	forval x = 0/4 {
		gen gr_treatment_status_`x' = 1 if treatment_status == `x'
		recode gr_treatment_status_`x' (. = 0)
		replace gr_treatment_status_`x' = . if treatment_status == .
	}

	set scheme jpalfull
	gen clients_n = _n
	qui sum clients_n 
	*if q_treatment_status!=. 

	graph bar gr_treatment_status_*, percentages /// percent is the default
		ytitle("Percentage (%) of agents", size(midsmall) orientation(vertical)) ///
		ylabel(0(5)25) ///
		blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
		title("Agent response distribution per treatment arm?", size(midsmall)) ///
		subtitle(" ", size(medsmall)) ///
		legend(order(1 "Pure control" 2 "T1" 3 "T2" 4 "T3" 5 "T4") size(vsmall) col(5)) ///
		note("Total clients = `: di %6.0fc `r(N)''", size(vsmall))	
	capture mkdir "$output/Agent-Client_`date'"
	graph export "$output/Agent-Client_`date'/Treatment-status_distribution.png", as(png) replace

restore
*Generating client response with minimum responses
preserve
	capture mkdir "$output/Agent-Client_`date'"
	*response min 1
	gen client_response_min_1 = total_respon_per_agen >= 1
	estpost tabulate treatment_status if client_response_min_1 == 1

	esttab using "$path/output/Agent-Client_`date'/table_response_min1.tex", ///
    replace ///
    cells("b(fmt(%9.0fc)) pct(fmt(%9.2f))") ///
    nonumber noobs ///
    booktabs ///
    prehead(`"\begin{table}[H]\centering"' ///
            `"\caption{Agents with at least one client response}"' ///
            `"\begin{tabular}{lcc}"' ///
            `"\toprule"' ///
            `"Treatment status & Number of agents & Percentage of agents\\"' ///
            `"\midrule"') ///
    postfoot(`"\midrule"' ///
             `"\end{tabular}"' ///
             `"\end{table}"')
	

	*response min 2
	gen client_response_min_2 = total_respon_per_agen >= 2
	estpost tabulate treatment_status if client_response_min_2 == 1

	esttab using "$path/output/Agent-Client_`date'/table_response_min2.tex", ///
    replace ///
    cells("b(fmt(%9.0fc)) pct(fmt(%9.2f))") ///
    nonumber noobs ///
    booktabs ///
    prehead(`"\begin{table}[H]\centering"' ///
            `"\caption{Agents with at least two client response}"' ///
            `"\begin{tabular}{lcc}"' ///
            `"\toprule"' ///
            `"Treatment status & Number of agents & Percentage of agents \\"' ///
            `"\midrule"') ///
    postfoot(`"\midrule"' ///
             `"\end{tabular}"' ///
             `"\end{table}"')

	
	*response min 3
	gen client_response_min_3 = total_respon_per_agen >= 3
	estpost tabulate treatment_status if client_response_min_3 == 1

	esttab using "$path/output/Agent-Client_`date'/table_response_min3.tex", ///
    replace ///
    cells("b(fmt(%9.0fc)) pct(fmt(%9.2f))") ///
    nonumber noobs ///
    booktabs ///
    prehead(`"\begin{table}[H]\centering"' ///
            `"\caption{Agents with at least three client response}"' ///
            `"\begin{tabular}{lcc}"' ///
            `"\toprule"' ///
            `"Treatment status & Number of clients & Percentage of agents \\"' ///
            `"\midrule"') ///
    postfoot(`"\midrule"' ///
             `"\end{tabular}"' ///
             `"\end{table}"')
			 
	*zero response
	gen client_response_0 = total_respon_per_agen == 0
	estpost tabulate treatment_status if client_response_0 == 1

	esttab using "$path/output/Agent-Client_`date'/table_response_0.tex", ///
    replace ///
    cells("b(fmt(%9.0fc)) pct(fmt(%9.2f))") ///
    nonumber noobs ///
    booktabs ///
    prehead(`"\begin{table}[H]\centering"' ///
            `"\caption{Agents with zero client response}"' ///
            `"\begin{tabular}{lcc}"' ///
            `"\toprule"' ///
            `"Treatment status & Number of clients & Percentage of agents \\"' ///
            `"\midrule"') ///
    postfoot(`"\midrule"' ///
             `"\end{tabular}"' ///
             `"\end{table}"')
			 
			 

	capture mkdir "$output/Agent-Client_`date'"

	* Buat indikator kumulatif
	gen resp_min_1 = total_respon_per_agen >= 1
	gen resp_min_2 = total_respon_per_agen >= 2
	gen resp_min_3 = total_respon_per_agen >= 3
	gen resp_0     = total_respon_per_agen == 0

	* Collapse jumlah per treatment_status
	collapse (sum) resp_0 resp_min_1 resp_min_2 resp_min_3, by(treatment_status)
	
	*Buat matrix dari dataset hasil collapsea
	mkmat resp_0 resp_min_1 resp_min_2 resp_min_3, matrix(C)

	* Tambahkan row dan col names
	matrix rownames C = treatment_status
	matrix colnames C = "Zero" "Min 1" "Min 2" "Min 3+"
	
	*Export ke LaTeX
	esttab matrix(C) using "$output/Agent-Client_`date'/table_response_comprehensive.tex", ///
		replace ///
		cells("C") ///
		nonumber noobs ///
		booktabs ///
		prehead(`"\begin{table}[H]\centering"' ///
				`"\caption{Agent responses by treatment status}"' ///
				`"\begin{tabular}{lcccc}"' ///
				`"\toprule"' ///
				`"Treatment status & Zero & Min 1 & Min 2 & Min 3+ \\"' ///
				`"\midrule"') ///
		postfoot(`"\midrule"' ///
				`"\end{tabular}"' ///
				`"\end{table}"')


	keep if total_respon_per_agen ==0
	keep unique_code_agent	
	tempfile agen_zeroresponse_client
	save `agen_zeroresponse_client'
	
	
	import delimited "/Users/athonaufalridwan/Library/CloudStorage/Dropbox/J-PAL IFII Agent Banking Network (BM)/06 Data/c Full-Scale/09 Contact List/contact_list_clients_final_v2.csv", clear    
	rename kode_unik_survei_agen unique_code_agent
	rename externaldatareference unique_code_client

	keep unique_code_agent unique_code_client cust_code_agen cust_code_nasabah
	rename unique_code_client unique_code_nasabah
	merge m:1 unique_code_agent using `agen_zeroresponse_client'
	keep if _merge == 3
	drop _merge

	bysort unique_code_agent: gen number = _n
	keep if number <= 100
	bysort unique_code_agent: gen number_client = _N
	duplicates drop unique_code_agent, force
	
	gen number_client_top = number_client
	replace number_client_top = 31 if number_client > 30

	label define top_lbl 31 ">30", modify
	label values number_client_top top_lbl
	
	label drop top_lbl
	label define top_lbl 31 ">30"
	label values number_client_top top_lbl
	
	set scheme plotplain

	histogram number_client_top, discrete percent ///
		color(maroon) ///
		xlabel(1(5)30 31 ">30", angle(0)) ///
		xtitle("Number of available clients per agent", size(medsmall)) ///
		ytitle("Percentage (%) of agents", size(medsmall))
	
	/*Creating histogram for total number of client per agent distribution
	set scheme plotplain
	histogram number_client, percent color(maroon) ///
		ylabel(0(10)50) ///
		xlabel(0(20)100) ///
		xtitle("Number of available clients per agent", size(medsmall)) ///
		ytitle("Percentage (%) of agents", size(medsmall)) ///
		
	capture mkdir "$output/Agent-Client_`date'"
	graph export "$output/Agent-Client_`date'/Number of available clients per agent.png", as(png) replace
	*/
