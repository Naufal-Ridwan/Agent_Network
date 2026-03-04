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


use "/Users/athonaufalridwan/Library/CloudStorage/Dropbox/J-PAL IFII Agent Banking Network (BM)/06 Data/c Full-Scale/06 Survey Data/dtafiles/02 agent_baseline/cleaned_baseline_agent_survey_`date'.dta", clear

keep unique_code_agent
tempfile agent_response
save `agent_response'

use "/Users/athonaufalridwan/Library/CloudStorage/Dropbox/J-PAL IFII Agent Banking Network (BM)/06 Data/c Full-Scale/10 Respondent List/contact_list_agents_final.dta", clear

keep cust_code_agen unique_code_agent

merge 1:1 unique_code_agent using `agent_response'

keep if _merge == 1
drop _merge
ren unique_code_agent kode_unik_survey_agen

export excel using "/Users/athonaufalridwan/Library/CloudStorage/Dropbox/J-PAL IFII Agent Banking Network (BM)/06 Data/c Full-Scale/10 Respondent List/output/(daftar penerima) Pengingat via ABS_`date'.xlsx", firstrow(variables) replace















