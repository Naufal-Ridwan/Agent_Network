*===================================================*
* Full-Scale - Client Survey (Baseline)
* HFC
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

* Muthia
    *gl path "C:\Users\jpals\Dropbox\J-PAL IFII Agent Banking Network (BM)\06 Data\c Full-Scale\06 Survey Data"
    //gl path "/Users/auliamuthia/Desktop/J-PAL IFII Agent Banking Network (BM)/06 Data/c Full-Scale/06 Survey Data"
	
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
use "$dta/cleaned_baseline_client_survey_02022026.dta", clear 
	duplicates drop unique_code, force // 6,460 observations deleted -- anomali, harusnya tidak ada duplicates unique code
	rename unique_code unique_code_nasabah
	tempfile client_response
	save `client_response'
	
use "/Users/athonaufalridwan/Library/CloudStorage/Dropbox/J-PAL IFII Agent Banking Network (BM)/06 Data/c Full-Scale/10 Respondent List/contact_list_clients_final", clear

	rename kode_unik_survei_nasabah unique_code_nasabah
	duplicates drop unique_code_nasabah,force
	merge 1:1 unique_code_nasabah using `client_response'

	keep if _merge ==3 //keep only if the unqiue code match	
	drop n client_num village subdistrict district id
	rename kode_unik_survei_agen unique_code_agen
	bysort unique_code_agen: gen n_client = _N
	
preserve
*q_1a_3
    drop if missing(q_1a_3)
	set scheme jpalfull
	qui count
	local total_n = r(N)

    forvalues i = 1/8 {
        gen is_q_1a_3_`i' = (q_1a_3 == `i')        
        bysort unique_code_agen: egen prop_q_1a_3_`i' = mean(is_q_1a_3_`i')        
        gen pct_q_1a_3_`i' = prop_q_1a_3_`i' * 100
    }

    bysort unique_code_agen: keep if _n == 1
	
    graph bar (mean) pct_q_1a_3_1 pct_q_1a_3_2 pct_q_1a_3_3 pct_q_1a_3_4 pct_q_1a_3_5 pct_q_1a_3_6 pct_q_1a_3_7 pct_q_1a_3_8, ///
		ytitle("Percentage (%) of clients", size(medsmall) orientation(vertical)) ///
		ylabel(0(5)25) ///
		blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
		title("What was {bf:the approximate transaction fee} charged by {bf:BM Agent}", size(medsmall)) ///
		subtitle("you use the last time you made {bf:a cash deposit}?", size(medsmall)) ///
		legend(order(1 "Rp0 - 500" 2 "Rp500 - 1.500" 3 "Rp1.500 - 2.500" 4 "Rp2.500 - 3.500" 5 "Rp3.500 - 4.500" ///
		6 "Rp4.500 - 5.500" 7 "Rp5.500 - 6.500" 8 "More than Rp6.500") size(small) col(3)) ///
		note("Total clients = `: di %6.0fc `total_n''", size(medsmall)) 
	
	graph export "$output/Client Baseline - `date'/7 - client_q_1a_3_w.png", as(png) replace
	
restore
*q_1b
preserve

    drop if missing(q_1b)
	set scheme jpalfull
	qui count
	local total_n = r(N)

    forvalues i = 1/6 {
        gen is_q_1b_`i' = (q_1b == `i')        
        bysort unique_code_agen: egen prop_q_1b_`i' = mean(is_q_1b_`i')        
        gen pct_q_1b_`i' = prop_q_1b_`i' * 100
    }

    bysort unique_code_agen: keep if _n == 1
	
    graph bar (mean) pct_q_1b_1 pct_q_1b_2 pct_q_1b_3 pct_q_1b_4 pct_q_1b_5 pct_q_1b_6, ///
		ytitle("Percentage (%) of clients", size(medsmall) orientation(vertical)) ///
		ylabel(0(10)50) ///
		blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
		title("When was the last time you did a{bf: cash deposit} with{bf: a non-BM Agent}?", size(medsmall)) ///
		subtitle(" ", size(medsmall)) ///
		legend(order(1 "Within the past 7 days" 2 "8-15 days ago" 3 "16-30 days ago" 4 "More than one month ago" ///
		5 "More than six month ago" 6 "I haven't done this transaction with BM Agent before") size(vsmall) col(2)) ///
	note("Total clients = `: di %6.0fc `total_n''", size(medsmall))
	
	graph export "$output/Client Baseline - `date'/9 - client_q_1b_w.png", as(png) replace
	
