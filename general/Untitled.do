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
	
*************
*IMPORT DATA*
*************


 use "/Users/athonaufalridwan/Library/CloudStorage/Dropbox/J-PAL IFII Agent Banking Network (BM)/06 Data/c Full-Scale/06 Survey Data/dtafiles/02 agent_baseline/cleaned_baseline_agent_survey_23022026.dta", clear
	
	keep unique_code_agent cust_code_agen
	tempfile agent_response
	save `agent_response'
 
 
 use "/Users/athonaufalridwan/Library/CloudStorage/Dropbox/J-PAL IFII Agent Banking Network (BM)/06 Data/c Full-Scale/10 Respondent List/contact_list_agents_final.dta", clear
	keep cust_code_agen unique_code_agent
	merge 1:1 unique_code_agent using `agent_response'
	keep if _merge == 3
	drop _merge
	tempfile agent_response_final
	save `agent_response_final'
 
 use "/Users/athonaufalridwan/Library/CloudStorage/Dropbox/J-PAL IFII Agent Banking Network (BM)/06 Data/c Full-Scale/07 Stratification/data/clean/Final_data_agen_survei_awal_final_new_stratification.dta", clear
	keep id cust_code_agen
	merge 1:1 cust_code_agen using `agent_response_final'
	keep if _merge == 1
	drop _merge
	tempfile agent_noresponse
	save `agent_noresponse'
	
 use "/Users/athonaufalridwan/Library/CloudStorage/Dropbox/J-PAL IFII Agent Banking Network (BM)/06 Data/c Full-Scale/10 Respondent List/contact_list_agents_final.dta", clear	
	keep cust_code_agen unique_code_agent
	merge 1:1 cust_code_agen using `agent_noresponse'
	keep if _merge == 3
	drop _merge
	
	rename id agent_code
	order agent_code, first



	*check
	
	
	
	
	


	


 
 
