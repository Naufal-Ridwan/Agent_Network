*===================================================*
* Full-Scale - Agent Survey (Baseline)
* Objective: Preparing dataset for voucher gift qualification analysis
* Author: Naufal
* Last modified: 17 Agustus 2025
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

*****************************
**------AGENT VOUCHER------**
*****************************

    import excel "$path/06 Survey Data/output/06 compensation/voucher/agent_50000_1.xlsx", sheet("Sheet1") firstrow
    tempfile agent_50000_1
    save `agent_50000_1'

    /*import excel "$path/06 Survey Data/output/06 compensation/voucher/agent_50000_2.xlsx", sheet("Sheet1") firstrow
    *append using `agent_50000_1' // ALSO DO NOT FORGET THE 5K AND ALSO THE REMAINING, THE DATA SHOULD BE 4 DIFFERENT FILES
    */
    
    keep RefId Nominal Sn RedeemLink Reason OperatorName
    replace RefId = substr(RefId, 5, .)
    rename RefId unique_code_agent
    replace Nominal = "50000"
    keep if Reason == "SUCCESS"
    drop Reason
    order unique_code_agent, first
    replace Sn = word(Sn, 1)
    replace RedeemLink = Sn if RedeemLink == "-"
    drop Sn
    replace unique_code_agent = regexr(unique_code_agent, "_1$", "")
    rename unique_code_agent ExternalDataReference

    export delimited using "$path/10 Respondent List/06 respondent_gift_qualtricks/02 agent_baseline/agent_voucher_qualtricks.csv", replace


*****************************
**-----CLIENT VOUCHER------**
*****************************
    clear all

    import excel "$path/06 Survey Data/output/06 compensation/voucher/client_baseline_compensation_d1 (1 & 2).xlsx", sheet("Sheet1") firstrow
    tempfile client_d1
    save `client_d1'

    *import excel "$path/06 Survey Data/output/06 compensation/voucher/client_baseline_compensation_d1 (1 & 2).xlsx", sheet("Sheet1") firstrow
    *append using `client_d1' // ALSO DO NOT FORGET THE 25K, THE DATA SHOULD BE 2 DIFFERENT FILES

    keep RefId Nominal Sn RedeemLink Reason OperatorName
    rename RefId unique_code_client
    replace Nominal = "25000"
    keep if Reason == "SUCCESS"
    drop Reason
    order unique_code_client, first
    replace Sn = word(Sn, 1)
    replace RedeemLink = Sn if RedeemLink == "-"
    drop Sn
    replace unique_code_client = regexr(unique_code_client, "_1$", "")
    rename unique_code_client ExternalDataReference

    export delimited using "$path/10 Respondent List/06 respondent_gift_qualtricks/02 agent_baseline/client_voucher_qualtricks.csv", replace