restore
*q_2a
preserve

    drop if missing(q_2a)
	set scheme jpalfull
	qui count
	local total_n = r(N)

    forvalues i = 1/6 {
        gen is_q_2a_`i' = (q_2a == `i')        
        bysort unique_code_agen: egen prop_q_2a_`i' = mean(is_q_2a_`i')        
        gen pct_q_2a_`i' = prop_q_2a_`i' * 100
    }

    bysort unique_code_agen: keep if _n == 1
	
    graph bar (mean) pct_q_2a_1 pct_q_2a_2 pct_q_2a_3 pct_q_2a_4 pct_q_2a_5 pct_q_2a_6, ///
		ytitle("Percentage (%) of clients", size(small) orientation(vertical)) ///
		ylabel(0(5)35) ///
		blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
		title("When was the last time you did a{bf: cash withdrawal} with{bf: BM Agent}?", size(medsmall)) ///
		subtitle(" ", size(medsmall)) ///
		legend(order(1 "Within the past 7 days" 2 "8-15 days ago" 3 "16-30 days ago" 4 "More than one month ago" ///
		5 "More than six month ago" 6 "I haven't done this transaction with BM Agent before") size(vsmall) col(2)) ///
		note("Total clients = `: di %6.0fc `total_n''", size(medsmall)) 
		
	graph export "$output/Client Baseline - `date'/12 - client_q_2a_w.png", as(png) replace
	
	
restore
*q_2a_3
preserve

    drop if missing(q_2a_3)
	set scheme jpalfull
	qui count
	local total_n = r(N)

    forvalues i = 1/6 {
        gen is_q_2a_3_`i' = (q_2a_3 == `i')        
        bysort unique_code_agen: egen prop_q_2a_3_`i' = mean(is_q_2a_3_`i')        
        gen pct_q_2a_3_`i' = prop_q_2a_3_`i' * 100
    }

    bysort unique_code_agen: keep if _n == 1
	
    graph bar (mean) pct_q_2a_3_1 pct_q_2a_3_2 pct_q_2a_3_3 pct_q_2a_3_4 pct_q_2a_3_5 pct_q_2a_3_6, ///
		ytitle("Percentage (%) of clients", size(medsmall) orientation(vertical)) ///
		ylabel(0(5)30) ///
		blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
		title("What was {bf:the approximate transaction fee} charged by {bf:BM Agent}", size(medsmall)) ///
		subtitle("you use the last time you made {bf:a cash withdrawal}?", size(medsmall)) ///
		legend(order(1 "Rp0 - 500" 2 "Rp500 - 1.500" 3 "Rp1.500 - 2.500" 4 "Rp2.500 - 3.500" 5 "Rp3.500 - 4.500" 6 "Rp4.500 - 5.500" 7 "Rp5.500 - 6.500" 8 "More than Rp6.500") size(small) col(3)) ///
		note("Total clients = `: di %6.0fc `total_n''", size(small)) 
		
	graph export "$output/Client Baseline - `date'/15 - client_q_2a_3_w.png", as(png) replace
	

restore
*q_2b
preserve

    drop if missing(q_2b)
	set scheme jpalfull
	qui count
	local total_n = r(N)

    forvalues i = 1/6 {
        gen is_q_2b_`i' = (q_2b == `i')        
        bysort unique_code_agen: egen prop_q_2b_`i' = mean(is_q_2b_`i')        
        gen pct_q_2b_`i' = prop_q_2b_`i' * 100
    }

    bysort unique_code_agen: keep if _n == 1
	
    graph bar (mean) pct_q_2b_1 pct_q_2b_2 pct_q_2b_3 pct_q_2b_4 pct_q_2b_5 pct_q_2b_6, ///
		ytitle("Percentage (%) of clients", size(medsmall) orientation(vertical)) ///
		ylabel(0(10)50) ///
		blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
		title("When was the last time you did a{bf: cash withdrawal} with{bf: a non-BM Agent}?", size(medsmall)) ///
		subtitle(" ", size(medsmall)) ///
		legend(order(1 "Within the past 7 days" 2 "8-15 days ago" 3 "16-30 days ago" 4 "More than one month ago" ///
		5 "More than six month ago" 6 "I haven't done this transaction with BM Agent before") size(vsmall) col(2)) ///
	note("Total clients = `: di %6.0fc `total_n''", size(small)) 
	
	graph export "$output/Client Baseline - `date'/17 - client_q_2b_w.png", as(png) replace
	
	
restore
*q_3a
preserve

    drop if missing(q_3a)
	set scheme jpalfull
	qui count
	local total_n = r(N)

    forvalues i = 1/5 {
        gen is_q_3a_`i' = (q_3a == `i')        
        bysort unique_code_agen: egen prop_q_3a_`i' = mean(is_q_3a_`i')        
        gen pct_q_3a_`i' = prop_q_3a_`i' * 100
    }

    bysort unique_code_agen: keep if _n == 1
	
    graph bar (mean) pct_q_3a_1 pct_q_3a_2 pct_q_3a_3 pct_q_3a_4 pct_q_3a_5, ///
		ytitle("Percentage (%) of clients", size(medsmall) orientation(vertical)) ///
		ylabel(0(5)40) ///
		blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
		title("Banking agents {bf:charge a fee} for each transaction made with them.", size(medsmall)) ///
		subtitle("How do you think these fees {bf:are set}?", size(medsmall)) ///
		legend(order(1 "There's an official price and the agent has to stick with it" ///
		2 "There's an official price, but agent can charge more/less" 3 "No official price and agent can decide the price" ///
		4 "The government sets the prices" 5 "I do not know") size(small) col(1)) ///
	note("Total clients = `: di %6.0fc `total_n''", size(small)) 
	
	graph export "$output/Client Baseline - `date'/20 - client_q_3a_w.png", as(png) replace

	
