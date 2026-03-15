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

*** Generating Agent Dataset for Agent Endline ***
use "/Users/athonaufalridwan/Library/CloudStorage/Dropbox/J-PAL IFII Agent Banking Network (BM)/06 Data/c Full-Scale/06 Survey Data/dtafiles/02 agent_baseline/cleaned_baseline_agent_survey_09032026.dta", clear 
    keep unique_code_agent q_7a treatment_status
    gen shrouding = 1 if q_7a == 1
    replace shrouding = 0 if q_7a == 0

    gen transparent = 1 if q_7a == 0
    replace transparent = 0 if q_7a == 1
    
    drop q_7a
    label drop treatment_status

    tempfile agent_response
    save `agent_response'

use "/Users/athonaufalridwan/Library/CloudStorage/Dropbox/J-PAL IFII Agent Banking Network (BM)/06 Data/c Full-Scale/10 Respondent List/contact_list_clients_final.dta", clear
    duplicates drop unique_code_agent, force
    drop cust_code_nasabah unique_code_client n_clients
    merge 1:1 unique_code_agent using `agent_response'
    order unique_code_agent, first 
    keep if _merge == 3
    drop _merge
    rename unique_code_agent ExternalDataReference

export delimited using "//Users/athonaufalridwan/Library/CloudStorage/Dropbox/J-PAL IFII Agent Banking Network (BM)/06 Data/c Full-Scale/09 Contact List/01. Qualtrics_library/agent_baseline_response_10.03.2026.csv", replace
*export excel using "/Users/athonaufalridwan/Library/CloudStorage/Dropbox/J-PAL IFII Agent Banking Network (BM)/06 Data/c Full-Scale/09 Contact List/01. Qualtricks_library/agent_baseline_response_10.03.2026.xls", firstrow(variables) replace

*** Generating Client Dataset for Client Midline ***
use "/Users/athonaufalridwan/Library/CloudStorage/Dropbox/J-PAL IFII Agent Banking Network (BM)/06 Data/c Full-Scale/06 Survey Data/dtafiles/01 client_baseline/cleaned_baseline_client_survey_23022026.dta", clear
    keep unique_code_client 
    gen response = 1
    duplicates drop unique_code_client, force
    tempfile client_response
    save `client_response'

import delimited "/Users/athonaufalridwan/Library/CloudStorage/Dropbox/J-PAL IFII Agent Banking Network (BM)/06 Data/c Full-Scale/09 Contact List/contact_list_clients_final_v2.csv", clear    
    rename externaldatareference unique_code_client
    rename kode_unik_survei_agen unique_code_agent
    merge 1:1 unique_code_client using `client_response'
    order unique_code_client, first
    replace response = 0 if response == .
    drop _merge
    merge m:1 unique_code_agent using `agent_response'
    keep if _merge == 3
    drop _merge shrouding transparent
    rename unique_code_client ExternalDataReference

export delimited using "//Users/athonaufalridwan/Library/CloudStorage/Dropbox/J-PAL IFII Agent Banking Network (BM)/06 Data/c Full-Scale/09 Contact List/01. Qualtrics_library/client_baseline_response_10.03.2026.csv", replace
*export excel using "/Users/athonaufalridwan/Library/CloudStorage/Dropbox/J-PAL IFII Agent Banking Network (BM)/06 Data/c Full-Scale/09 Contact List/01. Qualtricks_library/client_baseline_response_10.03.2026.xlsx", firstrow(variables) replace