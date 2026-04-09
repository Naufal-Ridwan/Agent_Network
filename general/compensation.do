*===================================================*
* Full-Scale - Agent Survey (Baseline)
* Currently cleaning the benchtest survey
* Author: Muthia
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

**************************************
**----------AGENT COMPENSATION------**

use "$dta/02 agent_baseline/cleaned_baseline_agent_survey_16032026.dta", clear
	sort enddate
	keep unique_code_agent compensation_option q_7a
	lab var compensation_option "Compensation option"

	destring compensation_option, replace
	label define comp_opt 1 "Indomaret" 2 "Alfamart" 3 "Tokopedia", replace
	label values compensation_option comp_opt

	rename compensation_option Merchant
	lab var Merchant "Merchant"
	lab var unique_code_agent "Ref ID"
	
	order Merchant, first
	gen Nominal = 50000
	replace Nominal = 55000 if q_7a == 1
	lab var Nominal "Nominal"
	order unique_code_agent, last
	
	*Generating 8000 respondent for first wave of voucher
		
	expand 2 if Nominal == 55000
	bysort unique_code_agent: gen split_order = _n if Nominal == 55000
	replace Nominal = cond(split_order==1, 50000, 5000) if Nominal == 55000
	tostring unique_code_agent, replace
	gen unique_code_agent_final = unique_code_agent + "_" + string(split_order) if split_order < .
	replace unique_code_agent = unique_code_agent_final if unique_code_agent_final != ""
	drop split_order unique_code_agent_final

	tempfile agent_compensation
	save `agent_compensation'

	drop if Nominal == 5000

	gen n = _n
	drop if n >5000
	drop n q_7a
	replace unique_code_agent = "001_" + unique_code_agent

	*First 5000 agent
	export excel using "$path/06 Survey Data/output/compensation/agent_baseline_compensation(50000)_1.xlsx", ///
    firstrow(varlabels) cell(A3) replace
	
	putexcel set "$path/06 Survey Data/output/compensation/agent_baseline_compensation(50000)_1.xlsx", modify

	putexcel A1 = ("UPLOAD VOUCHER IAK"), bold
	putexcel A2 = ("")

	*Second 5000 agent
	use `agent_compensation', clear
	drop if Nominal == 5000
	gen n = _n
	keep if n >= 5001 & n <= 10000
	drop n q_7a
	replace unique_code_agent = "001_" + unique_code_agent

	export excel using "$path/06 Survey Data/output/compensation/agent_baseline_compensation(50000)_2.xlsx", ///
    firstrow(varlabels) cell(A3) replace
	
	putexcel set "$path/06 Survey Data/output/compensation/agent_baseline_compensation(50000)_2.xlsx", modify

	putexcel A1 = ("UPLOAD VOUCHER IAK"), bold
	putexcel A2 = ("")

	*Remaining 147 agent
	use `agent_compensation', clear
	drop if Nominal == 5000
	gen n = _n
	keep if n >= 10001
	drop n q_7a
	replace unique_code_agent = "001_" + unique_code_agent

	export excel using "$path/06 Survey Data/output/compensation/agent_baseline_compensation(50000)_3.xlsx", ///
    firstrow(varlabels) cell(A3) replace
	
	putexcel set "$path/06 Survey Data/output/compensation/agent_baseline_compensation(50000)_3.xlsx", modify

	putexcel A1 = ("UPLOAD VOUCHER IAK"), bold
	putexcel A2 = ("")

	*Agent recieved additional IDR5000 compensation
	use `agent_compensation', clear
	drop if Nominal == 50000
	drop q_7a
	replace unique_code_agent = "001_" + unique_code_agent

	export excel using "$path/06 Survey Data/output/compensation/agent_baseline_compensation(5000).xlsx", ///
    firstrow(varlabels) cell(A3) replace
	
	putexcel set "$path/06 Survey Data/output/compensation/agent_baseline_compensation(5000).xlsx", modify

	putexcel A1 = ("UPLOAD VOUCHER IAK"), bold
	putexcel A2 = ("")




**************************************
**----------CLIENT COMPENSATION------**
*Data from 02 February 2026
use "$dta/01 client_baseline/cleaned_baseline_client_survey_30032026.dta", clear

	keep enddate q_13a unique_code_client
	rename q_13a compensation_option
	lab var compensation_option "Compensation option"

	rename compensation_option Merchant
	lab var Merchant "Merchant"
	lab var unique_code_client "Ref ID"
	gen Nominal = 25000
	lab var Nominal "Nominal"
	sort enddate

	set seed 123
	tempvar r
	gen `r' = runiform() if Merchant == ""

	replace Merchant = cond(`r' <= 1/3, "Indomaret", cond(`r' <= 2/3, "Alfamart", "Tokopedia")) if Merchant == ""
	
	gen n = _n
	order Merchant, first
	order unique_code_client, last
	keep Merchant unique_code_client Nominal n
	tempfile client_compensation
	save `client_compensation'

	*keep 5000 respondents for first wave of voucher
	drop if n >5000
	drop n

	export excel using "$path/06 Survey Data/output/compensation/client_baseline_compensation_d1_1.xlsx", ///
    firstrow(varlabels) cell(A3) replace
	
	putexcel set "$path/06 Survey Data/output/compensation/client_baseline_compensation_d1_1.xlsx", modify

	putexcel A1 = ("UPLOAD VOUCHER IAK"), bold
	putexcel A2 = ("")

	*generate 5000 respondents for second wave of voucher
	use `client_compensation', clear
	keep if n >= 5001 & n <= 10000
	drop n

	export excel using "$path/06 Survey Data/output/compensation/client_baseline_compensation_d1_2.xlsx", ///
    firstrow(varlabels) cell(A3) replace
	putexcel set "$path/06 Survey Data/output/compensation/client_baseline_compensation_d1_2.xlsx", modify
	putexcel A1 = ("UPLOAD VOUCHER IAK"), bold
	putexcel A2 = ("")
	
	*generate 10001 respondents for second wave of voucher
	use `client_compensation', clear
	keep if n >= 10001 & n <= 15000
	drop n

	export excel using "$path/06 Survey Data/output/compensation/client_baseline_compensation_d2_1.xlsx", ///
    firstrow(varlabels) cell(A3) replace
	putexcel set "$path/06 Survey Data/output/compensation/client_baseline_compensation_d2_1.xlsx", modify
	putexcel A1 = ("UPLOAD VOUCHER IAK"), bold
	putexcel A2 = ("")

	*generate 18001 respondents for second wave of voucher
	use `client_compensation', clear
	keep if n >= 15001 & n <= 20000
	drop n

	export excel using "$path/06 Survey Data/output/compensation/client_baseline_compensation_d2_2.xlsx", ///
    firstrow(varlabels) cell(A3) replace
	putexcel set "$path/06 Survey Data/output/compensation/client_baseline_compensation_d2_2.xlsx", modify
	putexcel A1 = ("UPLOAD VOUCHER IAK"), bold
	putexcel A2 = ("")

	*generate 18001 respondents for second wave of voucher
	use `client_compensation', clear	
	keep if n >= 20001
	drop n

	export excel using "$path/06 Survey Data/output/compensation/client_baseline_compensation_d3.xlsx", ///
    firstrow(varlabels) cell(A3) replace
	putexcel set "$path/06 Survey Data/output/compensation/client_baseline_compensation_d3.xlsx", modify
	putexcel A1 = ("UPLOAD VOUCHER IAK"), bold
	putexcel A2 = ("")