restore
*q_3a_1
preserve

    drop if missing(q_3a_1)
	set scheme jpalfull
	qui count
	local total_n = r(N)

    forvalues i = 1/3 {
        gen is_q_3a_1_`i' = (q_3a_1 == `i')        
        bysort unique_code_agen: egen prop_q_3a_1_`i' = mean(is_q_3a_1_`i')        
        gen pct_q_3a_1_`i' = prop_q_3a_1_`i' * 100
    }

    bysort unique_code_agen: keep if _n == 1

    graph bar (mean) pct_q_3a_1_1 pct_q_3a_1_2 pct_q_3a_1_3, ///
		ytitle("Percentage (%) of clients", size(medsmall) orientation(vertical)) ///
		ylabel(0(10)60) ///
		blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
		title("Does the agent typically {bf:charge more or less} than official price?", size(medsmall)) ///
		subtitle(" ", size(medsmall)) ///
		legend(order(1 "More" 2 "Less" 3 "Depends on the client (sometimes more/less)") size(medsmall) col(1)) ///
		note("Total clients = `: di %6.0fc `total_n''", size(small)) 
		
	graph export "$output/Client Baseline - `date'/21 - client_q_3a_1_w.png", as(png) replace
	
restore
*q_3b
preserve

	drop if missing(q_3b)
	set scheme jpalfull
	qui count
	local total_n = r(N)
	
    bysort unique_code_agen: egen n_yes = total(q_3b == 1)
    bysort unique_code_agen: gen n_total_agen = _N
    gen p_yes = n_yes / n_total_agen
    gen p_no  = 1 - p_yes

    bysort unique_code_agen: keep if _n == 1

    gen pct_yes = p_yes * 100
    gen pct_no  = p_no * 100
	
	graph bar (mean) pct_yes pct_no, /// percent is the default
		ytitle("Percentage (%) of clients", size(medsmall) orientation(vertical)) ///
		ylabel(0(25)75) ///
		blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
		title("Display of BM official price list in shop", size(medsmall)) ///
		subtitle("", size(medsmall)) ///
		legend(order(1 "Yes" 2 "No") size(medsmall) col(2)) ///
		note("Total clients = `: di %6.0fc `total_n''", size(small))
		
	graph export "$output/Client Baseline - `date'/22 - client_q_3b_w.png", as(png) replace
	
restore
*q_3c
preserve
   
	drop if missing(q_3c)
	set scheme jpalfull
	qui count
	local total_n = r(N)
	
    bysort unique_code_agen: egen n_yes = total(q_3c == 1)
    bysort unique_code_agen: gen n_total_agen = _N
    gen p_yes = n_yes / n_total_agen
    gen p_no  = 1 - p_yes

    bysort unique_code_agen: keep if _n == 1

    gen pct_yes = p_yes * 100
    gen pct_no  = p_no * 100
	
	graph bar (mean) pct_yes pct_no, /// percent is the default
		ytitle("Percentage (%) of clients", size(medsmall) orientation(vertical)) ///
		ylabel(0(25)100) ///
		blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
		title("Does your {bf:BM Agent} set the {bf:same price} for everyone?", size(medsmall)) ///
		subtitle(" ", size(medsmall)) ///
		legend(order(1 "Yes" 2 "No") size(medsmall) col(2)) ///
		note("Total clients = `: di %6.0fc `total_n''", size(medsmall)) 
	
	graph export "$output/Client Baseline - `date'/23 - client_q_3c_w.png", as(png) replace

	
restore
*q_3c_1
preserve
   
	drop if missing(q_3c_1)
	set scheme jpalfull
	qui count
	local total_n = r(N)
	
    bysort unique_code_agen: egen n_yes = total(q_3c_1 == 1)
    bysort unique_code_agen: gen n_total_agen = _N
    gen p_yes = n_yes / n_total_agen
    gen p_no  = 1 - p_yes

    bysort unique_code_agen: keep if _n == 1

    gen pct_yes = p_yes * 100
    gen pct_no  = p_no * 100
	
	graph bar (mean) pct_yes pct_no, /// percent is the default
		ytitle("Percentage (%) of clients", size(medsmall) orientation(vertical)) ///
		ylabel(0(25)90) ///
		blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
		title("If not, do you think there is a specific type of customer", size(medsmall)) ///
		subtitle("that your {bf:BM Agent} charge {bf:less}?", size(medsmall)) ///
		legend(order(1 "Yes" 2 "No") size(medsmall) col(2)) ///
		note("Total clients = `: di %6.0fc `total_n''", size(small)) 
	
	graph export "$output/Client Baseline - `date'/24 - client_q_3c_1_w.png", as(png) replace
	
