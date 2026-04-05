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
	gl path "/Users/athonaufalridwan/Library/CloudStorage/Dropbox/J-PAL IFII Agent Banking Network (BM)/06 Data/c Full-Scale"

* Set the path
gl do            "$path/06 Survey Data/dofiles"
gl dta           "$path/06 Survey Data/dtafiles"
gl log           "$path/06 Survey Data/logfiles"
gl output        "$path/06 Survey Data/output"
gl raw           "$path/06 Survey Data/rawresponses"

**********************************************************
*** PREPARING THE DATA SET FOR POSTER AND NOTIFICATION ***
**********************************************************
    use "$path/06 Survey Data/dtafiles/02 agent_baseline/cleaned_baseline_agent_survey_16032026.dta", clear
    tempfile agent_baseline
    save `agent_baseline'

    use "$path/06 Survey Data/dtafiles/01 client_baseline/cleaned_baseline_client_survey_30032026.dta", clear
    tempfile client_baseline
    save `client_baseline'

    import delimited "/Users/athonaufalridwan/Library/CloudStorage/Dropbox/J-PAL IFII Agent Banking Network (BM)/06 Data/c Full-Scale/09 Contact List/contact_list_clients_final_v2.csv", clear    
	rename kode_unik_survei_agen unique_code_agent
	rename externaldatareference unique_code_client
	keep unique_code_agent unique_code_client cust_code_agen cust_code_nasabah
	tempfile contact_list_client_final
	save `contact_list_client_final'

	merge m:1 unique_code_agent using `agent_baseline'
	keep if _merge ==3
	tempfile contact_list_agent_response
	save `contact_list_agent_response'
    drop _merge

***# 1. GENERATING REMINDER LIST FOR AGENT -- POSTERS AND NOTIFICATIONS

    *#1. Generating T2 & T3 Transparent notification
    use `contact_list_agent_response', clear
    keep unique_code_agent cust_code_agen treatment_status q_7a
    keep if treatment_status == 2 | treatment_status == 3
    keep if q_7a == 0 // 0 means plan B (Transparent)
    drop treatment_status q_7a
    duplicates drop unique_code_agent, force
    export excel using "$path/10 Respondent List/00 respondent_list_posterandnotif/mdab_jpalsea_informasi_agen_plasebo_final.xlsx", firstrow(varlabels) replace

    *#2. Generating T2 & T3 Shrouding
    use `contact_list_agent_response', clear
    keep unique_code_agent cust_code_agen treatment_status q_7a
    keep if treatment_status == 2 | treatment_status == 3 | treatment_status == 0 | treatment_status == 1
    keep if q_7a == 1 // 1 means plan A (Shrouding)
    drop treatment_status q_7a 
    duplicates drop unique_code_agent, force
    export excel using "$path/10 Respondent List/00 respondent_list_posterandnotif/mdab_jpalsea_informasi_agen_tarif_final.xlsx", firstrow(varlabels) replace

    *#3. Generating T4 Price List
    use `contact_list_agent_response', clear
    keep unique_code_agent cust_code_agen treatment_status q_7a
    keep if treatment_status == 4
    drop treatment_status q_7a
    duplicates drop unique_code_agent, force
    export excel using "$path/10 Respondent List/00 respondent_list_posterandnotif/agen_t4_belum_ada_template.xlsx", firstrow(varlabels) replace

***# 2. GENERATING REMINDER LIST FOR CLIENT -- POSTERS AND NOTIFICATIONS

    *#1. Generating T2 & T3 Transparent notification
    use `contact_list_agent_response', clear
    keep unique_code_client cust_code_nasabah treatment_status q_7a
    keep if treatment_status == 2 | treatment_status == 3
    keep if q_7a == 0 // 0 means plan B (Transparent)
    drop treatment_status q_7a
    duplicates drop unique_code_client, force
    export excel using "$path/10 Respondent List/00 respondent_list_posterandnotif/mdab_jpalsea_informasi_nasabah_harga_final.xlsx", firstrow(varlabels) replace

    *#2. Generating T2 & T3 Shrouding
    use `contact_list_agent_response', clear
    keep unique_code_client cust_code_nasabah treatment_status q_7a
    keep if (treatment_status == 0 | treatment_status == 1) | ///
            ((treatment_status == 2 | treatment_status == 3) & q_7a == 1)
    drop treatment_status q_7a
    duplicates drop unique_code_client, force
    export excel using "$path/10 Respondent List/00 respondent_list_posterandnotif/mdab_jpalsea_informasi_nasabah_plasebo_final.xlsx", firstrow(varlabels) replace

    *#3. Generating T4 Price List
    use `contact_list_agent_response', clear
    keep unique_code_client cust_code_nasabah treatment_status q_7a
    keep if treatment_status == 4
    drop treatment_status q_7a
    duplicates drop unique_code_client, force
    export excel using "$path/10 Respondent List/00 respondent_list_posterandnotif/nasabah_t4_belum_ada_template.xlsx", firstrow(varlabels) replace