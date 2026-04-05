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
	local date : display %tdDNCY daily("$S_DATE", "DMY")
	capture shell mkdir -p "$output/Agent-Client_`date'"

*Prepating dataset for the client has been send reminder at least once
use "/Users/athonaufalridwan/Library/CloudStorage/Dropbox/J-PAL IFII Agent Banking Network (BM)/06 Data/c Full-Scale/10 Respondent List/01_daftar_penerima_baseline_client/daftar_penerima_baseline_client.dta", clear
    rename kode_unik_survei_nasabah unique_code_client
    tempfile client_baseline_reminders
    save `client_baseline_reminders'

*Preapring dataset for agent-client with zero and 1 response minimum
use "$output/Agent-Client_31032026/agent-client response.dta", clear
    drop unique_code_nasabah strata agent_status
    rename total_respon_per_agen client_response_peragent
    keep if client_response_peragent == 0 | client_response_peragent == 1

    tempfile agent_zeroandone_response
    save `agent_zeroandone_response'

*Generating the number of clients have not response from agent with 0 or 1 response minimum
import delimited "/Users/athonaufalridwan/Library/CloudStorage/Dropbox/J-PAL IFII Agent Banking Network (BM)/06 Data/c Full-Scale/09 Contact List/contact_list_clients_final_v2.csv", clear    
	rename kode_unik_survei_agen unique_code_agent
	rename externaldatareference unique_code_client

    keep unique_code_agent unique_code_client cust_code_agen cust_code_nasabah
    merge m:1 unique_code_agent using `agent_zeroandone_response'
    keep if _merge == 3
    drop _merge
    rename unique_code_client unique_code_nasabah
    tempfile agent_zeroandone_response1
    save `agent_zeroandone_response1'

*Dropping client have response to the reminder from the agent with 1 response minimum
use "$path/dtafiles/01 client_baseline/cleaned_baseline_client_survey_30032026.dta", clear
    rename unique_code_client unique_code_nasabah
    keep unique_code_nasabah
    merge m:1 unique_code_nasabah using `agent_zeroandone_response1'
    keep if _merge ==2
    bysort unique_code_agent: gen number_client = _N
    tempfile agen_zeroandaoneresponse_client
    save `agen_zeroandaoneresponse_client'

*Creating histogram of number of clients with zero response from agent with 0 or 1 response minimum
    local N = _N
    local N_fmt : display %9.0fc `N'

    duplicates drop unique_code_agent, force
    gen number_client_top = number_client
    replace number_client_top = 31 if number_client > 30

    set scheme plotplain

    histogram number_client_top, discrete percent ///
        color(maroon) ///
        xlabel(1(5)30 31 ">30", angle(0)) ///
        xtitle("Number of available clients per agent with zero and one response", size(medsmall)) ///
        ytitle("Percentage", size(medsmall)) ///
        note("Note: Number of available clients in total = `N_fmt'", size(small) color(gs10) margin(0 0 0 0))
    graph export "$output/Agent-Client_`date'/agent_zeroandone_response_histogram.png", replace

*Generating the number of clients have not response from agent with 0 response minimum with max cap 30 per agent
    use `agen_zeroandaoneresponse_client', clear
    bysort unique_code_agent: gen number_client_peragent = _n
    drop if number_client_peragent >30
    duplicates drop unique_code_agent, force
    replace number_client = 30 if number_client >30

    set scheme plotplain
    histogram number_client, discrete percent ///
		color(maroon) ///
		xlabel(0(5)30 , angle(0)) ///
		xtitle("Number of available clients per agent with zero or one response", size(medsmall)) ///
		ytitle("Percentage (%)", size(medsmall))
    graph export "$output/Agent-Client_`date'/agent_zeroandone_response_max30_histogram.png", replace



    

    /*Adding how many reminders received by each client
    merge 1:1 unique_code_client using `client_baseline_reminders'
    keep if _merge == 3
    drop _merge

    *creating graph of zero response agent
    bysort unique_code_agent: gen number_client = _N
    tempfile agen_zeroandaoneresponse_client
    save `agen_zeroandaoneresponse_client'

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
		xtitle("Number of available clients per agent with zero responses", size(medsmall)) ///
		ytitle("Percentage", size(medsmall))
    graph export "$output/Agent-Client_`date'/agent_zero_response_histogram.png", replace
*/
0
    set scheme plotplain

	histogram total_reminder, discrete percent ///
		color(maroon) ///
		xlabel(1(1) 5, angle(0)) ///
        title ("Distribution of Reminders Received per Client (Agents with Zero Responses)", size(medsmall)) ///
		xtitle("Number of Reminders Received per Client", size(medsmall)) ///
		ytitle("Percentage", size(medsmall))
    graph export "$output/Agent-Client_`date'/client_noresponse_histogram.png", replace


    