restore
*q_3c_1_1
preserve

    drop if missing(q_3c_1_1)
	set scheme jpalfull
	qui count
	local total_n = r(N)

    foreach i in 1 2 4 5 6 7 8 {
    gen is_q_3c_1_1_`i' = (q_3c_1_1 == `i')        
    bysort unique_code_agen: egen prop_q_3c_1_1_`i' = mean(is_q_3c_1_1_`i')        
    gen pct_q_3c_1_1_`i' = prop_q_3c_1_1_`i' * 100
}
    bysort unique_code_agen: keep if _n == 1
	
    graph bar (mean) pct_q_3c_1_1_1 pct_q_3c_1_1_2 pct_q_3c_1_1_4 pct_q_3c_1_1_5 pct_q_3c_1_1_6 pct_q_3c_1_1_7 pct_q_3c_1_1_8, ///
		ytitle("Percentage (%) of clients", size(small) orientation(vertical)) ///
		ylabel(, labsize(small)) ///
		blabel(bar, pos(center) size(vsmall) format(%15.1fc)) ///
		title("Type of client charge with low fees", size(medsmall)) ///
		legend(order(1 "Friends & Family" 2 "High-value customers" 3 "New customers" 4 "Long-term customers" ///
		5 "Lower-income customers" 6 "Local customers" 7 "Can switch agents") ///
        size(small) col(2)) ///
		note("Total clients = `: di %6.0fc `total_n''", size(small)) 
	
	graph export "$output/Client Baseline - `date'/25 - q_3c_1_1_w.png", as(png) replace


restore
*q_4_a
preserve
   
	drop if missing(q_4_a)
	set scheme jpalfull
	qui count
	local total_n = r(N)
	
    bysort unique_code_agen: egen n_yes = total(q_4_a == 1)
    bysort unique_code_agen: gen n_total_agen = _N
    gen p_yes = n_yes / n_total_agen
    gen p_no  = 1 - p_yes

    bysort unique_code_agen: keep if _n == 1

    gen pct_yes = p_yes * 100
    gen pct_no  = p_no * 100
	
	graph bar (mean) pct_yes pct_no, /// percent is the default
		ytitle("Percentage (%) of clients", size(medsmall)) ///
		ylabel(0(25)100) /// 
		blabel(bar, pos(outside) size(medsmall) format(%15.1f)) ///
		title("Was the agent present when you first attempted the transaction?", size(medsmall)) ///
		legend(order(1 "Yes" 2 "No") size(medsmall) col(2)) ///
		note("Total clients = `: display %6.0fc `total_n''", size(small))

	graph export "$output/Client Baseline - `date'/26 - client_q_4a_w.png", as(png) replace
	
restore
*q_4_b
preserve
   
	drop if missing(q_4_b)
	set scheme jpalfull
	qui count
	local total_n = r(N)
	
    bysort unique_code_agen: egen n_yes = total(q_4_b == 1)
    bysort unique_code_agen: gen n_total_agen = _N
    gen p_yes = n_yes / n_total_agen
    gen p_no  = 1 - p_yes

    bysort unique_code_agen: keep if _n == 1

    gen pct_yes = p_yes * 100
    gen pct_no  = p_no * 100
	
	graph bar (mean) pct_yes pct_no, /// percent is the default
		ytitle("Percentage (%) of clients", size(medsmall)) ///
		ylabel(0(25)100) /// 
		blabel(bar, pos(outside) size(medsmall) format(%15.1f)) ///
		title("Was the agent able to complete the exact transaction you wanted to do?", size(medsmall)) ///
		legend(order(1 "Yes" 2 "No") size(medsmall) col(2)) ///
		note("Total clients = `: display %6.0fc `total_n''", size(small)) 
		
	graph export "$output/Client Baseline - `date'/26 - client_q_4b_w.png", as(png) replace
	
restore
*q_4c
preserve

    drop if missing(q_4_c)
	set scheme jpalfull
	qui count
	local total_n = r(N)

    forvalues i = 1/6 {
        gen is_q_4_c_`i' = (q_4_c == `i')        
        bysort unique_code_agen: egen prop_q_4_c_`i' = mean(is_q_4_c_`i')        
        gen pct_q_4_c_`i' = prop_q_4_c_`i' * 100
    }

    bysort unique_code_agen: keep if _n == 1
	
    graph bar (mean) pct_q_4_c_1 pct_q_4_c_2 pct_q_4_c_3 pct_q_4_c_4 pct_q_4_c_5 pct_q_4_c_6, ///
		ytitle("Percentage (%) of clients", size(medsmall) orientation(vertical)) ///
		ylabel(0(10)60) ///
		blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
		title("Was the agent able to complete the exact transaction you wanted to do?", size(medsmall)) ///
		subtitle("", size(medsmall)) ///
		legend(order(1 "No wait time" 2 " 5-10 minutes" 3 "10-15 minutes" 4 "15-30 minutes" 5 " 30-45 minutes" ///
		6 "More than 45 minutes") ///
		size(medsmall) col(2)) ///
		note("Total clients = `: di %6.0fc `total_n''", size(small))

	graph export "$output/Client Baseline - `date'/26 - client_q_4c__w.png", as(png) replace
	
