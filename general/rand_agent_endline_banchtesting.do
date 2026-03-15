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
gl do            "$path/dofiles/01 agent_baseline"
gl dta           "$path/dtafiles"
gl log           "$path/logfiles"
gl output        "$path/output"
gl raw           "$path/rawresponses/01 agent _baseline"
	
*************
*IMPORT DATA*
*************


 use "/Users/athonaufalridwan/Library/CloudStorage/Dropbox/J-PAL IFII Agent Banking Network (BM)/06 Data/c Full-Scale/06 Survey Data/dtafiles/02 agent_baseline/cleaned_baseline_agent_survey_23022026.dta", clear

keep treatment_status strata unique_code_agent q_7a 
set seed 12345

* Buat angka random
gen u = runiform()

* Dalam tiap kombinasi treatment × strata × q_7a, ambil 1
bysort treatment_status strata q_7a (u): ///
    gen pick = (_n==1)

drop u
keep if pick == 1
gen num = _n
order num, first
drop pick
export excel using "/Users/athonaufalridwan/Library/CloudStorage/Dropbox/J-PAL IFII Agent Banking Network (BM)/06 Data/c Full-Scale/06 Survey Data/dofiles/general/agent_benchtesting_endline.xls", firstrow(variables) replace
tempfile agent_benchtesting_endline
save `agent_benchtesting_endline'

****=== CLIENT RAND FOR BENCH TESTING ===*****

*Generating client that response in the baseline survey
use "/Users/athonaufalridwan/Library/CloudStorage/Dropbox/J-PAL IFII Agent Banking Network (BM)/06 Data/c Full-Scale/10 Respondent List/contact_list_clients_final.dta", clear
	keep unique_code_agent unique_code_client
	merge m:1 unique_code_agent using `agent_benchtesting_endline'
    keep if _merge == 3
    drop _merge num
    tempfile client_benchtesting_endline
    save `client_benchtesting_endline'

use "/Users/athonaufalridwan/Library/CloudStorage/Dropbox/J-PAL IFII Agent Banking Network (BM)/06 Data/c Full-Scale/06 Survey Data/dtafiles/01 client_baseline/cleaned_baseline_client_survey_23022026.dta", clear
    keep unique_code_client
    gen baseline_status = 1
    merge 1:1 unique_code_client using `client_benchtesting_endline'
    drop if _merge == 1
    bysort unique_code_agent: egen total_respon_per_agen = count(unique_code_client)
    replace baseline_status = 0 if baseline_status == .
    order unique_code_agent, first

    * Ambil 1 yang baseline status complete dan 1 yang tidak merespon
    sort unique_code_agent baseline_status
    bysort unique_code_agent baseline_status: gen num = _n
    keep if num == 1
    drop num

    * Put the cap on 60 for maximum benchtesting
    set seed 12345
    gen rand = runiform()
    sort rand
    keep in 1/60
    drop rand total_respon_per_agen q_7a _merge
    order unique_code_agent treatment_status strata unique_code_client baseline_status
export excel using "/Users/athonaufalridwan/Library/CloudStorage/Dropbox/J-PAL IFII Agent Banking Network (BM)/06 Data/c Full-Scale/06 Survey Data/dofiles/general/client_benchtesting_endline.xls", firstrow(variables) replace
