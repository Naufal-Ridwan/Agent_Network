*===================================================*
* Full-Scale - Client Survey (Baseline)
* WEIGHTED AVERAGE
* Author: Riko
* Last modified: 2 Sep 2025
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
gl dta           "$path/dtafiles/01 client_baseline"
gl log           "$path/logfiles"
gl output        "$path/output"
gl raw           "$path/rawresponses/client_baseline"
	
***IMPORTANT***

* Set local date
loc date : di %tdDNCY daily("$S_DATE", "DMY") // this is the default code, it will automatically capture the current date
// loc date "DDMMYYYY" // only use this manual setting if you're running this code late than the supposed day

shell mkdir "$output/Client Baseline - `date'"

*************
*IMPORT DATA*
*************
 use "/Users/athonaufalridwan/Library/CloudStorage/Dropbox/J-PAL IFII Agent Banking Network (BM)/06 Data/c Full-Scale/06 Survey Data/dtafiles/01 client_baseline/cleaned_baseline_client_survey_02022026.dta", clear
replace unique_code = externalreference if missing(unique_code)
keep unique_code
duplicates drop unique_code
tempfile nasabah_response
save `nasabah_response'

use 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