restore
*q_4d
preserve

    drop if missing(q_4_d)
	set scheme jpalfull
	qui count
	local total_n = r(N)

    forvalues i = 1/5 {
        gen is_q_4_d_`i' = (q_4_d == `i')        
        bysort unique_code_agen: egen prop_q_4_d_`i' = mean(is_q_4_d_`i')        
        gen pct_q_4_d_`i' = prop_q_4_d_`i' * 100
    }

    bysort unique_code_agen: keep if _n == 1
	
    graph bar (mean) pct_q_4_d_1 pct_q_4_d_2 pct_q_4_d_3 pct_q_4_d_4 pct_q_4_d_5, ///
		ytitle("Percentage (%) of clients", size(medsmall) orientation(vertical)) ///
		ylabel(0(25)90) ///
		blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
		title("How many times did you have to visit the agent ", size(medsmall)) ///
		subtitle("until the transaction you wanted to make was successful?", size(medsmall)) ///
		legend(order(1 "First visit" 2 "2 times" 3 "3 times" 4 "4 times" 5 "5 or more times") ///
		size(medsmall) col(2)) ///
		note("Total clients = `: di %6.0fc `total_n''", size(small))

	graph export "$output/Client Baseline - `date'/26 - client_q_4d__w.png", as(png) replace
	
restore
*q_4e
preserve
   
	drop if missing(q_4_e)
	set scheme jpalfull
	qui count
	local total_n = r(N)
	
    bysort unique_code_agen: egen n_yes = total(q_4_e == 1)
    bysort unique_code_agen: gen n_total_agen = _N
    gen p_yes = n_yes / n_total_agen
    gen p_no  = 1 - p_yes

    bysort unique_code_agen: keep if _n == 1

    gen pct_yes = p_yes * 100
    gen pct_no  = p_no * 100
	
	graph bar (mean) pct_yes pct_no, /// percent is the default
		ytitle("Percentage (%) of clients", size(medsmall)) ///
		ylabel(0(25)100) /// 
		blabel(bar, pos(outside) size(medsmall) format(%15.1f)) ///
		title("Did the agent clearly tell you the amount of the fee they would charge", size(medsmall)) ///
		subtitle("in addition to the transaction amount?", size(medsmall)) ///
		legend(order(1 "Yes" 2 "No") size(medsmall) col(2)) ///
		note("Total clients = `: display %6.0fc `total_n''", size(small)) 
		
	graph export "$output/Client Baseline - `date'/26 - client_q_4e_w.png", as(png) replace

	/*
restore
*q_5a
preserve

    drop if missing(q_5a_11)

    forvalues i = 11/10 {
        gen is_q_5a_1_`i' = (q_5a_1 == `i')        
        bysort unique_code_agen: egen prop_q_5a_1_`i' = mean(is_q_5a_1_`i')        
        gen pct_q_5a_1_`i' = prop_q_5a_1_`i' * 100
    }

    bysort unique_code_agen: keep if _n == 1
    set scheme jpalfull
	gen clients_n = _n
	qui sum clients_n 
	
    graph bar (mean) pct_q_5a_1_1 pct_q_5a_1_2 pct_q_5a_1_3 pct_q_5a_1_4 pct_q_5a_1_5 pct_q_5a_1_6 pct_q_5a_1_7 pct_q_5a_1_8 ///
	pct_q_5a_1_9 pct_q_5a_1_10, ///
		ytitle("Percentage (%) of clients", size(small) orientation(vertical)) ylabel(0(5)20, labsize(small)) ///
		blabel(bar, pos(center) size(vsmall) format(%15.1fc)) ///
		title("Most important characteristics of an agent", size(medsmall)) ///
		subtitle("", size(medsmall)) ///
		legend(order(1 "Prior customer" 2 "Answers clearly" 3 "Close proximity" 4 "Sufficient cash" 5 "Price transparency" ///
		6 "Always available" 7 "Lowest price" 8 "Bank-affiliated " 9 "Trusted agent" 10 "Same price for all") size(vsmall) col(3)) ///
		note("Total clients = `: di %6.0fc `total_n''", size(small)) 
		
		graph export "$output/Client Baseline - `date'/27 - client_q_5a_w.png", as(png) replace
*/	


restore
*q_5b
preserve

    drop if missing(q_5b)
	set scheme jpalfull
	qui count
	local total_n = r(N)

    forvalues i = 1/2 {
        gen is_q_5b_`i' = (q_5b == `i')        
        bysort unique_code_agen: egen prop_q_5b_`i' = mean(is_q_5b_`i')        
        gen pct_q_5b_`i' = prop_q_5b_`i' * 100
    }

    bysort unique_code_agen: keep if _n == 1
	
    graph bar (mean) pct_q_5b_1 pct_q_5b_2, ///
		ytitle("Percentage (%) of clients", size(medsmall) orientation(vertical)) ///
		ylabel(0(20)60) ///
		blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
		title("Which of the following statements do you {bf:agree with most}?", size(medsmall)) ///
		subtitle(" ", size(medsmall)) ///
		legend(order(1 "Continue doing business w/ regular agent, even if others offer lower prices" ///
		2 "Change to other agents who offer lower prices") size(small) col(1)) ///
		note("Total clients = `: di %6.0fc `total_n''", size(small))

	graph export "$output/Client Baseline - `date'/28 - client_q_5b_w.png", as(png) replace
	
	
