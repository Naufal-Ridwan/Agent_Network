*===================================================*
* Full-Scale - Agent Survey (Baseline)
* Currently cleaning the benchtest survey
* Author: Muthia
* Last modified: 17 Agustus 2025
* Last modified by: Muthia
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
gl do            "$path/06 Survey Data/dofiles/agent_baseline"
gl dta           "$path/06 Survey Data/dtafiles"
gl log           "$path/06 Survey Data/logfiles"
gl output        "$path/06 Survey Data/output"
gl raw           "$path/06 Survey Data/rawresponses"

***IMPORTANT***

* Set local date
local date : di %tdDNCY daily("$S_DATE", "DMY") //this is the default code, it will automatically capture the current date
//local date "DDMMYYYY" // only use this manual setting if you're running this code late than the supposed day

*********************************
**-------AGENT RESPONDENTS-----**

use "$dta/02 agent_baseline/cleaned_baseline_agent_survey_09032026.dta", clear
    keep unique_code_agent
    tempfile agent_response
    save `agent_response'

import delimited "/Users/athonaufalridwan/Library/CloudStorage/Dropbox/J-PAL IFII Agent Banking Network (BM)/06 Data/c Full-Scale/09 Contact List/contact_list_clients_final_v2.csv", clear    
    rename  kode_unik_survei_agen unique_code_agent
    duplicates drop unique_code_agent, force
    keep unique_code_agent cust_code_agen
    merge 1:1 unique_code_agent using `agent_response'
    order unique_code_agent, first 
    drop if _merge == 3
    drop _merge
    order unique_code_agent, last

export excel using "/Users/athonaufalridwan/Library/CloudStorage/Dropbox/J-PAL IFII Agent Banking Network (BM)/06 Data/c Full-Scale/10 Respondent List/(daftar penerima) mdab_jpalsea_survei_agen_pengingat_ketiga_final.xlsx", firstrow(variables) replace

*********************************
**-------CLIENT RESPONDENTS-----**
use "$dta/02 agent_baseline/cleaned_baseline_agent_survey_16032026.dta", clear 
	duplicates drop unique_code_agent, force
	tempfile agent_response
	save `agent_response'
	
use "$dta/01 client_baseline/cleaned_baseline_client_survey_23022026.dta", clear

	rename unique_code_client unique_code_nasabah
	duplicates drop unique_code_nasabah, force
	tempfile client_response
	save `client_response'
	
	
use "$path/10 Respondent List/contact_list_clients_final.dta", clear
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

    keep if total_respon_per_agen ==0
    rename unique_code_nasabah unique_code_client
    tempfile agen_noresponse
    save `agen_noresponse'


import delimited "/Users/athonaufalridwan/Library/CloudStorage/Dropbox/J-PAL IFII Agent Banking Network (BM)/06 Data/c Full-Scale/09 Contact List/contact_list_clients_final_v2.csv", clear    
    rename externaldatareference unique_code_client
    duplicates drop unique_code_client, force
    rename kode_unik_survei_agen unique_code_agent
    keep unique_code_client cust_code_nasabah unique_code_agent
    merge m:1 unique_code_agent using `agen_noresponse'
    keep if total_respon_per_agen == 0
    drop _merge
    drop strata treatment_status agent_status total_respon_per_agen
    
   *Generating number of clients per agent
    bysort unique_code_agent: gen num = _n
    keep if num <100 // we only want to include agents with less than 30 clients, since the survey is only sent to 30 clients per agent. This is to avoid including agents who have more than 30 clients but only a few of them are included in the survey, which could lead to bias in the results.
    drop num unique_code_agent
    rename unique_code_client kode_unik_survei_nasabah
export excel using "/Users/athonaufalridwan/Library/CloudStorage/Dropbox/J-PAL IFII Agent Banking Network (BM)/06 Data/c Full-Scale/10 Respondent List/(daftar penerima) mdab_jpalsea_survei_nasabah_pengingat_kedua_`date'.xlsx", firstrow(variables) replace