restore
*q_6a
preserve

    drop if missing(q_6a)
	set scheme jpalfull
	qui count
	local total_n = r(N)

    forvalues i = 1/4 {
        gen is_q_6a_`i' = (q_6a == `i')        
        bysort unique_code_agen: egen prop_q_6a_`i' = mean(is_q_6a_`i')        
        gen pct_q_6a_`i' = prop_q_6a_`i' * 100
    }

    bysort unique_code_agen: keep if _n == 1
	
    graph bar (mean) pct_q_6a_1 pct_q_6a_2 pct_q_6a_3 pct_q_6a_4, ///
		ytitle("Percentage (%) of clients", size(medsmall) orientation(vertical)) ///
		ylabel(0(10)50) ///
		blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
		title("Client reaction to being overcharged – {bf:other client}", size(medsmall)) ///
		subtitle("How would you react?", size(medsmall)) ///
		legend(order(1 "Indifferent" 2 "Unfair, switch" 3 "Unfair, stay" 4 "Fair") size(small) col(4)) ///
		note("Total clients = `: di %6.0fc `total_n''", size(small)) 
		
	graph export "$output/Client Baseline - `date'/29 -  client_q_6a_w.png", as(png) replace
	
restore
*q_6b
preserve

    drop if missing(q_6b)
	set scheme jpalfull
	qui count
	local total_n = r(N)

    forvalues i = 1/4 {
        gen is_q_6b_`i' = (q_6b == `i')        
        bysort unique_code_agen: egen prop_q_6b_`i' = mean(is_q_6b_`i')        
        gen pct_q_6b_`i' = prop_q_6b_`i' * 100
    }

    bysort unique_code_agen: keep if _n == 1
	
    graph bar (mean) pct_q_6b_1 pct_q_6b_2 pct_q_6b_3 pct_q_6b_4, ///
		ytitle("Percentage (%) of clients", size(medsmall) orientation(vertical)) ///
		ylabel(0(10)50) ///
		blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
		title("Client reaction to being overcharged – {bf:official fees}", size(medsmall)) ///
		subtitle("How would you react?", size(medsmall)) ///
		legend(order(1 "Indifferent" 2 "Unfair, switch" 3 "Unfair, stay" 4 "Fair") size(small) col(4)) ///
		note("Total clients = `: di %6.0fc `total_n''", size(small)) 
	
	graph export "$output/Client Baseline - `date'/30 - client_q_6b_w.png", as(png) replace
	
restore
*q_6c
preserve

    drop if missing(q_6c)
	set scheme jpalfull
	qui count
	local total_n = r(N)

    forvalues i = 1/3 {
        gen is_q_6c_`i' = (q_6c == `i')        
        bysort unique_code_agen: egen prop_q_6c_`i' = mean(is_q_6c_`i')        
        gen pct_q_6c_`i' = prop_q_6c_`i' * 100
    }

    bysort unique_code_agen: keep if _n == 1

    graph bar (mean) pct_q_6c_1 pct_q_6c_2 pct_q_6c_3, ///
		ytitle("Percentage (%) of clients", size(medsmall) orientation(vertical)) ///
		ylabel(0(10)75) ///
		blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
		title("Two Agents with the same fee of Rp3.000 for a cash withdrawal.", size(medsmall)) ///
		subtitle("Which agent would you prefer to {bf:regularly} do transactions with?", size(medsmall)) ///
		legend(order(1 "Agent A" 2 "Agent B" 3 "Indifferent") size(medsmall) col(3)) ///
		note("Total clients = `: di %6.0fc `total_n''", size(small)) 
	
	graph export "$output/Client Baseline - `date'/31 - client_q_6c_w.png", as(png) replace
	
	
restore
*q_10a
preserve

    drop if missing(q_10a)
	set scheme jpalfull
	qui count
	local total_n = r(N)
	
    forvalues i = 1/3 {
        gen is_q_10a_`i' = (q_10a == `i')        
        bysort unique_code_agen: egen prop_q_10a_`i' = mean(is_q_10a_`i')        
        gen pct_q_10a_`i' = prop_q_10a_`i' * 100
    }

    bysort unique_code_agen: keep if _n == 1
	
    graph bar (mean) pct_q_10a_1 pct_q_10a_2 pct_q_10a_3, ///
		ytitle("Percentage (%) of clients", size(medsmall) orientation(vertical)) ///
		ylabel(0(10)70) ///
		blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
		title("Last month, how much {bf:time} do you think your BM Agent spent", size(medsmall)) ///
		subtitle("{bf:advertising} his/her services to people in the village?", size(medsmall)) ///
		legend(order(1 "None at all" 2 "Some time" 3 "A lot of time") size(medsmall) col(3)) ///
		note("Total clients = `: di %6.0fc `total_n''", size(small))

	graph export "$output/Client Baseline - `date'/35 - client_q_10a_w.png", as(png) replace


restore
*q_10b
preserve

    drop if missing(q_10b)
	set scheme jpalfull
	qui count
	local total_n = r(N)

    forvalues i = 1/4 {
        gen is_q_10b_`i' = (q_10b == `i')        
        bysort unique_code_agen: egen prop_q_10b_`i' = mean(is_q_10b_`i')        
        gen pct_q_10b_`i' = prop_q_10b_`i' * 100
    }

    bysort unique_code_agen: keep if _n == 1
	
    graph bar (mean) pct_q_10b_1 pct_q_10b_2 pct_q_10b_3 pct_q_10b_4, ///
		ytitle("Percentage (%) of clients", size(medsmall) orientation(vertical)) ///
		ylabel(0(10)80) ///
		blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
		title("Do you agree with this statement?", size(small)) ///
		subtitle("Last month, BM Agent did all he/she could {bf:to convince village people to adopt the agent products}", size(small)) ///
		legend(order(1 "Disagree completely" 2 "Disagree" 3 "Agree" 4 "Fully agree") size(medsmall) col(2)) ///
		note("Total clients = `: di %6.0fc `total_n''", size(small))
	
graph export "$output/Client Baseline - `date'/36 - client_q_10b_w.png", as(png) replace


restore
*q_10e
preserve
   
	drop if missing(q_10e)
	set scheme jpalfull
	qui count
	local total_n = r(N)
	
    bysort unique_code_agen: egen n_yes = total(q_10e == 1)
    bysort unique_code_agen: gen n_total_agen = _N
    gen p_yes = n_yes / n_total_agen
    gen p_no  = 1 - p_yes

    bysort unique_code_agen: keep if _n == 1

    gen pct_yes = p_yes * 100
    gen pct_no  = p_no * 100
	
	graph bar (mean) pct_yes pct_no, /// percent is the default
	ytitle("Percentage (%) of clients", size(medsmall) orientation(vertical)) ///
		ylabel(0(10)60) ///
		blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
		title("Last month, has the agent approached you with", size(medsmall)) ///
		subtitle("{bf:new information about prices} for Bank Mandiri transactions?", size(medsmall)) ///
		legend(order(1 "Yes" 2 "No") size(medsmall) col(2)) ///
		note("Total clients = `: di %6.0fc `total_n''", size(small))

	graph export "$output/Client Baseline - `date'/39 - client_q_10e_w.png", as(png) replace

restore
*q_10f
preserve

	drop if missing(q_10f)
	set scheme jpalfull
	qui count
	local total_n = r(N)
	
    bysort unique_code_agen: egen n_yes = total(q_10f == 1)
    bysort unique_code_agen: gen n_total_agen = _N
    gen p_yes = n_yes / n_total_agen
    gen p_no  = 1 - p_yes

    bysort unique_code_agen: keep if _n == 1

    gen pct_yes = p_yes * 100
    gen pct_no  = p_no * 100
	
	graph bar (mean) pct_yes pct_no, /// percent is the default
		ytitle("Percentage (%) of clients", size(medsmall) orientation(vertical)) ///
		ylabel(0(10)60) ///
		blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
		title("Have you ever taken any {bf:benefits} from your agent ", size(medsmall)) ///
		subtitle("that are not related to their branchless banking business?", size(medsmall)) ///
		legend(order(1 "Yes" 2 "No") size(medsmall) col(2)) ///
		note("Total clients = `: di %6.0fc `total_n''", size(small))

	graph export "$output/Client Baseline - `date'/40 - client_q_10f_w.png", as(png) replace
	
restore
*q_11a
preserve

	drop if missing(q_11a)
	set scheme jpalfull
	qui count
	local total_n = r(N)
	
    bysort unique_code_agen: egen n_yes = total(q_11a == 1)
    bysort unique_code_agen: gen n_total_agen = _N
    gen p_yes = n_yes / n_total_agen
    gen p_no  = 1 - p_yes

    bysort unique_code_agen: keep if _n == 1

    gen pct_yes = p_yes * 100
    gen pct_no  = p_no * 100
	
	graph bar (mean) pct_yes pct_no, /// percent is the default
		ytitle("Percentage (%) of clients", size(medsmall) orientation(vertical)) ///
		ylabel(0(10)60) ///
		blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
		title("Which of the following statements do you agree with most?", size(medsmall)) ///
		subtitle(" ", size(medsmall)) ///
		legend(order(1 "There are many agents in my area" 2 "There are limited agents in my area") size(medsmall) col(1)) ///
		note("Total clients = `: di %6.0fc `total_n''", size(small))

	graph export "$output/Client Baseline - `date'/43 - client_q_11a_w.png", as(png) replace
	
	
restore
*q_12b
preserve

    drop if missing(q_12b)
	set scheme jpalfull
	qui count
	local total_n = r(N)

    forvalues i = 1/4 {
        gen is_q_12b_`i' = (q_12b == `i')        
        bysort unique_code_agen: egen prop_q_12b_`i' = mean(is_q_12b_`i')        
        gen pct_q_12b_`i' = prop_q_12b_`i' * 100
    }

    bysort unique_code_agen: keep if _n == 1
	
    graph bar (mean) pct_q_12b_1 pct_q_12b_2 pct_q_12b_3 pct_q_12b_4, ///
		ytitle("Percentage (%) of clients", size(medsmall) orientation(vertical)) ///
		ylabel(0(5)40) ///
		blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
		title("{bf:For how long} have you known your {bf:BM Agent}?", size(medsmall)) ///
		subtitle(" ", size(medsmall)) ///
		legend(order(1 "A few months" 2 "For about a year" 3 "Between 1-5 years" 4 "Longer than 5 years") size(small) col(2)) ///
		note("Total clients = `: di %6.0fc `total_n''", size(small))

	graph export "$output/Client Baseline - `date'/47 - client_q_12b_w.png", as(png) replace
	
restore
*q_12c
preserve

    drop if missing(q_12c)
	set scheme jpalfull
	qui count
	local total_n = r(N)

    forvalues i = 1/8 {
        gen is_q_12c_`i' = (q_12c == `i')        
        bysort unique_code_agen: egen prop_q_12c_`i' = mean(is_q_12c_`i')        
        gen pct_q_12c_`i' = prop_q_12c_`i' * 100
    }

    bysort unique_code_agen: keep if _n == 1
	
    graph bar (mean) pct_q_12c_1 pct_q_12c_2 pct_q_12c_3 pct_q_12c_4 pct_q_12c_5 pct_q_12c_6 pct_q_12c_7 pct_q_12c_8, ///
		ytitle("Percentage (%) of clients", size(medsmall) orientation(vertical)) ///
		ylabel(0(10)40) ///
		blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
		title("How often do you {bf:talk} with your {bf:BM Agent}?", size(medsmall)) ///
		subtitle(" ", size(medsmall)) ///
		legend(order(1 "Every day" 2 "A few times a week" 3 "Once a week" 4 "A few times per month" 5 "Once a month" ///
		6 "Every 3 months" 7 "Every 6 months" 8 "Once a year") size(small) col(3)) ///
		note("Total clients = `: di %6.0fc `total_n''", size(small)) 

	graph export "$output/Client Baseline - `date'/48 - client_q_12c_w.png", as(png) replace

restore
*q_12e
preserve

	drop if missing(q_12e)
	set scheme jpalfull
	qui count
	local total_n = r(N)
	
    bysort unique_code_agen: egen n_yes = total(q_12e == 1)
    bysort unique_code_agen: gen n_total_agen = _N
    gen p_yes = n_yes / n_total_agen
    gen p_no  = 1 - p_yes

    bysort unique_code_agen: keep if _n == 1

    gen pct_yes = p_yes * 100
    gen pct_no  = p_no * 100
	
	graph bar (mean) pct_yes pct_no, ///
		ytitle("Percentage (%) of clients", size(medsmall) orientation(vertical)) ///
		ylabel(0(25)100) ///
		blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
		title("Which of the following best describes your opinion about", size(medsmall)) ///
		subtitle("{bf:banking agents in general}?", size(medsmall)) ///
		legend(order(1 "Not honest and often overcharge customers" 2 "Honest and charge the correct prices") size(small) col(1)) ///
		note("Total clients = `: di %6.0fc `total_n''", size(small)) 

	graph export "$output/Client Baseline - `date'/51 - client_q_12e_w.png", as(png) replace

	
restore
*q_12h
preserve

	drop if missing(q_12h)
	set scheme jpalfull
	qui count
	local total_n = r(N)
	
    bysort unique_code_agen: egen n_yes = total(q_12h == 1)
    bysort unique_code_agen: gen n_total_agen = _N
    gen p_yes = n_yes / n_total_agen
    gen p_no  = 1 - p_yes

    bysort unique_code_agen: keep if _n == 1

    gen pct_yes = p_yes * 100
    gen pct_no  = p_no * 100
	
	graph bar (mean) pct_yes pct_no, /// 
		ytitle("Percentage (%) of clients", size(medsmall) orientation(vertical)) ///
		ylabel(0(10)70) ///
		blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
		title("Do you use Mandiri Agen {bf:to send or receive business payments}?", size(medsmall)) ///
		subtitle(" ", size(medsmall)) ///
		legend(order(1 "Yes" 2 "No") size(medsmall) col(2)) ///
		note("Total clients = `: di %6.0fc `total_n''", size(small))  

	graph export "$output/Client Baseline - `date'/55 - client_q_12h_w.png", as(png) replace

restore
*q_12i
preserve

	drop if missing(q_12i)
	set scheme jpalfull
	qui count
	local total_n = r(N)
	
    bysort unique_code_agen: egen n_yes = total(q_12i == 1)
    bysort unique_code_agen: gen n_total_agen = _N
    gen p_yes = n_yes / n_total_agen
    gen p_no  = 1 - p_yes

    bysort unique_code_agen: keep if _n == 1

    gen pct_yes = p_yes * 100
    gen pct_no  = p_no * 100
	
	graph bar (mean) pct_yes pct_no, /// 
		ytitle("Percentage (%) of clients", size(medsmall) orientation(vertical)) ///
		ylabel(0(10)70) ///
		blabel(bar, pos(top) size(medsmall) format(%15.1fc)) ///
		title("Do you use Mandiri Agen {bf:to receive salary payments}?", size(medsmall)) ///
		subtitle(" ", size(medsmall)) ///
		legend(order(1 "Yes" 2 "No") size(medsmall) col(2)) ///
		note("Total clients = `: di %6.0fc `total_n''", size(small)) 

	graph export "$output/Client Baseline - `date'/56 - client_q_12i_w.png", as(png) replace



	
